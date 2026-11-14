#if defined _crimson_immun_control_included_
 #endinput
#endif
#define _crimson_immun_control_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define _crimson_immun_control_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_immun_control_usedfor_plugins
public Plugin myinfo = {
	name = "L4D2 Immun Control - CrmMod",
	author = "crimson",
	description = "生还者免疫特感控制",
	version = "1.0.0",
	url = ""
};
#endif
enum {
	IMMUN_Smoker = 0,
	IMMUN_Hunter,
	IMMUN_Jockey,
	IMMUN_Charger,
	IMMUN_Tank,

	MAX_IMMUN_TYPE
}
#define IMMUN_MAX_FLAGS ((1 << MAX_IMMUN_TYPE) - 1)

static const char IMMUN_NAME[MAX_IMMUN_TYPE][] = {
	"舌头", "猎人", "猴子", "牛牛", "坦克"
};

enum {
	TAKEDAMAGE_NO = 0,              // 完全不参与伤害
	TAKEDAMAGE_EVENTS_ONLY = 1,     // 伤害事件照走, 血不掉
	TAKEDAMAGE_YES = 2,             // 正常
	TAKEDAMAGE_AIM = 3              // L4D2 下等同 YES
}
/******************************************************
**          	        variable
*******************************************************/
enum struct ImmunInfoData {
	int AllImmunFlag;                       // 全局免疫位, convar 驱动
	int PlayerImmunFlag[MAXPLAYERS+1];      // 每人一份, 默认跟全局
	int ImmunAbility[MAXPLAYERS+1];         // 上面两者的与, 运行时判定用

	DynamicDetour m_hDTR_SmokerGrab;
	DynamicDetour m_hDTR_HunterPounce;
	DynamicDetour m_hDTR_JockeyRide;
	DynamicDetour m_hDTR_ChargerCarry;
	DynamicDetour m_hDTR_ChargerPummel;
	DynamicDetour m_hDTR_KnockedDown;
	DynamicDetour m_hDTR_TankClaw;

	Handle m_hSDK_ReleaseTongueVictim;
	Handle m_hSDK_OnPounceEnded;
	Handle m_hSDK_OnRideEnded;
	Handle m_hSDK_OnCarryEnded;
	Handle m_hSDK_OnPummelEnded;

	void Reset() {
		static const ImmunInfoData def = { 
			0, {0, ...}, {0, ...}, 
			null, null, null, null, null, null, null, 
			null, null, null, null, null 
		};
		this = def;
	}
}
static ImmunInfoData g_eImmnu;

