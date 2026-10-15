#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sendproxy>

// 幸存者血条 —— 从老版 SendProxy Manager 插件移植。
//
// 老版: SendProxy_HookEntity(client, "m_hActiveWeapon", Prop_EHandle, cb) 挂回调, 回调里改 &value。
// 本版: 没有钩子 —— 每帧在 OnSendProxyPre() 里, 对"每个观察者"按 offset 排队它该看到的覆写。
//       于是老版那套 Hook/Unhook/IsHookedEntity 与 player_team/spawn/death/incap 事件同步
//       (只为管理挂钩生命周期) 整块不需要了; 剩下的是"这一帧谁该看到什么"。
//
// 三个覆写点 (都以"观察者客户端"为第一参数排队):
//   ① 观察者自己的 m_hActiveWeapon → 某医疗品  ⇒ 客户端 HUD 以为自己拿着药, 画出队友血条
//   ② 观察者自己的 m_lifeState     → 0(LIFE_ALIVE) ⇒ 死亡/观察者也能画出 HUD 元素
//   ③ 每个被击倒队友的 m_isIncapacitated → 0   ⇒ 观察者看到该队友的血条
//
// ⚠ 代价 (实测): ① 会把客户端预测带偏 —— 开枪**没有枪声**、视角/枪口**抖动剧烈**。
//   枪声与视角后坐都是客户端按"我手里那把枪"自己算、自己放的; 让它以为拿的是药,
//   它就不放枪声、后坐也对不上。这不是本版移植引入的: 老版同一套谎, 一样会这样;
//   而且服务端没有别的做法 —— 服务端画不了 HUD (只有 usermessage)。
//   缓解(未验证): 只在不开火的帧撒 ① —— 排队前判 GetClientButtons(client) & IN_ATTACK,
//   开火时跳过; 代价是扣扳机时血条闪一下。② ③ 不碰预测, 不受影响。

#define TEAM_SURVIVOR       2
#define LIFE_ALIVE          0

// 医疗品 (与老版同一张判据表)
static const char g_sHealingNetClasses[][] = {
    "CFirstAidKit",
    "CPainPills",
    "CItem_Adrenaline"
};
static const char g_sHealingClasses[][] = {
    "weapon_first_aid_kit",
    "weapon_pain_pills",
    "weapon_adrenaline"
};

ConVar g_cvEnable;
ConVar g_cvKey;
ConVar g_cvFov;
ConVar g_cvAllowDead;
ConVar g_cvAllowIncap;
ConVar g_cvMaxDistance;

// ConVar 快照 —— SendProxy 排队每帧都跑, 不在这里调 GetConVar
bool  g_bCvarEnable;
bool  g_bCvarAllowDead;
bool  g_bCvarAllowIncap;
int   g_iCvarKey;
float g_fCvarFov;
float g_fCvarMaxDistance;

bool g_bHpToggleEnabled[MAXPLAYERS + 1];
bool g_bHpHoldPressed[MAXPLAYERS + 1];

// 每图解析一次; -1 未解析, <0 解析失败
int g_iOffActiveWeapon = -1;
int g_iOffLifeState = -1;
int g_iOffIncap = -1;

int g_iDummyHealing = -1;      // 地图上没有医疗品时用的替身 (藏在地图下)
int g_iFoundHealing = -1;      // 地图上找到的医疗品, 失效了才重扫

public Plugin myinfo = {
    name        = "[L4D2] Survivors Healthbar",
    author      = "xZk/Assistant/Crimson",
    description = "Displays the survivors' native HUD health bar (example; breaks client prediction -- see header)",
    version     = "2.0",
    url         = ""
};

