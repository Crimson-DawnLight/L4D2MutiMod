#if defined _crimson_spawn_SI_included_
 #endinput
#endif
#define _crimson_spawn_SI_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define DEBUG 0
#define BENCHMARK 0

#define _crimson_spawn_SI_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_spawn_SI_usedfor_plugins
public Plugin myinfo = {
    name = "L4D2 Spawn SI",
    author = "crimson",
    description = "特感刷出控制(数量上限 / 产生比重 / 刷出时机)",
    version = "1.0.0",
    url = ""
};
#endif
/******************************************************
**          	        const
*******************************************************/
enum {
	SPAWN_NO_PREFERENCE = -1,				// -1
	SPAWN_ANYWHERE,							// 0
	SPAWN_BEHIND_SURVIVORS,					// 1
	SPAWN_NEAR_IT_VICTIM,					// 2
	SPAWN_SPECIALS_IN_FRONT_OF_SURVIVORS,	// 3
	SPAWN_SPECIALS_ANYWHERE,				// 4
	SPAWN_FAR_AWAY_FROM_SURVIVORS,			// 5
	SPAWN_ABOVE_SURVIVORS,					// 6
	SPAWN_IN_FRONT_OF_SURVIVORS,			// 7
	SPAWN_VERSUS_FINALE_DISTANCE,			// 8
	SPAWN_LARGE_VOLUME,						// 9
	SPAWN_NEAR_POSITION,					// 10
}

enum {
	SI_SMOKER,		// 0
	SI_BOOMER,		// 1
	SI_HUNTER,		// 2
	SI_SPITTER,		// 3
	SI_JOCKEY,		// 4
	SI_CHARGER,		// 5

	SI_MAX_SIZE		// 6
} 
#define SI_TANK         8

static const char g_sZombieClass[SI_MAX_SIZE][] = {
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger"
};
/******************************************************
**          	        variable
*******************************************************/
Handle
	g_hSpawnTimer,
	g_hRetryTimer,
	g_hUpdateTimer,
	g_hSuicideTimer;

// 只剩引擎自己的 convar 句柄; 本模块的可调项全部改由配置文件提供 (见 LoadConfigFile)
ConVar
	g_cSpawnRange,
	g_cDiscardRange,
	g_cSafeSpawnRange,
	g_cVsBossFlowBuffer;

// 配置文件: 本模块所有可调项都在这里 —— 原来那 28 个 ss_* convar 已废弃
#define SPAWN_CONFIG_FILE		"logs/l4d2_spawn_SI.cfg"

static char g_sConfigPath[PLATFORM_MAX_PATH];
static float g_fSpawnRangeMin = 200.0;		// 原 ss_spawnrange_min
static float g_fSpawnRangeMax = 1500.0;		// 原 ss_spawnrange_max

float
	g_fSpawnTimes[MAXPLAYERS + 1],
	g_fActionTimes[MAXPLAYERS + 1],
	g_pos[MAXPLAYERS+1][3];


enum struct SISpawnData {
	bool InSpawnTime;
	bool ScaleWeights;
	bool LeftSafeArea;
	bool Mode;

	int SILimit;
	int SpawnSize;
	int Direction;
	int SpawnLimits[SI_MAX_SIZE];
	int SpawnWeights[SI_MAX_SIZE];
	int SpawnTimeMode;
	int TankStatusAction;
	int SILimitCache;// = -1;
	int SpawnLimitsCache[SI_MAX_SIZE];
	int SpawnWeightsCache[SI_MAX_SIZE];
	int TankStatusLimits[SI_MAX_SIZE];
	int TankStatusWeights[SI_MAX_SIZE];
	int SpawnSizeCache;// = -1;
	int SpawnCounts[SI_MAX_SIZE];
	int BaseLimit;
	int BaseSize;
	int CurrentClass;// = -1;
	int LeadingFlow;
	int FinaleStarted;// = 1;

	float SpawnTimeMin;
	float SpawnTimeMax;
	float ExtraLimit;
	float ExtraSize;
	float SuicideTime;

	float StuckTime;
	float StuckInspect;
	float FirstSpawnTime;
	float VsBossFlowBuffer;

	void Reset() {
		static const SISpawnData def = { 
			false, false, false, false, 
			0, 0, 0, 
			{-1, ...}, {-1, ...}, 
			0, 0, 0, 
			{-1, ...}, {-1, ...}, {-1, ...}, {-1, ...}, 
			-1, {0, ...}, 0, 0, -1, 0, -1,
			0.0, 0.0, 0.0, 0.0, 0.0, 
			0.0, 0.0, 0.0, 0.0
		};
		this = def;
	}


	void InitTimes() {

		if (this.SpawnTimeMin > this.SpawnTimeMax)
			this.SpawnTimeMin = this.SpawnTimeMax;
			
		if (this.SILimit <= 1 || this.SpawnTimeMode <= 0)
			g_fSpawnTimes[0] = this.SpawnTimeMax;
		else {
			float unit = (this.SpawnTimeMax - this.SpawnTimeMin) / (this.SILimit - 1);
			switch (this.SpawnTimeMode) {
				case 1: {
					g_fSpawnTimes[0] = this.SpawnTimeMin;
					for (int i = 1; i <= MaxClients; i++)
						g_fSpawnTimes[i] = i < this.SILimit ? (g_fSpawnTimes[i - 1] + unit) : this.SpawnTimeMax;
				}

				case 2: {
					g_fSpawnTimes[0] = this.SpawnTimeMax;
					for (int i = 1; i <= MaxClients; i++)
						g_fSpawnTimes[i] = i < this.SILimit ? (g_fSpawnTimes[i - 1] - unit) : this.SpawnTimeMax;
				}
			}	
		} 
	}


}

static SISpawnData g_eSIData;

// enum struct SISpawnInfo {
// 	DynamicDetour DTR_OnFirstSurvivorLeftSafeArea;

// }
// static SISpawnInfo g_eSIInfo;
/******************************************************
**          			main
*******************************************************/
/**
 * @brief	提供多特的封装
 * @note	public 	注释后的函数, 可供外部调用
 * @note    forward 注释后的函数, 需要在对应命名 forward 转发调用
 * @note	private 注释后的函数, 请不要外部调用

 * @note	外部通过调用 property 来访问静态数据
 */
