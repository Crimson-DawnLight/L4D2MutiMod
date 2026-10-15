#if defined _crimson_block_msgs_included_
 #endinput
#endif
#define _crimson_block_msgs_included_

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define _crimson_block_msgs_usedfor_plugins
/******************************************************
**          	        const
*******************************************************/
#if defined _crimson_block_msgs_usedfor_plugins
public Plugin myinfo = {
    name = "L4D2 Block Messages",
    author = "crimson",
    description = "block the game's own notices",
    version = "1.0.0",
    url = ""
};
#endif
enum {
    BLOCK_TextMsg,
    BLOCK_PZDmgMsg,
    BLOCK_server_cvar,
    BLOCK_player_death,
    BLOCK_player_incapacitated,
    BLOCK_defibrillator_used,
    BLOCK_player_disconnect,

    MAX_BLOCK_TYPE
}
/******************************************************
**          	        variable
*******************************************************/
enum struct BlockMsgsData {
    bool block_TextMsg;
    bool block_PZDmgMsg;
    bool block_server_cvar;
    bool block_player_death;
    bool block_player_incapacitated;
    bool block_defibrillator_used;
    bool block_player_disconnect;

    void Reset() {
        static const BlockMsgsData def = { false, false, false, false, false, false, false };
        this = def;
    }
}
static BlockMsgsData g_eBlock;
/******************************************************
**          			main
*******************************************************/
/**
 * @brief	提供阻断游戏提示的封装
 * @note	public 	注释后的函数, 可供外部调用
 * @note    forward 注释后的函数, 需要在对应命名 forward 转发调用
 * @note	private 注释后的函数, 请不要外部调用

 * @note	外部通过调用 property 来访问静态数据
 */
methodmap BlockMessage {
    // public 
    public static void Update(int flags) {
            g_eBlock.block_TextMsg              = view_as<bool>(flags & (1 << BLOCK_TextMsg) );
            g_eBlock.block_PZDmgMsg             = view_as<bool>(flags & (1 << BLOCK_PZDmgMsg) );
            g_eBlock.block_server_cvar          = view_as<bool>(flags & (1 << BLOCK_server_cvar) );
            g_eBlock.block_player_death         = view_as<bool>(flags & (1 << BLOCK_player_death) );
            g_eBlock.block_player_incapacitated = view_as<bool>(flags & (1 << BLOCK_player_incapacitated) );
            g_eBlock.block_defibrillator_used   = view_as<bool>(flags & (1 << BLOCK_defibrillator_used) );
            g_eBlock.block_player_disconnect    = view_as<bool>(flags & (1 << BLOCK_player_disconnect) );
        }
    // public forward 
    public static void PluginStart() {
        HookUserMessage(GetUserMessageId("TextMsg"), UM_TextMsg, true);      // 屏蔽游戏自带的闲置提示
        HookUserMessage(GetUserMessageId("PZDmgMsg"), UM_PZDmgMsg, true);    // 屏蔽游戏自带的其它提示
        HookEvent("server_cvar",            Event_server_cvar,          EventHookMode_Pre);         // 屏蔽游戏自带的ConVar更改提示.

        #if defined _crimson_block_msgs_usedfor_plugins
            HookEvent("player_death",           Event_player_death,         EventHookMode_Pre);         // 屏蔽游戏自带的玩家死亡提示(好像会导致游戏自带的结算界面统计出问题).
            HookEvent("player_incapacitated",   Event_player_incapacitated, EventHookMode_Pre);         // 屏蔽游戏自带的玩家倒下提示.
            HookEvent("defibrillator_used",     Event_defibrillator_used,   EventHookMode_Pre);         // 屏蔽游戏自带的使用电击器提示.
            HookEvent("player_disconnect",      Event_player_disconnect,    EventHookMode_Pre);         // 屏蔽游戏自带的玩家离开提示.
        #endif

        g_eBlock.Reset();
        }
    // public EventHook 
    public static Action server_cvar() {
        return g_eBlock.block_server_cvar ? Plugin_Continue : Plugin_Handled;
        }
    public static void player_death(Event event) {
        if(g_eBlock.block_player_death)
            event.BroadcastDisabled = true;
        }
    public static void player_incapacitated(Event event)  {
        if(g_eBlock.block_player_incapacitated)
            event.BroadcastDisabled = true;
        }
    
    public static void defibrillator_used(Event event) {
        if(g_eBlock.block_defibrillator_used)
            event.BroadcastDisabled = true;
        }
    public static void player_disconnect(Event event) {
        if(g_eBlock.block_player_disconnect)
            event.BroadcastDisabled = true;
        }
    // public UserMessage
    public static Action PZDmgMsg() {
        return g_eBlock.block_PZDmgMsg ? Plugin_Handled : Plugin_Continue;
        }
    public static Action TextMsg(BfRead msg) {
        if(!g_eBlock.block_TextMsg) return Plugin_Continue;
        
        static char sMsg[254];
        msg.ReadString(sMsg, sizeof sMsg);

        // 聊天栏提示：XXX 现已闲置.
        return strcmp(sMsg, "\x03#L4D_idle_spectator") == 0 ? Plugin_Handled : Plugin_Continue;
        }
    // public 
}
/******************************************************
**          		Variable Hook
*******************************************************/
public Action UM_PZDmgMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
	return BlockMessage.PZDmgMsg();
}

