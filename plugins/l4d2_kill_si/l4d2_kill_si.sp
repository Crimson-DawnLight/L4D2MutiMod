#if defined _crimson_kill_si_included_
 #endinput
#endif
#define _crimson_kill_si_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <[API]l4d2_base>

#define _crimson_kill_si_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_kill_si_usedfor_plugins
public Plugin myinfo = {
    name = "Kill SI - CrmMod",
    author = "crimson",
    description = "击杀特感回血",
    version = "1.0.0",
    url = ""
};
#endif
#define CVAR_FLAGS FCVAR_NOTIFY
/******************************************************
**          	        variable
*******************************************************/
static ConVar g_cvHealth;
static ConVar g_cvCycle;

static int g_iHealth = 5;
static int g_iCycle = 1;

static int PlayerKillSINum[MAXPLAYERS+1];
/******************************************************
**          			main
*******************************************************/
methodmap KillSI {
    public KillSI(int Client) {
        return view_as<KillSI>(Client);
        }
    property int index {
        public get() { return view_as<int>(this); }
        }
    property int killNum {
        public get()			{ return PlayerKillSINum[this.index]; }
        public set(int value)	{ PlayerKillSINum[this.index] = value; }
        }
    // private 特感/女巫 -> zombieClass, 其余 0
    public static int GetSIZombieClass(int infected) {
        PlayerState player = PlayerState(infected);

        if(PlayerState.IsValid(infected)) {
            if(GetClientTeam(infected) == 3)
                return player.ZC;
        }
        else if(infected > MaxClients && IsValidEntity(infected) && player.IsWitch)
            return player.ZC;

        return 0;
        }
    // public forward
    public static void PluginStart() {
        g_cvHealth = CreateConVar("l4d2_kill_si_health", "5", "击杀特感回复的血量.", CVAR_FLAGS, true, 0.0);
        g_cvCycle  = CreateConVar("l4d2_kill_si_cycle", "1", "击杀特感的循环次数(累计击杀N个特感回复一次血量).", CVAR_FLAGS, true, 1.0);

        g_cvHealth.AddChangeHook(OnCvarChanged);
        g_cvCycle.AddChangeHook(OnCvarChanged);
        RefreshCvar();

        HookEvent("player_death", Event_player_death);
        HookEvent("round_start", Event_round_start);
        }
    public static void MapStart() {
        for(int i = 0; i <= MaxClients; i++)
            PlayerKillSINum[i] = 0;
        }
    public static void RoundStart() {
        for(int i = 0; i <= MaxClients; i++)
            PlayerKillSINum[i] = 0;
        }
    public static void PutInServer(int Client) {
        if(!PlayerState.IsValid(Client))	return;

        PlayerKillSINum[Client] = 0;
        }
    public static void player_death(int attacker, int victim) {
        int victim_ZC = KillSI.GetSIZombieClass(victim);

        if(victim_ZC == 0)	return;

        PlayerState player = PlayerState(attacker);

        if(!player.Valid)	return;

        int reward = 0;

        if(victim_ZC >= ZC_SMOKER && victim_ZC <= ZC_CHARGER) {
            KillSI killer = KillSI(attacker);
            killer.killNum++;

            if(killer.killNum >= g_iCycle) {
                killer.killNum = 0;
                reward = g_iHealth;
            }
        }
        else if(victim_ZC == ZC_WITCH)
            reward = 60;
        else if(victim_ZC == ZC_TANK)
            reward = 70;

        if(reward <= 0)	return;

        if(!player.IsHang && !player.Incap)
            player.HP += reward;
        }
}
/******************************************************
**          			CallBack
*******************************************************/
static void Event_round_start(Event event, const char[] event_name, bool dontBroadcast) {
    KillSI.RoundStart();
}

static void Event_player_death(Event event, const char[] event_name, bool dontBroadcast) {
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    KillSI.player_death(attacker, victim);
}

static void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    RefreshCvar();
}

static void RefreshCvar() {
    g_iHealth = g_cvHealth.IntValue;
    g_iCycle = g_cvCycle.IntValue;

    if(g_iCycle < 1)	g_iCycle = 1;
}
/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_kill_si_usedfor_plugins
public void OnPluginStart() {
    KillSI.PluginStart();

    AutoExecConfig(true, "l4d2_kill_si");
}

public void OnMapStart() {
    KillSI.MapStart();
}

public void OnClientPutInServer(int Client) {
    KillSI.PutInServer(Client);
}
#endif
/******************************************************
**          			  END
*******************************************************/