methodmap SISpawnManager {
	// private 
	// public static void StartSDKCall(GameData hGameData) {
	// 	g_eWHInfo.DTR_OnFirstSurvivorLeftSafeArea = DynamicDetour.FromConf(hGameData, "L4DD::CDirector::OnFirstSurvivorLeftSafeArea");
    //     if(!g_eWHInfo.DTR_OnFirstSurvivorLeftSafeArea)
    //         SetFailState("Failed to find 'CDirector::OnFirstSurvivorLeftSafeArea' signature");
        
    //     if(!g_eWHInfo.DTR_OnFirstSurvivorLeftSafeArea.Enable(Hook_Post, _OnFirstSurvivorLeftSafeArea_Post))
    //         SetFailState("Failed to detour 'CTerrorMeleeWeapon::StartMeleeSwing'");
	// }
	// private find targetPos
	public static bool IsValidNavArea(float vecPos[3]) {
        return L4D2Direct_GetTerrorNavArea(vecPos) != Address_Null;
        }
    public static int GetNavProgressPercent(const float vecPos[3], float maxDist) {
		Address pNav = view_as<Address>(L4D_GetNearestNavArea(vecPos, maxDist));

		if(pNav == Address_Null)	return -1;

		float max_flow_dist = L4D2Direct_GetMapMaxFlowDistance();
        float now_nav_flow = L4D2Direct_GetTerrorNavAreaFlow(pNav) / max_flow_dist;
        float now_nav_promixity = now_nav_flow + g_eSIData.VsBossFlowBuffer / max_flow_dist;

        return now_nav_promixity < 1.0 ? RoundToNearest(now_nav_promixity * 100.0) : 100;
        }
    public static bool IsPosAhead(const float targetPos[3], const float defPos[3]) {
		// *@note	whether targetPos is ahead of all players
        if (!g_eSIData.Mode || g_eSIData.LeadingFlow > 90 || g_eSIData.FinaleStarted != 1)
            return true;

        int pos_flow = SISpawnManager.GetNavProgressPercent(targetPos, 300.0);
    	int target_flow = SISpawnManager.GetNavProgressPercent(defPos, 300.0);

		// *@note Bug Fix: pos_flow + 300 -> pos_flow + 3
        return pos_flow + 3 >= target_flow;
        }
    
    public static bool IsNearAnySurv(const float targetPos[3], bool IsRefresh) {
		static const bool DefBool[MAXPLAYERS+1] = { false, ...};
		static bool survivorValid[MAXPLAYERS+1];
		static float survivorPos[MAXPLAYERS+1][3];

		if(IsRefresh) {
			survivorValid = DefBool;

			for(int i = 0; i <= MAXPLAYERS; i++)
				survivorPos[i] = NULL_VECTOR;
			
			for (int i = 1; i <= MaxClients; i++) {
				if ( !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) 
					continue;
				
				survivorValid[i] = true;
				GetClientAbsOrigin(i, survivorPos[i]);
			}

			return false;
		}

        for (int i = 1; i <= MaxClients; i++) 
			if(survivorValid[i] && GetVectorDistance(targetPos, survivorPos[i]) < 600.0)
				return true;

        return false;
        }
    public static bool IsPosStuck(int client, const float targetPos[3]) {
		// *@note	check wheher SI will be stucked in target position
        static float vMins[3], vMaxs[3], vEnd[3];
        GetClientMins(client, vMins);
        GetClientMaxs(client, vMaxs);
        vEnd[0] = targetPos[0];
        vEnd[1] = targetPos[1];
        vEnd[2] = targetPos[2] + 70.0;
        TR_TraceHullFilter(targetPos, vEnd, vMins, vMaxs, MASK_NPCSOLID_BRUSHONLY, TR_EntityFilter);
        return TR_DidHit();
        }
    public static bool IsPosVisible(const float targetPos[3], bool IsRefresh) {
		// *@note	whehter target position can be saw by any survivor
        static const bool DefBool[MAXPLAYERS+1] = { false, ...};
		static bool survivorValid[MAXPLAYERS+1];
		static float survivorEyePos[MAXPLAYERS+1][3];
    
		if(IsRefresh) {
			survivorValid = DefBool;

			for(int i = 0; i <= MAXPLAYERS; i++)
				survivorEyePos[i] = NULL_VECTOR;
			
			for (int i = 1; i <= MaxClients; i++) {
				if ( !IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) 
					continue;
				
				survivorValid[i] = true;
				GetClientEyePosition(i, survivorEyePos[i]);
			}

			return true;
		}

		float endPos[3];
		endPos = targetPos;
		endPos[2] += 50.0;

		for (int i = 1; i <= MaxClients; i++) {
			if(!survivorValid[i])	continue;
			
			TR_TraceRayFilter(survivorEyePos[i], endPos, MASK_VISIBLE, RayType_EndPoint, TR_EntityFilter);

			if (!TR_DidHit())
				return true;
		}

        return false;
        }
    public static float GetPosHeightFromGround(float vPos[3]) {
		// *@note	Get the distance of target position from ground
        static float vDown[3];
        vPos[2] += 50.0;
        vDown = vPos;
        vDown[2] -= 100000.0;
        Handle hndl = TR_TraceHullFilterEx(vPos, vDown, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID, TR_EntityFilter);
        if (TR_DidHit(hndl)) {
            TR_GetEndPosition(vPos, hndl);
            delete hndl;
            return vPos[2];
        }
        delete hndl;
        return vPos[2] - 50.0;
        }
	public static float GetRanFloat(float min, float max) {
		return (GetURandomFloat() * (max - min)) + min;
		}
	public static void GetRanVec(float vecPos[3], int areaType) {
		static const int AreaDirection[8][2] = {
			{  1,  1 },
			{ -1, -1 },
			{  1, -1 },
			{ -1,  1 },
			{  1,  0 },
			{ -1,  0 },
			{  0,  1 },
			{  0, -1 }
		};

		vecPos[0] += AreaDirection[areaType][0] == 0 ? 0.0 : float(AreaDirection[areaType][0]) * SISpawnManager.GetRanFloat(600.0, 1200.0);
		vecPos[1] += AreaDirection[areaType][1] == 0 ? 0.0 : float(AreaDirection[areaType][1]) * SISpawnManager.GetRanFloat(600.0, 1200.0);
		}
	public static bool FindValidLocations(int client, float targetPos[3]) {
		static const int MAX_ENGINE_TRY = 8;
		static const int MAX_MANUAL_TRY = 30;

		float defPos[3];
		GetClientAbsOrigin(client, defPos);

		SISpawnManager.IsPosVisible(targetPos, true);

		// use engine method to find spawn pos
		for (int i = 0; i < MAX_ENGINE_TRY; i++) {
			if (!L4D_GetRandomPZSpawnPosition(client, i + 1, 10, targetPos)) 	continue;
			if (GetVectorDistance(targetPos, defPos) > 1500.0)	continue;
			if (SISpawnManager.IsPosVisible(targetPos, false))	continue;
			
			return true;
		}

		defPos[2] = SISpawnManager.GetPosHeightFromGround(defPos);

		// Start Manually Find spawn pos
		for (int i = 0; i < MAX_MANUAL_TRY; i++) {
			for(int areaType = 0; areaType < 8; areaType++) {
				targetPos = defPos;
				SISpawnManager.GetRanVec(targetPos, areaType);

				if(!SISpawnManager.IsValidNavArea(targetPos))		continue;
				if(!SISpawnManager.IsPosAhead(targetPos, defPos))	continue;
				if( SISpawnManager.IsPosVisible(targetPos, false))	continue;
				if( SISpawnManager.IsPosStuck(client, targetPos))	continue;
				return true;
			}
		}

		SISpawnManager.IsNearAnySurv(targetPos, true);

		for (int i = 0; i < MAX_MANUAL_TRY; i++) {
			for(int areaType = 0; areaType < 8; areaType++) {
				targetPos = defPos;
				SISpawnManager.GetRanVec(targetPos, areaType);

				if(!SISpawnManager.IsValidNavArea(targetPos))		continue;
				if(!SISpawnManager.IsPosAhead(targetPos, defPos))	continue;
				if( SISpawnManager.IsNearAnySurv(targetPos, false))	continue;
				if( SISpawnManager.IsPosStuck(client, targetPos))	continue;
				return true;
			}
		}
		return false;
		}
	
    // private Spawn Queue 
	public static int GetUsedPlayerSpawnSlotCount() {
		int count;
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsClientInKickQueue(i))
				count++;
			else if (IsClientConnected(i) && !IsFakeClient(i))
				count++;
		}

		return count;
		}
	public static int GetSICount() {
		int count;
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsClientInKickQueue(i) && GetClientTeam(i) == 3)
				count++;
		}

		return count;
		}
	public static int GenerateSISpawnIndex() {
		static int totalWeight;
		static int standardizedWeight;
		static int tempWeights[SI_MAX_SIZE];
		static float unit;
		static float random;
		static float intervalEnds[SI_MAX_SIZE];

		totalWeight = 0;
		standardizedWeight = 0;

		for (int i = 0; i < SI_MAX_SIZE; i++) {
			tempWeights[i] = g_eSIData.SpawnCounts[i] < g_eSIData.SpawnLimits[i] ? (g_eSIData.ScaleWeights ? ((g_eSIData.SpawnLimits[i] - g_eSIData.SpawnCounts[i]) * g_eSIData.SpawnWeights[i]) : g_eSIData.SpawnWeights[i]) : 0;
			totalWeight += tempWeights[i];
		}

		unit = 1.0 / totalWeight;
		for (int i = 0; i < SI_MAX_SIZE; i++) {
			if (tempWeights[i] >= 0) {
				standardizedWeight += tempWeights[i];
				intervalEnds[i] = standardizedWeight * unit;
			}
		}

		random = SISpawnManager.GetRanFloat(0.0, 1.0);
		for (int i = 0; i < SI_MAX_SIZE; i++) {
			if (tempWeights[i] > 0 && intervalEnds[i] >= random)
				return i;
		}

		return -1;
		}
	public static void SetSITypeCount() {
		static const int def[SI_MAX_SIZE] = { 0, ...};
		g_eSIData.SpawnCounts = def;

		for (int i = 1; i <= MaxClients; i++) {
			SIBot player = SIBot(i);

			if(!player.IsValidSIQueue)	continue;

			int SIType = player.ZC;			// 引擎 1 基 (1 = Smoker .. 6 = Charger), 与全篇同名变量同义

			if(SIType < 1 || SIType > SI_MAX_SIZE)		continue;

			int typeIndex = SIType - 1;		// 落成 0 基, 才拿去索引
			g_eSIData.SpawnCounts[typeIndex]++;
		}
		}
	public static void ExecuteSpawnQueue(int totalSI, bool retry, int SIType = 0) {
		if (totalSI >= g_eSIData.SILimit)
			return;

		#if BENCHMARK
		g_profiler = new Profiler();
		g_profiler.Start();
		#endif

		int killType = SIType -1;
		int spawnSize;
		ArrayList aQueue = new ArrayList();

		// Kill Incativate SI and spawn another one with same SIType
		if (killType != -1) {
			aQueue.Push(killType);
			g_eSIData.SpawnCounts[killType]++;
		}
		else {
			int allowedSI = g_eSIData.SILimit - totalSI;
			spawnSize = g_eSIData.SpawnSize > allowedSI ? allowedSI : g_eSIData.SpawnSize;

			int ValidClient = SISpawnManager.GetUsedPlayerSpawnSlotCount();

			int exceed = ValidClient + spawnSize;
			if (exceed >= 30)
				spawnSize -= exceed - 29;

			SISpawnManager.SetSITypeCount();

			for (int i = 0; i < spawnSize; i++) {
				killType = SISpawnManager.GenerateSISpawnIndex();
				if (killType == -1)
					break;

				aQueue.Push(killType);
				g_eSIData.SpawnCounts[killType]++;
			}
		}

		spawnSize = aQueue.Length;

		if (spawnSize <= 0) {
			delete aQueue;
			return;
		}

		g_eSIData.InSpawnTime = true;
		int client = SISpawnManager.GetAheadSurvivor();
		
		// There must exist an Alive ahead survivor, or chapter will restart
		if (!SIBot(client).IsSurv)	return;

		g_eSIData.Direction = !retry ? SPAWN_NO_PREFERENCE : (g_eSIData.Mode ? SPAWN_IN_FRONT_OF_SURVIVORS : SPAWN_LARGE_VOLUME);

		int count = 0, SISpawnIndex = 0, nextSIType = 0;
		float spawnPos[3];

		for (int i = 0; i < spawnSize; i++) {
			if (!SISpawnManager.FindValidLocations(client, spawnPos))	continue;
			
			nextSIType = aQueue.Get(i) + 1;
			spawnPos[2] += 5.0;
			SISpawnIndex = L4D2_SpawnSpecial(nextSIType, spawnPos, NULL_VECTOR);
			spawnPos[2] -= 5.0;

			if (SISpawnIndex <= 0 || SISpawnIndex > MaxClients)	continue;

			SIBot player = SIBot(SISpawnIndex);
			player.Ducked = true;
			player.flags |= FL_DUCKING;
			count++;
		}

		g_eSIData.InSpawnTime = false;

		#if BENCHMARK
		g_profiler.Stop();
		PrintToServer("[SS] ProfilerTime: %f", g_profiler.Time);
		#endif

		if (retry) {
			if (!count) {
				#if DEBUG
				PrintToServer("[SS] Retry spawn SI! spawned:%d failed:%d", count, aQueue.Length - count);
				#endif
				g_hRetryTimer = CreateTimer(1.0, tmrRetrySpawn, false);
			}
		}
		#if DEBUG
		else {
			if (!count)
				PrintToServer("[SS] Spawn SI failed! spawned:%d failed:%d", count, aQueue.Length - count);
		}
		#endif

		delete aQueue;
		}
    // private 
	public static void TankStatusActoin(bool isTankAlive) {
        static bool loaded;
        if (!isTankAlive) {
            if (loaded) {
                loaded = false;
                SISpawnManager.LoadCacheSpawnLimits();
                SISpawnManager.LoadCacheSpawnWeights();
            }
        }
        else {
            if (!loaded && g_eSIData.TankStatusAction) {
                loaded = true;
                for (int i; i < SI_MAX_SIZE; i++) {
                    g_eSIData.SpawnLimitsCache[i] = g_eSIData.SpawnLimits[i];
                    g_eSIData.SpawnWeightsCache[i] = g_eSIData.SpawnWeights[i];
                }
                SISpawnManager.LoadCacheTankCustom();
            }
        }
    	}
	public static void SetSIType(int class) {
		g_eSIData.SpawnLimitsCache = g_eSIData.SpawnLimits;
		g_eSIData.SpawnWeightsCache = g_eSIData.SpawnWeights;

		for (int i; i < SI_MAX_SIZE; i++)		
			g_eSIData.SpawnLimits[i] = i != class ? 0 : g_eSIData.SILimit;

		g_eSIData.CurrentClass = class;
		}
	// private 
	public static int GetAheadSurvivor() {
		static int i, leader;
		static float flow, MaxFlow;
		leader = 0;
		MaxFlow = 0.0;
		for (i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || GetEntProp(i, Prop_Send, "m_isIncapacitated") || !IsPlayerAlive(i))
				continue;

			flow = L4D2Direct_GetFlowDistance(i);
			if (flow > MaxFlow) {
				MaxFlow = flow;
				leader = i;
			}
		}
		if (leader > 0 && g_eSIData.FinaleStarted == 1 && (MaxFlow / L4D2Direct_GetMapMaxFlowDistance() * 100.0) > 0.0)
			g_eSIData.Mode = true;
		else {
			g_eSIData.Mode = false;
			leader = SISpawnManager.GetAnyRandomSurvivor();
		}
		return leader;
		}
	public static int GetAnyRandomSurvivor() {
		int client;
		ArrayList aClients = new ArrayList();

		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && !GetEntProp(i, Prop_Send, "m_isIncapacitated") && IsPlayerAlive(i))
				aClients.Push(i);
		}

		if (aClients.Length > 0) {
			SetRandomSeed(GetGameTickCount());
			client = aClients.Get(GetRandomInt(0, aClients.Length - 1));
		}
		delete aClients;

		return client;
		}
	// private 
	public static void KillInactiveSI(int client, int SIType) {
		#if DEBUG
		PrintToServer("[SS] Kill inactive SI -> %N", client);
		#endif
		ForcePlayerSuicide(client);

		if (!g_hRetryTimer)
			SISpawnManager.ExecuteSpawnQueue(SISpawnManager.GetSICount(), true, SIType);
		}
	public static int SetRandomType() {
		static int class;
		static int zombieClass[SI_MAX_SIZE] = {0, 1, 2, 3, 4, 5};

		class %= SI_MAX_SIZE;
		if (!class)
			SortIntegers(zombieClass, sizeof zombieClass, Sort_Random);

		SISpawnManager.SetSIType(zombieClass[class]);
		g_eSIData.CurrentClass += SI_MAX_SIZE;

		return zombieClass[class++];
		}
    public static void TweakSettings(bool restore) {
        if (!restore) {
            g_cSpawnRange.SetInt(RoundToNearest(g_fSpawnRangeMax));
            g_cDiscardRange.SetInt(g_cSpawnRange.IntValue + 500);
            g_cSafeSpawnRange.SetInt(RoundToNearest(g_fSpawnRangeMin));
        }
        else {
            g_cSpawnRange.RestoreDefault();
            g_cDiscardRange.RestoreDefault();
            g_cSafeSpawnRange.RestoreDefault();
        }
        }
    
	public static void SetSpawnCount() {
		int count;
		int limit;
		int spawnSize;
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
				count++;
		}

		count -= 4;
		if (count < 1) {
			limit = g_eSIData.BaseLimit;
			spawnSize = g_eSIData.BaseSize;
		}
		else {
			limit = g_eSIData.BaseLimit + RoundToCeil(g_eSIData.ExtraLimit * count);
			spawnSize = g_eSIData.BaseSize + RoundToCeil(count / g_eSIData.ExtraSize);
		}

		if (limit == g_eSIData.SILimit && spawnSize == g_eSIData.SpawnSize)
			return;

		g_eSIData.SILimit = limit;
		g_eSIData.SpawnSize = spawnSize;
		PrintToChatAll("\x04[提示]\x05特感总数\x04:\x03%d\x05特\x04,\x05每次数量\x04:\x03%d\x05特\x04,\x05刷新间隔\x04:\x05最小\x03%.1f\x05秒\x04,\x05最大\x03%.1f\x05秒.", limit, spawnSize <= limit ? spawnSize : limit, g_eSIData.SpawnTimeMin, g_eSIData.SpawnTimeMax);
		}
	// private  
	public static void LoadCacheSpawnLimits() {
		if (g_eSIData.SILimitCache != -1) {
			g_eSIData.SILimit = g_eSIData.SILimitCache;
			g_eSIData.SILimitCache = -1;
		}

		if (g_eSIData.SpawnSizeCache != -1) {
			g_eSIData.SpawnSize = g_eSIData.SpawnSizeCache;
			g_eSIData.SpawnSizeCache = -1;
		}

		for (int i; i < SI_MAX_SIZE; i++) {
			if (g_eSIData.SpawnLimitsCache[i] != -1) {
				g_eSIData.SpawnLimits[i] = g_eSIData.SpawnLimitsCache[i];
				g_eSIData.SpawnLimitsCache[i] = -1;
			}
		}
		}
	public static void LoadCacheSpawnWeights() {
		for (int i; i < SI_MAX_SIZE; i++) {
			if (g_eSIData.SpawnWeightsCache[i] != -1) {
				g_eSIData.SpawnWeights[i] = g_eSIData.SpawnWeightsCache[i];
				g_eSIData.SpawnWeightsCache[i] = -1;
			}
		}
		}
	public static void LoadCacheTankCustom() {
		for (int i; i < SI_MAX_SIZE; i++) {
			if (g_eSIData.TankStatusLimits[i] != -1)
				g_eSIData.SpawnLimits[i] = g_eSIData.TankStatusLimits[i];
				
			if (g_eSIData.TankStatusWeights[i] != -1)
				g_eSIData.SpawnWeights[i] = g_eSIData.TankStatusWeights[i];
		}
		}
	public static void ResetLimits() {
			LoadConfigFile();	// 配置的真源是文件
			}
	public static void ResetWeights() {
			LoadConfigFile();	// 配置的真源是文件
			}
    // private 
	public static void StartSpawnTimer() {
		SISpawnManager.EndSpawnTimer();
		g_hSpawnTimer = CreateTimer(g_eSIData.SpawnTimeMode > 0 ? g_fSpawnTimes[SISpawnManager.GetSICount()] : SISpawnManager.GetRanFloat(g_eSIData.SpawnTimeMin, g_eSIData.SpawnTimeMax), tmrSpawnSpecial);
		}
	public static void EndSpawnTimer() {
		delete g_hSpawnTimer;
		delete g_hRetryTimer;
		}
	public static void StartCustomSpawnTimer(float time) {
		SISpawnManager.EndSpawnTimer();
		g_hSpawnTimer = CreateTimer(time, tmrSpawnSpecial);
		}
	// public forward 
    public static void PluginStart() {
        // 引擎自己的 convar: 这几个是本模块要读/改的引擎开关, 不是我们的配置
        g_cSpawnRange        = FindConVar("z_spawn_range");
        g_cDiscardRange      = FindConVar("z_discard_range");
        g_cSafeSpawnRange    = FindConVar("z_safe_spawn_range");
        g_cVsBossFlowBuffer  = FindConVar("versus_boss_buffer");

        //AutoExecConfig(true, "specialspawner");

        HookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
        HookEvent("finale_vehicle_leaving", Event_RoundEnd,		EventHookMode_PostNoCopy);
        HookEvent("round_start",			Event_RoundStart,	EventHookMode_PostNoCopy);
        HookEvent("player_hurt",			Event_player_hurt);
        HookEvent("player_team",			Event_player_team);
        HookEvent("player_spawn",			Event_player_spawn);
        HookEvent("player_death",			Event_player_death,	EventHookMode_Pre);


        RegAdminCmd("sm_tgsx",				cmdResetSpawn,	ADMFLAG_RCON, "处死所有特感并重新开始生成计时");

        RegAdminCmd("sm_spawn",			cmdSpawnSet,	ADMFLAG_RCON, "修改特感刷出参数并写回配置");
        RegAdminCmd("sm_spawn_reload",	cmdSpawnReload,	ADMFLAG_RCON, "重新读取特服配置");
        RegAdminCmd("sm_tgjs",				cmdForceTimer,	ADMFLAG_RCON, "开始生成计时");
        RegAdminCmd("sm_tgms",				cmdType,		ADMFLAG_ROOT, "随机轮换模式");

        HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);

        // if (L4D_HasAnySurvivorLeftSafeArea())
        //     L4D_OnFirstSurvivorLeftSafeArea_Post(0);
		
		g_eSIData.Reset();
        }
	public static void ConfigsExecuted() {
		LoadConfigFile();		// 读 logs/l4d2_spawn_SI.cfg (没有就按默认生成一份)
		SISpawnManager.TweakSettings(false);
		}
    public static void MapStart() {}
    public static void MapEnd() {
        g_eSIData.LeftSafeArea = false;
        g_eSIData.LeadingFlow = 0;
        g_eSIData.FinaleStarted = 1;
        SISpawnManager.EndSpawnTimer();
        delete g_hSuicideTimer;
        SISpawnManager.TankStatusActoin(false);

        if (g_eSIData.CurrentClass >= SI_MAX_SIZE)
            SISpawnManager.SetRandomType();
        else if (g_eSIData.CurrentClass > -1)
            SISpawnManager.SetSIType(g_eSIData.CurrentClass);
        }
    public static void PluginEnd() {
        SISpawnManager.TweakSettings(true);
        }
    public static void Disconnect(int client) {
        if (!client || !IsClientInGame(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
            return;

        CreateTimer(0.1, tmrTankDisconnect, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    // public EventHook 
    public static void RoundStart() {
        SISpawnManager.EndSpawnTimer();
        }
    public static void RoundEnd() {
        SISpawnManager.MapEnd();
        }
    public static void player_hurt(int victim, int attacker) {
        if (!g_eSIData.LeftSafeArea)   return;

        SIBot victimPlayer = SIBot(victim);
        if (victimPlayer.IsValid)
            victimPlayer.ActionTime = GetEngineTime();

        SIBot attackerPlayer = SIBot(attacker);
        if (attackerPlayer.IsValid)
            attackerPlayer.ActionTime = GetEngineTime();
        }
    public static void player_team(int currentTeam, int oldteam) {
    	if (currentTeam != 2 && oldteam != 2)   return;

        delete g_hUpdateTimer;
        g_hUpdateTimer = CreateTimer(2.0, tmrUpdate);
	    }
    public static void player_spawn(int client) {
        SIBot player = SIBot(client);

        if (player.ZC != SI_TANK) {
            if (player.IsFake) {
                player.ActionTime = GetEngineTime();
                player.RecordPos();
            }
        }
        else    CreateTimer(0.1, tmrTankSpawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    	}
    public static void player_death(int client) {
        SIBot player = SIBot(client);
        int class = player.ZC;

        if (class == SI_TANK && !player.IsAnyTankAlive)
            SISpawnManager.TankStatusActoin(false);

        if (class != SI_JOCKEY + 1 && player.IsFake)	// class 是 1 基
            RequestFrame(NextFrame_KickBot, GetClientUserId(client));
    	}
    // public 
}

methodmap SIBot {
    public SIBot(int Client) {
        return view_as<SIBot>(Client);
    	}

    property int index {
        public get()    { return view_as<int>(this); }
        }
    // private bool 
    property bool IsSurv {
        public get() {
            int client = this.index;
	        return  client > 0 && 
                    client <= MaxClients && 
                    IsClientInGame(client) && 
                    GetClientTeam(client) == 2 && 
					IsPlayerAlive(client);
            }
        }
    property bool IsValid {
        public get() {
            int client = this.index;
	        return  client > 0 && 
                    client <= MaxClients && 
                    IsClientInGame(client);
            }
        }
    property bool IsFake {
        public get()    { return IsFakeClient(this.index); }
        }
    property bool IsAnyTankAlive {
        public get() {
            int client = this.index;

            for (int i = 1; i <= MaxClients; i++)
                if (i != client && IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == SI_TANK)
                    return true;

            return false;
        }
        }
    property bool IsAliveTank {
        public get() {
            int client = this.index;
            return  client > 0 && 
                    client <= MaxClients && 
                    IsClientInGame(client) && 
                    GetClientTeam(client) == 3 && 
                    GetEntProp(client, Prop_Send, "m_zombieClass") == SI_TANK && 
                    IsPlayerAlive(client);
        }
        }
	property bool IsValidSIQueue {
		public get() {
			int client = this.index;
			return 	IsClientInGame(client) && 
					!IsClientInKickQueue(client) && 
					GetClientTeam(client) == 3 && 
					IsPlayerAlive(client);
			}
		}
	property bool hasVisibleThreats {
		public get() 	{ return GetEntProp(this.index, Prop_Send, "m_hasVisibleThreats"); }
		}
	property bool Ducked {
        public get()            { return !!GetEntProp(this.index, Prop_Send, "m_bDucked"); }
        public set(bool value)	{ SetEntProp(this.index, Prop_Send, "m_bDucked", value ? 1 : 0); }
        }
	// private int 
    property int ZC {
        public get()            { return GetEntProp(this.index, Prop_Send, "m_zombieClass"); }
        // public set(int value)   { SetEntProp(this.index, Prop_Send, "m_zombieClass", value); }
        }
	property int flags {
        public get()            { return GetEntityFlags(this.index); }
        public set(int value)   { SetEntityFlags(this.index, value); }
        }
    // priavte float
    property float ActionTime {
        public get()            { return g_fActionTimes[this.index]; }
        public set(float value) { g_fActionTimes[this.index] = value; }
        }
    // public 
	public bool IsUsingAbility(int SIType) {
		switch (SIType) {
			case 1:
				return GetEntPropEnt(this.index, Prop_Send, "m_tongueVictim") > 0;

			case 3:
				return GetEntPropEnt(this.index, Prop_Send, "m_pounceVictim") > 0;

			case 5:
				return GetEntPropEnt(this.index, Prop_Send, "m_jockeyVictim") > 0;

			case 6:
				return GetEntPropEnt(this.index, Prop_Send, "m_carryVictim") > 0 || GetEntPropEnt(this.index, Prop_Send, "m_pummelVictim") > 0;
		}

		return false;
		}
    public void RecordPos() {
        GetClientAbsOrigin(this.index, g_pos[this.index]);
        }
    // public 
    // public 
}
/******************************************************
**              lef4dhooks forward
*******************************************************/
public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal) {
	if (!g_eSIData.InSpawnTime) {
		if (!strcmp(key, "MaxSpecials", false) || !strcmp(key, "cm_MaxSpecials", false)) {
			retVal = 0;
			return Plugin_Handled;
		}
	}
	else if (!strcmp(key, "PreferredSpecialDirection", false)) {
		retVal = g_eSIData.Direction;
		return Plugin_Handled;
	}
	else if (!strcmp(key, "MaxSpecials", false) || !strcmp(key, "cm_MaxSpecials", false)) {
		retVal = g_eSIData.SILimit;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client) {
	if (g_eSIData.LeftSafeArea)
		return;

	g_eSIData.LeftSafeArea = true;

	if (g_eSIData.CurrentClass >= SI_MAX_SIZE) {
		PrintToChatAll("\x03当前轮换\x01: \n");
		PrintToChatAll("\x01[\x05%s\x01]\x04模式\x01", g_sZombieClass[g_eSIData.CurrentClass - SI_MAX_SIZE]);
	}
	else if (g_eSIData.CurrentClass > -1)
		PrintToChatAll("\x01[\x05%s\x01]\x04模式\x01", g_sZombieClass[g_eSIData.CurrentClass]);

	SISpawnManager.StartCustomSpawnTimer(g_eSIData.FirstSpawnTime);
	delete g_hSuicideTimer;
	g_hSuicideTimer = CreateTimer(2.0, tmrForceSuicide, _, TIMER_REPEAT);
}
/******************************************************
**          			CallBack
*******************************************************/
// timer
static Action tmrForceSuicide(Handle timer) {
	static int i;
	static int SIType;
	static float time, pos[3];

	time = GetEngineTime();
	for (i = 1; i <= MaxClients; i++) {
		SIBot player = SIBot(i);

		if(!player.IsValidSIQueue)	continue;

		SIType = player.ZC;

		if (SIType < 1 || SIType > SI_MAX_SIZE)	continue;		// 引擎 1 基 (同上游写法)

		L4D_WarpToValidPositionIfStuck(i);

		if ( player.hasVisibleThreats || player.IsUsingAbility(SIType)) {
			player.ActionTime = time;
			player.RecordPos();
			continue;
		}

		if (time - player.ActionTime > g_eSIData.SuicideTime)
			SISpawnManager.KillInactiveSI(i, SIType);
		else if (time - player.ActionTime > g_eSIData.StuckTime) {
			GetClientAbsOrigin(i, pos);
			if (GetVectorDistance(pos, g_pos[i]) < g_eSIData.StuckInspect)
				SISpawnManager.KillInactiveSI(i, SIType);
		}
	}

	return Plugin_Continue;
}
static Action tmrUpdate(Handle timer) {
	g_hUpdateTimer = null;
	SISpawnManager.SetSpawnCount();

	return Plugin_Continue;
}
static Action tmrTankSpawn(Handle timer, int client) {
    SIBot tank = SIBot(GetClientOfUserId(client));

	if(!tank.IsAliveTank)   return Plugin_Stop;

	int totalLimit;
	int totalWeight;
	for (int i; i < SI_MAX_SIZE; i++) {
		totalLimit += g_eSIData.SpawnLimits[i];
		totalWeight += g_eSIData.SpawnWeights[i];
	}

	if (totalLimit && totalWeight)
		SISpawnManager.TankStatusActoin(true);

	return Plugin_Continue;
}
static void NextFrame_KickBot(any client) {
	if ((client = GetClientOfUserId(client)) && IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client))
		KickClient(client);
}
static Action tmrTankDisconnect(Handle timer) {
	if (SIBot(-1).IsAnyTankAlive)
		return Plugin_Stop;

	SISpawnManager.TankStatusActoin(false);
	return Plugin_Continue;
}
static Action tmrSpawnSpecial(Handle timer) {
	g_hSpawnTimer = null;
	delete g_hRetryTimer;

	int totalSI = SISpawnManager.GetSICount();
	SISpawnManager.ExecuteSpawnQueue(totalSI, true);

	g_hSpawnTimer = CreateTimer(g_eSIData.SpawnTimeMode > 0 ? g_fSpawnTimes[totalSI] : SISpawnManager.GetRanFloat(g_eSIData.SpawnTimeMin, g_eSIData.SpawnTimeMax), tmrSpawnSpecial);

	return Plugin_Continue;
}
static Action tmrRetrySpawn(Handle timer, bool retry) {
	g_hRetryTimer = null;
	SISpawnManager.ExecuteSpawnQueue(SISpawnManager.GetSICount(), retry);

	return Plugin_Continue;
}

// entity ouput
static void OnFinaleStart(const char[] output, int caller, int activator, float delay) {
	int entity = FindEntityByClassname(-1, "trigger_finale");

	if (entity != -1)
		g_eSIData.FinaleStarted = GetEntProp(entity, Prop_Data, "m_type");
}
// TE 
static bool TR_EntityFilter(int entity, int mask) {
	if (entity <= MaxClients)
		return false;
	else if (entity > MaxClients) {
		char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 || strcmp(classname, "prop_physics") == 0 || strcmp(classname, "tank_rock") == 0)
			return false;
	}

	return true;
}

/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_spawn_SI_usedfor_plugins
public void OnPluginStart() {
	SISpawnManager.PluginStart();
}

public void OnConfigsExecuted() {
	SISpawnManager.ConfigsExecuted();
}

public void OnMapStart() {
	SISpawnManager.MapStart();
}

public void OnMapEnd() {
	SISpawnManager.MapEnd();
}

public void OnPluginEnd() {
	SISpawnManager.PluginEnd();
}

public void OnClientDisconnect(int client) {
	SISpawnManager.Disconnect(client);
}

// event
static void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
    SISpawnManager.RoundEnd();
}

static void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	SISpawnManager.RoundStart();
}