static ConVar g_cvImmunFlags;
static ConVar g_cvReleaseDelay;
static ConVar g_cvGetUpInvuln;
static Handle g_hGetUpTimer[MAXPLAYERS+1];
static int g_iGetUpUserID[MAXPLAYERS+1];        // 句柄属于哪个 userid, 防断线后节点复用
/******************************************************
**          			main
*******************************************************/
methodmap ImmmunControl {
	public ImmmunControl(int Client) {
		return view_as<ImmmunControl>(Client);
		}

	property int index {
		public get()    { return view_as<int>(this); }
		}
	// public 
	public static bool IsValidClient(int client) {
		return client > 0 && client <= MaxClients && IsClientInGame(client);
		}
	// public
	property bool ImmunSmoker {
		public get()            { return !!(g_eImmnu.ImmunAbility[this.index] & (1 << IMMUN_Smoker)); }
		public set(bool value)  { this.SetPlayerImmun(IMMUN_Smoker, value); }
		}
	property bool ImmunHunter {
		public get()            { return !!(g_eImmnu.ImmunAbility[this.index] & (1 << IMMUN_Hunter)); }
		public set(bool value)  { this.SetPlayerImmun(IMMUN_Hunter, value); }
		}
	property bool ImmunJockey {
		public get()            { return !!(g_eImmnu.ImmunAbility[this.index] & (1 << IMMUN_Jockey)); }
		public set(bool value)  { this.SetPlayerImmun(IMMUN_Jockey, value); }
		}
	property bool ImmunCharger {
		public get()            { return !!(g_eImmnu.ImmunAbility[this.index] & (1 << IMMUN_Charger)); }
		public set(bool value)  { this.SetPlayerImmun(IMMUN_Charger, value); }
		}
	property bool ImmunTank {
		public get()            { return !!(g_eImmnu.ImmunAbility[this.index] & (1 << IMMUN_Tank)); }
		public set(bool value)  { this.SetPlayerImmun(IMMUN_Tank, value); }
		}
	// public 
	public static void SetAllImmun(int immunType, bool IsImmun) {
		if(immunType < 0 || immunType >= MAX_IMMUN_TYPE)
			return;

		int bitFlag = (1 << immunType);

		if(IsImmun) g_eImmnu.AllImmunFlag |= bitFlag;
		else        g_eImmnu.AllImmunFlag &= ~bitFlag;

		for(int i = 1; i <= MaxClients; i++) {
			if(!ImmmunControl.IsValidClient(i))
				continue;

			ImmmunControl.ApplyGlobal(i);

			// 开了免疫就把当前正被这个特感控制的人放出来
			if(IsImmun) ImmmunControl(i).ReleaseControlDelay(immunType);
		}
		}
	// public 进服/换图时把全局位套到这个人身上
	public static void ApplyGlobal(int client) {
		if(!ImmmunControl.IsValidClient(client))
			return;

		g_eImmnu.PlayerImmunFlag[client] = g_eImmnu.AllImmunFlag;
		ImmmunControl(client).UpdateImmun();
		}
	// public 单人开关某类型
	public void SetPlayerImmun(int immunType, bool IsImmun) {
		if(immunType < 0 || immunType >= MAX_IMMUN_TYPE)
			return;

		int bitFlag = (1 << immunType);

		if(IsImmun) g_eImmnu.PlayerImmunFlag[this.index] |= bitFlag;
		else        g_eImmnu.PlayerImmunFlag[this.index] &= ~bitFlag;

		this.UpdateImmun();

		// 开了免疫就把当前正被这个特感控制的人放出来
		if(IsImmun) this.ReleaseControlDelay(immunType);
		}
	// private Update
	public void UpdateImmun() {
		int Client = this.index;
		g_eImmnu.ImmunAbility[Client] = g_eImmnu.AllImmunFlag & g_eImmnu.PlayerImmunFlag[Client];
		}
	// private 解控延迟秒数, <0.1 视为无延迟
	public static float ReleaseDelay() {
		return g_cvReleaseDelay.FloatValue;
		}
	// private 排队一次延迟解控
	public static void ScheduleRelease(int victim, int immunType) {
		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(victim));
		dPack.WriteCell(immunType);
		CreateTimer(ImmmunControl.ReleaseDelay(), Immun_TimerDelayedRelease, dPack);
		}
	// public 解控入口: 延迟由 l4d_immun_release_delay 决定, <0.1 视为无延迟
	public void ReleaseControlDelay(int immunType) {
		int victim = this.index;
		if(immunType < 0 || immunType >= MAX_IMMUN_TYPE)
			return;

		if(ImmmunControl.ReleaseDelay() < 0.1) {
			this.ReleaseControl(immunType);
			return;
		}

		ImmmunControl.ScheduleRelease(victim, immunType);
		}
	// public 真正执行解控
	public void ReleaseControl(int immunType) {
		int victim = this.index;
		if(immunType < 0 || immunType >= MAX_IMMUN_TYPE)
			return;

		int attacker;

		switch(immunType) {
			case IMMUN_Smoker: {        // 解除舌头控制
				attacker = GetEntPropEnt(victim, Prop_Send, "m_tongueOwner");
				if(attacker > 0) {
					SDKCall(g_eImmnu.m_hSDK_ReleaseTongueVictim, attacker, victim);
					ImmmunControl.NotifyReleased(victim, attacker, immunType);
					}
				}
			case IMMUN_Hunter: {        // 解除猎人控制
				attacker = GetEntPropEnt(victim, Prop_Send, "m_pounceAttacker");
				if(attacker > 0) {
					SDKCall(g_eImmnu.m_hSDK_OnPounceEnded, attacker, victim);
					ImmmunControl.NotifyReleased(victim, attacker, immunType);
					}
				}
			case IMMUN_Jockey: {        // 解除猴子控制
				attacker = GetEntPropEnt(victim, Prop_Send, "m_jockeyAttacker");
				if(attacker > 0) {
					SDKCall(g_eImmnu.m_hSDK_OnRideEnded, attacker, victim);
					ImmmunControl.NotifyReleased(victim, attacker, immunType);
					}
				}
			case IMMUN_Charger: {       // 解除牛牛控制
				attacker = GetEntPropEnt(victim, Prop_Send, "m_carryAttacker");
				if(attacker > 0) {
					ImmmunControl.ReleaseCarry(attacker, victim);
					ImmmunControl.NotifyReleased(victim, attacker, immunType);
					}

				attacker = GetEntPropEnt(victim, Prop_Send, "m_pummelAttacker");
				if(attacker > 0) {
					ImmmunControl.ReleasePummel(attacker, victim);
					ImmmunControl.NotifyReleased(victim, attacker, immunType);
					}
				}
			}
		}
	// private 解控聊天提示
	public static void NotifyReleased(int victim, int attacker, int immunType) {
		if(!ImmmunControl.IsValidClient(victim))
			return;

		char sVictim[MAX_NAME_LENGTH];
		GetClientName(victim, sVictim, sizeof(sVictim));

		if(ImmmunControl.IsValidClient(attacker)) {
			char sAttacker[MAX_NAME_LENGTH];
			GetClientName(attacker, sAttacker, sizeof(sAttacker));

			PrintToChat(victim, "\x04[多特]\x03 自动解除\x05%s\x03的控制.", sAttacker);
			}
		else {
			PrintToChat(victim, "\x04[免疫]\x03 自动解除\x05%s\x03的控制", IMMUN_NAME[immunType]);
			}
		}
	// public 解除牛牛携带
	public static void ReleaseCarry(int attacker, int victim) {
		SDKCall(g_eImmnu.m_hSDK_OnCarryEnded, attacker, victim);

		ImmmunControl.SetWeaponAttack(attacker, true, 0.5);
		ImmmunControl.SetWeaponAttack(attacker, false, 0.6);

		SetEntPropEnt(attacker, Prop_Send, "m_carryVictim", -1);
		SetEntPropEnt(victim, Prop_Send, "m_carryAttacker", -1);

		ImmmunControl.TeleportOut(attacker, victim);
		}
	// public 解除牛牛殴打
	public static void ReleasePummel(int attacker, int victim) {
		SDKCall(g_eImmnu.m_hSDK_OnPummelEnded, attacker, "", victim);

		ImmmunControl.SetWeaponAttack(attacker, true, 0.5);
		ImmmunControl.SetWeaponAttack(attacker, false, 0.6);

		SetEntPropEnt(attacker, Prop_Send, "m_pummelVictim", -1);
		SetEntPropEnt(victim, Prop_Send, "m_pummelAttacker", -1);

		ImmmunControl.TeleportOut(attacker, victim);
		}
	// private
	public static void TeleportOut(int attacker, int victim) {
		float vPos[3];
		vPos[0] = GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1 ? 20.0 : 50.0;

		SetVariantString("!activator");
		AcceptEntityInput(victim, "SetParent", attacker);
		TeleportEntity(victim, vPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(victim, "ClearParent");

		// 修卡飞行动画
		CreateTimer(0.3, Immun_TimerFixAnim, GetClientUserId(victim));
		}
	// private
	public static void SetWeaponAttack(int client, bool primary, float time) {
		if(primary) {
			int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
			if(GetEntPropFloat(ability, Prop_Send, "m_timestamp") < GetGameTime() + time)
				SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
		}

		int weapon = GetPlayerWeaponSlot(client, 0);
		if(weapon != -1) {
			if(primary) SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + time);
			else        SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + time);
		}
		}
	// public 倒地起身无敌
	public static void StartGetUpInvuln(int client) {
		if(!ImmmunControl.IsValidClient(client) || !IsPlayerAlive(client))
			return;

		if(g_hGetUpTimer[client] != null && g_iGetUpUserID[client] == GetClientUserId(client))
			KillTimer(g_hGetUpTimer[client]);

		ImmmunControl.SetTakeDamage(client, TAKEDAMAGE_EVENTS_ONLY);
		g_iGetUpUserID[client] = GetClientUserId(client);
		g_hGetUpTimer[client] = CreateTimer(g_cvGetUpInvuln.FloatValue, Immun_TimerRestoreTakeDamage, g_iGetUpUserID[client]);
		}
	// private
	public static void SetTakeDamage(int client, int value) {
		SetEntProp(client, Prop_Data, "m_takedamage", value);
		}
	// private
	public static DynamicDetour LoadDetour(GameData hGameData, const char[] sName, DHookCallback callback) {
		DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, sName);

		if(hDetour == null)
			SetFailState("Failed to load detour \"%s\"", sName);

		if(!hDetour.Enable(Hook_Pre, callback))
			SetFailState("Failed to enable detour \"%s\"", sName);

		return hDetour;
		}
	// public forward
	public static void PluginStart(GameData hGameData) {
		g_eImmnu.m_hDTR_TankClaw      = ImmmunControl.LoadDetour(hGameData, "L4DD::CTankClaw::OnPlayerHit",                  DTR_Immun_TankClawHit);
		g_eImmnu.m_hDTR_KnockedDown   = ImmmunControl.LoadDetour(hGameData, "L4DD::CTerrorPlayer::OnKnockedDown",            DTR_Immun_KnockedDown);
		g_eImmnu.m_hDTR_SmokerGrab    = ImmmunControl.LoadDetour(hGameData, "L4DD::CTerrorPlayer::GrabVictimWithTongue",     DTR_Immun_SmokerGrab);
		g_eImmnu.m_hDTR_HunterPounce  = ImmmunControl.LoadDetour(hGameData, "L4DD::CTerrorPlayer::OnPouncedOnSurvivor",      DTR_Immun_HunterPounce);
		g_eImmnu.m_hDTR_JockeyRide    = ImmmunControl.LoadDetour(hGameData, "L4DD::CTerrorPlayer::OnLeptOnSurvivor",         DTR_Immun_JockeyRide);
		g_eImmnu.m_hDTR_ChargerCarry  = ImmmunControl.LoadDetour(hGameData, "L4DD::CTerrorPlayer::OnStartCarryingVictim",    DTR_Immun_ChargerCarry);
		g_eImmnu.m_hDTR_ChargerPummel = ImmmunControl.LoadDetour(hGameData, "L4DD::CTerrorPlayer::QueuePummelVictim",        DTR_Immun_ChargerPummel);

		StartPrepSDKCall(SDKCall_Player);
		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::ReleaseTongueVictim"))
			SetFailState("Failed to find signature 'CTerrorPlayer::ReleaseTongueVictim'");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_eImmnu.m_hSDK_ReleaseTongueVictim = EndPrepSDKCall();
		if(g_eImmnu.m_hSDK_ReleaseTongueVictim == null)
			SetFailState("Failed to create SDKCall 'CTerrorPlayer::ReleaseTongueVictim'");

		StartPrepSDKCall(SDKCall_Player);
		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPounceEnded"))
			SetFailState("Failed to find signature 'CTerrorPlayer::OnPounceEnded'");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_eImmnu.m_hSDK_OnPounceEnded = EndPrepSDKCall();
		if(g_eImmnu.m_hSDK_OnPounceEnded == null)
			SetFailState("Failed to create SDKCall 'CTerrorPlayer::OnPounceEnded'");

		StartPrepSDKCall(SDKCall_Player);
		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRideEnded"))
			SetFailState("Failed to find signature 'CTerrorPlayer::OnRideEnded'");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_eImmnu.m_hSDK_OnRideEnded = EndPrepSDKCall();
		if(g_eImmnu.m_hSDK_OnRideEnded == null)
			SetFailState("Failed to create SDKCall 'CTerrorPlayer::OnRideEnded'");

		StartPrepSDKCall(SDKCall_Player);
		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnCarryEnded"))
			SetFailState("Failed to find signature 'CTerrorPlayer::OnCarryEnded'");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_eImmnu.m_hSDK_OnCarryEnded = EndPrepSDKCall();
		if(g_eImmnu.m_hSDK_OnCarryEnded == null)
			SetFailState("Failed to create SDKCall 'CTerrorPlayer::OnCarryEnded'");

		StartPrepSDKCall(SDKCall_Player);
		if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded"))
			SetFailState("Failed to find signature 'CTerrorPlayer::OnPummelEnded'");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_eImmnu.m_hSDK_OnPummelEnded = EndPrepSDKCall();
		if(g_eImmnu.m_hSDK_OnPummelEnded == null)
			SetFailState("Failed to create SDKCall 'CTerrorPlayer::OnPummelEnded'");

		

		g_cvImmunFlags = CreateConVar("l4d_immun_flags", "31", "生还者免疫哪些特感 (位掩码: 1=舌 2=猎 4=猴 8=牛 16=坦)",
									FCVAR_NOTIFY, true, 0.0, true, float(IMMUN_MAX_FLAGS));
		g_cvImmunFlags.AddChangeHook(OnImmunFlagsChanged);
		OnImmunFlagsChanged(g_cvImmunFlags, "", "");        // 开局按默认值套一遍

		g_cvReleaseDelay = CreateConVar("l4d_immun_release_delay", "0.1", "免疫延迟解控秒数 (<0.1 = 直接阻断抓取, >=0.1 = 抓取成立后延迟解控)", FCVAR_NOTIFY, true, 0.0, true, 10.0);
		g_cvGetUpInvuln = CreateConVar("l4d_immun_getup_invuln", "0.3", "倒地起身后的无敌时长秒数 (<0.1 = 关闭)", FCVAR_NOTIFY, true, 0.0, true, 30.0);

		HookEvent("revive_success", Immun_EventReviveSuccess);
		}
	public static void PluginEnd() {
		if(g_eImmnu.m_hDTR_SmokerGrab != null) {
			g_eImmnu.m_hDTR_SmokerGrab.Disable(Hook_Pre, DTR_Immun_SmokerGrab);
			delete g_eImmnu.m_hDTR_SmokerGrab;
			g_eImmnu.m_hDTR_SmokerGrab = null;
		}
		if(g_eImmnu.m_hDTR_HunterPounce != null) {
			g_eImmnu.m_hDTR_HunterPounce.Disable(Hook_Pre, DTR_Immun_HunterPounce);
			delete g_eImmnu.m_hDTR_HunterPounce;
			g_eImmnu.m_hDTR_HunterPounce = null;
		}
		if(g_eImmnu.m_hDTR_JockeyRide != null) {
			g_eImmnu.m_hDTR_JockeyRide.Disable(Hook_Pre, DTR_Immun_JockeyRide);
			delete g_eImmnu.m_hDTR_JockeyRide;
			g_eImmnu.m_hDTR_JockeyRide = null;
		}
		if(g_eImmnu.m_hDTR_ChargerCarry != null) {
			g_eImmnu.m_hDTR_ChargerCarry.Disable(Hook_Pre, DTR_Immun_ChargerCarry);
			delete g_eImmnu.m_hDTR_ChargerCarry;
			g_eImmnu.m_hDTR_ChargerCarry = null;
		}
		if(g_eImmnu.m_hDTR_ChargerPummel != null) {
			g_eImmnu.m_hDTR_ChargerPummel.Disable(Hook_Pre, DTR_Immun_ChargerPummel);
			delete g_eImmnu.m_hDTR_ChargerPummel;
			g_eImmnu.m_hDTR_ChargerPummel = null;
		}
		if(g_eImmnu.m_hDTR_KnockedDown != null) {
			g_eImmnu.m_hDTR_KnockedDown.Disable(Hook_Pre, DTR_Immun_KnockedDown);
			delete g_eImmnu.m_hDTR_KnockedDown;
			g_eImmnu.m_hDTR_KnockedDown = null;
		}
		if(g_eImmnu.m_hDTR_TankClaw != null) {
			g_eImmnu.m_hDTR_TankClaw.Disable(Hook_Pre, DTR_Immun_TankClawHit);
			delete g_eImmnu.m_hDTR_TankClaw;
			g_eImmnu.m_hDTR_TankClaw = null;
		}

		// 起身无敌: 收掉计时器并恢复受击, 免得带着免伤卸载
		for(int i = 1; i <= MaxClients; i++) {
			if(g_hGetUpTimer[i] == null)
				continue;

			if(g_iGetUpUserID[i] == GetClientUserId(i))
				KillTimer(g_hGetUpTimer[i]);

			g_hGetUpTimer[i] = null;
			g_iGetUpUserID[i] = 0;

			if(ImmmunControl.IsValidClient(i))
				ImmmunControl.SetTakeDamage(i, TAKEDAMAGE_YES);
		}

		delete g_eImmnu.m_hSDK_ReleaseTongueVictim;
		delete g_eImmnu.m_hSDK_OnPounceEnded;
		delete g_eImmnu.m_hSDK_OnRideEnded;
		delete g_eImmnu.m_hSDK_OnCarryEnded;
		delete g_eImmnu.m_hSDK_OnPummelEnded;
		}
}
/******************************************************
**          			CallBack
*******************************************************/
// 舌头抓人
static MRESReturn DTR_Immun_SmokerGrab(int pThis, DHookReturn hReturn, DHookParam hParams) {
	int victim;
	if(!hParams.IsNull(1))
		victim = hParams.Get(1);

	if(!ImmmunControl.IsValidClient(victim) || !ImmmunControl(victim).ImmunSmoker)
		return MRES_Ignored;

	// 无延迟: 直接阻断抓取
	if(ImmmunControl.ReleaseDelay() < 0.1) {
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	// 延迟解控: 放行这次控制, 到点自动脱控
	ImmmunControl.ScheduleRelease(victim, IMMUN_Smoker);
	return MRES_Ignored;
}
// 猎人扑人
static MRESReturn DTR_Immun_HunterPounce(int pThis, DHookReturn hReturn, DHookParam hParams) {
	int victim;
	if(!hParams.IsNull(1))
		victim = hParams.Get(1);

	if(!ImmmunControl.IsValidClient(victim) || !ImmmunControl(victim).ImmunHunter)
		return MRES_Ignored;

	// 无延迟: 直接阻断抓取
	if(ImmmunControl.ReleaseDelay() < 0.1) {
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	// 延迟解控: 放行这次控制, 到点自动脱控
	ImmmunControl.ScheduleRelease(victim, IMMUN_Hunter);
	return MRES_Ignored;
}
// 猴子骑人
static MRESReturn DTR_Immun_JockeyRide(int pThis, DHookReturn hReturn, DHookParam hParams) {
	int victim;
	if(!hParams.IsNull(1))
		victim = hParams.Get(1);

	if(!ImmmunControl.IsValidClient(victim) || !ImmmunControl(victim).ImmunJockey)
		return MRES_Ignored;

	// 无延迟: 直接阻断抓取
	if(ImmmunControl.ReleaseDelay() < 0.1) {
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	// 延迟解控: 放行这次控制, 到点自动脱控
	ImmmunControl.ScheduleRelease(victim, IMMUN_Jockey);
	return MRES_Ignored;
}
// 牛牛抓人
static MRESReturn DTR_Immun_ChargerCarry(int pThis, DHookReturn hReturn, DHookParam hParams) {
	int victim;
	if(!hParams.IsNull(1))
		victim = hParams.Get(1);

	if(!ImmmunControl.IsValidClient(victim) || !ImmmunControl(victim).ImmunCharger)
		return MRES_Ignored;

	// 无延迟: 直接阻断抓取
	if(ImmmunControl.ReleaseDelay() < 0.1) {
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	// 延迟解控: 放行这次控制, 到点自动脱控
	ImmmunControl.ScheduleRelease(victim, IMMUN_Charger);
	return MRES_Ignored;
}
// 牛牛殴打
static MRESReturn DTR_Immun_ChargerPummel(int pThis, DHookReturn hReturn, DHookParam hParams) {
	int victim;
	if(!hParams.IsNull(1))
		victim = hParams.Get(1);

	if(!ImmmunControl.IsValidClient(victim) || !ImmmunControl(victim).ImmunCharger)
		return MRES_Ignored;

	// 无延迟: 阻断殴打并修动画
	if(ImmmunControl.ReleaseDelay() < 0.1) {
		SetEntityMoveType(victim, MOVETYPE_WALK); // 防原地踩空/卡走动画

		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(pThis));
		dPack.WriteCell(GetClientUserId(victim));
		RequestFrame(Immun_OnPummelTeleport, dPack);

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	// 延迟解控: 放行这次殴打, 到点解控 + 修动画
	ImmmunControl.ScheduleRelease(victim, IMMUN_Charger);
	return MRES_Ignored;
}
// 坦克石头(2) / 牛牛撞倒(3)
static MRESReturn DTR_Immun_KnockedDown(int pThis, DHookParam hParams) {
	if(!ImmmunControl.IsValidClient(pThis))
		return MRES_Ignored;

	switch(hParams.Get(1)) {
		case 2: if(ImmmunControl(pThis).ImmunTank)       return MRES_Supercede;
		case 3: if(ImmmunControl(pThis).ImmunCharger)    return MRES_Supercede;
	}

	return MRES_Ignored;
}
// 坦克拳头
static MRESReturn DTR_Immun_TankClawHit(int pThis, DHookParam hParams) {
	int player;
	if(!hParams.IsNull(1))
		player = hParams.Get(1);

	if(!ImmmunControl.IsValidClient(player) || !ImmmunControl(player).ImmunTank)
		return MRES_Ignored;

	return MRES_Supercede;
}

// 延迟解控落地
static Action Immun_TimerDelayedRelease(Handle timer, DataPack dPack) {
	dPack.Reset();
	int victim = GetClientOfUserId(dPack.ReadCell());
	int immunType = dPack.ReadCell();
	delete dPack;

	if(!ImmmunControl.IsValidClient(victim) || !IsPlayerAlive(victim))
		return Plugin_Stop;

	ImmmunControl(victim).ReleaseControl(immunType);
	return Plugin_Stop;
}

static void Immun_OnPummelTeleport(DataPack dPack) {
	dPack.Reset();
	int attacker = dPack.ReadCell();
	int victim = dPack.ReadCell();
	delete dPack;

	attacker = GetClientOfUserId(attacker);
	if(!attacker || !IsClientInGame(attacker))
		return;

	victim = GetClientOfUserId(victim);
	if(!victim || !IsClientInGame(victim))
		return;

	SetVariantString("!activator");
	AcceptEntityInput(victim, "SetParent", attacker);
	TeleportEntity(victim, view_as<float>({50.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(victim, "ClearParent");
}

static Action Immun_TimerFixAnim(Handle timer, int userid) {
	int target = GetClientOfUserId(userid);

	if(target && IsPlayerAlive(target)) {
		SetEntityMoveType(target, MOVETYPE_WALK);

		int seq = GetEntProp(target, Prop_Send, "m_nSequence");
		if(seq == 650 || seq == 665 || seq == 661 || seq == 651 || seq == 554 || seq == 551) {
			float vPos[3];
			GetClientAbsOrigin(target, vPos);
			TeleportEntity(target, vPos, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		}
	}

	return Plugin_Continue;
}

// 倒地起身 (队友拉起/救援)
static void Immun_EventReviveSuccess(Event event, const char[] name, bool dontBroadcast) {
	if(g_cvGetUpInvuln.FloatValue < 0.1)
		return;

	ImmmunControl.StartGetUpInvuln(GetClientOfUserId(GetEventInt(event, "subject")));
}

// 起身无敌结束, 恢复受击
static Action Immun_TimerRestoreTakeDamage(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);
	if(client <= 0)
		return Plugin_Stop;

	g_hGetUpTimer[client] = null;
	g_iGetUpUserID[client] = 0;

	if(ImmmunControl.IsValidClient(client))
		ImmmunControl.SetTakeDamage(client, TAKEDAMAGE_YES);

	return Plugin_Stop;
}

static void OnImmunFlagsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	for(int type = 0; type < MAX_IMMUN_TYPE; type++)
		ImmmunControl.SetAllImmun(type, !!(convar.IntValue & (1 << type)));
}
/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_immun_control_usedfor_plugins
public void OnPluginStart() {
	if(GetEngineVersion() != Engine_Left4Dead2)
		SetFailState("Plugin only supports Left 4 Dead 2");

	GameData hGameData = LoadGameConfigFile("l4d2_immun_control");
	if(hGameData == null)
		SetFailState("Failed to load \"gamedata/l4d2_immun_control.txt\"");

	ImmmunControl.PluginStart(hGameData);
	delete hGameData;
	AutoExecConfig(true, "l4d2_immun_control");
}

public void OnPluginEnd() {
	ImmmunControl.PluginEnd();
}

public void OnClientPutInServer(int client) {
	ImmmunControl.ApplyGlobal(client);
}

#endif
/******************************************************
**						END
*******************************************************/
