#pragma semicolon 1
#pragma newdecls required

#if defined _crimson_reserve_ammo_included_
 #endinput
#endif
#define _crimson_reserve_ammo_included_

#include <sourcemod>
#include <sdktools>

#define _crimson_reserve_ammo_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_reserve_ammo_usedfor_plugins
public Plugin myinfo = {
    name = "L4D2 Reserve Ammo",
    author = "crimson",
    description = "自定义各武器备弹上限",
    version = "1.0.0",
    url = ""
};
#endif
enum {
    IDX_RIFLE = 0,
    IDX_AUTOSHOTGUN,
    IDX_GRENADE,
    IDX_SHOTGUN,
    IDX_HUNTING,
    IDX_SMG,
    IDX_SNIPER,

    MAX_WEP_AMMO_TYPE
}

static const int g_iDefAmmoTypes[MAX_WEP_AMMO_TYPE] = {
    3,   // 步枪
    8,   // 连喷
    17,  // 榴弹
    7,   // 单喷
    9,   // 猎枪
    5,   // 冲锋枪
    10   // 狙击
};
static const int g_iDefAmmoValue[MAX_WEP_AMMO_TYPE] = {
    360,    // 步枪
     90,    // 连喷
     30,    // 榴弹
     72,    // 单喷
    150,    // 猎枪
    650,    // 冲锋枪
    180     // 狙击
};

static const char g_sConVarNames[MAX_WEP_AMMO_TYPE][] = {
    "ammo_assaultrifle_max",
    "ammo_autoshotgun_max",
    "ammo_grenadelauncher_max",
    "ammo_shotgun_max",
    "ammo_huntingrifle_max",
    "ammo_smg_max",
    "ammo_sniperrifle_max"
};
// static const char g_sWeaponNames[MAX_WEP_AMMO_TYPE][32] = {
//     "步枪",
//     "连喷",
//     "榴弹",
//     "单喷",
//     "猎枪",
//     "冲锋枪",
//     "狙击枪"
// };

#define MAX_WEP_AMMO_NUM    0x3FF

#define AMMO_CONFIG_DATA    "data/l4d2_reserve_ammo.cfg"
/******************************************************
**          	        variable
*******************************************************/
static ConVar g_cv_WeaponAmmo[MAX_WEP_AMMO_TYPE];

enum struct AmmoInfoData {
	bool HasSet;
    int ammo[MAX_WEP_AMMO_TYPE];
	
	void Reset() {
		static const AmmoInfoData def = { false, {360, 90,  30,  72,  150, 650, 180} };
		this = def;
	}
}

static AmmoInfoData g_eAmmo;

/******************************************************
**          			main
*******************************************************/
/**
 * @brief	提供修改备弹的封装
 * @note	public 	注释后的函数, 可供外部调用
 * @note    forward 注释后的函数, 需要在对应命名 forward 转发调用
 * @note	private 注释后的函数, 请不要外部调用

 * @note	外部通过调用 property 来访问静态数据
 */
