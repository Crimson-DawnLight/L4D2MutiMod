#if defined _crimson_dmg_number_api_included_
 #endinput
#endif
#define _crimson_dmg_number_api_included_

#pragma semicolon 1
#pragma newdecls required

/**
 * @brief	L4D2 伤害数字 —— 跨插件调用用的 native 声明
 * @note	实现与 native 注册在 l4d2_dmg_number.inc 的插件段里; 两种用法二选一, 别同时用:
 *			· #include <userbase/l4d2_dmg_number>  → 直接调方法 (实现就在你插件里)
 *			· #include <[API]l4d2_dmg_number>     → 调 native (对方插件已加载, 跨插件边界)
 */
methodmap DmgNum_t {
	/**
	 * 判断是否执行伤害展示 (推荐应用于 SDKHook_OnTakeDamageAlive calback)
	 *
	 * @param victim            被攻击者
	 * @param attacker          攻击者
	 * @param dmg               伤害值
	 * @param weapon            攻击者武器
	 * @return					=true 展示这次伤害, =false 过滤这次伤害展示
	 */
	public static native bool ShouldDisplay(int victim, int attacker, int dmg, int weapon);

	/**
	 * 执行伤害展示
	 *
	 * @param victim            被攻击者
	 * @param attacker          攻击者
	 * @param dmg               伤害值
	 * @param high              数字的高
	 * @param width             数字的宽
	 * @param color             数字的颜色
	 * @return					=true 插件正常工作
	 */
	public static native bool DisplayToClient(int victim, int attacker, int dmg, float high = 24.0, float width = 7.0, const int color[4]);

	/**
	 * 配置伤害展示
	 *
	 * @param mode              = 0 使用默认配置, 展示全部伤害 ,非零时, 需要自行在 SDKHook_OnTakeDamageAlive 里配置 L4D2_DamageNumber_ToShow()
								= 1 自定义配置, 仅在特感受到伤害生成数字特效
								= 2 自定义配置, 仅在玩家受到伤害生成数字特效
								= 3 自定义配置, 全部类型都会生成数字特效
	 * @return					= true 插件正常工作
	 */
	public static native bool SetMode(int mode);
}
