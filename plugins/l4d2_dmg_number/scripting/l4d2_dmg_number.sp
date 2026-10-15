#if defined _crimson_damage_number_included_
 #endinput
#endif
#define _crimson_damage_number_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define _crimson_damage_number_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#define SPRITE_BEAM		"materials/sprites/laserbeam.vmt"

#define NUMBER_OHIGH    40.0
#define NUMBER_INTERVAL 10.0
#define NUMBER_HIGH     24.0
#define NUMBER_WIDTH    7.0

static const float NumberOffset[6][3] = {
	{0.0, -NUMBER_WIDTH,  NUMBER_HIGH},
	{0.0,  NUMBER_WIDTH,  NUMBER_HIGH},
	{0.0, -NUMBER_WIDTH,  0.0},
	{0.0,  NUMBER_WIDTH,  0.0},
	{0.0, -NUMBER_WIDTH, -NUMBER_HIGH},
	{0.0,  NUMBER_WIDTH, -NUMBER_HIGH},
};
static const float NumberAPIOffset[6][3] = {
	{0.0, -1.0,  1.0},
	{0.0,  1.0,  1.0},
	{0.0, -1.0,  0.0},
	{0.0,  1.0,  0.0},
	{0.0, -1.0, -1.0},
	{0.0,  1.0, -1.0},
};

static const int NumberLine[10] = {
	0x77, // 012456
	0x24, // 25
	0x5D, // 02346
	0x6D, // 02356
	0x2E, // 1235
	0x6B, // 01356
	0x7B, // 013456
	0x25, // 025
	0x7F, // 0123456
	0x6F, // 012356
};

static const int NumberConnect[7][2] = {
	{0, 1},
	{0, 2},
	{1, 3},
	{2, 3},
	{2, 4},
	{3, 5},
	{4, 5}
};

static const int RedColor[4] = {255, 0, 0, 255};
/******************************************************
**          	        variable
*******************************************************/
static float NumberRealOffset[6][3];
static float number_high = NUMBER_HIGH;
static float number_width = NUMBER_WIDTH;

static int g_BeamSprite;
static int g_iDisplayDamage_Mode;
/******************************************************
**          			main
*******************************************************/
/**
 * @brief	提供传递显示伤害数字的封装
 * @note	public 	注释后的函数, 可供外部调用
 * @note    forward 注释后的函数, 需要在对应命名 forward 转发调用
 * @note	private 注释后的函数, 请不要外部调用

 * @note	外部通过调用 property 来访问静态数据
 */