static void Event_player_hurt(Event event, const char[] name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    SISpawnManager.player_hurt(victim, attacker);
}

static void Event_player_team(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;

    SISpawnManager.player_team(event.GetInt("team"), event.GetInt("oldteam"));
}

static void Event_player_spawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 3)   return;

	SISpawnManager.player_spawn(client);
}

static void Event_player_death(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 3)   return;

    SISpawnManager.player_death(client);
}

/******************************************************
**          		配置 (KV 文件)
*******************************************************/
// 首次生成配置时用的默认值 —— 等于原来那批 ss_* convar 的默认
static void ApplyDefaults() {
	g_eSIData.SILimit = 15;
	g_eSIData.SpawnSize = 2;
	g_eSIData.ScaleWeights = true;
	g_eSIData.SpawnTimeMin = 8.0;
	g_eSIData.SpawnTimeMax = 10.0;
	g_eSIData.SpawnTimeMode = 1;
	g_eSIData.BaseLimit = 4;
	g_eSIData.ExtraLimit = 1.0;
	g_eSIData.BaseSize = 2;
	g_eSIData.ExtraSize = 2.0;
	g_eSIData.SuicideTime = 20.0;
	g_eSIData.StuckTime = 10.0;
	g_eSIData.StuckInspect = 50.0;
	g_eSIData.FirstSpawnTime = 0.0;
	g_eSIData.TankStatusAction = 0;

	static const int defLimit[SI_MAX_SIZE] = { 1, 1, 4, 1, 4, 4 };
	static const int defWeight[SI_MAX_SIZE] = { 200, 200, 100, 200, 100, 200 };

	for (int i = 0; i < SI_MAX_SIZE; i++) {
		g_eSIData.SpawnLimits[i] = defLimit[i];
		g_eSIData.SpawnWeights[i] = defWeight[i];
		g_eSIData.TankStatusLimits[i] = defLimit[i];
		g_eSIData.TankStatusWeights[i] = defWeight[i];
	}

	g_fSpawnRangeMin = 200.0;
	g_fSpawnRangeMax = 1500.0;
}

