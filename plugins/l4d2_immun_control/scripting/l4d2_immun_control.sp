#if defined _crimson_immun_control_included_
 #endinput
#endif
#define _crimson_immun_control_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>        // 外部依赖: left4dhooks.smx (发布时需说明)

// 这里不能用 <[API]l4d2_base> 的 PlayerState.Valid —— 那个头与 <left4dhooks>
// 不能同时 include(两边都裸定义 enum WeaponType, error 021)。下面是它的等价判定。
static bool IsValidPlayer(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

#define _crimson_immun_control_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_immun_control_usedfor_plugins
public Plugin myinfo = {
    name = "L4D2 Immun Control",
    author = "豆瓣酱な/crimson",
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
/******************************************************
**          	        variable
*******************************************************/
enum struct ImmunInfoData {
    int AllImmunFlag;                       // 全局免疫位, convar 驱动
    int PlayerImmunFlag[MAXPLAYERS+1];      // 每人一份, 默认跟全局
    int ImmunAbility[MAXPLAYERS+1];         // 上面两者的与, 运行时判定用

    void Reset() {
        static const ImmunInfoData def = { 0, {0, ...}, {0, ...} };
        this = def;
    }
}
static ImmunInfoData g_eImmnu;
/******************************************************
**          			main
*******************************************************/
/**
 * @brief	提供免疫特感控制的封装
 * @note	public 	注释后的函数, 可供外部调用
 * @note    forward 注释后的函数, 需要在对应命名 forward 转发调用
 * @note	private 注释后的函数, 请不要外部调用
 */
methodmap ImmmunControl {
    public ImmmunControl(int Client) {
        return view_as<ImmmunControl>(Client);
        }

    property int index {
        public get()    { return view_as<int>(this); }
        }
    // public 单类型免疫位 (读: 全局与个人都开才算)
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
    // public 全局: 改全局位, 并把在服生还者一起重套
    public static void SetAllImmun(int immunType, bool IsImmun) {
        if(immunType < 0 || immunType >= MAX_IMMUN_TYPE)
            return;

        int bitFlag = (1 << immunType);

        if(IsImmun) g_eImmnu.AllImmunFlag |= bitFlag;
        else        g_eImmnu.AllImmunFlag &= ~bitFlag;

        for(int i = 1; i <= MaxClients; i++) {
            if(!IsValidPlayer(i))
                continue;

            ImmmunControl.ApplyGlobal(i);
        }
        }
    // public 进服/换图时把全局位套到这个人身上
    public static void ApplyGlobal(int client) {
        if(!IsValidPlayer(client))
            return;

        g_eImmnu.PlayerImmunFlag[client] = g_eImmnu.AllImmunFlag;
        ImmmunControl(client).UpdateImmun();
        }
    // public 单人开关某类型
    public void SetPlayerImmun(int immunType, bool IsImmun) {
        if(immunType < 0 || immunType >= MAX_IMMUN_TYPE)
            return;

        int bitFlag = (1 << immunType);          // 原版这里漏了声明, 用了上一函数的局部名

        if(IsImmun) g_eImmnu.PlayerImmunFlag[this.index] |= bitFlag;
        else        g_eImmnu.PlayerImmunFlag[this.index] &= ~bitFlag;

        this.UpdateImmun();
        }
    // private Update
    public void UpdateImmun() {
        int Client = this.index;
        g_eImmnu.ImmunAbility[Client] = g_eImmnu.AllImmunFlag & g_eImmnu.PlayerImmunFlag[Client];
        }
    // public 解除正在控制该玩家的特感 (原版是 static 却用了 this)
    public void ReleaseControl(int immunType) {
        int victim = this.index;
        int attacker;
        switch(immunType) {
            case IMMUN_Smoker: {        // 解除舌头控制
                attacker = GetEntPropEnt(victim, Prop_Send, "m_tongueOwner");
                if(attacker > 0)    L4D_Smoker_ReleaseVictim(victim, attacker);
                }
            case IMMUN_Hunter: {        // 解除猎人控制
                attacker = GetEntPropEnt(victim, Prop_Send, "m_pounceAttacker");
                if(attacker > 0)    L4D_Hunter_ReleaseVictim(victim, attacker);
                }
            case IMMUN_Jockey: {        // 解除猴子控制
                attacker = GetEntPropEnt(victim, Prop_Send, "m_jockeyAttacker");
                if(attacker > 0)    L4D2_Jockey_EndRide(victim, attacker);
                }
            case IMMUN_Charger: {       // 解除牛牛控制
                attacker = GetEntPropEnt(victim, Prop_Send, "m_carryAttacker");
                if(attacker > 0)    L4D2_Charger_EndCarry(victim, attacker);

                attacker = GetEntPropEnt(victim, Prop_Send, "m_pummelAttacker");
                if(attacker > 0)    L4D2_Charger_EndPummel(victim, attacker);
                }
            }
        }
}
/******************************************************
**				left4dhooks forward
*******************************************************/
//舌头缠住生还者时.
public Action L4D_OnGrabWithTongue(int victim, int attacker)  {
	if (!IsValidPlayer(victim) || !ImmmunControl(victim).ImmunSmoker)
		return Plugin_Continue;

	return Plugin_Handled;
}
//猎人扑倒生还者时.
public Action L4D_OnPouncedOnSurvivor(int victim, int attacker)
{
	if (!IsValidPlayer(victim) || !ImmmunControl(victim).ImmunHunter)
		return Plugin_Continue;

	return Plugin_Handled;
}
//猴子骑乘生还者时.
public Action L4D2_OnJockeyRide(int victim, int attacker)
{
	if (!IsValidPlayer(victim) || !ImmmunControl(victim).ImmunJockey)
		return Plugin_Continue;

	return Plugin_Handled;
}
//牛牛携带生还者时.
public Action L4D2_OnStartCarryingVictim(int victim, int attacker)
{
	if (!IsValidPlayer(victim) || !ImmmunControl(victim).ImmunCharger)
		return Plugin_Continue;

	return Plugin_Handled;
}
//牛牛殴打生还者时.
public Action L4D2_OnPummelVictim(int attacker, int victim)
{
	if (!IsValidPlayer(victim) || !ImmmunControl(victim).ImmunCharger)
		return Plugin_Continue;

	// from "left4dhooks_test.sp": 挡掉殴打后把人挪开, 免得卡住
	DataPack dPack = new DataPack();
	dPack.WriteCell(GetClientUserId(attacker));
	dPack.WriteCell(GetClientUserId(victim));
	RequestFrame(OnPummelTeleport, dPack);

	// To block the stumble animation, uncomment and use the following 2 lines:
	AnimHookEnable(victim, OnPummelOnAnimPre, INVALID_FUNCTION);
	CreateTimer(0.3, TimerOnPummelResetAnim, victim);

	return Plugin_Handled;
}
// To fix getting stuck use this:
void OnPummelTeleport(DataPack dPack) {
	dPack.Reset();
	int attacker = dPack.ReadCell();
	int victim = dPack.ReadCell();
	delete dPack;

	attacker = GetClientOfUserId(attacker);
	if (!attacker || !IsClientInGame(attacker))
		return;

	victim = GetClientOfUserId(victim);
	if (!victim || !IsClientInGame(victim))
		return;

	SetVariantString("!activator");
	AcceptEntityInput(victim, "SetParent", attacker);
	TeleportEntity(victim, view_as<float>({50.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(victim, "ClearParent");
}
// To block the stumble animation use the next two functions:
Action OnPummelOnAnimPre(int client, int &anim) {
	if (anim == L4D2_ACT_TERROR_SLAMMED_WALL || anim == L4D2_ACT_TERROR_SLAMMED_GROUND) {
		anim = L4D2_ACT_STAND;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
// Don't need client userID since it's not going to be validated just removed
Action TimerOnPummelResetAnim(Handle timer, any victim) {
	AnimHookDisable(victim, OnPummelOnAnimPre);

	return Plugin_Continue;
}
//免疫坦克石头和牛牛撞倒.
public Action L4D_OnKnockedDown(int client, int reason)
{
	if (!IsValidPlayer(client))
		return Plugin_Continue;

	switch(reason)
	{
		case 2: {   // 坦克石头
			if (!ImmmunControl(client).ImmunTank)
				return Plugin_Continue;
			return Plugin_Handled;
			}
		case 3: {   // 牛牛撞倒
			if (!ImmmunControl(client).ImmunCharger)
				return Plugin_Continue;
			return Plugin_Handled;
			}
	}
	return Plugin_Continue;
}
//免疫坦克拳头.
public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
	if (!IsValidPlayer(player) || !ImmmunControl(player).ImmunTank)
		return Plugin_Continue;

	return Plugin_Handled;
}
/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_immun_control_usedfor_plugins
static ConVar g_cvImmunFlags;

static void OnImmunFlagsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	// 全局位: 逐类型套下去 (SetAllImmun 会同时更新 AllImmunFlag 与在服玩家)
	for(int type = 0; type < MAX_IMMUN_TYPE; type++)
		ImmmunControl.SetAllImmun(type, !!(convar.IntValue & (1 << type)));
}

public void OnPluginStart() {
	g_cvImmunFlags = CreateConVar("l4d_immun_flags", "31", "生还者免疫哪些特感 (位掩码: 1=舌 2=猎 4=猴 8=牛 16=坦)",
	                              FCVAR_NOTIFY, true, 0.0, true, float((1 << MAX_IMMUN_TYPE) - 1));
	g_cvImmunFlags.AddChangeHook(OnImmunFlagsChanged);
	OnImmunFlagsChanged(g_cvImmunFlags, "", "");        // 开局按默认值套一遍

	RegConsoleCmd("sm_immun", Cmd_Immun);
}

public void OnClientPutInServer(int client) {
	ImmmunControl.ApplyGlobal(client);
}

public Action Cmd_Immun(int client, int args) {
	if (args < 1) {
		if (client > 0) PrintToChat(client, "\x04[Usage] \x03!immun <flag 0-%d>  当前 = %d", (1 << MAX_IMMUN_TYPE) - 1, g_cvImmunFlags.IntValue);
		else            PrintToServer("[immun_control] sm_immun <flag 0-%d>, 当前 = %d", (1 << MAX_IMMUN_TYPE) - 1, g_cvImmunFlags.IntValue);
		return Plugin_Handled;
	}

	g_cvImmunFlags.IntValue = GetCmdArgInt(1);      // 走 convar, 由变更钩子统一套用

	return Plugin_Handled;
}
#endif
/******************************************************
**						END
*******************************************************/