methodmap DmgNum_t {
	public DmgNum_t(int Client) {
		return view_as<DmgNum_t>(Client);
		}
	// private
	property bool IsValid {
		public get() {
			int Client = view_as<int>(this);
			return  Client > 0 && Client <= MaxClients && IsClientInGame(Client);
			}
		}
	// public 
	public static bool ShouldDisplay(int victim, int attacker, int dmg, int weapon) {
		if(dmg <= 0)    return false;
		dmg = dmg > 999 ? 999 : dmg;

		if(weapon == -1)    return false;

		if(!DmgNum_t(attacker).IsValid || GetClientTeam(attacker) != 2 || !DmgNum_t(victim).IsValid)  return false;
		
		switch(g_iDisplayDamage_Mode) {
			case 1: return GetClientTeam(victim) == 3;
			case 2: return GetClientTeam(victim) == 2;
		}
		
		return true;
		}
	public static void DisplaySingleNumber(int Client, int num, float roffset, const float centerPos[3], const float Heading[3], const int color[4] = RedColor) {
		if(num < 0 || num > 9) return;

		float angle[3], right[3], up[3];
		GetVectorAngles(Heading, angle);
		angle[0] = 0.0;
		GetAngleVectors(angle, NULL_VECTOR, right, up);

		float startPos[3], EndPos[3], pos[3], epos[3], x[3], y[3];
		for(int i = 0; i < 7; i++) {
			if( !(NumberLine[num] & (1 << i)) ) continue;

			startPos = centerPos;
			EndPos = centerPos;

			if(g_iDisplayDamage_Mode == 0)
			{
				pos = NumberOffset[NumberConnect[i][0]];
				epos = NumberOffset[NumberConnect[i][1]];
			}
			else
			{
				pos = NumberRealOffset[NumberConnect[i][0]];
				epos = NumberRealOffset[NumberConnect[i][1]];
			}

			pos[1] += roffset;
			x = right;
			y = up;
			ScaleVector(x, pos[1]);
			ScaleVector(y, pos[2]);
			AddVectors(x, startPos, startPos);
			AddVectors(y, startPos, startPos);

			epos[1] += roffset;
			x = right;
			y = up;
			ScaleVector(x, epos[1]);
			ScaleVector(y, epos[2]);
			AddVectors(x, EndPos, EndPos);
			AddVectors(y, EndPos, EndPos);
			
			TE_SetupBeamPoints(startPos, EndPos, g_BeamSprite, 0, 0, 0, 0.2, 1.0, 1.0, 0, 0.0, color, 0);
			TE_SendToClient(Client);
		}
		}
	public static void DisplayToClient(int victim, int attacker, int dmg, float high = 24.0, float width = 7.0, const int color[4]) {
		if(g_iDisplayDamage_Mode != 0) {
			number_high = high;
			number_width = width;

			for(int i = 0; i < 6; i++)
			{
				NumberRealOffset[i][1] = NumberAPIOffset[i][1] * number_high;
				NumberRealOffset[i][2] = NumberAPIOffset[i][2] * number_width;
			}
		}

		float entpos[3], pos[3], Heading[3];
		GetClientEyePosition(victim, entpos);
		GetClientEyePosition(attacker, pos);
		SubtractVectors(entpos, pos, Heading);

		float woffset = NUMBER_INTERVAL + 2.0 * number_width;
		float centerPos[3];
		centerPos = entpos;
		centerPos[2] += NUMBER_OHIGH;

		char dmgstr[16];
		FormatEx(dmgstr, sizeof dmgstr, "%3d", dmg);
		int count = strlen(dmgstr);

		for(int i = 0; i < count; i++) {
			int num = dmgstr[i] - 48;    // 48 57
			if(num < 0 || num > 9) num = 0;

			float roffset = float(i - 1) * woffset;
			DmgNum_t.DisplaySingleNumber(attacker, num, roffset, centerPos, Heading, color);
		}
		}
	// public forward 
	public static void MapStart() {
		g_BeamSprite = PrecacheModel(SPRITE_BEAM);
		}
	public static void PutInServer(int Client) {
		if(!DmgNum_t(Client).IsValid)   return;

		SDKUnhook(Client, SDKHook_OnTakeDamageAlive, OnTakeDamages);
		SDKHook(Client, SDKHook_OnTakeDamageAlive, OnTakeDamages);
		}
	// public SDKHook 
	public static Action OnTakeDamages(int victim, int attacker, float damage, int weapon) {
		if(g_iDisplayDamage_Mode != 0)  return Plugin_Continue;

		int dmg = RoundToNearest(damage);
		if(!DmgNum_t.ShouldDisplay(victim, attacker, dmg, weapon))    return Plugin_Continue;

		DmgNum_t.DisplayToClient(victim, attacker, dmg, .color = RedColor);
		return Plugin_Continue;
		}
	// public 
}
/******************************************************
**          			CallBack
*******************************************************/

/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_damage_number_usedfor_plugins
static ConVar g_cvMode;

static void OnModeChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_iDisplayDamage_Mode = convar.IntValue;
}

