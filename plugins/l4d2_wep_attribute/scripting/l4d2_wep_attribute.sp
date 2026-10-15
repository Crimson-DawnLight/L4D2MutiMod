#if defined _crimson_wep_attribute_included_
 #endinput
#endif
#define _crimson_wep_attribute_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define _crimson_wep_attribute_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_wep_attribute_usedfor_plugins
public Plugin myinfo = {
    name = "L4D2 Weapon Attribute",
    author = "crimson",
    description = "运行时读写武器 / 近战属性 (KV 配置 data/weapon_attributes.cfg)",
    version = "1.0.0",
    url = ""
};
#endif
#define FILE_CONFIG_DEF     "data/weapon_attributes_def.cfg"
#define FILE_CONFIG         "data/weapon_attributes.cfg"

// weapon 
enum WepAttrInt {
	IWA_Damage,
	IWA_Bullets,
	IWA_ClipSize,
	IWA_Bucket,
	IWA_Tier, // L4D2 only
	IWA_DefaultSize, // Default weapon clip size
	IWA_WeaponType, // Can use with the "WeaponType" enum

	MAX_WEPATTR_INT_TYPE
};

enum WepAttrFloat  {
	FWA_MaxPlayerSpeed,
	FWA_SpreadPerShot,
	FWA_MaxSpread,
	FWA_SpreadDecay,
	FWA_MinDuckingSpread,
	FWA_MinStandingSpread,
	FWA_MinInAirSpread,
	FWA_MaxMovementSpread,
	FWA_PenetrationNumLayers,
	FWA_PenetrationPower,
	FWA_PenetrationMaxDist,
	FWA_CharPenetrationMaxDist,
	FWA_Range,
	FWA_RangeModifier,
	FWA_CycleTime,
	FWA_PelletScatterPitch,
	FWA_PelletScatterYaw,
	FWA_VerticalPunch,
	FWA_HorizontalPunch, // Requires "z_gun_horiz_punch" cvar changed to "1" - maybe not, read/write might work fine without
	FWA_GainRange,
	FWA_ReloadDuration,

	MAX_WEPATTR_FLOAT_TYPE
};

// melee
enum MeleeAttrInt {
	IMWA_DamageFlags,
	IMWA_RumbleEffect,

    MAX_MELEEATTR_INT_TYPE
};

enum MeleeAttrBool {
	BMWA_Decapitates,

	MAX_MELEEATTR_BOOL_TYPE
};

enum MeleeAttrFloat {
	FMWA_Damage,
	FMWA_RefireDelay,
	FMWA_WeaponIdleTime,
    
	MAX_MELEEATTR_FLOAT_TYPE
};
/******************************************************
**          	        SDK Variable
*******************************************************/
// weapon type 
#define MAX_WEP_CLS_TYPE    45
static const char WepClassName[MAX_WEP_CLS_TYPE][] = {
    "weapon_none",
    "weapon_pistol",
    "weapon_smg",			
    "weapon_pumpshotgun",		
    "weapon_autoshotgun",		
    "weapon_rifle",	
    "weapon_hunting_rifle",
    "weapon_smg_silenced",
    "weapon_shotgun_chrome",	
    "weapon_rifle_desert",	
    "weapon_sniper_military",
    "weapon_shotgun_spas",
    "weapon_first_aid_kit",	
    "weapon_molotov",		
    "weapon_pipe_bomb",
    "weapon_pain_pills",	
    "weapon_gascan",	
    "weapon_propanetank",	
    "weapon_oxygentank",
    "weapon_melee",
    "weapon_chainsaw",
    "weapon_grenade_launcher",
    // "weapon_ammo_pack",
    "weapon_adrenaline",	
    "weapon_defibrillator",
    "weapon_vomitjar",
    "weapon_rifle_ak47",	
    "weapon_gnome",
    "weapon_cola_bottles",
    "weapon_fireworkcrate",
    "weapon_upgradepack_incendiary",
    "weapon_upgradepack_explosive",
    "weapon_pistol_magnum",
    "weapon_smg_mp5",
    "weapon_rifle_sg552",
    "weapon_sniper_awp",
    "weapon_sniper_scout",
    "weapon_rifle_m60",
    "weapon_tank_claw",
    "weapon_hunter_claw",
    "weapon_charger_claw",
    "weapon_boomer_claw",
    "weapon_smoker_claw",
    "weapon_spitter_claw",
    "weapon_jockey_claw",
    "weapon_ammo_spawn" 
    };
static const int WepTableOffset[MAX_WEP_CLS_TYPE] = {
     0,
     1,
     2,
     3,
     4,
     5,
     6,
     7,
     8,
     9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    // 22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    54 
    };