static void GetConfigPath() {
	if (strlen(g_sConfigPath) <= 0)
		BuildPath(Path_SM, g_sConfigPath, sizeof g_sConfigPath, SPAWN_CONFIG_FILE);
}

// 把配置写回文件 —— 首次生成与 sm_spawn 改完都走这里, 所以文件里始终带注释
static void WriteConfigFile() {
	GetConfigPath();

	File file = OpenFile(g_sConfigPath, "w");
	if (file == null) {
		LogError("[SS] 无法写入配置文件: %s", g_sConfigPath);
		return;
	}

	file.WriteLine("// L4D2 Spawn SI —— 特感刷出配置");
	file.WriteLine("// 改完用 sm_spawn_reload 重载; 也可用 sm_spawn <项> <值> 在线改(会自动写回本文件)");
	file.WriteLine("\"SI_Spawn\"");
	file.WriteLine("{");
	file.WriteLine("    \"General\"");
	file.WriteLine("    {");
	file.WriteLine("        \"silimit\"          \"%d\"      // 同时存在的最大特感数", g_eSIData.SILimit);
	file.WriteLine("        \"spawnsize\"        \"%d\"      // 一次产生多少只", g_eSIData.SpawnSize);
	file.WriteLine("        \"scale_weights\"    \"%d\"      // 1 = 按剩余额度缩放比重", g_eSIData.ScaleWeights ? 1 : 0);
	file.WriteLine("        \"time_min\"         \"%.1f\"    // 最小刷新间隔(秒)", g_eSIData.SpawnTimeMin);
	file.WriteLine("        \"time_max\"         \"%.1f\"    // 最大刷新间隔(秒)", g_eSIData.SpawnTimeMax);
	file.WriteLine("        \"time_mode\"        \"%d\"      // 0 = 随机 | 1 = 递增 | 2 = 递减", g_eSIData.SpawnTimeMode);
	file.WriteLine("        \"base_limit\"       \"%d\"      // 4 名生还者时的特感总数", g_eSIData.BaseLimit);
	file.WriteLine("        \"extra_limit\"      \"%.1f\"    // 每多一名生还者增加的数目", g_eSIData.ExtraLimit);
	file.WriteLine("        \"base_size\"        \"%d\"      // 4 人时每批数量", g_eSIData.BaseSize);
	file.WriteLine("        \"extra_size\"       \"%.1f\"    // 每多少人多刷一只", g_eSIData.ExtraSize);
	file.WriteLine("        \"suicide_time\"     \"%.1f\"    // 特感自动处死时间(秒)", g_eSIData.SuicideTime);
	file.WriteLine("        \"stuck_time\"       \"%.1f\"    // 卡住判定时间(秒)", g_eSIData.StuckTime);
	file.WriteLine("        \"stuck_inspect\"    \"%.1f\"    // 卡住检测半径", g_eSIData.StuckInspect);
	file.WriteLine("        \"first_time\"       \"%.1f\"    // 离开安全区后第一波刷新时间(秒)", g_eSIData.FirstSpawnTime);
	file.WriteLine("        \"range_min\"        \"%.1f\"    // 最小生成距离", g_fSpawnRangeMin);
	file.WriteLine("        \"range_max\"        \"%.1f\"    // 最大生成距离", g_fSpawnRangeMax);
	file.WriteLine("    }");
	file.WriteLine("");
	file.WriteLine("    \"Class\"");
	file.WriteLine("    {");

	for (int i = 0; i < SI_MAX_SIZE; i++) {
		file.WriteLine("        \"%s\"", g_sZombieClass[i]);
		file.WriteLine("        {");
		file.WriteLine("            \"limit\"   \"%d\"", g_eSIData.SpawnLimits[i]);
		file.WriteLine("            \"weight\"  \"%d\"", g_eSIData.SpawnWeights[i]);
		file.WriteLine("        }");
	}

	file.WriteLine("    }");
	file.WriteLine("");
	file.WriteLine("    \"TankStatus\"");
	file.WriteLine("    {");
	file.WriteLine("        \"action\"  \"%d\"              // 坦克出现期间是否套用下面这套参数", g_eSIData.TankStatusAction);

	for (int i = 0; i < SI_MAX_SIZE; i++) {
		file.WriteLine("        \"%s\"", g_sZombieClass[i]);
		file.WriteLine("        {");
		file.WriteLine("            \"limit\"   \"%d\"", g_eSIData.TankStatusLimits[i]);
		file.WriteLine("            \"weight\"  \"%d\"", g_eSIData.TankStatusWeights[i]);
		file.WriteLine("        }");
	}

	file.WriteLine("    }");
	file.WriteLine("}");

	delete file;
}