public void OnPluginStart() {
	// 展示模式: 0=全部 1=仅特感 2=仅玩家 3=全部(自定义). convar 是唯一真源
	g_cvMode = CreateConVar("l4d_dmg_number_mode", "0", "伤害数字展示模式 (0=全部 1=仅特感 2=仅玩家 3=自定义)",
	                        FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_cvMode.AddChangeHook(OnModeChanged);
	g_iDisplayDamage_Mode = g_cvMode.IntValue;

	RegConsoleCmd("sm_dmgnum", Cmd_DmgNum);
}

public Action Cmd_DmgNum(int client, int args) {
	if (args < 1) {
		if (client > 0) PrintToChat(client, "\x04[Usage] \x03!dmgnum <0-3>  当前 = %d", g_cvMode.IntValue);
		else            PrintToServer("[dmg_number] sm_dmgnum <0-3>, 当前 = %d", g_cvMode.IntValue);
		return Plugin_Handled;
	}

	g_cvMode.IntValue = GetCmdArgInt(1);    // 走 convar, 由变更钩子统一写回

	return Plugin_Handled;
}

public void OnMapStart() {
	DmgNum_t.MapStart();
}

public void OnClientPutInServer(int Client) {
	DmgNum_t.PutInServer(Client);
}

public Action OnTakeDamages(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	return DmgNum_t.OnTakeDamages(victim, attacker, damage, weapon);
}

public Plugin myinfo = {
	name = "L4D2_TE_ShowDamageNumber",
	author = "crimson",
	description = "击中特感或坦克会看到伤害数字(学习版)",
	version = "1.0.0",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	if(GetEngineVersion() != Engine_Left4Dead2)    
	{
		strcopy(error, err_max, "This Plugins only support L4D2!!");
		return APLRes_SilentFailure;
	}

	RegPluginLibrary("L4D2_TE_ShowDamageNumber");
	CreateNative("DmgNum_t.ShouldDisplay",    Native_IsShowDamageNumber);
	CreateNative("DmgNum_t.DisplayToClient",    Native_ToShowDamageNumber);
	CreateNative("DmgNum_t.SetMode",   Native_SetDamageNumberMode);
	return APLRes_Success;
}

public any Native_IsShowDamageNumber(Handle plugin, int numParams) {   // 原为 bool, CreateNative 要求 NativeCall(any)
	if (numParams < 4)  return ThrowNativeError(SP_ERROR_PARAM, "Expected 4 parameters");
	
	int victim = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	int dmg = GetNativeCell(3);
	int weapon = GetNativeCell(4);
	
	bool result = DmgNum_t.ShouldDisplay(victim, attacker, dmg, weapon);
	return view_as<bool>(result);
}

public any Native_ToShowDamageNumber(Handle plugin, int numParams) {
	if (numParams < 6)  return ThrowNativeError(SP_ERROR_PARAM, "Expected 6 parameters");
	
	int victim = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	int dmg = GetNativeCell(3);
	float high = view_as<float>(GetNativeCell(4));
	float width = view_as<float>(GetNativeCell(5));
	int color[4];
	GetNativeArray(6, color, sizeof color);
	
	DmgNum_t.DisplayToClient(victim, attacker, dmg, high, width, color);
	return true;
}

public any Native_SetDamageNumberMode(Handle plugin, int numParams) {
	if (numParams < 1)  return ThrowNativeError(SP_ERROR_PARAM, "Expected 1 parameters");

	int mode = GetNativeCell(1);

	if(mode >= 0 && mode <= 3)          // 原为 ||, 恒真 -> 越界值也会被接受; 一并修正
		g_cvMode.IntValue = mode;       // 走 convar, 保持单一真源

	return true;
}
#endif
/******************************************************
**          	API (发布时切出去)
*******************************************************/
/* 这一块是给「不 include 实现、只跨插件调 native」的调用方用的声明。
 * 它在源码里保持注释态: 同名字 methodmap 和实现放在同一文件会 error 432, 不能参与本文件编译。
 * 发布时把 //@API_BEGIN 与 //@API_END 之间取出、去掉行首 "//", 即得 [API]l4d2_dmg_number.inc。
 */
//@API_BEGIN
//#if defined _crimson_dmg_number_api_included_
// #endinput
//#endif
//#define _crimson_dmg_number_api_included_
//
//#pragma semicolon 1
//#pragma newdecls required
//
///**
// * @brief	L4D2 伤害数字 —— 跨插件调用用的 native 声明
// * @note	实现与 native 注册在 l4d2_dmg_number.inc 的插件段里; 两种用法二选一, 别同时用:
// *			· #include <userbase/l4d2_dmg_number>  → 直接调方法 (实现就在你插件里)
// *			· #include <[API]l4d2_dmg_number>     → 调 native (对方插件已加载, 跨插件边界)
// */
//methodmap DmgNum_t {
//	/**
//	 * 判断是否执行伤害展示 (推荐应用于 SDKHook_OnTakeDamageAlive calback)
//	 *
//	 * @param victim            被攻击者
//	 * @param attacker          攻击者
//	 * @param dmg               伤害值
//	 * @param weapon            攻击者武器
//	 * @return					=true 展示这次伤害, =false 过滤这次伤害展示
//	 */
//	public static native bool ShouldDisplay(int victim, int attacker, int dmg, int weapon);
//
//	/**
//	 * 执行伤害展示
//	 *
//	 * @param victim            被攻击者
//	 * @param attacker          攻击者
//	 * @param dmg               伤害值
//	 * @param high              数字的高
//	 * @param width             数字的宽
//	 * @param color             数字的颜色
//	 * @return					=true 插件正常工作
//	 */
//	public static native bool DisplayToClient(int victim, int attacker, int dmg, float high = 24.0, float width = 7.0, const int color[4]);
//
//	/**
//	 * 配置伤害展示
//	 *
//	 * @param mode              = 0 使用默认配置, 展示全部伤害 ,非零时, 需要自行在 SDKHook_OnTakeDamageAlive 里配置 L4D2_DamageNumber_ToShow()
//								= 1 自定义配置, 仅在特感受到伤害生成数字特效
//								= 2 自定义配置, 仅在玩家受到伤害生成数字特效
//								= 3 自定义配置, 全部类型都会生成数字特效
//	 * @return					= true 插件正常工作
//	 */
//	public static native bool SetMode(int mode);
//}
//@API_END
/******************************************************
**          			  END
*******************************************************/