methodmap ReserveAmmo {
    // private cvar
    public static void SetCvars() {
        for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++) {
            if(g_cv_WeaponAmmo[i] != null)  continue;
            
            g_cv_WeaponAmmo[i] = FindConVar(g_sConVarNames[i]);

            if(g_cv_WeaponAmmo[i] != null)
                g_cv_WeaponAmmo[i].IntValue = g_eAmmo.ammo[i];
            }
        }
    // private settings
    public static void GetSettings() {
        if(g_eAmmo.HasSet)  return;
        
        ReserveAmmo.LoadConfig();
        g_eAmmo.HasSet = true;
        // for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++)
        //     g_eAmmo.ammo[i] = g_iDefAmmoValue[i];
        }
    public static void LoadConfig() {
        static char sPath[PLATFORM_MAX_PATH];
        if(strlen(sPath) <= 0)
	        BuildPath(Path_SM, sPath, sizeof sPath, AMMO_CONFIG_DATA);

	    if( !FileExists(sPath) && !ReserveAmmo.CreateConfig(sPath)) {
            for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++)
                g_eAmmo.ammo[i] = g_iDefAmmoValue[i];

            return;
        }
        
	    KeyValues AmmoKV = new KeyValues("ammo");

	    if( !AmmoKV.ImportFromFile(sPath) ) {
		    LogMessage("Error loading file: \"%s\". will use default ammo value.", sPath);
            for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++)
                g_eAmmo.ammo[i] = g_iDefAmmoValue[i];

            delete AmmoKV;
            return;
        }

        int _ammo = -1;
        AmmoKV.GotoFirstSubKey();
        
        for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++) {
            _ammo = AmmoKV.GetNum(g_sConVarNames[i][5], g_iDefAmmoValue[i]);

            if(_ammo <= 0 || _ammo > MAX_WEP_AMMO_NUM)
                _ammo = g_iDefAmmoValue[i];

            g_eAmmo.ammo[i] = _ammo;
            // LogMessage("[Ammo] %s = %d", g_sConVarNames[i], g_eAmmo.ammo[i]);
        }

        delete AmmoKV;
        }
    public static bool CreateConfig(const char[] sPath) {
        LogMessage("Start Creating File: %s", sPath);

        File file = OpenFile(sPath, "w");
	    if (file == null) {
	    	LogError("Cannot open file: \"%s\"", sPath);
			return false;
	    }

	    if (!file.WriteLine("")) {
	    	LogError("Cannot write file line: \"%s\"", sPath);
	    	delete file;
			return false;
	    }
	    delete file;
         
        KeyValues AmmoKV = new KeyValues("ammo");
        
        for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++)
            AmmoKV.SetNum(g_sConVarNames[i][5], g_iDefAmmoValue[i]);
        
        if(!AmmoKV.ExportToFile(sPath)) {
            LogError("Failed to save to file: %s", sPath);
            delete AmmoKV;
            return false;
        }

        delete AmmoKV;
        return true;
        }
    // private 
    public static bool IsValidClient(int client) {
        return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
        }

    public static int GetWepIndex(int PrimType) {
        for(int i = 0; i < MAX_WEP_AMMO_TYPE; i++)
            if(g_iDefAmmoTypes[i] == PrimType)
                return i;
        
        return -1;
        }
    // public 
    public static void ManualRefresh() {
        g_eAmmo.Reset();
        ReserveAmmo.GetSettings();
        ReserveAmmo.SetCvars();
        }
    // private Ammo 
    public static bool SetPlayerAmmo(int Client) {
        //int weapon = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");
        int weapon = GetPlayerWeaponSlot(Client, 0);
        
        if(weapon == -1)    return false;
        
        int Clip = GetEntProp(weapon, Prop_Data, "m_iClip1");
        int PrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
        int Ammo = GetEntProp(Client, Prop_Send, "m_iAmmo", _, PrimType);
        
        int wepAmmoIndex = ReserveAmmo.GetWepIndex(PrimType);

        if(wepAmmoIndex == -1)  return false;

        int currentAmmo = g_eAmmo.ammo[wepAmmoIndex] - g_iDefAmmoValue[wepAmmoIndex] + Ammo;
        
        currentAmmo = (currentAmmo < MAX_WEP_AMMO_NUM ? currentAmmo : MAX_WEP_AMMO_NUM);

        SetEntProp(weapon, Prop_Send, "m_iClip1", Clip);
        SetEntProp(Client, Prop_Send, "m_iAmmo",  currentAmmo, _, PrimType);
        
        return true;
        }
    public static void SetAllSurvAmmo() {
        for(int i = 1; i <= MaxClients; i++)
            if(ReserveAmmo.IsValidClient(i))
                ReserveAmmo.SetPlayerAmmo(i);
        }
    // public forward 
    public static void PluginStart() {
        #if defined _crimson_reserve_ammo_usedfor_plugins
        HookEvent("round_start",        Event_round_start);

        RegConsoleCmd("sm_ammo",        Cmd_LoadAmmoConfig);
        #endif

        ReserveAmmo.GetSettings();
        ReserveAmmo.SetCvars();
	    }

	public static void MapStart() {
        g_eAmmo.Reset();
        ReserveAmmo.GetSettings();
        ReserveAmmo.SetCvars();
	    }

	public static void MapEnd() {
		g_eAmmo.Reset();
	    }
    // public EventHook
    public static void RoundStart() {
        ReserveAmmo.GetSettings();
        ReserveAmmo.SetCvars();

        CreateTimer(15.0, _DelayToSetPlayerAmmo, _, TIMER_FLAG_NO_MAPCHANGE);
        }
}
/******************************************************
**          			CallBack
*******************************************************/
static Action _DelayToSetPlayerAmmo(Handle timer) {
    ReserveAmmo.SetAllSurvAmmo();
    return Plugin_Handled;
}
/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_reserve_ammo_usedfor_plugins
public void OnPluginStart() {
	ReserveAmmo.PluginStart();
}

public void OnMapStart() {
	ReserveAmmo.MapStart();
}

public void OnMapEnd() {
	ReserveAmmo.MapEnd();
}

static void Event_round_start(Event event, const char[] name, bool dontBroadcast) {
	ReserveAmmo.RoundStart();
}

static Action Cmd_LoadAmmoConfig(int Client, int args) {
    ReserveAmmo.ManualRefresh();
    return Plugin_Handled;
}
#endif
/******************************************************
**					        END
*******************************************************/