// 读配置; 文件不在(或读不出来)就套默认值生成一份
static void LoadConfigFile() {
	GetConfigPath();

	g_eSIData.VsBossFlowBuffer = g_cVsBossFlowBuffer != null ? g_cVsBossFlowBuffer.FloatValue : 0.0;

	if (!FileExists(g_sConfigPath)) {
		LogMessage("[SS] 没有配置文件, 按默认值生成: %s", g_sConfigPath);
		ApplyDefaults();
		WriteConfigFile();
		g_eSIData.InitTimes();
		return;
	}

	KeyValues kv = new KeyValues("SI_Spawn");
	if (!kv.ImportFromFile(g_sConfigPath)) {
		LogError("[SS] 配置文件读取失败, 按默认值重新生成: %s", g_sConfigPath);
		delete kv;
		ApplyDefaults();
		WriteConfigFile();
		g_eSIData.InitTimes();
		return;
	}

	if (kv.JumpToKey("General")) {
		g_eSIData.SILimit           = kv.GetNum("silimit", g_eSIData.SILimit);
		g_eSIData.SpawnSize         = kv.GetNum("spawnsize", g_eSIData.SpawnSize);
		g_eSIData.ScaleWeights      = kv.GetNum("scale_weights", g_eSIData.ScaleWeights ? 1 : 0) != 0;
		g_eSIData.SpawnTimeMin      = kv.GetFloat("time_min", g_eSIData.SpawnTimeMin);
		g_eSIData.SpawnTimeMax      = kv.GetFloat("time_max", g_eSIData.SpawnTimeMax);
		g_eSIData.SpawnTimeMode     = kv.GetNum("time_mode", g_eSIData.SpawnTimeMode);
		g_eSIData.BaseLimit         = kv.GetNum("base_limit", g_eSIData.BaseLimit);
		g_eSIData.ExtraLimit        = kv.GetFloat("extra_limit", g_eSIData.ExtraLimit);
		g_eSIData.BaseSize          = kv.GetNum("base_size", g_eSIData.BaseSize);
		g_eSIData.ExtraSize         = kv.GetFloat("extra_size", g_eSIData.ExtraSize);
		g_eSIData.SuicideTime       = kv.GetFloat("suicide_time", g_eSIData.SuicideTime);
		g_eSIData.StuckTime         = kv.GetFloat("stuck_time", g_eSIData.StuckTime);
		g_eSIData.StuckInspect      = kv.GetFloat("stuck_inspect", g_eSIData.StuckInspect);
		g_eSIData.FirstSpawnTime    = kv.GetFloat("first_time", g_eSIData.FirstSpawnTime);
		g_fSpawnRangeMin            = kv.GetFloat("range_min", g_fSpawnRangeMin);
		g_fSpawnRangeMax            = kv.GetFloat("range_max", g_fSpawnRangeMax);
		kv.GoBack();
	}

	if (kv.JumpToKey("Class") && kv.GotoFirstSubKey()) {
		do {
			char name[32];
			kv.GetSectionName(name, sizeof name);

			for (int i = 0; i < SI_MAX_SIZE; i++) {
				if (strcmp(name, g_sZombieClass[i], false) != 0)	continue;

				g_eSIData.SpawnLimits[i] = kv.GetNum("limit", g_eSIData.SpawnLimits[i]);
				g_eSIData.SpawnWeights[i] = kv.GetNum("weight", g_eSIData.SpawnWeights[i]);
				break;
			}
		} while (kv.GotoNextKey());

		kv.GoBack();
		kv.GoBack();
	}

	if (kv.JumpToKey("TankStatus")) {
		g_eSIData.TankStatusAction = kv.GetNum("action", g_eSIData.TankStatusAction);

		if (kv.GotoFirstSubKey()) {
			do {
				char name[32];
				kv.GetSectionName(name, sizeof name);

				for (int i = 0; i < SI_MAX_SIZE; i++) {
					if (strcmp(name, g_sZombieClass[i], false) != 0)	continue;

					g_eSIData.TankStatusLimits[i] = kv.GetNum("limit", g_eSIData.TankStatusLimits[i]);
					g_eSIData.TankStatusWeights[i] = kv.GetNum("weight", g_eSIData.TankStatusWeights[i]);
					break;
				}
			} while (kv.GotoNextKey());
		}

		kv.GoBack();
	}

	delete kv;

	g_eSIData.InitTimes();
}