public Action UM_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)  {
	return BlockMessage.TextMsg(msg);
}

public Action Event_server_cvar(Event event, const char[] name, bool dontBroadcast) {
	return BlockMessage.server_cvar();
}
/******************************************************
**					used for plugins
*******************************************************/
#if defined _crimson_block_msgs_usedfor_plugins
static ConVar g_cvBlockFlags;

static void OnBlockFlagsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	BlockMessage.Update(convar.IntValue);
}

public void OnPluginStart() {
	BlockMessage.PluginStart();

	// 阻断位掩码: 1 << BLOCK_*; 默认 127 = 全部阻断.
	// 必须在 PluginStart 之后 Update —— 它末尾的 Reset 会把所有位清成 false.
	g_cvBlockFlags = CreateConVar("l4d_block_msgs_flags", "127", "屏蔽哪些游戏提示 (位掩码, 1<<BLOCK_*)", FCVAR_NOTIFY, true, 0.0, true, 127.0);
	g_cvBlockFlags.AddChangeHook(OnBlockFlagsChanged);
	BlockMessage.Update(g_cvBlockFlags.IntValue);

	RegConsoleCmd("sm_blockmsg", Cmd_BlockMsg);
}

public Action Cmd_BlockMsg(int client, int args) {
	if (args < 1) {
		if (client > 0) PrintToChat(client, "\x04[Usage] \x03!blockmsg <flag>  当前值 = %d", g_cvBlockFlags.IntValue);
		else            PrintToServer("[block_msgs] sm_blockmsg <flag>, 当前值 = %d", g_cvBlockFlags.IntValue);
		return Plugin_Handled;
	}

	int flags = GetCmdArgInt(1);
	if (flags < 0 || flags >= (1 << MAX_BLOCK_TYPE)) {
		if (client > 0) PrintToChat(client, "\x04[Error] \x03flag 范围 0 - %d", (1 << MAX_BLOCK_TYPE) - 1);
		else            PrintToServer("[block_msgs] flag 范围 0 - %d", (1 << MAX_BLOCK_TYPE) - 1);
		return Plugin_Handled;
	}

	g_cvBlockFlags.IntValue = flags;        // 走 convar, 由变更钩子统一 Update

	return Plugin_Handled;
}

public void Event_player_death(Event event, const char[] name, bool dontBroadcast)  {
	BlockMessage.player_death(event);
}

public void Event_player_incapacitated(Event event, const char[] name, bool dontBroadcast) {
	BlockMessage.player_incapacitated(event);
}

public void Event_player_disconnect(Event event, const char[] name, bool dontBroadcast)  {
	BlockMessage.player_disconnect(event);
}

public void Event_defibrillator_used(Event event, const char[] name, bool dontBroadcast)  {
	BlockMessage.defibrillator_used(event);
}
#endif
/******************************************************
**          			  END
*******************************************************/