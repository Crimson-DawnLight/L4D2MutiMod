#if defined _crimson_weapon_reload_included_
 #endinput
#endif
#define _crimson_weapon_reload_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>            // SDKCall 系列 + GetEntPropEnt
#include <[API]l4d2_base>      // GetWeaponTypeFromCls + WeaponType

#define _crimson_weapon_reload_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_weapon_reload_usedfor_plugins
public Plugin myinfo = {
    name = "WeaponReload Function",
    author = "crimson",
    description = "provide reload function",
    version = "1.0.0",
    url = ""
};
#endif
/******************************************************
**          	        variable
*******************************************************/
static Handle g_hSDK_CTerrorGun_FinishReload;
static Handle g_hSDK_CTerrorGun_AbortReload;
/******************************************************
**          			main
*******************************************************/
methodmap WepReload {
	public WepReload(int weapon) {
		return view_as<WepReload>(weapon);
		}
    // public SDKCall
    public void FinishReload() {
        SDKCall(g_hSDK_CTerrorGun_FinishReload, view_as<int>(this));
        }
    public void AbortReload() {
        SDKCall(g_hSDK_CTerrorGun_AbortReload, view_as<int>(this));
        }
    // public: 完整重装 —— 先 Abort 再 Finish, 顺序不可换
    public void Reload() {
        SDKCall(g_hSDK_CTerrorGun_AbortReload, view_as<int>(this));
        SDKCall(g_hSDK_CTerrorGun_FinishReload, view_as<int>(this));
        }
    // public forward
	public static void PluginStart(GameData hGameData) {
        StartPrepSDKCall(SDKCall_Entity);
        if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorGun::FinishReload") == false )
        {
            LogError("Failed to find signature: \"CTerrorGun::FinishReload\"");
        } else {
            g_hSDK_CTerrorGun_FinishReload = EndPrepSDKCall();
            if( g_hSDK_CTerrorGun_FinishReload == null )
                LogError("Failed to create SDKCall: \"CTerrorGun::FinishReload\"");
        }

        StartPrepSDKCall(SDKCall_Entity);
        if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorGun::AbortReload") == false )
        {
            LogError("Failed to find signature: \"CTerrorGun::AbortReload\"");
        } else {
            g_hSDK_CTerrorGun_AbortReload = EndPrepSDKCall();
            if( g_hSDK_CTerrorGun_AbortReload == null )
                LogError("Failed to create SDKCall: \"CTerrorGun::AbortReload\"");
        }
        }
	// public EventHook
	// public
}
/******************************************************
**          			CallBack
*******************************************************/

/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_weapon_reload_usedfor_plugins
public void OnPluginStart() {
    GameData hGameData = LoadGameConfigFile("weapon_reloading");

    if(hGameData == null)
        SetFailState("Failed to load \"gamedata/weapon_reloading.txt\"");

    WepReload.PluginStart(hGameData);

    delete hGameData;

    RegConsoleCmd("sm_reload", Cmd_Reload);
}

public Action Cmd_Reload(int client, int args) {
    if(client <= 0)                             // 控制台执行: 没有目标武器
        return Plugin_Handled;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(weapon == -1)
        return Plugin_Handled;

    // CTerrorGun 的虚表只对枪械成立: 1..19 = 步枪/冲锋枪/霰弹/狙击/榴弹/手枪/马格南。
    // 近战、投掷物、道具(20..)套上去会崩, 必须挡掉。
    char sCls[64];
    GetEntityClassname(weapon, sCls, sizeof sCls);

    WeaponType type = GetWeaponTypeFromCls(sCls);
    if(type < WeaponType_RifleM60 || type > WeaponType_Magnum)
        return Plugin_Handled;

    WepReload wep = view_as<WepReload>(weapon);
    wep.Reload();

    return Plugin_Handled;
}
#endif
/******************************************************
**          			  END
*******************************************************/