static Address WepPtrs[MAX_WEP_CLS_TYPE] = { Address_Null, ...};

// weapon Attribute int
static const char WepIntAttrName[MAX_WEPATTR_INT_TYPE][] = {
    "damage",
    "bullets",
    "clipsize",
    "bucket",
    "tier",
    "defaultsize",
    "weapontype"
    };
static const char WepIntOffsetString[MAX_WEPATTR_INT_TYPE][] = {
    "L4D2IntWeapon_Damage",
    "L4D2IntWeapon_Bullets",
    "L4D2IntWeapon_ClipSize",
    "L4D2IntWeapon_Bucket",
    "L4D2IntWeapon_Tier",
    "L4D2IntWeapon_DefaultSize",
    "L4D2IntWeapon_Type" 
    };
static Address WepIntOffset[MAX_WEPATTR_INT_TYPE] = { Address_Null, ...};

// weapon Attribute float
static const char WepFloatAttrName[MAX_WEPATTR_FLOAT_TYPE][] = {
    "maxplayerspeed",
    "spreadpershot",
    "maxspread",
    "spreaddecay",
    "minduckspread",
    "minstandspread",
    "minairspread",
    "maxmovespread",
    "penlayers",
    "penpower",
    "penmaxdist",
    "charpenmaxdist",
    "range",
    "rangemod",
    "cycletime",
    "scatterpitch",
    "scatteryaw",
    "verticalpunch",
    "horizpunch",
    "gainrange",
    "reloadduration"
    };
static const char WepFloatOffsetString[MAX_WEPATTR_FLOAT_TYPE][] = {
    "L4D2FloatWeapon_MaxPlayerSpeed",
    "L4D2FloatWeapon_SpreadPerShot",
    "L4D2FloatWeapon_MaxSpread",
    "L4D2FloatWeapon_SpreadDecay",
    "L4D2FloatWeapon_MinDuckingSpread",
    "L4D2FloatWeapon_MinStandingSpread",
    "L4D2FloatWeapon_MinInAirSpread",
    "L4D2FloatWeapon_MaxMovementSpread",
    "L4D2FloatWeapon_PenetrationNumLayers",
    "L4D2FloatWeapon_PenetrationPower",
    "L4D2FloatWeapon_PenetrationMaxDist",
    "L4D2FloatWeapon_CharPenetrationMaxDist",
    "L4D2FloatWeapon_Range",
    "L4D2FloatWeapon_RangeModifier",
    "L4D2FloatWeapon_CycleTime",
    "L4D2FloatWeapon_ScatterPitch",
    "L4D2FloatWeapon_ScatterYaw",
    "L4D2FloatWeapon_VerticalPunch",
    "L4D2FloatWeapon_HorizontalPunch",
    "L4D2FloatWeapon_GainRange",
    "L4D2FloatWeapon_ReloadDuration" 
    };
static Address WepFloatOffset[MAX_WEPATTR_FLOAT_TYPE];

// melee type 
#define MAX_MELEE_SCRIPT_TYPE       13
static const char MeleeScriptName[MAX_MELEE_SCRIPT_TYPE][] = {
    "fireaxe",
    "frying_pan",
    "machete",
    "baseball_bat",
    "crowbar",
    "cricket_bat",
    "tonfa",
    "katana",
    "electric_guitar",
    "knife",
    "golfclub",
    "pitchfork",
    "shovel" 
    };
static Address MeleePtrs[MAX_MELEE_SCRIPT_TYPE] = { Address_Null, ...};

// melee Attribute int
static const char MeleeIntAttrString[MAX_MELEEATTR_INT_TYPE][] = {
	"DamageFlags",
	"RumbleEffect"
    };
static Address MeleeIntOffset[MAX_MELEEATTR_INT_TYPE];

// melee Attribute bool
static const char MeleeBoolAttrString[MAX_MELEEATTR_BOOL_TYPE][] = {
    "Decapitates"
    };
static Address MeleeBoolOffset[MAX_MELEEATTR_BOOL_TYPE];

// melee Attribute float
static const char MeleeFloatAttrString[MAX_MELEEATTR_FLOAT_TYPE][] = {
    "Damage",
    "RefireDelay",
    "WeaponIdleTime"
    };
static Address MeleeFloatOffset[MAX_MELEEATTR_FLOAT_TYPE];

static Handle g_hSDK_GetWeaponInfo;
static Handle g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo;
// Address g_pWeaponInfoDatabase;
static Address g_pMeleeWeaponInfoStore;