static void PrintSpawnUsage(int client) {
	ReplyToCommand(client, "\x04[SS] 用法 \x05sm_spawn <项> <值>");
	ReplyToCommand(client, "\x05  特感名 \x01[ smoker | boomer | hunter | spitter | jockey | charger ] \x04→ 该类上限");
	ReplyToCommand(client, "\x05  <特感名>.weight \x04→ 该类产生比重;  \x05all \x04→ 所有特感上限");
	ReplyToCommand(client, "\x05  max | size | wave \x04→ 特感总数 / 每批数量");
	ReplyToCommand(client, "\x05  time_min | time_max | time_mode \x04→ 刷新间隔(秒) / 模式");
	ReplyToCommand(client, "\x05  base_limit | extra_limit | base_size | extra_size \x04→ 按人数伸缩");
	ReplyToCommand(client, "\x05  suicide_time | stuck_time | stuck_inspect | first_time \x04→ 处死与首波");
	ReplyToCommand(client, "\x05  range_min | range_max | tank_action \x04→ 生成距离 / 坦克期间套参数");
	ReplyToCommand(client, "\x04[SS] 重载配置: \x05sm_spawn_reload");
	ReplyToCommand(client, "\x04[SS] 当前 \x05总数 \x03%d\x05, 每批 \x03%d\x05, 各类上限 \x03%d/%d/%d/%d/%d/%d",
		g_eSIData.SILimit, g_eSIData.SpawnSize,
		g_eSIData.SpawnLimits[0], g_eSIData.SpawnLimits[1], g_eSIData.SpawnLimits[2],
		g_eSIData.SpawnLimits[3], g_eSIData.SpawnLimits[4], g_eSIData.SpawnLimits[5]);
}