public void OnPluginStart()
{
    g_cvEnable      = CreateConVar("l4d2_survivors_healthbar_enable", "1", "1 = 启用, 0 = 停用", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvKey         = CreateConVar("l4d2_survivors_healthbar_key", "16", "按键位号 (1 << 位), -1 = 不需要按键; 见 IN_SCORE(tab)=16", FCVAR_NONE);
    g_cvFov         = CreateConVar("l4d2_survivors_healthbar_fov", "90.0", "视野角(度): 至少有队友落在这个锥内才显示", FCVAR_NONE, true, 1.0, true, 360.0);
    g_cvAllowDead   = CreateConVar("l4d2_survivors_healthbar_dead", "1", "死亡/观察者也能看 (改 m_lifeState)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvAllowIncap  = CreateConVar("l4d2_survivors_healthbar_incap", "1", "看到被击倒队友的血条 (改 m_isIncapacitated)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvMaxDistance = CreateConVar("l4d2_survivors_healthbar_distance", "1000.0", "最大距离, 0 = 不限", FCVAR_NONE, true, 0.0, true, 1000.0);
    AutoExecConfig(true, "l4d2_survivors_healthbar");

    g_cvEnable.AddChangeHook(OnConVarChanged);
    g_cvKey.AddChangeHook(OnConVarChanged);
    g_cvFov.AddChangeHook(OnConVarChanged);
    g_cvAllowDead.AddChangeHook(OnConVarChanged);
    g_cvAllowIncap.AddChangeHook(OnConVarChanged);
    g_cvMaxDistance.AddChangeHook(OnConVarChanged);
    CacheConVars();

    RegConsoleCmd("sm_hp_toggle", Cmd_HpToggle, "开/关血条");
    RegConsoleCmd("sm_togglehp", Cmd_HpToggle, "开/关血条");
    RegConsoleCmd("+hp_view", Cmd_HpViewOn, "按住显示血条");
    RegConsoleCmd("-hp_view", Cmd_HpViewOff, "松开隐藏血条");
}

public void OnMapStart()
{
    // 偏移按类布局解析, 换图重来一遍; 实体类换图重建
    g_iOffActiveWeapon = -1;
    g_iOffLifeState = -1;
    g_iOffIncap = -1;

    g_iDummyHealing = -1;
    g_iFoundHealing = -1;
}

public void OnClientDisconnect(int client)
{
    g_bHpToggleEnabled[client] = false;
    g_bHpHoldPressed[client] = false;
}

void CacheConVars()
{
    g_bCvarEnable      = g_cvEnable.BoolValue;
    g_iCvarKey         = g_cvKey.IntValue;
    g_fCvarFov         = g_cvFov.FloatValue;
    g_bCvarAllowDead   = g_cvAllowDead.BoolValue;
    g_bCvarAllowIncap  = g_cvAllowIncap.BoolValue;
    g_fCvarMaxDistance = g_cvMaxDistance.FloatValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    CacheConVars();
}

/**
 * 每帧一次: 只往"观察者"那一侧排队 —— 覆写是按客户端打包时套用的, 天然 per-client。
 */
public void OnSendProxyPre()
{
    if (!g_bCvarEnable)
        return;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR)
            continue;
        if (!IsActivationConditionMet(client))
            continue;
        if (!EnsureOffsets(client))
            return;

        int playerRef = EntIndexToEntRef(client);
        bool alive = IsPlayerAlive(client);

        // 老版对"死人且不许看"的观察者整条放行 (连带 ③ 也不排)
        if (!alive && !g_bCvarAllowDead)
            continue;

        // ① 活人: 没拿着医疗品就把"手上的武器"对本人伪装成医疗品, 客户端才会画血条。
        //    老版有个视野闸门 —— 视野里没队友就不伪装 (② ③ 不看视野, 与老版一致)。
        if (alive)
        {
            if (IsAnyPlayerInFOV(client, g_fCvarFov))
            {
                int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
                if (!IsCarryingHealingItem(active))
                {
                    int item = GetHealingItemFor(client);
                    if (item != -1)
                        SendProxy.AddChangeEHandle(client, playerRef, g_iOffActiveWeapon, EHandle(EntIndexToEntRef(item)));
                }
            }
        }
        // ② 死人/观察者: 只有把本人的 lifeState 说成活着, 客户端才画 HUD
        else if (g_bCvarAllowDead)
        {
            SendProxy.AddChangeCell(client, playerRef, g_iOffLifeState, LIFE_ALIVE);
        }

        // ③ 被击倒的队友: 让这个观察者看到他们的血条
        if (g_bCvarAllowIncap)
        {
            for (int target = 1; target <= MaxClients; target++)
            {
                if (target == client || !IsClientInGame(target) || GetClientTeam(target) != TEAM_SURVIVOR)
                    continue;
                if (GetEntProp(target, Prop_Send, "m_isIncapacitated") == 0)
                    continue;
                if (!WithinMaxDistance(client, target))
                    continue;

                SendProxy.AddChangeCell(client, EntIndexToEntRef(target), g_iOffIncap, 0);
            }
        }
    }
}

bool EnsureOffsets(int client)
{
    if (g_iOffActiveWeapon > 0 && g_iOffLifeState > 0 && g_iOffIncap > 0)
        return true;

    g_iOffActiveWeapon = GetEntSendPropOffs(client, "m_hActiveWeapon");
    g_iOffLifeState    = GetEntSendPropOffs(client, "m_lifeState");
    g_iOffIncap        = GetEntSendPropOffs(client, "m_isIncapacitated");

    if (g_iOffActiveWeapon < 0 || g_iOffLifeState < 0 || g_iOffIncap < 0)
    {
        LogError("SendProxy 偏移解析失败 (activeWeapon=%d lifeState=%d incap=%d)",
                 g_iOffActiveWeapon, g_iOffLifeState, g_iOffIncap);
        return false;
    }
    return true;
}