// StringMap g_aWeaponPtrs;					// Stores weapon pointers to retrieve CCSWeaponInfo and CTerrorWeaponInfo data
// StringMap g_aWeaponIDs;						// Store weapon IDs to get above pointers
// StringMap g_aMeleeIDs;						// Store melee IDs
// ArrayList g_aMeleePtrs;						// Stores melee pointers
/******************************************************
**          	        variable
*******************************************************/
enum struct WepAttributeData {
    bool HasBuild;
    int iWepAttr[MAX_WEPATTR_INT_TYPE];
    float fWepAttr[MAX_WEPATTR_FLOAT_TYPE];
    
    void Reset() {
        static const WepAttributeData def = { false, {-1, ...}, {-1.0, ...} };
        this = def;
    }
}
static WepAttributeData g_eDefWepAttr[MAX_WEP_CLS_TYPE];
static WepAttributeData g_eWepAttr[MAX_WEP_CLS_TYPE];

enum struct MeleeAttributeData {
    bool HasBuild;
    bool bMeleeAttr[MAX_MELEEATTR_BOOL_TYPE];
    int iMeleeAttr[MAX_MELEEATTR_INT_TYPE];
    float fMeleeAttr[MAX_MELEEATTR_FLOAT_TYPE];

    void Reset() {
        static const MeleeAttributeData def = { false, {false}, {-1, ...}, {-1.0, ...} };
        this = def;
    }
}
static MeleeAttributeData g_eDefMeleeAttr[MAX_MELEE_SCRIPT_TYPE];
static MeleeAttributeData g_eMeleeAttr[MAX_MELEE_SCRIPT_TYPE];

static bool g_bMapStarted;
/******************************************************
**          			main
*******************************************************/
/**
 * @brief	提供修改武器属性封装
 * @note	public 	注释后的函数, 可供外部调用
 * @note    forward 注释后的函数, 需要在对应命名 forward 转发调用
 * @note	private 注释后的函数, 请不要外部调用

 * @note	外部通过调用 property 来访问静态数据
 */