// false = 这项不认识 (调用方负责打用法)
static bool ApplySetting(const char[] type, const char[] value) {
	int iv = StringToInt(value);
	float fv = StringToFloat(value);

	for (int i = 0; i < SI_MAX_SIZE; i++) {
		if (strcmp(type, g_sZombieClass[i], false) == 0) {
			g_eSIData.SpawnLimits[i] = iv < 0 ? 0 : (iv > 32 ? 32 : iv);
			return true;
		}

		char key[32];
		FormatEx(key, sizeof key, "%s.weight", g_sZombieClass[i]);
		if (strcmp(type, key, false) == 0) {
			g_eSIData.SpawnWeights[i] = iv < 0 ? 0 : iv;
			return true;
		}
	}

	if (strcmp(type, "all", false) == 0) {
		for (int i = 0; i < SI_MAX_SIZE; i++)
			g_eSIData.SpawnLimits[i] = iv < 0 ? 0 : (iv > 32 ? 32 : iv);
	}
	else if (strcmp(type, "max", false) == 0 || strcmp(type, "silimit", false) == 0)
		g_eSIData.SILimit = iv < 0 ? 0 : (iv > 32 ? 32 : iv);
	else if (strcmp(type, "size", false) == 0 || strcmp(type, "spawnsize", false) == 0 || strcmp(type, "wave", false) == 0)
		g_eSIData.SpawnSize = iv < 0 ? 0 : (iv > 32 ? 32 : iv);
	else if (strcmp(type, "time_min", false) == 0)
		g_eSIData.SpawnTimeMin = fv < 0.1 ? 0.1 : fv;
	else if (strcmp(type, "time_max", false) == 0)
		g_eSIData.SpawnTimeMax = fv < 1.0 ? 1.0 : fv;
	else if (strcmp(type, "time_mode", false) == 0)
		g_eSIData.SpawnTimeMode = iv < 0 ? 0 : (iv > 2 ? 2 : iv);
	else if (strcmp(type, "base_limit", false) == 0)
		g_eSIData.BaseLimit = iv < 0 ? 0 : iv;
	else if (strcmp(type, "extra_limit", false) == 0)
		g_eSIData.ExtraLimit = fv < 0.0 ? 0.0 : fv;
	else if (strcmp(type, "base_size", false) == 0)
		g_eSIData.BaseSize = iv < 0 ? 0 : iv;
	else if (strcmp(type, "extra_size", false) == 0)
		g_eSIData.ExtraSize = fv < 1.0 ? 1.0 : fv;
	else if (strcmp(type, "suicide_time", false) == 0)
		g_eSIData.SuicideTime = fv < 1.0 ? 1.0 : fv;
	else if (strcmp(type, "stuck_time", false) == 0)
		g_eSIData.StuckTime = fv < 1.0 ? 1.0 : fv;
	else if (strcmp(type, "stuck_inspect", false) == 0)
		g_eSIData.StuckInspect = fv < 1.0 ? 1.0 : fv;
	else if (strcmp(type, "first_time", false) == 0)
		g_eSIData.FirstSpawnTime = fv < 0.0 ? 0.0 : fv;
	else if (strcmp(type, "range_min", false) == 0)
		g_fSpawnRangeMin = fv < 0.0 ? 0.0 : fv;
	else if (strcmp(type, "range_max", false) == 0)
		g_fSpawnRangeMax = fv < 0.0 ? 0.0 : fv;
	else if (strcmp(type, "tank_action", false) == 0) {
		int last = g_eSIData.TankStatusAction;
		g_eSIData.TankStatusAction = iv <= 0 ? 0 : 1;

		if (last != g_eSIData.TankStatusAction)
			SISpawnManager.TankStatusActoin(SIBot(-1).IsAnyTankAlive);
	}
	else
		return false;

	g_eSIData.InitTimes();
	return true;
}