bool WithinMaxDistance(int client, int target)
{
    if (g_fCvarMaxDistance <= 0.0)
        return true;

    float clientPos[3], targetPos[3];
    GetClientAbsOrigin(client, clientPos);
    GetClientAbsOrigin(target, targetPos);
    return GetVectorDistance(clientPos, targetPos) <= g_fCvarMaxDistance;
}

// 开关 / 按住 / 按键位, 三选一
bool IsActivationConditionMet(int client)
{
    if (g_bHpToggleEnabled[client] || g_bHpHoldPressed[client])
        return true;

    if (g_iCvarKey > -1 && (GetClientButtons(client) & (1 << g_iCvarKey)))
        return true;

    return false;
}

// 视野锥内至少有一名活着的队友
bool IsAnyPlayerInFOV(int client, float fovDegrees)
{
    float eyePos[3], eyeAngles[3], forwardVec[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAngles);
    GetAngleVectors(eyeAngles, forwardVec, NULL_VECTOR, NULL_VECTOR);

    float maxCos = Cosine(DegToRad(fovDegrees * 0.5));
    float targetPos[3], targetDir[3];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (i == client || !IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i))
            continue;
        if (!WithinMaxDistance(client, i))
            continue;

        GetClientAbsOrigin(i, targetPos);
        targetPos[2] += 40.0;    // 瞄准上半身, 与老版一致

        SubtractVectors(targetPos, eyePos, targetDir);
        NormalizeVector(targetDir, targetDir);

        if (GetVectorDotProduct(forwardVec, targetDir) >= maxCos)
            return true;
    }

    return false;
}

bool IsCarryingHealingItem(int weapon)
{
    if (weapon <= 0 || !IsValidEntity(weapon))
        return false;

    char netclass[32];
    if (!GetEntityNetClass(weapon, netclass, sizeof(netclass)))
        return false;

    for (int i = 0; i < sizeof(g_sHealingNetClasses); i++)
    {
        if (strcmp(netclass, g_sHealingNetClasses[i]) == 0)
            return true;
    }
    return false;
}

/**
 * 找一个能当"血条钥匙"的医疗品: 自己的背包 → 地图上的 → 藏起来的替身。
 */
int GetHealingItemFor(int client)
{
    int slot3 = GetPlayerWeaponSlot(client, 3);     // 3 = 医疗包
    if (slot3 != -1 && IsValidEntity(slot3))
    {
        char netclass[32];
        if (GetEntityNetClass(slot3, netclass, sizeof(netclass)) && strcmp(netclass, "CFirstAidKit") == 0)
            return slot3;
    }

    int slot4 = GetPlayerWeaponSlot(client, 4);     // 4 = 药丸 / 肾上腺素
    if (slot4 != -1 && IsValidEntity(slot4))
        return slot4;

    return GetAnyHealingItem();
}

/**
 * 地图上找一个医疗品, 没有就造替身。
 * 找到的地图实体缓存住 (失效才重扫) —— 每帧扫三遍类名表太贵。
 */
int GetAnyHealingItem()
{
    int cached = EntRefToEntIndex(g_iFoundHealing);
    if (cached != INVALID_ENT_REFERENCE && IsValidEntity(cached))
        return cached;

    for (int i = 0; i < sizeof(g_sHealingClasses); i++)
    {
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, g_sHealingClasses[i])) != -1)
        {
            if (IsValidEntity(entity))
            {
                g_iFoundHealing = EntIndexToEntRef(entity);
                return entity;
            }
        }
    }

    return GetOrCreateDummyHealingItem();
}

int GetOrCreateDummyHealingItem()
{
    int dummy = EntRefToEntIndex(g_iDummyHealing);
    if (dummy != INVALID_ENT_REFERENCE && IsValidEntity(dummy))
        return dummy;

    dummy = CreateEntityByName("weapon_pain_pills");
    if (dummy == -1)
        return -1;

    DispatchKeyValue(dummy, "origin", "0 0 -10000");
    DispatchKeyValue(dummy, "rendermode", "10");
    DispatchSpawn(dummy);
    SetEntityMoveType(dummy, MOVETYPE_NONE);

    g_iDummyHealing = EntIndexToEntRef(dummy);
    return dummy;
}

public Action Cmd_HpToggle(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
    {
        g_bHpToggleEnabled[client] = !g_bHpToggleEnabled[client];
        PrintToChat(client, "\x04[HP]\x01 血条 %s", g_bHpToggleEnabled[client] ? "\x03开启" : "\x02关闭");
    }
    return Plugin_Handled;
}

public Action Cmd_HpViewOn(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
        g_bHpHoldPressed[client] = true;
    return Plugin_Handled;
}

public Action Cmd_HpViewOff(int client, int args)
{
    if (client > 0 && IsClientInGame(client))
        g_bHpHoldPressed[client] = false;
    return Plugin_Handled;
}