methodmap WeaponAttribute {
    // private 
    public static int GetWepType(const char[] sWeaponName) {
        static StringMap map;
        static char weaponName[32];
        static int wepType;

        if( strncmp(sWeaponName, "weapon_", 7) )
            FormatEx(weaponName, sizeof weaponName, "weapon_%s", sWeaponName);
        else    strcopy(weaponName, sizeof weaponName, sWeaponName);

        if(map == null) {
            map = new StringMap();
        
            for(int i = 0; i < MAX_WEP_CLS_TYPE; i++)
                map.SetValue(WepClassName[i], i);
        }

        return  map.GetValue(weaponName, wepType) ? wepType : -1;
        }
    public static int GetMeleeType(const char[] sMeleeName) {
        static StringMap map;
        static int meleeType;

        if(map == null) {
            map = new StringMap();

            for(int i = 0; i < MAX_MELEE_SCRIPT_TYPE; i++)
                map.SetValue(MeleeScriptName[i], i);
        }

        return map.GetValue(sMeleeName, meleeType) ? meleeType : -1;
        }
    // private 
    public static void StartSDKCall() {
        GameData hGameData = new GameData("l4d2_wep_attribute");
	    if( hGameData == null )
            SetFailState("Failed to load \"%s.txt\" gamedata.", "l4d2_wep_attribute");

        // Offset
        for(int i = 0; i < view_as<int>(MAX_WEPATTR_INT_TYPE); i++)
            WepIntOffset[i] = view_as<Address>( hGameData.GetOffset(WepIntOffsetString[i]) );

        for(int i = 0; i < view_as<int>(MAX_WEPATTR_FLOAT_TYPE); i++)
            WepFloatOffset[i] = view_as<Address>( hGameData.GetOffset(WepFloatOffsetString[i]) );

		MeleeIntOffset[0]   = view_as<Address>( hGameData.GetOffset("L4D2IntMeleeWeapon_DamageFlags") );
		MeleeIntOffset[1]   = view_as<Address>( hGameData.GetOffset("L4D2IntMeleeWeapon_RumbleEffect") );
        MeleeBoolOffset[0]  = view_as<Address>( hGameData.GetOffset("L4D2BoolMeleeWeapon_Decapitates") );
		MeleeFloatOffset[0] = view_as<Address>( hGameData.GetOffset("L4D2FloatMeleeWeapon_Damage") );
		MeleeFloatOffset[1] = view_as<Address>( hGameData.GetOffset("L4D2FloatMeleeWeapon_RefireDelay") );
		MeleeFloatOffset[2] = view_as<Address>( hGameData.GetOffset("L4D2FloatMeleeWeapon_WeaponIdleTime") );

        // Address
        // g_pWeaponInfoDatabase = hGameData.GetAddress("WeaponInfoDatabase");
        g_pMeleeWeaponInfoStore = hGameData.GetAddress("MeleeWeaponInfoStore");

        // Signature
        StartPrepSDKCall(SDKCall_Static);
        if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetWeaponInfo") == false )
        {
            LogError("Failed to find signature: \"GetWeaponInfo\"");
        } else {
            PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
            PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
            g_hSDK_GetWeaponInfo = EndPrepSDKCall();
            if( g_hSDK_GetWeaponInfo == null )
                LogError("Failed to create SDKCall: \"GetWeaponInfo\"");
        }

        StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CMeleeWeaponInfoStore::GetMeleeWeaponInfo") == false )
		{
			LogError("Failed to find signature: \"CMeleeWeaponInfoStore::GetMeleeWeaponInfo\"");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo = EndPrepSDKCall();
			if( g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo == null )
				LogError("Failed to create SDKCall: \"CMeleeWeaponInfoStore::GetMeleeWeaponInfo\"");
		}

        delete hGameData;

        // g_aWeaponPtrs = new StringMap();
	    // g_aWeaponIDs = new StringMap();

        // for(int i = 0; i < MAX_WEP_CLS_TYPE; i++)
        //     g_aWeaponIDs.SetValue(WepClassName[i], WepTableOffset[i]);

        // g_aMeleePtrs = new ArrayList(2);
		// g_aMeleeIDs = new StringMap();

        // for(int i = 0; i < MAX_MELEE_SCRIPT_TYPE; i++)
        //     g_aMeleeIDs.SetValue(MeleeScriptName[i], i);

        }
    public static Address GetWepPointer(const char[] sWeaponName) {
        int wepType = WeaponAttribute.GetWepType(sWeaponName);
        if(wepType == -1 || wepType >= MAX_WEP_CLS_TYPE)  return Address_Null;

        Address ptr = WepPtrs[wepType];

        if( ptr == Address_Null) {
            if( WepTableOffset[wepType] == -1 && wepType != 44) {
                LogError("Invalid weapon name (%s) or weapon unavailable (%d)", sWeaponName, wepType);
                return Address_Null;
            }

            //PrintToServer("#### CALL g_hSDK_GetWeaponInfo");
            ptr = view_as<Address>( SDKCall(g_hSDK_GetWeaponInfo, WepTableOffset[wepType]) );

            if( ptr != Address_Null ) 
                WepPtrs[wepType] = ptr;
        }

        return ptr;
        }
    public static Address GetMeleePointer(int meleeType) {
        if(!g_bMapStarted)  return Address_Null;
        if(meleeType < 0 || meleeType >= MAX_MELEE_SCRIPT_TYPE)     return Address_Null;

        Address ptr = MeleePtrs[meleeType];

        if(ptr != Address_Null)     return ptr;
        
        ptr = view_as<Address>(SDKCall(g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo, g_pMeleeWeaponInfoStore, meleeType));
        
        if( ptr == Address_Null) {
            LogStackTrace("Invalid melee ID (%d) or melee unavailable.", Address_Null);
            return Address_Null;
        }

        MeleePtrs[meleeType] = ptr;
        return ptr;
        }
    // private 
    // private weapon 
    public static int   GetWepInt(Address ptr, int iAttr) {
        if(iAttr < 0 || iAttr >= view_as<int>(MAX_WEPATTR_INT_TYPE))
            return -1;

        if( ptr == Address_Null )     return -1;
        
        int iValue = LoadFromAddress(ptr + WepIntOffset[iAttr], NumberType_Int32);
        return iValue;
        }
    
    public static float GetWepFloat(Address ptr, int fAttr) {
        if( fAttr < 0 || fAttr >= view_as<int>(MAX_WEPATTR_FLOAT_TYPE) )    return -1.0;
        if( ptr == Address_Null)     return -1.0;
        
        float fValue = view_as<float>(LoadFromAddress(ptr + WepFloatOffset[fAttr], NumberType_Int32));
        return fValue;
        }
    public static bool  SetWepInt(Address ptr, int iAttr, int iValue) {
        if( iValue < 0)  return false;
        if( iAttr < 0 || iAttr >= view_as<int>(MAX_WEPATTR_INT_TYPE))    return false;
        if( iAttr == view_as<int>(IWA_Tier) )    return false;
        if( ptr == Address_Null ) return false;

        StoreToAddress(ptr + WepIntOffset[iAttr], iValue, NumberType_Int32, false);
        return true;
        }
    public static bool  SetWepFloat(Address ptr, int fAttr, float fValue) {
        if( fValue < 0.0)    return false;
        if( fAttr < 0 || fAttr >= view_as<int>(MAX_WEPATTR_FLOAT_TYPE) )   return false;
        if( ptr == Address_Null )     return false;
        
        StoreToAddress(ptr + WepFloatOffset[fAttr], fValue, NumberType_Int32, false);
        return true;
        }
    
    // private melee 
    public static int   GetMeleeInt(Address ptr, int iAttr) {
        // int meleeType = WeaponAttribute.GetMeleeType(sMeleeName);
        // if(meleeType == -1)     return -1;
        // Address ptr = WeaponAttribute.GetMeleePointer(meleeType);
        if(ptr == Address_Null)     return -1;

        int iValue = LoadFromAddress(ptr + MeleeIntOffset[iAttr], NumberType_Int16);
        return iValue;
        }
    public static bool  GetMeleeBool(Address ptr, int bAttr) {
        if(ptr == Address_Null)     return false;

        bool bValue = view_as<bool>(LoadFromAddress(ptr + MeleeBoolOffset[bAttr], NumberType_Int8));
        return bValue;
        }
    public static float GetMeleeFloat(Address ptr, int fAttr) {
        if(ptr == Address_Null)     return -1.0;

        float fValue = view_as<float>(LoadFromAddress(ptr + MeleeFloatOffset[fAttr], NumberType_Int32));
        return fValue;
        }
    public static void  SetMeleeInt(Address ptr, int iAttr, int iValue) {
        if(iValue < 0)  return;
        if(iAttr < 0 || iAttr > view_as<int>(MAX_MELEEATTR_INT_TYPE) )     return;

        StoreToAddress(ptr + MeleeIntOffset[iAttr], iValue, NumberType_Int16);
        }
    public static void  SetMeleeBool(Address ptr, int bAttr, bool bValue) {
        if(bAttr < 0 || bAttr > view_as<int>(MAX_MELEEATTR_BOOL_TYPE))     return;
        
        StoreToAddress(ptr + MeleeBoolOffset[bAttr], bValue, NumberType_Int8);
        }
    public static void  SetMeleeFloat(Address ptr, int fAttr, float fValue) {
        if(fValue < 0.0)  return;
        if(fAttr < 0 || fAttr > view_as<int>(MAX_MELEEATTR_FLOAT_TYPE))     return;

        StoreToAddress(ptr + MeleeFloatOffset[fAttr], fValue, NumberType_Int32);
        }
    // private default  This shouldn't be called by user
    public static bool GetDefWepAttr() {
        Address ptr = Address_Null;
        for(int wepType = 1; wepType < MAX_WEP_CLS_TYPE; wepType++) {
            g_eDefWepAttr[wepType].Reset();

            ptr = WeaponAttribute.GetWepPointer(WepClassName[wepType]);

            if(ptr == Address_Null && wepType != 44) {
                LogError("Failed to load weapon \"%s\" pointer", WepClassName[wepType]);
                continue;
            }

            for(int iAttr = 0; iAttr < view_as<int>(MAX_WEPATTR_INT_TYPE); iAttr++)
                g_eDefWepAttr[wepType].iWepAttr[iAttr] = WeaponAttribute.GetWepInt(ptr, iAttr);
            
            for(int fAttr = 0; fAttr < view_as<int>(MAX_WEPATTR_FLOAT_TYPE); fAttr++)
                g_eDefWepAttr[wepType].fWepAttr[fAttr] = WeaponAttribute.GetWepFloat(ptr, fAttr);
            
            // g_eWepAttr[wepType] = g_eDefWepAttr[wepType];
        }
        }
    public static void GetDefMeleeAttr() {
        Address ptr = Address_Null;

        for(int meleeType = 0; meleeType < MAX_MELEE_SCRIPT_TYPE; meleeType++) {
            g_eDefMeleeAttr[meleeType].Reset();

            ptr = WeaponAttribute.GetMeleePointer(meleeType);

            if(ptr == Address_Null) {
                LogError("Failed to load melee \"%s\" pointer", MeleeScriptName[meleeType]);
                continue;
            }

            for(int iAttr = 0; iAttr < view_as<int>(MAX_MELEEATTR_INT_TYPE); iAttr++)
                g_eDefMeleeAttr[meleeType].iMeleeAttr[iAttr] = WeaponAttribute.GetMeleeInt(ptr, iAttr);

            for(int bAttr = 0; bAttr < view_as<int>(MAX_MELEEATTR_BOOL_TYPE); bAttr++)
                g_eDefMeleeAttr[meleeType].bMeleeAttr[bAttr] = WeaponAttribute.GetMeleeBool(ptr, bAttr);
            
            for(int fAttr = 0; fAttr < view_as<int>(MAX_MELEEATTR_FLOAT_TYPE); fAttr++)
                g_eDefMeleeAttr[meleeType].fMeleeAttr[fAttr] = WeaponAttribute.GetMeleeFloat(ptr, fAttr);

            // g_eMeleeAttr[meleeType] = g_eDefMeleeAttr[meleeType];
        }
        }
    // private load 
    public static void SaveToConfig(bool UseDef, const char[] filePath) {
        KeyValues kv = new KeyValues("Attribute");
        
        if (kv.JumpToKey("weapon", true)) {
            for (int wepType = 1; wepType < MAX_WEP_CLS_TYPE; wepType++) {
                if (kv.JumpToKey(WepClassName[wepType], true)) {
                    if (kv.JumpToKey("int", true)) {
                        for (int iAttr = 0; iAttr < view_as<int>(MAX_WEPATTR_INT_TYPE); iAttr++) {
                            int iValue = UseDef ? g_eDefWepAttr[wepType].iWepAttr[iAttr] : g_eWepAttr[wepType].iWepAttr[iAttr];
                            kv.SetNum(WepIntAttrName[iAttr], iValue);
                        }
                        
                        kv.GoBack();
                    }
                    
                    if (kv.JumpToKey("float", true)) {
                        for (int fAttr = 0; fAttr < view_as<int>(MAX_WEPATTR_FLOAT_TYPE); fAttr++) {
                            float fValue = UseDef ? g_eDefWepAttr[wepType].fWepAttr[fAttr] : g_eWepAttr[wepType].fWepAttr[fAttr];
                                kv.SetFloat(WepFloatAttrName[fAttr], fValue);
                        }
                        
                        kv.GoBack();
                    }
                    
                    kv.GoBack();
                }
            }
            
            kv.GoBack();
        }
        
        if(kv.JumpToKey("melee", true)) {
            for(int meleeType = 0; meleeType < MAX_MELEE_SCRIPT_TYPE; meleeType++) {
                if(kv.JumpToKey(MeleeScriptName[meleeType], true)) {
                    if(kv.JumpToKey("int", true)) {
                        for(int iAttr = 0; iAttr < view_as<int>(MAX_MELEEATTR_INT_TYPE); iAttr++) {
                            int iValue = g_eDefMeleeAttr[meleeType].iMeleeAttr[iAttr];
                            kv.SetNum(MeleeIntAttrString[iAttr], iValue);
                        }

                        kv.GoBack();
                    }

                    if(kv.JumpToKey("bool", true)) {
                        for(int bAttr = 0; bAttr < view_as<int>(MAX_MELEEATTR_BOOL_TYPE); bAttr++) {
                            bool bValue = g_eDefMeleeAttr[meleeType].bMeleeAttr[bAttr];
                            kv.SetNum(MeleeBoolAttrString[bAttr], view_as<int>(bValue));
                        }

                        kv.GoBack();
                    }

                    if(kv.JumpToKey("float", true)) {
                        for(int fAttr = 0; fAttr < view_as<int>(MAX_MELEEATTR_FLOAT_TYPE); fAttr++) {
                            float fValue = g_eDefMeleeAttr[meleeType].fMeleeAttr[fAttr];
                            kv.SetFloat(MeleeFloatAttrString[fAttr], fValue);
                        }

                        kv.GoBack();
                    }

                    kv.GoBack();
                }
            }

            kv.GoBack();
        }

        // char filePath[PLATFORM_MAX_PATH];
        // BuildPath(Path_SM, filePath, sizeof filePath, FILE_CONFIG);
        
        if (!kv.ExportToFile(filePath))
            LogError("Failed to save weapon attributes to file: %s", filePath);
        else
            LogMessage("Weapon attributes saved to: %s", filePath);
        
        delete kv;
        }
    public static void LoadFromConfig(bool UseDef) {
        char filePath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, filePath, sizeof filePath, UseDef ? FILE_CONFIG_DEF : FILE_CONFIG);

        KeyValues kv = new KeyValues("Attribute");

        if(!kv.ImportFromFile(filePath)) {
            LogError("Failed To load config \"%s\"", filePath);
            return;
        }
        
        if (kv.JumpToKey("weapon", true)) {
            for (int wepType = 1; wepType < MAX_WEP_CLS_TYPE; wepType++) {
                UseDef ? g_eDefWepAttr[wepType].Reset() : g_eWepAttr[wepType].Reset();

                if (kv.JumpToKey(WepClassName[wepType], true)) {
                    if (kv.JumpToKey("int", true)) {
                        for (int iAttr = 0; iAttr < view_as<int>(MAX_WEPATTR_INT_TYPE); iAttr++) {
                            int iValue = kv.GetNum(WepIntAttrName[iAttr], -1);
                            if(UseDef)  g_eDefWepAttr[wepType].iWepAttr[iAttr] = iValue;
                            else        g_eWepAttr[wepType].iWepAttr[iAttr] = iValue;
                        }
                        
                        kv.GoBack();
                    }
                    
                    if (kv.JumpToKey("float", true)) {
                        for (int fAttr = 0; fAttr < view_as<int>(MAX_WEPATTR_FLOAT_TYPE); fAttr++) {
                            float fValue = kv.GetFloat(WepFloatAttrName[fAttr], -1.0);
                            if(UseDef)  g_eDefWepAttr[wepType].fWepAttr[fAttr] = fValue;
                            else        g_eWepAttr[wepType].fWepAttr[fAttr] = fValue;
                        }
                        
                        kv.GoBack();
                    }
                    
                    kv.GoBack();
                }
            }
            
            kv.GoBack();
        }
        
        if(kv.JumpToKey("melee", true)) {
            for(int meleeType = 0; meleeType < MAX_MELEE_SCRIPT_TYPE; meleeType++) {
                UseDef ? g_eDefMeleeAttr[meleeType].Reset() : g_eMeleeAttr[meleeType].Reset();
            
                if(kv.JumpToKey(MeleeScriptName[meleeType], true)) {
                    if(kv.JumpToKey("int", true)) {
                        for(int iAttr = 0; iAttr < view_as<int>(MAX_MELEEATTR_INT_TYPE); iAttr++) {
                            int iValue = kv.GetNum(MeleeIntAttrString[iAttr], -1);
                            if(UseDef)  g_eDefMeleeAttr[meleeType].iMeleeAttr[iAttr] = iValue;
                            else        g_eMeleeAttr[meleeType].iMeleeAttr[iAttr] = iValue;
                        }

                        kv.GoBack();
                    }

                    if(kv.JumpToKey("bool", true)) {
                        for(int bAttr = 0; bAttr < view_as<int>(MAX_MELEEATTR_BOOL_TYPE); bAttr++) {
                            bool bValue = view_as<bool>(kv.GetNum(MeleeBoolAttrString[bAttr], 0));
                            if(UseDef)  g_eDefMeleeAttr[meleeType].bMeleeAttr[bAttr] = bValue;
                            else        g_eMeleeAttr[meleeType].bMeleeAttr[bAttr] = bValue;
                        }

                        kv.GoBack();
                    }

                    if(kv.JumpToKey("float", true)) {
                        for(int fAttr = 0; fAttr < view_as<int>(MAX_MELEEATTR_FLOAT_TYPE); fAttr++) {
                            float fValue = kv.GetFloat(MeleeFloatAttrString[fAttr], -1.0);
                            if(UseDef)  g_eDefMeleeAttr[meleeType].fMeleeAttr[fAttr] = fValue;
                            else        g_eMeleeAttr[meleeType].fMeleeAttr[fAttr] = fValue;
                        }

                        kv.GoBack();
                    }

                    kv.GoBack();
                }
            }

            kv.GoBack();
        }
        }
    public static void SetWepAttr(bool UseDef) {
        Address ptr = Address_Null;
        for(int wepType = 1; wepType < MAX_WEP_CLS_TYPE; wepType++) {
            ptr = WeaponAttribute.GetWepPointer(WepClassName[wepType]);

            if(ptr == Address_Null && wepType != 44) {
                LogError("Failed to load weapon \"%s\" pointer", WepClassName[wepType]);
                continue;
            }

            for(int iAttr = 0; iAttr < view_as<int>(MAX_WEPATTR_INT_TYPE); iAttr++)
                WeaponAttribute.SetWepInt(ptr, iAttr, UseDef ? g_eDefWepAttr[wepType].iWepAttr[iAttr] : g_eWepAttr[wepType].iWepAttr[iAttr]);
            
            for(int fAttr = 0; fAttr < view_as<int>(MAX_WEPATTR_FLOAT_TYPE); fAttr++)
                WeaponAttribute.SetWepFloat(ptr, fAttr, UseDef ? g_eDefWepAttr[wepType].fWepAttr[fAttr] : g_eWepAttr[wepType].fWepAttr[fAttr]);
        }
        }
    public static void SetMeleeAttr(bool UseDef) {
        Address ptr = Address_Null;
        char sMap[32];
        GetCurrentMap(sMap, sizeof sMap);

        for(int meleeType = 0; meleeType < MAX_MELEE_SCRIPT_TYPE; meleeType++) {
            ptr = WeaponAttribute.GetMeleePointer(meleeType);

            if(ptr == Address_Null) {
                LogMessage("Melee \"%s\" doesnt exists in currenMap \"%s\"", MeleeScriptName[meleeType], sMap);
                continue;
            }

            for(int iAttr = 0; iAttr < view_as<int>(MAX_MELEEATTR_INT_TYPE); iAttr++)
                WeaponAttribute.SetMeleeInt(ptr, iAttr, UseDef ? g_eDefMeleeAttr[meleeType].iMeleeAttr[iAttr] : g_eMeleeAttr[meleeType].iMeleeAttr[iAttr]);

            for(int bAttr = 0; bAttr < view_as<int>(MAX_MELEEATTR_BOOL_TYPE); bAttr++)
                WeaponAttribute.SetMeleeBool(ptr, bAttr, UseDef ? g_eDefMeleeAttr[meleeType].bMeleeAttr[bAttr] : g_eMeleeAttr[meleeType].bMeleeAttr[bAttr]);
            
            for(int fAttr = 0; fAttr < view_as<int>(MAX_MELEEATTR_FLOAT_TYPE); fAttr++)
                WeaponAttribute.SetMeleeFloat(ptr, fAttr, UseDef ? g_eDefMeleeAttr[meleeType].fMeleeAttr[fAttr] : g_eMeleeAttr[meleeType].fMeleeAttr[fAttr]);
        }
        }
    // public 
    public static void Update() {
        WeaponAttribute.LoadFromConfig(false);
        WeaponAttribute.SetWepAttr(false);
        WeaponAttribute.SetMeleeAttr(false);
        }
    // public forward 
    public static void PluginStart() {
        WeaponAttribute.StartSDKCall();

        #if defined _crimson_wep_attribute_usedfor_plugins
        RegConsoleCmd("sm_attr",        Cmd_SaveConfig);
        RegConsoleCmd("sm_loadattr",    Cmd_LoadConfig);
        #endif

        char filePathDef[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, filePathDef, sizeof filePathDef, FILE_CONFIG_DEF);

        if(!FileExists(filePathDef))
            SetFailState("Can't find config file \"%s\"", filePathDef);

        WeaponAttribute.LoadFromConfig(true);

        char filePath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, filePath, sizeof filePath, FILE_CONFIG);
        
        if(!FileExists(filePath)) {
            File file = OpenFile(filePath, "w");
            if (file == null) {
                LogError("Cannot open file: \"%s\"", filePath);
                return;
            }

            if (!file.WriteLine("")) {
                LogError("Cannot write file line: \"%s\"", filePath);
                delete file;
                return;
            }
            delete file;

            WeaponAttribute.SaveToConfig(true, filePath);

            for(int wepType = 1; wepType < MAX_WEP_CLS_TYPE; wepType++)
                g_eWepAttr[wepType] = g_eDefWepAttr[wepType];

            for(int meleeType = 0; meleeType < MAX_MELEE_SCRIPT_TYPE; meleeType++)
                g_eMeleeAttr[meleeType] = g_eDefMeleeAttr[meleeType];
        }
        else WeaponAttribute.LoadFromConfig(false);
        }
    public static void MapStart() {
        static bool HasSet = false;
        g_bMapStarted = true;

        if(!HasSet) {
            WeaponAttribute.LoadFromConfig(false);
            HasSet = true;
        }
        WeaponAttribute.SetWepAttr(false);
        WeaponAttribute.SetMeleeAttr(false);
        }
    public static void MapEnd() {
        g_bMapStarted = false;
        WeaponAttribute.SetWepAttr(true);
        WeaponAttribute.SetMeleeAttr(true);
        }
    public static void PluginEnd() {
        WeaponAttribute.SetWepAttr(true);
        WeaponAttribute.SetMeleeAttr(true);
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
#if defined _crimson_wep_attribute_usedfor_plugins
public void OnPluginStart() {
	WeaponAttribute.PluginStart();
}

public void OnMapStart() {
	WeaponAttribute.MapStart();
}

public void OnMapEnd() {
	WeaponAttribute.MapEnd();
}

public void OnPluginEnd() {
    WeaponAttribute.PluginEnd();
}

static Action Cmd_SaveConfig(int Client, int args) {
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof filePath, FILE_CONFIG);

    WeaponAttribute.GetDefWepAttr();
    WeaponAttribute.GetDefMeleeAttr();
    WeaponAttribute.SaveToConfig(true, filePath);

    if(Client)  PrintToChat(Client, "\x04[提示] \x03成功将武器属性还原为默认值.");
    else        PrintToServer("[WeaponAttribute] 成功将武器属性还原为默认值.");
    return  Plugin_Handled;
}

static Action Cmd_LoadConfig(int Client, int args) {
    WeaponAttribute.Update();
    if(Client)  PrintToChat(Client, "\x04[提示] \x03已读取并设置武器属性.");
    else        PrintToServer("[WeaponAttribute] 已读取并设置武器属性.");
    return  Plugin_Handled;
}
#endif
/******************************************************
**          			  END
*******************************************************/