Action cmdSpawnSet(int client, int args) {
	if (args < 2) {
		PrintSpawnUsage(client);
		return Plugin_Handled;
	}

	char type[32], value[32];
	GetCmdArg(1, type, sizeof type);
	GetCmdArg(2, value, sizeof value);

	if (!ApplySetting(type, value)) {
		PrintSpawnUsage(client);
		return Plugin_Handled;
	}

	WriteConfigFile();
	SISpawnManager.TweakSettings(false);
	ReplyToCommand(client, "\x04[SS] \x05%s \x04= \x05%s", type, value);

	return Plugin_Handled;
}

Action cmdSpawnReload(int client, int args) {
	LoadConfigFile();
	SISpawnManager.TweakSettings(false);
	ReplyToCommand(client, "\x04[SS] 已重新读取配置: \x05%s", g_sConfigPath);
	ReplyToCommand(client, "\x04[SS] 总数 \x03%d\x04, 每批 \x03%d", g_eSIData.SILimit, g_eSIData.SpawnSize);

	return Plugin_Handled;
}

// cmd
Action cmdResetSpawn(int client, int args) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") != 8)
			ForcePlayerSuicide(i);
	}

	SISpawnManager.StartCustomSpawnTimer(g_fSpawnTimes[0]);
	ReplyToCommand(client, "[SS] Slayed all special infected. Spawn timer restarted. Next potential spawn in %.1f seconds.", g_eSIData.SpawnTimeMin);
	return Plugin_Handled;
}

Action cmdForceTimer(int client, int args) {
	if (args < 1) {
		SISpawnManager.StartSpawnTimer();
		ReplyToCommand(client, "[SS] Spawn timer started manually.");
		return Plugin_Handled;
	}

	float time = GetCmdArgFloat(1);
	SISpawnManager.StartCustomSpawnTimer(time < 0.1 ? 0.1 : time);
	ReplyToCommand(client, "[SS] Spawn timer started manually. Next potential spawn in %.1f seconds.", time);

	return Plugin_Handled;
}

Action cmdType(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "\x04!type/sm_type \x05<class>.");
		ReplyToCommand(client, "\x05<type> \x01[ off | random | smoker | boomer | hunter | spitter | jockey | charger ]");
		return Plugin_Handled;
	}

	char arg[16];
	GetCmdArg(1, arg, sizeof arg);
	if (strcmp(arg, "off", false) == 0) {
		g_eSIData.CurrentClass = -1;
		ReplyToCommand(client, "已关闭单一特感模式");
		SISpawnManager.ResetLimits();
	}
	else if (strcmp(arg, "random", false) == 0) {
		PrintToChatAll("\x03当前轮换\x01: \n");
		PrintToChatAll("\x01[\x05%s\x01]\x04模式\x01", g_sZombieClass[SISpawnManager.SetRandomType()]);
	}
	else {
		int class = -1;

		for (int i = 0; i < SI_MAX_SIZE; i++) {
			if (strcmp(arg, g_sZombieClass[i], false) == 0) {
				class = i;
				break;
			}
		}

		if (class == -1) {
			ReplyToCommand(client, "\x04!type/sm_type \x05<class>.");
			ReplyToCommand(client, "\x05<type> \x01[ off | random | smoker | boomer | hunter | spitter | jockey | charger ]");
		}
		else if (class == g_eSIData.CurrentClass)
			ReplyToCommand(client, "目标特感类型与当前特感类型相同");
		else {
			SISpawnManager.SetSIType(class);
			PrintToChatAll("\x01[\x05%s\x01]\x04模式\x01", g_sZombieClass[class]);
		}
	}

	return Plugin_Handled;
}
#endif
/******************************************************
**          			  END
*******************************************************/