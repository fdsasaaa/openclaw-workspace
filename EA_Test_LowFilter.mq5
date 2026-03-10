//+------------------------------------------------------------------+
//| EA_NengLiang_MT5_HighFreq.mq5                                    |
//| MT5版本 - 能量块箱体突破交易系统 (高频同步版)                         |
//| 已优化：移除性能节流，实现与MT4完全一致的Tick级响应逻辑                 |
//+------------------------------------------------------------------+
#property copyright "Converted to MT5 (High Frequency Sync)"
#property version   "1.01"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//------------------------ 授权配置 -----------------------------
// 授权账号列表（多个账号用逗号分隔）
string g_AuthorizedAccounts = "7334683,3442455,11132566,993484";
// 授权截止时间（格式：YYYY-MM-DD HH:MM:SS）
string g_AuthExpiryTime = "2025-12-27 09:54:10";

//------------------------ 枚举定义 -----------------------------
enum 手数计算模式
{
    模式_固定手数      = 0, // 固定手数
    模式_以损定量      = 1  // 以损定量
};
enum 交易方向
{
    多空都做 = 0,      // ①多空都做
    只做多单 = 1,      // ②只做多单
    只做空单 = 2       // ③只做空单
};
enum 移动止损模式
{
    模式_固定点数         = 0,
    模式_ATR              = 1,
    模式_K线区间          = 2,
    模式_成交量           = 3,
    模式_分时段           = 4,
    模式_多因子           = 5,
    模式_箱体高度         = 6,
    模式_三合一合并       = 7,
    模式_箱体内K线平均比  = 8
};
//------------------------ 输入参数 -----------------------------
input 手数计算模式  交易手数模式          = 模式_以损定量;
input int         魔术号                = 9999999;
input double      以损定量百分比        = 1.0;
input double      初始手                = 0.1;
input bool        启用马丁              = true;
input double      马丁倍数              = 1.4;
input int         马丁最大次数          = 1;  // 🔥 修改：从2改为1（与TV策略一致）
input double      反向手数因子          = 0.0;
// 保留参数（未使用）
bool        是否启动统计显示      = false;
int         最近交易笔数          = 10;
int         文本大小              = 7;
int         行间距                = 14;
color       文本颜色              = clrBlack;
color       分隔线颜色            = clrBlack;
color       背景颜色              = clrBlack;
string      EA_Comment            = "NengLiangKuai";
input 交易方向    做单方向              = 多空都做;

// ---【背景时段可视化系统 - MT4核心功能移植】---
input string   NOTE_BACKGROUND = "====== 背景和辅助视觉 ======";
input bool     Bg_ShowBackground = true;              // 显示背景时段
input int      Bg_AlertMinutes = 5;                   // 提前N分钟提醒（0=关闭）
input string   Bg_ManualStart = "";                   // 手动指定开始时间（格式:HH:MM）
input string   Bg_ManualEnd = "";                     // 手动指定结束时间（格式:HH:MM）
input int      Bg_DrawFutureDays = 3;                 // 绘制未来天数（0=不绘制）
input double   Bg_GlobalHourShift = 0.0;              // 全局时间偏移（小时）
input double   Bg_UtcOffsetBroker = 2.0;              // 经纪商UTC偏移
input double   Bg_UtcOffsetSession = 3.0;             // 交易所UTC偏移
input int      Bg_BackgroundAlpha = 5;                // 透明度（1-10级）
input color    Bg_PreSessionColor = clrDarkSlateGray; // 预备期颜色
input color    Bg_ActiveSessionColor = clrDarkGreen;  // 活跃期颜色
input color    Bg_CoolDownColor = clrMaroon;          // 冷却期颜色
input color    Bg_LineColor = clrDodgerBlue;          // 分界线颜色
input bool     Bg_ShowVerticalLine = true;             // 显示垂直分界线

// ---【核心优化：实盘环境模拟与过滤参数】---
input string   NOTE_OPTIMIZATION     = "====== 实盘环境模拟与过滤 ======";
input bool     启用点差保护          = true;
input int      点差限制              = 10;      // 【新增】首单点差限制 (微点Points, 0=不限制)
input double   最大点差占比          = 0.15;   // [风控] 点差/箱体高度的最大比率(0.15=15%)
input int      模拟滑点微点数        = 50;     // [回测专用] 强制滑点微点数 (US30建议50-80)
input int      最小箱体波动微点      = 150;    // [风控] 最小箱体高度 (过滤死鱼行情)

// ---【AI优化：箱体质量评分系统参数】---
input string   NOTE_SCORING          = "====== AI优化：箱体质量评分系统 ======";
input bool     启用质量评分过滤      = true;
input double   质量评分阈值          = 25.0;   // 🔥 修改：从20改为35（与TV策略一致）
input int      ATR周期               = 14;     // ATR周期 (TradingView默认14)
input double   ATR止损倍数           = 1.7;    // 🔥 修改：从2.0改为1.7（与TV策略一致）
input int      最大箱体年龄K线数     = 30;     // 最大箱体年龄 (TradingView默认30)
input double   ATR波动率上限占比     = 2.0;    // ATR不超过价格的百分之几 (TradingView默认2%)

// ---【AI优化：强制冷却机制参数】---
input string   NOTE_COOLDOWN         = "====== AI优化：强制冷却机制 ======";
input bool     启用强制冷却         = true;
input int      冷却K线数            = 6;      // 马丁爆仓后强制休息K线数 (TradingView默认6)

// ---【AI优化：智能过滤参数】---
input string   NOTE_SMART_FILTER     = "====== AI优化：智能过滤 ======";
input bool     启用智能过滤          = false;
input double   最小成交量倍数       = 1.3;    // 🔥 修改：从0.8改为1.3（与TV策略一致）

// ---【新增：箱体高度过滤参数】---
input string   NOTE_BOX_HEIGHT_FILTER = "====== 新增：箱体高度过滤 ======";
input bool     启用箱体高度过滤    = false;   // 启用箱体高度过滤
input double   箱体高度倍数限制     = 3.0;    // 箱体高度不超过平均K线高度的N倍
input int      高度过滤回溯K线数    = 10;     // 计算平均K线高度时回溯的K线数

// 交易时间窗口
input string TradeTime1_Start = "00:00";
input string TradeTime1_End   = "00:00";
input string TradeTime2_Start = "00:00";
input string TradeTime2_End   = "00:00";
input string TradeTime3_Start = "00:00";
input string TradeTime3_End   = "00:00";
input string TradeTime4_Start = "00:00";
input string TradeTime4_End   = "00:00";
input string TradeTime5_Start = "00:00";
input string TradeTime5_End   = "00:00";

// 止盈止损参数
double J单止盈倍数 = 22.0;
// J单止盈倍数（箱体高度的N倍）

// 量能过滤参数
bool        启用量能过滤          = false;
int         量能统计Bar数         = 20;
double      量能放大倍数          = 1.2;
//【新增】箱体突破失效倍数：当突破距离超过箱体高度的N倍时，箱体作废
double       箱体突破失效倍数    = 0.3;
// 突破距离超过箱体高度的此倍数后箱体作废（0=禁用检测）
int          箱体突破检测K线数  = 30;
// 检测箱体是否被突破时，检查箱体右边界后的K线数（0=检查到当前）

//【新增】诊断日志开关
bool        启用诊断日志          = true;
// 隐藏参数
// 移动止损参数
bool        是否启动移动止损      = true;
移动止损模式    移动止损方式    = 模式_箱体高度;
int         移动止损触发点数      = 130;
// 移动止损触发点数（固定点数模式使用）
int         移动止损步长          = 65;
// 移动止损步长（固定点数模式使用）
double      箱体高度触发倍数      = 0.85;  // 🔥 修改：从0.65改为0.85（与TV策略一致）
// (原g_BoxHeightTriggerMultiplier) 箱体高度触发倍数
double      箱体高度步长倍数      = 0.32;
double      箱体高度回撤倍数      = 0.45;  // 🔥 修改：从0.32改为0.45（与TV策略一致）
// (原g_BoxHeightStepMultiplier) 箱体高度步长倍数
int       箱体过滤等级          = 0;
double    浮盈倍数              = 51.5;
// 保留参数（未使用）
bool      启用G单模式           = false;
// 保留参数（未使用）
double    重挂J单倍数因子       = 0.0;
// 重挂J单倍数因子（保留）
int       面板固定高度          = 0;
// 面板固定高度(像素,0为自动)
int       面板顶部留空          = 15;
// 面板顶部内容留空距离 (像素)
double    g_BoxKLineAvgHeightMultiplier = 0.1; // 【隐藏参数】箱体内K线平均高度乘以（默认数值0.1）

string        指标名称              = "nengliang";
// Default from MQL4
string  指标前缀              = "Rectangle";
// 箱体名称前缀 (多个前缀用逗号分隔，如 "Rectangle,daiyong")
int           Darvas模式            = 3;
// 指标参数（保留，与MT4一致）
int           枢轴强度              = 3;
// 指标参数（保留，与MT4一致）
int           滚动周期              = 1;
// 指标参数（保留，与MT4一致）
int           g_BoxMinBars        = 10;
double        g_NoBreakMaxScore   = 10.0;
double        g_RatioMaxScore     = 60.0;
double        g_MinScore          = 80.0;
double        g_RatioRefValue     = 20000.0;
double        g_HeightRefValue    = 0.05;
double        g_HeightMaxScore    = 30.0;

// 【AI优化】评分系统全局变量
double g_boxScoreFlatness      = 0.0;  // 平坦度评分
double g_boxScoreIndependence  = 0.0;  // 独立性评分
double g_boxScoreSmoothness    = 0.0;  // 平滑度评分
double g_boxScoreSpace         = 0.0;  // 空间评分
double g_boxScoreVolume        = 0.0;  // 成交量评分
double g_boxScoreTime          = 0.0;  // 时间评分
double g_boxScoreMicro         = 0.0;  // 微观评分
double g_boxTotalScore         = 0.0;  // 总评分
int    g_boxBars               = 0;    // 箱体K线数
double g_boxHeight             = 0.0;  // 箱体高度
double g_boxSpikeRatio         = 0.0;  // 尖刺比例
double g_boxTopR2              = 0.0;  // 上边界R²
double g_boxBottomR2           = 0.0;  // 下边界R²
int    g_boxTouchesTop         = 0;    // 上边界触碰次数
int    g_boxTouchesBottom      = 0;    // 下边界触碰次数

// 【AI优化】强制冷却机制变量
int    g_nextTradeBar          = 0;    // 下次允许交易的K线索引

// 【AI优化】ATR止损变量
double g_atrStopLoss           = 0.0;  // ATR动态止损价格

// 【AI优化】评分系统常量 (移植自TradingView)
double MinAspect               = 2.5;  // 最小长宽比
double AspectTarget            = 4.5;  // 目标长宽比
double MaxBoxATR               = 2.0;  // 最大箱体ATR
double MaxBoxATRHard           = 2.5;  // 硬性最大ATR
double SpikeThreshold          = 0.35; // 尖刺阈值
double MaxSpikeRatio           = 0.25; // 最大尖刺比例
int    IdealBarsMin            = 5;    // 理想最小K线数
int    IdealBarsMax            = 120;  // 理想最大K线数
double w_flatness              = 0.25; // 平坦度权重
double w_independence          = 0.20; // 独立性权重
double w_smoothness            = 0.12; // 平滑度权重
double w_space                 = 0.13; // 空间权重
double w_volume                = 0.12; // 成交量权重
double w_time                  = 0.10; // 时间权重
double w_micro                 = 0.08; // 微观权重

// 【核心开关】箱体突破高度百分比后彻底失效控制
bool          EnableBoxInvalidation = true;
// (true=6.9逻辑: 突破后彻底失效, false=7.x逻辑: 突破后暂停追单)

//------------------------ 全局变量 -----------------------------
CTrade        g_Trade;
CPositionInfo g_Position;
COrderInfo    g_Order;
int           g_indicatorHandle = INVALID_HANDLE;
bool          g_hasBox            = false;
string        g_boxName           = "";
double        g_boxTop            = 0.0;
double        g_boxBot            = 0.0;
bool          g_ordersPlaced      = false;
datetime      g_lastCloseTime     = 0;
bool          g_lastTradeWasLoss  = false;
int           g_martinCount       = 0;
double        g_lastTradeLot      = 0.0;
// 箱体锁定机制
bool      g_isBoxLocked       = false;
string    g_lockedBoxName     = "";
double    g_lockedBoxTop      = 0.0;
double    g_lockedBoxBot      = 0.0;
int       g_boxMartinCount    = 0;
double    g_boxLastTradeLot   = 0.0;

// 止损后重入
bool      g_needReEntryCheck  = false;
datetime  g_lastStopLossBarTime = 0;
double    g_stopLossBarClosePrice = 0.0;
bool      g_stopLossClosedOutsideBox = false;
int       g_lastStopLossDirection = -1;
datetime  g_closePriceJudgedBarTime = 0;      // 收盘价判断完成时的K线时间（确保下一根K线才执行）

// J单箱体信息
string    g_lastJOrderBoxName = "";
double    g_lastJOrderBoxTop  = 0.0;
double    g_lastJOrderBoxBot  = 0.0;
datetime  g_lastJOrderTime    = 0;

// 失效箱体列表
string    g_invalidatedBoxes[];

// 交易窗口关闭控制
datetime  g_lastWindowCloseCheckDate = 0;
bool      g_windowClosedToday = false;

double    g_boxInitialLot       = 0.0;
int       g_boxOrderCount       = 0;
//【新增】箱体开仓标记（开仓后不受时间限制）
bool      g_boxHasOpenedPosition = false;   // 当前箱体是否已有订单开仓

// 性能优化变量
datetime  g_lastUpdateTime      = 0;
double    g_lastPrice           = 0.0;
bool      g_cachedHasPosition   = false;
bool      g_cachedHasOrders     = false;
datetime  g_lastCacheTime       = 0;
int       g_tickCounter         = 0;
// Tick计数器

// 统计面板
int    Panel_X         = 5;
int    Panel_Y         = 25;
color  TextColor       = clrOrange;
color  DividerColor    = clrNONE;
color  BackgroundColor = clrBlack;

// 背景时段可视化系统变量
datetime g_lastBgUpdate = 0;
datetime g_lastAlertCheck = 0;
datetime g_manualStartTime = 0;
datetime g_manualEndTime = 0;
bool     g_bgInitialized = false;

int    type[];
double yingkui[];
string orderSymbol[];
double zyk = 0.0;
int    avol = 0;
int    ylvol = 0;
string statPrefix = "WJ_";
// 订单追踪（移动止损）
struct OrderTrailingInfo
{
    ulong  ticket;
    bool   allowTrailing;
};
OrderTrailingInfo g_OrderTrails[];
//-------------------- 增强诊断日志系统 (MT4结构化输出移植) --------------------

//+------------------------------------------------------------------+
//| 基础诊断日志输出                                                 |
//+------------------------------------------------------------------+
void DiagPrint(string msg)
{
   if(!启用诊断日志) return;
   Print(msg);
}

//+------------------------------------------------------------------+
//| 箱体分析诊断                                                     |
//+------------------------------------------------------------------+
void DiagPrint_BoxAnalysis(string boxName, double boxTop, double boxBot, double boxHeight)
{
    if(!启用诊断日志) return;
    PrintFormat("[箱体分析] 当前箱体: %s, 高度: %.1f点, 范围: [%.5f - %.5f]",
                boxName, boxHeight/_Point, boxBot, boxTop);
}

//+------------------------------------------------------------------+
//| 开仓决策诊断                                                     |
//+------------------------------------------------------------------+
void DiagPrint_OrderDecision(double spreadRatio, double minVolatility, double currentSpread)
{
    if(!启用诊断日志) return;
    PrintFormat("[开仓决策] 点差占比: %.2f%%, 最小波动: %.1f点, 当前点差: %.0f点",
                spreadRatio * 100, minVolatility/_Point, currentSpread);
}

//+------------------------------------------------------------------+
//| 马丁状态诊断                                                     |
//+------------------------------------------------------------------+
void DiagPrint_MartinStatus(int martinCount, int maxMartin, double currentLot, bool isBoxLocked = false)
{
    if(!启用诊断日志) return;
    string context = isBoxLocked ? "箱体" : "全局";
    PrintFormat("[马丁状态] %s马丁: %d/%d次, 当前手数: %.2f",
                context, martinCount, maxMartin, currentLot);
}

//+------------------------------------------------------------------+
//| 交易环境诊断                                                     |
//+------------------------------------------------------------------+
void DiagPrint_TradingEnvironment(bool spreadOk, bool volatilityOk, bool volumeOk, bool timeOk)
{
    if(!启用诊断日志) return;
    PrintFormat("[交易环境] 点差检查:%s, 波动检查:%s, 量能检查:%s, 时间检查:%s",
                spreadOk ? "✓" : "✗",
                volatilityOk ? "✓" : "✗",
                volumeOk ? "✓" : "✗",
                timeOk ? "✓" : "✗");
}

//+------------------------------------------------------------------+
//| 止损后重入诊断                                                   |
//+------------------------------------------------------------------+
void DiagPrint_ReEntry(string direction, double closePrice, bool outsideBox, double lotSize)
{
    if(!启用诊断日志) return;
    PrintFormat("[止损重入] %s重入, 收盘价:%.5f, %s箱体外侧, 手数:%.2f",
                direction, closePrice, outsideBox ? "在" : "不在", lotSize);
}

//+------------------------------------------------------------------+
//| 移动止损诊断                                                     |
//+------------------------------------------------------------------+
void DiagPrint_TrailingStop(ulong ticket, double oldSL, double newSL, double currentProfit)
{
    if(!启用诊断日志) return;
    PrintFormat("[移动止损] #%d: SL %.5f → %.5f (浮盈:%.0f点)",
                ticket, oldSL, newSL, currentProfit/_Point);
}

//+------------------------------------------------------------------+
//| 系统状态诊断                                                     |
//+------------------------------------------------------------------+
void DiagPrint_SystemStatus(bool hasBox, bool hasPosition, bool hasOrders, bool boxLocked)
{
    if(!启用诊断日志) return;
    PrintFormat("[系统状态] 箱体:%s, 持仓:%s, 挂单:%s, 锁定:%s",
                hasBox ? "✓" : "✗",
                hasPosition ? "✓" : "✗",
                hasOrders ? "✓" : "✗",
                boxLocked ? "✓" : "✗");
}

// 辅助函数：清除非ASCII字符，并截断注释到 31 字符以内 (MT4对订单注释限制，MT5虽然宽松但也做处理)
string CleanAndTruncateComment(string original)
{
    // 1. 移除非ASCII字符(一些经纪商不支持中文/特殊字符)
    string pure="";
    for(int i=0; i<StringLen(original); i++)
    {
        ushort c = StringGetCharacter(original,i);
        if(c >= 32 && c < 127) // Basic ASCII printable characters
            pure += ShortToString(c);
    }
    // 2. 截断到31字节以内
    if(StringLen(pure)>31) pure = StringSubstr(pure,0,31);
    return pure;
}

//+------------------------------------------------------------------+
//| 初始化函数                                                         |
//+------------------------------------------------------------------+
int OnInit()
{
    //==================== 授权验证 ====================
    // 获取当前登录账号
    long currentAccount = AccountInfoInteger(ACCOUNT_LOGIN);
    // 验证账号是否在授权列表中
    bool accountAuthorized = false;
    string accounts[];
    int accountCount = StringSplit(g_AuthorizedAccounts, ',', accounts);
    for(int i = 0; i < accountCount; i++)
    {
        StringTrimLeft(accounts[i]);
        StringTrimRight(accounts[i]);
        if(StringToInteger(accounts[i]) == currentAccount)
        {
            accountAuthorized = true;
            break;
        }
    }
    
    // 验证使用时间
    bool timeValid = true;
    datetime expiryTime = StringToTime(g_AuthExpiryTime);
    if(expiryTime > 0 && TimeCurrent() > expiryTime)
    {
        timeValid = false;
    }
    
    // 授权验证失败
    if(!accountAuthorized || !timeValid)
    {
        string errorMsg = "";
        if(!accountAuthorized)
            errorMsg = "账号 " + IntegerToString(currentAccount) + " 未获得授权。\\n";
        if(!timeValid)
            errorMsg += "授权已于 " + g_AuthExpiryTime + " 过期。\\n";
        errorMsg += "\\n授权使用，请联系管理员\\nTelegram: @laocaimi1314";
        
        MessageBox(errorMsg, "需要授权", MB_OK | MB_ICONERROR);
        Print("========================================");
        Print("【授权失败】EA未获得使用授权");
        Print("  当前账号: ", currentAccount);
        Print("  授权账号: ", g_AuthorizedAccounts);
        Print("  授权截止: ", g_AuthExpiryTime);
        Print("  联系方式: Telegram @laocaimi1314");
        Print("========================================");
        return(INIT_FAILED);
    }
    
    // 授权验证成功
    Print("========================================");
    Print("【授权验证通过】账号 ", currentAccount, " 已授权");
    Print("  授权截止时间: ", g_AuthExpiryTime);
    Print("========================================");
    //==================== 授权验证结束 ====================
    // 设置魔术号
    g_Trade.SetExpertMagicNumber(魔术号);
    g_Trade.SetDeviationInPoints(10);
    // 设置订单填充模式
    g_Trade.SetTypeFilling(ORDER_FILLING_RETURN);
    
    // 加载指标（与MT4一致：即使加载失败也继续运行，可以使用手动绘制的箱体）
    // 注意：MT5指标参数与MT4可能不同，这里尝试加载nengliang指标
    // 如果您的MT5指标需要参数，请在iCustom中添加
    g_indicatorHandle = iCustom(_Symbol, PERIOD_CURRENT, 指标名称);
    if(g_indicatorHandle == INVALID_HANDLE)
    {
        PrintFormat("【指标加载】警告：'%s' 指标文件可能不存在", 指标名称);
        PrintFormat("  提示：请确保 '%s.ex5' 文件存在于 Indicators 目录", 指标名称);
        PrintFormat("  备选：EA将尝试识别手动绘制的矩形框");
        // 与MT4一致：不返回INIT_FAILED，允许EA继续运行
    }
    else
    {
        PrintFormat("【指标加载】'%s' 指标已启用，将持续在后台运行", 指标名称);
        PrintFormat("  - 识别前缀: '%s'", 指标前缀);
        PrintFormat("  - 参数: DarvasMode=%d, PivotStrength=%d, RollingPeriod=%d", 
                    Darvas模式, 枢轴强度, 滚动周期);
    }
    
    // 初始化统计数组
    ArrayResize(g_OrderTrails, 0);
    ArrayResize(type, 最近交易笔数);
    ArrayInitialize(type, -1);
    ArrayResize(yingkui, 最近交易笔数);
    ArrayInitialize(yingkui, 0.0);
    ArrayResize(orderSymbol, 最近交易笔数);
    for(int i = 0; i < ArraySize(orderSymbol); i++)
        orderSymbol[i] = "";
    ArrayResize(g_invalidatedBoxes, 0);
    
    // 删除旧对象
    DeleteObjectsWithPrefix(statPrefix);
    
    // 图表设置
    ChartSetInteger(0, CHART_SHOW_GRID, false);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    // 与MT4一致，设置为蜡烛图
    
    // 初始化箱体锁定和重入相关变量（与MT4一致）
    g_isBoxLocked = false;
    g_lockedBoxName = "";
    g_lockedBoxTop = 0;
    g_lockedBoxBot = 0;
    g_boxMartinCount = 0;
    g_boxLastTradeLot = 0;
    g_needReEntryCheck = false;
    g_lastStopLossBarTime = 0;
    g_stopLossBarClosePrice = 0;
    g_stopLossClosedOutsideBox = false;
    g_lastStopLossDirection = -1;
    g_lastJOrderBoxName = "";
    g_lastJOrderBoxTop = 0;
    g_lastJOrderBoxBot = 0;
    g_lastJOrderTime = 0;
    g_lastWindowCloseCheckDate = 0;
    g_windowClosedToday = false;
    g_boxHasOpenedPosition = false;

    // 初始化背景时段可视化系统
    if(Bg_ShowBackground) {
        Bg_Initialize();
        Bg_ParseManualTimes();
    }
    
    Print("========================================");
    Print("【能量块EA MT5版本-高频同步】初始化完成");
    Print("  魔术号: ", 魔术号);
    Print("  初始手数: ", 初始手);
    Print("  马丁: ", (启用马丁 ? "启用" : "禁用"));
    Print("  移动止损: ", (是否启动移动止损 ? "启用" : "禁用"));
    Print("========================================");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 去初始化函数                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(g_indicatorHandle != INVALID_HANDLE)
        IndicatorRelease(g_indicatorHandle);

    DeleteObjectsWithPrefix(statPrefix);
    if(Bg_ShowBackground) {
        Bg_DeleteAllObjects();
    }
    Print("EA已卸载，原因代码: ", reason);
}

//+------------------------------------------------------------------+
//| OnTick函数 (已移除所有节流限制，实现MT4级响应速度)                   |
//+------------------------------------------------------------------+
void OnTick()
{
    EnsureAllOrdersTrailing();
    g_tickCounter++;

    // 系统状态诊断（每100个Tick输出一次，避免刷屏）
    static int statusCounter = 0;
    if(++statusCounter >= 100) {
        DiagPrint_SystemStatus(g_hasBox, g_cachedHasPosition, g_cachedHasOrders, g_isBoxLocked);
        statusCounter = 0;
    }
    
    datetime currentTime = TimeCurrent();

    // 【同步优化】为了像MT4一样实时，先更新持仓状态
    bool hasPositionNow = HasOpenPositionDirect();
    g_cachedHasPosition = hasPositionNow;
    g_cachedHasOrders = HasPendingOrdersDirect();

    // 【同步优化】只要有持仓且开启移动止损，必须每个Tick都检查，不能等待
    if(是否启动移动止损 && hasPositionNow)
    {
        CheckTrailingStop();
    }
    
    // 【修改】移除此处的Tick节流，模拟MT4全速运行
    // if(g_tickCounter % 10 != 0) return; // REMOVED
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // 【修改】移除价格微变过滤，确保任何波动都能触发逻辑
    /* if(g_lastUpdateTime == currentTime) {
        double priceChange = MathAbs(currentPrice - g_lastPrice);
        double minChange = _Point * 2; 
        if(priceChange < minChange) return;
    }
    */
    
    g_lastUpdateTime = currentTime;
    g_lastPrice = currentPrice;
    
    // 更新马丁计数
    UpdateMartinOnClose();
    // 【新增】检查箱体订单是否已开仓
    CheckBoxOrderOpened();

    // 【新增】箱体失效检测 - 核心优化
    if(g_hasBox && EnableBoxInvalidation) {
        if(CheckBoxInvalidation(g_boxName, g_boxTop, g_boxBot)) {
            ResetBoxState();  // 清空当前箱体
            if(启用诊断日志)
                PrintFormat("[箱体失效] %s 因突破距离过大已作废", g_boxName);
            return;  // 跳过本次Tick的后续处理
        }
    }
    
    // 检查交易窗口结束（只删挂单）
    CheckAndCloseOrdersAfterWindow1End();
    // 判断交易时间
    bool tradingWindow = IsTradingTime();
    bool allowTrading = tradingWindow || g_boxHasOpenedPosition || g_isBoxLocked;
    // 【优化】标记防抖：只有在g_ordersPlaced=true且持续3秒无挂单时，才重置
    static datetime lastNoOrderTime = 0;
    if(!g_cachedHasPosition && !g_cachedHasOrders)
    {
        if(g_ordersPlaced)
        {
            if(lastNoOrderTime == 0) lastNoOrderTime = currentTime;
            else if(currentTime - lastNoOrderTime >= 3)
            {
                if(启用诊断日志) DiagPrint("[重置标记] 挂单标记已设置但持续3秒无挂单，重置 g_ordersPlaced");
                g_ordersPlaced = false;
                lastNoOrderTime = 0;
            }
        }
        else lastNoOrderTime = 0;
    }
    else lastNoOrderTime = 0;
    
    if(!allowTrading)
    {
        // 不在交易时间且箱体未开仓，删除挂单
        if(g_cachedHasOrders)
            RemoveAllPendingOrders();
        g_ordersPlaced = false;
    }
    else
    {
        // === 安全检查 ===
        // 如果马丁次数已达上限，强制清理重入等待状态
        if (g_needReEntryCheck && g_martinCount >= 马丁最大次数) {
             // PrintFormat("[OnTick安全检查] 马丁已达上限但仍在重入等待，强制清理");
             g_needReEntryCheck = false;
             g_lastStopLossBarTime = 0;
             g_stopLossBarClosePrice = 0;
             g_stopLossClosedOutsideBox = false;
             g_lastStopLossDirection = -1;
             g_closePriceJudgedBarTime = 0;
        }
        if (g_needReEntryCheck && g_isBoxLocked && g_boxMartinCount >= 马丁最大次数) {
             // PrintFormat("[OnTick安全检查] 箱体马丁已达上限但仍在重入等待，强制清理");
             g_needReEntryCheck = false;
             g_lastStopLossBarTime = 0;
             g_stopLossBarClosePrice = 0;
             g_stopLossClosedOutsideBox = false;
             g_lastStopLossDirection = -1;
             g_closePriceJudgedBarTime = 0;
        }
        
        // 止损后重入检查
        CheckReEntryAfterStopLoss();
        // 如果正在等待重入（等待K线收盘等），不进行新单逻辑
        if(g_needReEntryCheck) return;
        // 无挂单无持仓，扫描新箱体
        if(!g_cachedHasOrders && !g_cachedHasPosition)
        {
            ScanForNewBox();
        }
        
        // 有持仓就删除挂单
        if(g_cachedHasPosition)
        {
            if(g_cachedHasOrders)
                RemoveAllPendingOrders();
        }
        else
        {
            // 识别到箱体，价格在箱体内，放置J单挂单
            if(g_hasBox && !g_ordersPlaced && !g_cachedHasOrders)
            {
                double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                double mid = (bid + ask) * 0.5;
                if(mid >= g_boxBot && mid <= g_boxTop)
                {
                    // --- 【新增】首单点差限制逻辑 ---
                    bool spreadCheckPassed = true;
                    double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD); // 获取当前点差(微点)

                    // 如果设置了限制(大于0)，且当前点差超过限制
                    if(点差限制 > 0 && currentSpread > 点差限制)
                    {
                        spreadCheckPassed = false;
                        DiagPrint(StringFormat("【点差过滤】当前点差 %.0f > 限制 %d，暂停挂单，等待点差回落", currentSpread, 点差限制));
                    }

                    // 诊断：开仓决策环境检查
                    double boxHeight = g_boxTop - g_boxBot;
                    double spreadRatio = (boxHeight > 0) ? (currentSpread / boxHeight) : 999;
                    double minVolatility = 最小箱体波动微点 * _Point;
                    DiagPrint_OrderDecision(spreadRatio, minVolatility, currentSpread);

                    // 只有点差检查通过，且量能检查通过，才执行挂单
                    if(spreadCheckPassed && CheckVolumeFilter())
                    {
                        PlaceTwoOrders_OneSideN();
                        // g_ordersPlaced is set inside PlaceTwoOrders
                        g_boxOrderCount++;
                    }
                    else
                    {
                        if(启用诊断日志) DiagPrint("[初次挂单] 量能过滤未通过");
                    }
                }
            }
            
            // 价格回到箱体，重新挂单
            CheckReEnterBoxAndPlaceOrder();
        }
    }
    
    // 统计面板 (保留节流以节省图表资源，不影响交易逻辑)
    static datetime lastPanelUpdate = 0;
    if(是否启动统计显示 && currentTime - lastPanelUpdate >= 1) // At least 1 sec
    {
        ShowStatistics();
        lastPanelUpdate = currentTime;
    }

    // 背景时段可视化系统更新（节流：每分钟更新一次）
    if(Bg_ShowBackground && currentTime - g_lastBgUpdate >= 60) {
        Bg_UpdateBackground();
        if(Bg_AlertMinutes > 0) Bg_CheckPreSessionAlert();
        g_lastBgUpdate = currentTime;
    }
}

//+------------------------------------------------------------------+
//| 直接检查持仓（不使用缓存）                                         |
//+------------------------------------------------------------------+
bool HasOpenPositionDirect()
{
    int total = PositionsTotal();
    for(int i = 0; i < total; i++)
    {
        if(g_Position.SelectByIndex(i))
        {
            if(g_Position.Symbol() == _Symbol && g_Position.Magic() == 魔术号)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| 直接检查挂单（不使用缓存）                                         |
//+------------------------------------------------------------------+
bool HasPendingOrdersDirect()
{
    int total = OrdersTotal();
    for(int i = 0; i < total; i++)
    {
        if(g_Order.SelectByIndex(i))
        {
            if(g_Order.Symbol() == _Symbol && g_Order.Magic() == 魔术号)
                return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| 判断是否有持仓（使用缓存）                                         |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
    return g_cachedHasPosition;
}

//+------------------------------------------------------------------+
//| 判断是否有挂单（使用缓存）                                         |
//+------------------------------------------------------------------+
bool HasPendingOrders()
{
    return g_cachedHasOrders;
}

//+------------------------------------------------------------------+
//| 删除所有挂单                                                       |
//+------------------------------------------------------------------+
void RemoveAllPendingOrders()
{
    int total = OrdersTotal();
    for(int i = total - 1; i >= 0; i--)
    {
        if(g_Order.SelectByIndex(i))
        {
            if(g_Order.Symbol() == _Symbol && g_Order.Magic() == 魔术号)
            {
                ulong ticket = g_Order.Ticket();
                if(g_Trade.OrderDelete(ticket))
                    RemoveTrailingTicket(ticket);
            }
        }
    }
    
    // 更新缓存
    g_cachedHasOrders = false;
}

//+------------------------------------------------------------------+
//| 关闭所有持仓                                                       |
//+------------------------------------------------------------------+
void CloseAllOpenPositions()
{
    int total = PositionsTotal();
    for(int i = total - 1; i >= 0; i--)
    {
        if(g_Position.SelectByIndex(i))
        {
            if(g_Position.Symbol() == _Symbol && g_Position.Magic() == 魔术号)
            {
                ulong ticket = g_Position.Ticket();
                if(g_Trade.PositionClose(ticket))
                    RemoveTrailingTicket(ticket);
            }
        }
    }
    
    // 更新缓存
    g_cachedHasPosition = false;
}

//+------------------------------------------------------------------+
//| 关闭所有订单                                                       |
//+------------------------------------------------------------------+
void CloseAllOrders()
{
    CloseAllOpenPositions();
    RemoveAllPendingOrders();
}

// 辅助函数：检查名称是否包含有效前缀
bool HasValidPrefix(string name, string prefixList)
{
    if(StringLen(prefixList) == 0) return false;
    string prefixes[];
    StringSplit(prefixList, ',', prefixes);
    
    for(int i=0; i<ArraySize(prefixes); i++)
    {
        string p = prefixes[i];
        StringTrimLeft(p);
        StringTrimRight(p);
        if(StringLen(p) > 0 && StringFind(name, p, 0) == 0)
            return true;
    }
    return false;
}
//+------------------------------------------------------------------+
//| 扫描新箱体 (已移除频率限制，实现Tick级扫描)                         |
//+------------------------------------------------------------------+
void ScanForNewBox()
{
    // 1. 如果箱体已锁定，直接使用锁定信息
    if(g_isBoxLocked)
    {
        g_hasBox = true;
        g_boxName = g_lockedBoxName;
        g_boxTop = g_lockedBoxTop;
        g_boxBot = g_lockedBoxBot;
        return;
    }
    
    // 2. 如果已有箱体且有订单，暂停扫描
    if(g_hasBox && (g_cachedHasOrders || g_cachedHasPosition)) 
        return;
        
    // 【修改】移除 10秒 扫描限制，模拟MT4每Tick扫描
    // static datetime lastScanTime = 0;
    // datetime currentTime = TimeCurrent();
    // if(currentTime - lastScanTime < 10) return; // REMOVED
    // lastScanTime = currentTime;

    // ==========================================
    // 阶段一：尝试扫描图表对象 (用于可视化回测或实盘)
    // ==========================================
    string latestRectName = "";
    double latestBoxTop = 0;
    double latestBoxBot = 0;

    int objCount = ObjectsTotal(0, 0, OBJ_RECTANGLE);
    // 只有当图表上有对象时才执行对象扫描逻辑
    if(objCount > 0)
    {
        datetime latestPrefixedTime = 0;
        string latestPrefixedName = "";
        double latestPrefixedTop = 0;
        double latestPrefixedBot = 0;
        
        datetime latestAnyTime = 0;
        string latestAnyName = "";
        double latestAnyTop = 0;
        double latestAnyBot = 0;

        for(int i = objCount - 1; i >= 0; i--)
        {
            string nm = ObjectName(0, i, 0, OBJ_RECTANGLE);
            if(nm == "") continue;
            if(IsBoxInvalidated(nm)) continue; // 跳过失效箱体

            bool hasPrefix = HasValidPrefix(nm, 指标前缀);
            datetime t1 = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 0);
            datetime t2 = (datetime)ObjectGetInteger(0, nm, OBJPROP_TIME, 1);
            datetime boxRightEdgeTime = MathMax(t1, t2);
            // 过滤太旧的箱体
            if (Bars(_Symbol, PERIOD_CURRENT) > 200) {
                 datetime oldTime = iTime(_Symbol, PERIOD_CURRENT, MathMin(Bars(_Symbol, PERIOD_CURRENT)-1, 199));
                 if (boxRightEdgeTime < oldTime) continue;
            }
            
            double p1 = ObjectGetDouble(0, nm, OBJPROP_PRICE, 0);
            double p2 = ObjectGetDouble(0, nm, OBJPROP_PRICE, 1);
            double tempTop = NormalizeDouble(MathMax(p1, p2), _Digits);
            double tempBot = NormalizeDouble(MathMin(p1, p2), _Digits);
            // 检查是否被突破（包含失效检测）
            if(IsBoxAlreadyBroken(nm, tempTop, tempBot)) continue;
            // 检查高度
            int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
            if((tempTop - tempBot) < stopLevel * _Point * 2.0) continue;
            if(hasPrefix) {
                if(boxRightEdgeTime > latestPrefixedTime) {
                    latestPrefixedTime = boxRightEdgeTime;
                    latestPrefixedName = nm;
                    latestPrefixedTop = tempTop;
                    latestPrefixedBot = tempBot;
                }
            }
            if(boxRightEdgeTime > latestAnyTime) {
                latestAnyTime = boxRightEdgeTime;
                latestAnyName = nm;
                latestAnyTop = tempTop;
                latestAnyBot = tempBot;
            }
        }
        
        // 优先使用带前缀的
        if(latestPrefixedName != "") {
            latestRectName = latestPrefixedName;
            latestBoxTop = latestPrefixedTop;
            latestBoxBot = latestPrefixedBot;
        } else if(latestAnyName != "") {
            latestRectName = latestAnyName;
            latestBoxTop = latestAnyTop;
            latestBoxBot = latestAnyBot;
        }
    }

    // ==========================================
    // 阶段二：如果没有找到图表对象，尝试从指标缓冲区读取 (用于非可视化回测)
    // ==========================================
    if(latestRectName == "" && g_indicatorHandle != INVALID_HANDLE)
    {
        double bufTop[], bufBot[];
        // 读取指标缓冲区 Index 3 (BoxTop) 和 Index 4 (BoxBottom)
        if(CopyBuffer(g_indicatorHandle, 3, 0, 1, bufTop) > 0 &&
           CopyBuffer(g_indicatorHandle, 4, 0, 1, bufBot) > 0)
        {
            // 检查当前K线是否有有效的箱体数据
            if(bufTop[0] != EMPTY_VALUE && bufBot[0] != EMPTY_VALUE && bufTop[0] > bufBot[0])
            {
     
                // 生成一个基于价格的唯一名称，用于模拟对象名
                // 格式：Auto_Top价格_Bottom价格
                string autoName = StringFormat("Auto_%.5f_%.5f", bufTop[0], bufBot[0]);
                // 简单检查是否失效 (基于名称列表)
                if(!IsBoxInvalidated(autoName))
                {
                    double closePrice = iClose(_Symbol, PERIOD_CURRENT, 0);
                    bool isBroken = (closePrice > bufTop[0] || closePrice < bufBot[0]);
                    if(!isBroken)
                    {
                        latestRectName = autoName;
                        latestBoxTop = bufTop[0];
                        latestBoxBot = bufBot[0];
                        
                        // 诊断日志：确认在非可视化模式下获取到了数据
                        static datetime lastBufLog = 0;
                        if(启用诊断日志 && TimeCurrent() - lastBufLog > 3600) {
                            Print("【系统信息】通过数据流读取到箱体: ", autoName);
                            lastBufLog = TimeCurrent();
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 阶段三：更新全局状态
    // ==========================================
    if(latestRectName == "") return;
    if(latestRectName != g_boxName || !g_hasBox)
    {
        g_boxName = latestRectName;
        g_hasBox = true;
        g_ordersPlaced = false;
        g_boxTop = latestBoxTop;
        g_boxBot = latestBoxBot;
        g_boxOrderCount = 0;
        g_boxHasOpenedPosition = false;
        // 重置开仓标记

        // 计算初始手数
        if(交易手数模式 == 模式_固定手数)
            g_boxInitialLot = 初始手;
        else
            g_boxInitialLot = CalcLotByRisk(g_boxTop, g_boxBot);
        // 诊断日志：箱体分析
        double boxHeight = g_boxTop - g_boxBot;
        DiagPrint_BoxAnalysis(g_boxName, g_boxTop, g_boxBot, boxHeight);
        DiagPrint(StringFormat("[✓ 新箱体识别] %s [%.5f-%.5f] 初始手:%.2f", g_boxName, g_boxBot, g_boxTop, g_boxInitialLot));
    }
}

//+------------------------------------------------------------------+
//| 完整的箱体失效检测系统 - MT5核心优化（基于MT4 v8.0逻辑）           |
//+------------------------------------------------------------------+
bool CheckBoxInvalidation(string boxName, double boxTop, double boxBot)
{
    if(boxName == "") return false;

    // 1. 获取箱体右边界时间
    datetime boxEndTime = GetBoxEndTime(boxName);
    if(boxEndTime == 0) return false;

    // 2. 计算突破距离（检查箱体右边界后的K线）
    int barsToCheck = (箱体突破检测K线数 > 0) ? 箱体突破检测K线数 : 999;
    double maxBreakDistance = 0.0;
    int barsChecked = 0;

    for(int i = 0; i < barsToCheck && barsChecked < 5000; i++) // 防止无限循环
    {
        datetime barTime = iTime(_Symbol, PERIOD_CURRENT, i);
        if(barTime <= boxEndTime) break; // 只检查箱体右边界后的K线

        double high = iHigh(_Symbol, PERIOD_CURRENT, i);
        double low = iLow(_Symbol, PERIOD_CURRENT, i);

        // 计算突破距离（使用最高价和最低价）
        double upBreak = MathMax(0, high - boxTop);
        double downBreak = MathMax(0, boxBot - low);
        double currentBreakDistance = MathMax(upBreak, downBreak);

        maxBreakDistance = MathMax(maxBreakDistance, currentBreakDistance);
        barsChecked++;
    }

    // 3. 判断是否失效
    double boxHeight = MathAbs(boxTop - boxBot);
    if(boxHeight <= 0) return false;

    double invalidThreshold = boxHeight * 箱体突破失效倍数;

    if(maxBreakDistance > invalidThreshold) {
        // 箱体失效 - 记录到失效列表
        AddInvalidatedBox(boxName);
        if(启用诊断日志)
            PrintFormat("【箱体失效】%s 突破距离:%.1f点 > 阈值:%.1f点 (%.1f倍高度)",
                        boxName, maxBreakDistance/_Point, invalidThreshold/_Point,
                        箱体突破失效倍数);
        return true;  // 箱体失效
    }

    return false;  // 箱体有效
}

//+------------------------------------------------------------------+
//| 获取箱体右边界时间                                                 |
//+------------------------------------------------------------------+
datetime GetBoxEndTime(string boxName)
{
    if(boxName == "") return 0;

    // 优先从图表对象获取
    if(ObjectFind(0, boxName) >= 0)
    {
        datetime time1 = (datetime)ObjectGetInteger(0, boxName, OBJPROP_TIME, 0);
        datetime time2 = (datetime)ObjectGetInteger(0, boxName, OBJPROP_TIME, 1);
        return MathMax(time1, time2);
    }

    return 0;
}

//+------------------------------------------------------------------+
//| 优化后的箱体突破检查：兼容原有逻辑，支持容错率过滤                    |
//+------------------------------------------------------------------+
bool IsBoxAlreadyBroken(string boxName, double boxTop, double boxBot)
{
    // 首先检查是否已在失效列表中
    if(IsBoxInvalidated(boxName))
        return true;

    // 如果失效检测开关关闭，直接返回未突破
    if(!EnableBoxInvalidation)
        return false;

    // 使用新的完整失效检测逻辑
    return CheckBoxInvalidation(boxName, boxTop, boxBot);
}

//+------------------------------------------------------------------+
//| 放置J单（双向挂单）                                                |
//+------------------------------------------------------------------+
void PlaceTwoOrders_OneSideN()
{
    if(!g_hasBox)
        return;

    // 【新增】箱体失效检查 - 二次确认
    if(EnableBoxInvalidation && IsBoxInvalidated(g_boxName)) {
        if(启用诊断日志)
            PrintFormat("[拒绝开仓] 箱体 %s 已在失效列表中", g_boxName);
        return;
    }

    // 【新增】环境安全检查
    if(!IsTradeEnvironmentSafe(g_boxTop, g_boxBot))
        return;

    if(g_cachedHasOrders)
        RemoveAllPendingOrders();
    
    double baseLotCalc = g_boxInitialLot;
    if(baseLotCalc <= 0)
    {
        if(交易手数模式 == 模式_以损定量 && g_hasBox)
            baseLotCalc = CalcLotByRisk(g_boxTop, g_boxBot);
        else
            baseLotCalc = 初始手;
        if(baseLotCalc <= 0)
            return;
        
        g_boxInitialLot = baseLotCalc;
    }
    
    double nextLot = CalcNextLot_ConsideringMartin(baseLotCalc);
    // 标准化手数
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if(lotStep <= 0) lotStep = 0.01;
    
    nextLot = MathMax(minLot, MathRound(nextLot / lotStep) * lotStep);
    if(nextLot > maxLot && maxLot > 0) nextLot = maxLot;
    if(nextLot < minLot)
        return;
    
    int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double stopLevelPrice = stopLevel * _Point;
    
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    bool buyOrderPlaced = false;
    bool sellOrderPlaced = false;
    
    // 做多单
    if(做单方向 == 多空都做 || 做单方向 == 只做多单)
    {
        string cmtBuy = EA_Comment + "_J_Buy_" + g_boxName;
        if(StringLen(cmtBuy) > 31) cmtBuy = StringSubstr(cmtBuy, 0, 31);
        
        double buyP = g_boxTop;
        double sl = g_boxBot;
        double dist = MathAbs(buyP - sl);
        double tp = 0;
        if(J单止盈倍数 > 0)
            tp = NormalizeDouble(buyP + dist * J单止盈倍数, _Digits);
        // 调整价格
        if(buyP <= ask + stopLevelPrice)
            buyP = NormalizeDouble(ask + stopLevelPrice + _Point * 2, _Digits);
        if(MathAbs(buyP - sl) < stopLevelPrice)
            sl = NormalizeDouble(buyP - (stopLevelPrice + _Point * 2), _Digits);
        if(tp != 0 && MathAbs(tp - buyP) < stopLevelPrice)
            tp = NormalizeDouble(buyP + (stopLevelPrice + _Point * 2), _Digits);

        // 【优化】回测滑点模拟：强制抬高买入价格
        if(MQLInfoInteger(MQL_TESTER) && 模拟滑点微点数 > 0) {
            buyP = NormalizeDouble(buyP + 模拟滑点微点数 * _Point, _Digits);
            if(tp > 0) tp = NormalizeDouble(tp + 模拟滑点微点数 * _Point, _Digits);
        }

        if(sl < buyP)
        {
            g_Trade.BuyStop(nextLot, buyP, _Symbol, sl, tp, 
                           ORDER_TIME_GTC, 0, cmtBuy);
            if(g_Trade.ResultRetcode() == TRADE_RETCODE_DONE)
            {
                ulong ticket = g_Trade.ResultOrder();
                AddTrailingTicket(ticket, true);
                buyOrderPlaced = true;
                g_cachedHasOrders = true; // 更新缓存
            }
        }
    }
    
    // 做空单
    if(做单方向 == 多空都做 || 做单方向 == 只做空单)
    {
        string cmtSell = EA_Comment + "_J_Sell_" + g_boxName;
        if(StringLen(cmtSell) > 31) cmtSell = StringSubstr(cmtSell, 0, 31);
        
        double sellP = g_boxBot;
        double sl = g_boxTop;
        double dist = MathAbs(sellP - sl);
        double tp = 0;
        if(J单止盈倍数 > 0)
            tp = NormalizeDouble(sellP - dist * J单止盈倍数, _Digits);
        // 调整价格
        if(sellP >= bid - stopLevelPrice)
            sellP = NormalizeDouble(bid - (stopLevelPrice + _Point * 2), _Digits);
        if(MathAbs(sellP - sl) < stopLevelPrice)
            sl = NormalizeDouble(sellP + (stopLevelPrice + _Point * 2), _Digits);
        if(tp != 0 && MathAbs(tp - sellP) < stopLevelPrice)
            tp = NormalizeDouble(sellP - (stopLevelPrice + _Point * 2), _Digits);

        // 【优化】回测滑点模拟：强制压低卖出价格
        if(MQLInfoInteger(MQL_TESTER) && 模拟滑点微点数 > 0) {
            sellP = NormalizeDouble(sellP - 模拟滑点微点数 * _Point, _Digits);
            if(tp > 0) tp = NormalizeDouble(tp - 模拟滑点微点数 * _Point, _Digits);
        }

        if(sl > sellP)
        {
            g_Trade.SellStop(nextLot, sellP, _Symbol, sl, tp,
                            ORDER_TIME_GTC, 0, cmtSell);
            if(g_Trade.ResultRetcode() == TRADE_RETCODE_DONE)
            {
                ulong ticket = g_Trade.ResultOrder();
                AddTrailingTicket(ticket, true);
                sellOrderPlaced = true;
                g_cachedHasOrders = true; // 更新缓存
            }
        }
    }
    
    // 更新状态
    if((做单方向 == 多空都做 && buyOrderPlaced && sellOrderPlaced) ||
       (做单方向 == 只做多单 && buyOrderPlaced) ||
       (做单方向 == 只做空单 && sellOrderPlaced))
    {
        g_ordersPlaced = true;
        // 记录J单箱体信息
        g_lastJOrderBoxName = g_boxName;
        g_lastJOrderBoxTop = g_boxTop;
        g_lastJOrderBoxBot = g_boxBot;
        g_lastJOrderTime = TimeCurrent();
        
        // Print("【J单记录】箱体:", g_boxName, " [", g_boxBot, "-", g_boxTop, "]");
    }
}

//+------------------------------------------------------------------+
//| 检查马丁策略触发条件 (MT4深度绑定逻辑)                           |
//+------------------------------------------------------------------+
bool CheckMartinCondition(string currentBoxName = "")
{
    if(!启用马丁 || !g_lastTradeWasLoss)
        return false;

    // 如果有箱体锁定，必须在同一箱体内才能马丁
    if(g_isBoxLocked)
    {
        if(currentBoxName == "" && g_hasBox)
            currentBoxName = g_boxName;

        if(g_lockedBoxName != currentBoxName)
        {
            if(启用诊断日志)
                DiagPrint(StringFormat("【马丁检查】箱体锁定模式，当前箱体(%s)≠锁定箱体(%s)，禁止马丁",
                                      currentBoxName, g_lockedBoxName));
            return false;
        }
    }

    // 检查马丁次数上限
    int currentMartinCount = g_isBoxLocked ? g_boxMartinCount : g_martinCount;
    if(currentMartinCount >= 马丁最大次数)
    {
        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁检查】马丁次数已达上限(%d)，禁止继续马丁", 马丁最大次数));
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| 考虑马丁计算手数 (增强版 - 与箱体锁定深度绑定)                     |
//+------------------------------------------------------------------+
double CalcNextLot_ConsideringMartin(double baseLot)
{
    bool martinEnabled = (启用马丁 && 马丁倍数 > 1.0);

    // 如果马丁未启用，直接返回基础手数
    if(!martinEnabled)
    {
        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁计算】马丁未启用，使用基础手数: %.5f", baseLot));
        return baseLot;
    }

    // 如果上次不是亏损，不应用马丁
    if(!g_lastTradeWasLoss)
    {
        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁计算】上次非亏损，使用基础手数: %.5f", baseLot));
        return baseLot;
    }

    // 获取当前马丁上下文
    bool isBoxLocked = g_isBoxLocked;
    string currentBoxName = g_hasBox ? g_boxName : "";
    string lockedBoxName = g_lockedBoxName;

    int martinCount = 0;
    double lastTradeLot = 0.0;

    // 确定马丁计数和上次手数
    if(isBoxLocked && lockedBoxName == currentBoxName)
    {
        // 箱体锁定模式：同一箱体内的马丁
        martinCount = g_boxMartinCount;
        lastTradeLot = g_boxLastTradeLot;

        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁计算】箱体锁定模式: 箱体=%s, 马丁次数=%d, 上次手数=%.5f",
                                  lockedBoxName, martinCount, lastTradeLot));
    }
    else if(isBoxLocked)
    {
        // 箱体锁定但不是当前箱体：检查是否允许跨箱体马丁
        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁计算】跨箱体请求: 当前=%s, 锁定=%s, 不允许跨箱体马丁",
                                  currentBoxName, lockedBoxName));
        return baseLot;
    }
    else
    {
        // 全局马丁模式
        martinCount = g_martinCount;
        lastTradeLot = g_lastTradeLot;

        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁计算】全局马丁模式: 马丁次数=%d, 上次手数=%.5f",
                                  martinCount, lastTradeLot));
    }

    // 检查马丁次数上限
    if(martinCount >= 马丁最大次数)
    {
        if(启用诊断日志)
            DiagPrint(StringFormat("【马丁计算】达到最大马丁次数(%d)，使用基础手数: %.5f",
                                  马丁最大次数, baseLot));
        return baseLot;
    }

    // 应用马丁倍数
    if(lastTradeLot > 0.000001)
    {
        double newLot = NormalizeDouble(lastTradeLot * 马丁倍数, 5);

        // 记录马丁操作
        if(isBoxLocked && lockedBoxName == currentBoxName)
        {
            g_boxMartinCount++;
            g_boxLastTradeLot = newLot;
            if(启用诊断日志)
                DiagPrint(StringFormat("【马丁计算】箱体马丁: %.5f × %.2f = %.5f (第%d次)",
                                      lastTradeLot, 马丁倍数, newLot, g_boxMartinCount));
        }
        else
        {
            g_martinCount++;
            if(启用诊断日志)
                DiagPrint(StringFormat("【马丁计算】全局马丁: %.5f × %.2f = %.5f (第%d次)",
                                      lastTradeLot, 马丁倍数, newLot, g_martinCount));
        }

        return newLot;
    }

    // 默认返回基础手数
    if(启用诊断日志)
        DiagPrint(StringFormat("【马丁计算】无上次手数记录，使用基础手数: %.5f", baseLot));
    return baseLot;
}

//+------------------------------------------------------------------+
//| 以损定量计算手数                                                   |
//+------------------------------------------------------------------+
double CalcLotByRisk(double boxTop, double boxBot)
{
    // 参数验证
    if(boxTop <= boxBot)
    {
        Print("【以损定量】错误：箱体参数无效 Top=", boxTop, " Bot=", boxBot);
        return 初始手;
    }
    
    // 获取账户信息
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // 使用净值进行计算（更安全）
    double accountValue = equity > 0 ? equity : balance;
    // 风险百分比
    double riskPercent = 以损定量百分比;
    if(riskPercent <= 0 || riskPercent > 100)
    {
        Print("【以损定量】风险百分比无效：", riskPercent, "，使用默认值1.0%");
        riskPercent = 1.0;
    }
    
    // 计算风险金额（账户净值的N%）
    double riskAmount = accountValue * riskPercent / 100.0;
    // 箱体高度作为止损距离（价格单位）
    double boxHeight = boxTop - boxBot;
    // 转换为点数
    double stopLossPips = boxHeight / _Point;
    if(stopLossPips < 1)
    {
        Print("【以损定量】箱体高度过小：", boxHeight, " 使用最小值");
        stopLossPips = 1;
    }
    
    // 获取交易品种信息
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (_Point / tickSize);
    // 计算手数 = 风险金额 / (止损点数 × 每点价值)
    double lotSize = riskAmount / (stopLossPips * pointValue);
    // 标准化手数
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    if(lotStep > 0)
        lotSize = MathFloor(lotSize / lotStep) * lotStep;
    // 限制在最小和最大手数范围内
    if(lotSize < minLot) lotSize = minLot;
    if(lotSize > maxLot && maxLot > 0) lotSize = maxLot;
    
    // 详细日志输出
    Print("========================================");
    // Print("【以损定量计算】");
    Print("  账户净值：", DoubleToString(accountValue, 2));
    Print("  风险百分比：", DoubleToString(riskPercent, 2), "%");
    Print("  风险金额：", DoubleToString(riskAmount, 2));
    Print("  箱体高度：", DoubleToString(boxHeight, _Digits), " (", DoubleToString(stopLossPips, 1), " 点)");
    Print("  每点价值：", DoubleToString(pointValue, 2));
    Print("  计算手数：", DoubleToString(lotSize, 2));
    Print("  手数范围：", DoubleToString(minLot, 2), " - ", DoubleToString(maxLot, 2), " (步长:", DoubleToString(lotStep, 2), ")");
    Print("========================================");
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| 更新马丁计数（处理历史订单）                                       |
//+------------------------------------------------------------------+
void UpdateMartinOnClose()
{
    static datetime lastProcessedTime = 0;
    // 优化：只查询最近24小时的历史
    datetime fromTime = (lastProcessedTime > 0) ? lastProcessedTime : TimeCurrent() - 86400;
    if(!HistorySelect(fromTime, TimeCurrent()))
        return;
    
    int totalDeals = HistoryDealsTotal();
    bool hasNewDeal = false;
    for(int i = totalDeals - 1; i >= 0; i--)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        if(dealTicket == 0) continue;
        
        if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) continue;
        if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != 魔术号) continue;
        
        long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        if(dealEntry != DEAL_ENTRY_OUT) continue; // 只处理平仓
        
        datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
        // 如果这笔交易已经处理过，由于从后往前遍历，后面的都处理过了
        if(dealTime <= lastProcessedTime)
            break;
        double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
        double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
        double totalProfit = profit + swap + commission;
        
        string comment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
        double lots = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
        bool isLoss = (totalProfit < 0);
        
        // MT5关键修复：获取原始注释
        ulong positionTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
        string originalComment = "";
        if(HistorySelectByPosition(positionTicket))
        {
            int ordersTotal = HistoryOrdersTotal();
            for(int j = 0; j < ordersTotal; j++)
            {
                ulong orderTicket = HistoryOrderGetTicket(j);
                long orderType = HistoryOrderGetInteger(orderTicket, ORDER_TYPE);
                
                if(orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP ||
                   orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL)
                {
                    if(HistoryOrderGetInteger(orderTicket, ORDER_POSITION_ID) == positionTicket)
                    {
    
                        originalComment = HistoryOrderGetString(orderTicket, ORDER_COMMENT);
                        if(originalComment != "") break;
                    }
                }
            }
        }
        
        // 判断是J单还是C单（使用原始订单注释）
        bool isJ_Order = (StringFind(originalComment, "_J_") >= 0 || 
                         StringFind(originalComment, "_ReEntry_") 
                         >= 0 ||
                         StringFind(originalComment, "_Chase_") >= 0 ||
                         (StringFind(originalComment, EA_Comment) >= 0 && StringFind(originalComment, "_C") < 0));
        // EA注释但不含_C
        
        // Print("【Deal处理】票号:", dealTicket, " Deal注释:", comment,
        //       " 订单注释:", originalComment, " 盈亏:", totalProfit,
        //       " 是J单:", isJ_Order, " 手数:", lots);
        if(isJ_Order)
        {
            g_lastTradeLot = lots;
            if(isLoss)
            {
                g_lastTradeWasLoss = true;
                // 锁定箱体
                if(!g_isBoxLocked && g_lastJOrderBoxName != "")
                {
                    g_isBoxLocked = true;
                    g_lockedBoxName = g_lastJOrderBoxName;
                    g_lockedBoxTop = g_lastJOrderBoxTop;
                    g_lockedBoxBot = g_lastJOrderBoxBot;
                    g_boxMartinCount = 0;
                    g_boxLastTradeLot = lots;
                    // Print("【✓ 箱体锁定成功】", g_lockedBoxName, " [", g_lockedBoxBot, "-", g_lockedBoxTop, "] 手数:", lots);
                }
                
                // 更新马丁计数
                bool martinEnabled = (启用马丁 && 马丁倍数 > 1.0);
                if(martinEnabled)
                {
                    if(g_isBoxLocked && g_boxMartinCount < 马丁最大次数)
                    {
                        g_boxMartinCount++;
                        g_boxLastTradeLot = lots;
                        // Print("【马丁累加】次数:", g_boxMartinCount, " 手数:", lots);
                    }
                    else if(g_isBoxLocked && g_boxMartinCount >= 马丁最大次数)
                    {
                        // 马丁上限，箱体失效
                      
                        // Print("【马丁上限】箱体 ", g_lockedBoxName, " 马丁次数已达上限，放弃并失效");
                        AddInvalidatedBox(g_lockedBoxName);
                        ResetBoxState();
                        // Explicitly reset opened position flag in ResetBoxState
                    }
                    
                    if(g_martinCount < 马丁最大次数)
                      
                        g_martinCount++;
                }
                else
                {
                     if(g_isBoxLocked) g_boxLastTradeLot = lots;
                     g_martinCount = 0;
                }
                
                // 记录止损K线信息
                // Note: In MT5 deal time is close time.
                int barShift = GetBarShift(_Symbol, PERIOD_CURRENT, dealTime);
                if(barShift >= 0)
                {
                    g_lastStopLossBarTime = iTime(_Symbol, PERIOD_CURRENT, barShift);
                    g_needReEntryCheck = true;
                    
                    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
                    if(g_lastStopLossBarTime < currentBarTime)
                    {
                        // 止损K线已收盘
                        g_stopLossBarClosePrice = iClose(_Symbol, PERIOD_CURRENT, barShift);
                        bool priceInBox = (g_stopLossBarClosePrice > g_lockedBoxBot && 
                                          g_stopLossBarClosePrice < g_lockedBoxTop);
                        g_stopLossClosedOutsideBox = !priceInBox;
                        
                        // Print("【KeyBar判断】止损K线已收盘: ", g_stopLossBarClosePrice,
                        //       " 外侧:", g_stopLossClosedOutsideBox);
                    }
                    else
                    {
                        g_stopLossBarClosePrice = 0;
                        g_stopLossClosedOutsideBox = false;
                        // Print("【KeyBar标记】止损K线未收盘");
                    }
                }
                
                g_ordersPlaced = false;
            }
            else // J单止盈
            {
                // Print("【J单止盈】解除箱体锁定");
                g_lastTradeWasLoss = false;
                g_martinCount = 0;
                
                if(g_isBoxLocked)
                {
                    AddInvalidatedBox(g_lockedBoxName);
                }
                
                if(g_lastJOrderBoxName != "" && !g_isBoxLocked)
                {
                    AddInvalidatedBox(g_lastJOrderBoxName);
                }
                
                ResetBoxState();
            }
        }
        
        hasNewDeal = true;
        if(dealTime > lastProcessedTime)
            lastProcessedTime = dealTime;
    }
}

//+------------------------------------------------------------------+
//| 重置箱体状态（完全重置，包括马丁）                                 |
//+------------------------------------------------------------------+
void ResetBoxState()
{
    g_isBoxLocked = false;
    g_lockedBoxName = "";
    g_lockedBoxTop = 0;
    g_lockedBoxBot = 0;
    g_boxMartinCount = 0;
    g_boxLastTradeLot = 0;
    
    g_hasBox = false;
    g_boxName = "";
    g_ordersPlaced = false;
    
    g_lastJOrderBoxName = "";
    g_lastJOrderBoxTop = 0;
    g_lastJOrderBoxBot = 0;
    
    // 完全重置马丁状态
    g_lastTradeWasLoss = false;
    g_martinCount = 0;
    g_lastTradeLot = 0;
    // 【关键】重置箱体开仓标记
    g_boxHasOpenedPosition = false;
    
    // 重置重入检查
    g_needReEntryCheck = false;
    g_lastStopLossBarTime = 0;
    g_stopLossBarClosePrice = 0;
    g_stopLossClosedOutsideBox = false;
    g_lastStopLossDirection = -1;
    g_closePriceJudgedBarTime = 0;
}

//+------------------------------------------------------------------+
//| 重置箱体状态（保留马丁和箱体锁定，用于窗口结束）                   |
//+------------------------------------------------------------------+
void ResetBoxStateKeepMartin()
{
    // 关键：保留箱体锁定状态和马丁状态
    // g_isBoxLocked - 保留
    // g_lockedBoxName - 保留
    // g_lockedBoxTop - 保留
    // g_lockedBoxBot - 保留
    // g_boxMartinCount - 保留
    // g_boxLastTradeLot - 保留
    
    g_hasBox = false;
    g_boxName = "";
    g_ordersPlaced = false;
    
    // 保留J单箱体信息（用于重入）
    // g_lastJOrderBoxName - 保留
    // g_lastJOrderBoxTop - 保留
    // g_lastJOrderBoxBot - 保留
    
    // 保留马丁状态：g_lastTradeWasLoss, g_martinCount, g_lastTradeLot
}

//+------------------------------------------------------------------+
//| 【完整重入机制】检查止损后重入                                      |
//+------------------------------------------------------------------+
void CheckReEntryAfterStopLoss()
{
    if (!g_needReEntryCheck) return;

    // === 修复Bug1: 箱体已解锁时，必须重置重入检查标志（否则系统永久卡死） ===
    if (!g_isBoxLocked) {
        // PrintFormat("[修复-箱体解锁] 箱体已解锁但g_needReEntryCheck=true，强制重置重入状态");
        // 重置所有重入检查相关的状态变量
        g_needReEntryCheck = false;
        g_lastStopLossBarTime = 0;
        g_stopLossBarClosePrice = 0;
        g_stopLossClosedOutsideBox = false;
        g_lastStopLossDirection = -1;
        g_closePriceJudgedBarTime = 0;
        // PrintFormat("[修复-箱体解锁] 重入状态已重置，系统可以继续运行");
        return;
    }
    // === 修复结束 ===

    // === 新增：超时检查 ===
    // 如果止损时间距离现在太久（比如超过1000根K线），强制重置
    datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (g_lastStopLossBarTime > 0) {
        int timeDiff = (int)(currentTime - g_lastStopLossBarTime);
        int maxWaitSeconds = PeriodSeconds(PERIOD_CURRENT) * 1000; // 最多等待1000根K线的时间

        if (timeDiff > maxWaitSeconds || timeDiff < 0) {
            // PrintFormat("[重入检查-超时] 止损时间过久或无效，强制重置。止损时间:%s, 当前时间:%s, 时差:%d秒",
            //             TimeToString(g_lastStopLossBarTime),
            //             TimeToString(currentTime),
            //             timeDiff);

            // 强制重置所有相关状态
            g_needReEntryCheck = false;
            g_lastStopLossBarTime = 0;
            g_stopLossBarClosePrice = 0;
            g_stopLossClosedOutsideBox = false;
            g_lastStopLossDirection = -1;
            g_closePriceJudgedBarTime = 0;
            // 如果箱体还锁定，也失效它
            if (g_isBoxLocked) {
                // PrintFormat("[重入检查-超时] 同时失效过期箱体: %s", g_lockedBoxName);
                if (g_lockedBoxName != "") {
                    AddInvalidatedBox(g_lockedBoxName);
                }
                g_isBoxLocked = false;
                g_lockedBoxName = "";
                g_lockedBoxTop = 0;
                g_lockedBoxBot = 0;
                g_boxMartinCount = 0;
                g_boxLastTradeLot = 0;
                g_boxHasOpenedPosition = false;
            }

            // 重置当前箱体
            g_hasBox = false;
            g_boxName = "";
            g_ordersPlaced = false;

            // PrintFormat("[重入检查-超时] 超时重置完成，系统恢复正常");
            return;
        }
    }
    // === 超时检查结束 ===
    
    // 如果有持仓或挂单，不重入
    if(g_cachedHasPosition || g_cachedHasOrders)
    {
        g_needReEntryCheck = false;
        return;
    }
    
    // 【关键】获取止损K线和当前K线的开盘时间
    datetime stopLossBarOpenTime = g_lastStopLossBarTime;
    datetime currentBarOpenTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    // 【步骤1】如果止损K线收盘价还未确定（止损发生在当前K线），需要先等K线收盘
    if(g_stopLossBarClosePrice == 0 && currentBarOpenTime == stopLossBarOpenTime)
    {
        // 还在止损K线内，等待该K线收盘
        static int waitCloseCount = 0;
        if(启用诊断日志 && waitCloseCount % 200 == 0)
        {
            string msgWait = StringFormat("[等待止损K收盘] K线:%s", TimeToString(stopLossBarOpenTime));
            DiagPrint(msgWait);
        }
        waitCloseCount++;
        return;
    }
    
    // 【步骤2】止损K线已收盘，获取收盘价并判断位置
    if(g_stopLossBarClosePrice == 0 && currentBarOpenTime > stopLossBarOpenTime)
    {
        // 止损K线已经收盘，现在获取其收盘价
        int barShift = GetBarShift(_Symbol, PERIOD_CURRENT, stopLossBarOpenTime);
        if(barShift > 0) // 确保不是当前K线
        {
            g_stopLossBarClosePrice = iClose(_Symbol, PERIOD_CURRENT, barShift);
            // 判断止损K线收盘价相对箱体的位置
            bool priceInBox = (g_stopLossBarClosePrice > g_lockedBoxBot && 
                              g_stopLossBarClosePrice < g_lockedBoxTop);
            g_stopLossClosedOutsideBox = !priceInBox;

            PrintFormat("[止损K已收盘] 止损K:%s收盘价:%.5f %s箱体, 将在本根K线直接执行%s",
                        TimeToString(stopLossBarOpenTime), g_stopLossBarClosePrice,
                        (priceInBox ? "在" : "出"),
                        (g_stopLossClosedOutsideBox ? "追单" : "挂单"));
        }
        else
        {
            // === 修改：增强错误处理 ===
            PrintFormat("[警告] 无法获取止损K线收盘价，barShift=%d，止损时间=%s，当前时间=%s",
                       barShift,
                       TimeToString(stopLossBarOpenTime),
          
                     TimeToString(currentBarOpenTime));
            // 计算时间差
            int timeDiff = (int)(currentBarOpenTime - stopLossBarOpenTime);
            int expectedBars = timeDiff / PeriodSeconds(PERIOD_CURRENT);

            PrintFormat("[警告] 时间差=%d秒，预期相差约%d根K线，但无法找到该K线", timeDiff, expectedBars);
            // 如果时间差超过100根K线，认为数据异常，强制重置
            if (expectedBars > 100 || barShift < 0) {
                // PrintFormat("[警告] 止损K线太久远或数据异常，强制重置重入检查状态");
                g_needReEntryCheck = false;
                g_lastStopLossBarTime = 0;
                g_stopLossBarClosePrice = 0;
                g_stopLossClosedOutsideBox = false;
                g_lastStopLossDirection = -1;
                g_closePriceJudgedBarTime = 0;
                // 如果箱体还锁定，也失效它
                if (g_isBoxLocked) {
                    PrintFormat("[警告] 同时失效异常箱体: %s", g_lockedBoxName);
                    if (g_lockedBoxName != "") {
                        AddInvalidatedBox(g_lockedBoxName);
                    }
                    g_isBoxLocked = false;
                    g_lockedBoxName = "";
                    g_lockedBoxTop = 0;
                    g_lockedBoxBot = 0;
                    g_boxMartinCount = 0;
                    g_boxLastTradeLot = 0;
                    g_boxHasOpenedPosition = false;
                }

                g_hasBox = false;
                g_boxName = "";
                g_ordersPlaced = false;

                PrintFormat("[警告] 异常重置完成，系统恢复正常");
            } else {
                // 时间差不大，只是暂时找不到，设置标志为false让下次重试
                g_needReEntryCheck = false;
            }
            return;
        }
    }
    
    // 【步骤3】确认收盘价已获取
    if(g_stopLossBarClosePrice == 0)
    {
        // 收盘价尚未获取，继续等待
        return;
    }

    // 【步骤4】当前已经是止损K线之后的第一根K线开盘，直接执行重入逻辑
    PrintFormat("========================================");
    if(启用诊断日志) Print("【重入触发】新K线开盘！");
    PrintFormat("  止损K线: %s (收盘:%.5f)", TimeToString(stopLossBarOpenTime), g_stopLossBarClosePrice);
    PrintFormat("  当前K线: %s", TimeToString(currentBarOpenTime));
    PrintFormat("  箱体: %s [%.5f-%.5f]", g_lockedBoxName, g_lockedBoxBot, g_lockedBoxTop);
    if(启用诊断日志) Print("  策略: " + (g_stopLossClosedOutsideBox ? "追单(止损近侧)" : "挂单(止损对侧)"));
    PrintFormat("========================================");
    
    g_needReEntryCheck = false; // 只执行一次
    ExecuteDirectReEntry();
}

//+------------------------------------------------------------------+
//| 【完整重入逻辑】执行直接重入（市价单或挂单）                        |
//+------------------------------------------------------------------+
void ExecuteDirectReEntry()
{
    if(!g_isBoxLocked) return;
    
    // 【最终安全防线】再次确保不是在“止损K线”里直接重入
    datetime curBarOpen = iTime(_Symbol, PERIOD_CURRENT, 0);
    if(g_lastStopLossBarTime > 0 && curBarOpen <= g_lastStopLossBarTime)
    {
       if(启用诊断日志)
       {
           DiagPrint(StringFormat("[防护] 当前仍在止损K线内，禁止重入。止损K:%s", TimeToString(g_lastStopLossBarTime)));
       }
       return;
    }

    // 清理所有旧挂单
    if(g_cachedHasOrders)
    {
        // Print("【重入清理】删除旧挂单");
        RemoveAllPendingOrders();
    }
    
    // Print("【重入执行】箱体:", g_lockedBoxName, " 锁定:是, 收盘在箱体外:",
    //       (g_stopLossClosedOutsideBox ? "是" : "否"));
    double boxHeight = g_lockedBoxTop - g_lockedBoxBot;
    if(boxHeight <= 0) return;
    
    double baseLot = g_boxInitialLot > 0 ? g_boxInitialLot : 初始手;
    double nextLot = CalcNextLot_ConsideringMartin(baseLot);
    
    // 标准化手数
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    if(lotStep <= 0) lotStep = 0.01;
    nextLot = MathMax(minLot, MathRound(nextLot / lotStep) * lotStep);
    if(maxLot > 0 && nextLot > maxLot) nextLot = maxLot;
    if(nextLot < minLot)
    {
        Print("重入手数", nextLot, "小于最小手数", minLot);
        return;
    }
    
    int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double stopLevelDist = stopLevel * _Point;
    double tpDistance = boxHeight * J单止盈倍数;
    
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    // 【关键】根据止损K线收盘价位置决定开仓方式
    if(g_stopLossClosedOutsideBox)
    {
        // ====== 情况1：止损K线收盘在箱体外侧 → 直接市价开仓 (追单) ======
        
        // 判断收盘价在箱体上方还是下方
        bool isBuy = (g_stopLossBarClosePrice > g_lockedBoxTop);
        // 收在上沿外侧 → 开多单
        bool isSell = (g_stopLossBarClosePrice < g_lockedBoxBot);
        // 收在下沿外侧 → 开空单
        
        // 【新增检查】突破幅度 N% 规则
        double breakDist = (isBuy ? g_stopLossBarClosePrice - g_lockedBoxTop : g_lockedBoxBot - g_stopLossBarClosePrice);
        double ratio = (boxHeight > 0) ? (breakDist / boxHeight) : 999;
        if (ratio > 箱体突破失效倍数)
        {
            // PrintFormat("【重入放弃】突破太远，比率=%.2f > %.2f，不追单", ratio, 箱体突破失效倍数);
            // 【新增：双模式切换逻辑】
            if (EnableBoxInvalidation)
            {
                // 6.9 模式：彻底失效
                // PrintFormat("【模式：彻底失效】箱体 %s 已加入黑名单，停止追踪。", g_lockedBoxName);
                if(g_lockedBoxName != "") AddInvalidatedBox(g_lockedBoxName);
                // 【修复】使用统一清理函数
                ResetBoxState();
                g_martinCount = 0;
                g_lastTradeWasLoss = false;
                g_needReEntryCheck = false;
                g_stopLossClosedOutsideBox = false;
            }
            else
            {
                // 7.x 模式：暂停追单（原逻辑）
                g_stopLossClosedOutsideBox = false;
            }
            return;
        }

        double slPrice = 0;
        double tpPrice = 0;
        
        if(isBuy && (做单方向 == 多空都做 || 做单方向 == 只做多单))
        {
            // 多单：止损在箱体下沿
            slPrice = NormalizeDouble(g_lockedBoxBot, _Digits);
            tpPrice = (J单止盈倍数 > 0) ? NormalizeDouble(ask + tpDistance, _Digits) : 0;
            // 检查止损距离（如果太近，转为挂单）
            double slDist = MathAbs(ask - slPrice);
            if(slDist < stopLevelDist)
            {
                // PrintFormat("  ⚠ 追多止损距离%.0f点<最小%.0f点，改为挂单", slDist/_Point, stopLevelDist/_Point);
                g_stopLossClosedOutsideBox = false;
                ExecuteDirectReEntry(); // 递归调用挂单逻辑
                return;
            }
            
            string comment = EA_Comment + "_Chase_Buy_" + g_lockedBoxName;
            comment = CleanAndTruncateComment(comment);
            
            if(g_Trade.Buy(nextLot, _Symbol, ask, slPrice, tpPrice, comment))
            {
                ulong ticket = g_Trade.ResultOrder();
                AddTrailingTicket(ticket, true);
                
                PrintFormat("  ✓ 追多#%d @ %.5f, SL:%.5f(下沿-远侧), 距离:%.0f点",
                            ticket, ask, slPrice, slDist/_Point);
                Print("  原因: 止损K线收盘价", g_stopLossBarClosePrice, 
                      " 在箱体上沿", g_lockedBoxTop, "外侧");
                g_lastJOrderBoxName = g_lockedBoxName;
                g_lastJOrderBoxTop = g_lockedBoxTop;
                g_lastJOrderBoxBot = g_lockedBoxBot;
                g_lastJOrderTime = TimeCurrent();
                g_ordersPlaced = true;
                g_cachedHasPosition = true;
            }
            else
            {
                Print("【重入失败】多单开仓失败，错误:", GetLastError());
                // 失败也转为挂单尝试? 或者等待下一次
                g_stopLossClosedOutsideBox = false;
                ExecuteDirectReEntry();
                return;
            }
        }
        else if(isSell && (做单方向 == 多空都做 || 做单方向 == 只做空单))
        {
            // 空单：止损在箱体上沿
            slPrice = NormalizeDouble(g_lockedBoxTop, _Digits);
            tpPrice = (J单止盈倍数 > 0) ? NormalizeDouble(bid - tpDistance, _Digits) : 0;
            // 检查止损距离
            double slDist = MathAbs(bid - slPrice);
            if(slDist < stopLevelDist)
            {
                // PrintFormat("  ⚠ 追空止损距离%.0f点<最小%.0f点，改为挂单", slDist/_Point, stopLevelDist/_Point);
                g_stopLossClosedOutsideBox = false;
                ExecuteDirectReEntry(); // 递归调用挂单逻辑
                return;
            }
            
            string comment = EA_Comment + "_Chase_Sell_" + g_lockedBoxName;
            comment = CleanAndTruncateComment(comment);
            
            if(g_Trade.Sell(nextLot, _Symbol, bid, slPrice, tpPrice, comment))
            {
                ulong ticket = g_Trade.ResultOrder();
                AddTrailingTicket(ticket, true);
                
                PrintFormat("  ✓ 追空#%d @ %.5f, SL:%.5f(上沿-远侧), 距离:%.0f点",
                            ticket, bid, slPrice, slDist/_Point);
                Print("  原因: 止损K线收盘价", g_stopLossBarClosePrice,
                      " 在箱体下沿", g_lockedBoxBot, "外侧");
                g_lastJOrderBoxName = g_lockedBoxName;
                g_lastJOrderBoxTop = g_lockedBoxTop;
                g_lastJOrderBoxBot = g_lockedBoxBot;
                g_lastJOrderTime = TimeCurrent();
                g_ordersPlaced = true;
                g_cachedHasPosition = true;
            }
            else
            {
                Print("【重入失败】空单开仓失败，错误:", GetLastError());
                g_stopLossClosedOutsideBox = false;
                ExecuteDirectReEntry();
                return;
            }
        }
        else
        {
            Print("【重入警告】方向不匹配或未知，改为挂单");
            g_stopLossClosedOutsideBox = false;
            ExecuteDirectReEntry();
        }
    }
    else
    {
        // ====== 情况2：止损K线收盘在箱体内侧 → 箱体两侧挂单 ======
        
        // Print("【重入挂单】止损K线收在箱体内，重新在箱体两侧挂单");
        int ordersPlaced = 0;
        
        // 多单挂单
        if(做单方向 == 多空都做 || 做单方向 == 只做多单)
        {
            double buyP = NormalizeDouble(g_lockedBoxTop, _Digits);
            double slBuy = NormalizeDouble(g_lockedBoxBot, _Digits);
            double tpBuy = (J单止盈倍数 > 0) ? NormalizeDouble(buyP + tpDistance, _Digits) : 0;
            // 智能调整挂单价格
            if(buyP <= ask + stopLevelDist)
            {
                double newBuyP = NormalizeDouble(ask + stopLevelDist + _Point * 2, _Digits);
                if(newBuyP - buyP < boxHeight * 0.5)
                {
                    buyP = newBuyP;
                    if(tpBuy > 0) tpBuy = NormalizeDouble(buyP + tpDistance, _Digits);
                }
            }

            // 【优化】回测滑点模拟：挂单更差
            if(MQLInfoInteger(MQL_TESTER) && 模拟滑点微点数 > 0) {
                buyP = NormalizeDouble(buyP + 模拟滑点微点数 * _Point, _Digits);
                if(tpBuy > 0) tpBuy = NormalizeDouble(tpBuy + 模拟滑点微点数 * _Point, _Digits);
            }

            // 【新增】检查TP是否超过券商最大限制
            double maxTPDist = ask * 0.3;
            if (tpBuy != 0 && MathAbs(tpBuy - buyP) > maxTPDist) {
                DiagPrint(StringFormat("[重入TP过大-Buy] TP=%.5f 距离=%.0f点 超过限制，设为0", tpBuy, MathAbs(tpBuy - buyP)/_Point));
                tpBuy = 0;
            }

            // 检查止损距离（仅警告）
            if(MathAbs(buyP - slBuy) < stopLevelDist)
            {
                // Print("警告: 重入BuyStop止损距离小，保持止损在箱体下沿");
            }
            
            string cmtBuy = EA_Comment + "_ReEntry_BuyStop_" + g_lockedBoxName;
            cmtBuy = CleanAndTruncateComment(cmtBuy);
            
            if(g_Trade.BuyStop(nextLot, buyP, _Symbol, slBuy, tpBuy, 
                              ORDER_TIME_GTC, 0, cmtBuy))
            {
                ulong ticket = g_Trade.ResultOrder();
                AddTrailingTicket(ticket, true);
                // Print("【重入挂单-多】#", ticket, " Buy Stop 价格:", buyP, " SL:", slBuy, " (箱体下沿)");
                ordersPlaced++;
                g_cachedHasOrders = true;
            }
        }
        
        // 空单挂单
        if(做单方向 == 多空都做 || 做单方向 == 只做空单)
        {
            double sellP = NormalizeDouble(g_lockedBoxBot, _Digits);
            double slSell = NormalizeDouble(g_lockedBoxTop, _Digits);
            double tpSell = (J单止盈倍数 > 0) ? NormalizeDouble(sellP - tpDistance, _Digits) : 0;
            // 智能调整挂单价格
            if(sellP >= bid - stopLevelDist)
            {
                double newSellP = NormalizeDouble(bid - stopLevelDist - _Point * 2, _Digits);
                if(sellP - newSellP < boxHeight * 0.5)
                {
                    sellP = newSellP;
                    if(tpSell > 0) tpSell = NormalizeDouble(sellP - tpDistance, _Digits);
                }
            }

            // 【优化】回测滑点模拟：挂单更差
            if(MQLInfoInteger(MQL_TESTER) && 模拟滑点微点数 > 0) {
                sellP = NormalizeDouble(sellP - 模拟滑点微点数 * _Point, _Digits);
                if(tpSell > 0) tpSell = NormalizeDouble(tpSell - 模拟滑点微点数 * _Point, _Digits);
            }

            // 【新增】检查TP是否超过券商最大限制
            double maxTPDist = bid * 0.3;
            if (tpSell != 0 && MathAbs(tpSell - sellP) > maxTPDist) {
                DiagPrint(StringFormat("[重入TP过大-Sell] TP=%.5f 距离=%.0f点 超过限制，设为0", tpSell, MathAbs(tpSell - sellP)/_Point));
                tpSell = 0;
            }

            // 检查止损距离（仅警告）
            if(MathAbs(sellP - slSell) < stopLevelDist)
            {
                // Print("警告: 重入SellStop止损距离小，保持止损在箱体上沿");
            }
            
            string cmtSell = EA_Comment + "_ReEntry_SellStop_" + g_lockedBoxName;
            cmtSell = CleanAndTruncateComment(cmtSell);
            
            if(g_Trade.SellStop(nextLot, sellP, _Symbol, slSell, tpSell,
                               ORDER_TIME_GTC, 0, cmtSell))
            {
                ulong ticket = g_Trade.ResultOrder();
                AddTrailingTicket(ticket, true);
                // Print("【重入挂单-空】#", ticket, " Sell Stop 价格:", sellP, " SL:", slSell, " (箱体上沿)");
                ordersPlaced++;
                g_cachedHasOrders = true;
            }
        }
        
        if(ordersPlaced > 0)
        {
            g_lastJOrderBoxName = g_lockedBoxName;
            g_lastJOrderBoxTop = g_lockedBoxTop;
            g_lastJOrderBoxBot = g_lockedBoxBot;
            g_lastJOrderTime = TimeCurrent();
            g_ordersPlaced = true;
        }
    }
}

//+------------------------------------------------------------------+
//| 价格回到箱体，重新挂单                                             |
//+------------------------------------------------------------------+
void CheckReEnterBoxAndPlaceOrder()
{
    if(!g_hasBox) return;
    if(g_cachedHasOrders || g_cachedHasPosition) return;
    if(g_ordersPlaced) return;
    
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double mid = (bid + ask) * 0.5;
    bool priceInBox = (mid >= g_boxBot && mid <= g_boxTop);
    if(priceInBox)
    {
        // 检查量能过滤
        if(CheckVolumeFilter())
        {
            PlaceTwoOrders_OneSideN();
            g_ordersPlaced = true;
        }
        else
        {
            if(启用诊断日志) DiagPrint("[重入箱体] 量能过滤未通过，不挂单");
        }
    }
}

//+------------------------------------------------------------------+
//| 移动止损（与MT4完全一致）                                          |
//+------------------------------------------------------------------+
void CheckTrailingStop()
{
    if(!是否启动移动止损) return;
    
    // 【关键修复】直接检查持仓，不使用缓存，确保每次都能获取最新状态
    if(!HasOpenPositionDirect()) return;
    // 没有持仓就不检查
    
    double point = _Point;
    int digits = _Digits;
    int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double stopLevelPriceDist = stopLevel * point;
    
    double actual_trigger_pips_input = (double)移动止损触发点数; 
    double actual_step_pips_input = (double)移动止损步长;
    double triggerDistPrice; 
    double stepDistPrice;    
    
    // 【关键修复】优先使用锁定的箱体信息（持仓期间箱体可能被锁定）
    double boxTop = 0;
    double boxBot = 0;
    bool hasValidBox = false;
    
    if(g_isBoxLocked && g_lockedBoxTop > g_lockedBoxBot)
    {
        // 使用锁定的箱体信息
        boxTop = g_lockedBoxTop;
        boxBot = g_lockedBoxBot;
        hasValidBox = true;
    }
    else if(g_hasBox && g_boxTop > g_boxBot)
    {
        // 使用当前箱体信息
        boxTop = g_boxTop;
        boxBot = g_boxBot;
        hasValidBox = true;
    }
    
    if (移动止损方式 == 模式_箱体高度)
    {
        // 【箱体高度模式】浮盈达到箱体高度的N倍时，提损箱体高度的M倍
        if (hasValidBox)
        {
            double boxHeight = boxTop - boxBot;
            triggerDistPrice = boxHeight * 箱体高度触发倍数;  // 触发距离 = 箱体高度 * 触发倍数
            stepDistPrice = boxHeight * 箱体高度步长倍数;
            // 步长 = 箱体高度 * 步长倍数
            
            // 确保不小于最小止损距离
            triggerDistPrice = MathMax(triggerDistPrice, stopLevelPriceDist + point);
            stepDistPrice = MathMax(stepDistPrice, stopLevelPriceDist + point);
            
            if(启用诊断日志)
            {
                 static datetime lastBoxModeLog = 0;
                 if(TimeCurrent() - lastBoxModeLog > 60)
                 {
                     DiagPrint(StringFormat("Trailing Stop '箱体高度': BoxHeight=%.*f, Trigger=%.*f (%.1f pips), Step=%.*f (%.1f pips)",
                                            digits, boxHeight, digits, triggerDistPrice, triggerDistPrice/point, 
                                            digits, stepDistPrice, stepDistPrice/point));
                     lastBoxModeLog = TimeCurrent();
                 }
            }
        }
        else
        {
            // 没有有效箱体，使用固定点数
            triggerDistPrice = MathMax(actual_trigger_pips_input * point, stopLevelPriceDist + point);
            stepDistPrice = MathMax(actual_step_pips_input * point, stopLevelPriceDist + point);
            
            if(启用诊断日志)
            {
                 static datetime lastFallbackLog = 0;
                 if(TimeCurrent() - lastFallbackLog > 60)
                 {
                     DiagPrint(StringFormat("Trailing Stop '箱体高度' (无有效箱体): Trigger=%.*f (%.1f pips), Step=%.*f (%.1f pips)",
                                            digits, triggerDistPrice, triggerDistPrice/point, digits, stepDistPrice, 
                                            stepDistPrice/point));
                     lastFallbackLog = TimeCurrent();
                 }
            }
        }
    }
    else if (移动止损方式 == 模式_箱体内K线平均比)
    {
        // 【关键修复】优先使用锁定的箱体名称
        string boxNameToUse = "";
        if(g_isBoxLocked && g_lockedBoxName != "")
            boxNameToUse = g_lockedBoxName;
        else if(g_hasBox && g_boxName != "")
            boxNameToUse = g_boxName;
        if (boxNameToUse != "")
        {
            double avg_body_price_diff = GetAveragePriceBodyInBox(boxNameToUse, _Symbol, PERIOD_CURRENT);
            if (avg_body_price_diff > point && g_BoxKLineAvgHeightMultiplier > 0) 
            {
                double calculated_trigger_pips = (avg_body_price_diff / point) * g_BoxKLineAvgHeightMultiplier;
                triggerDistPrice = MathMax(calculated_trigger_pips * point, actual_trigger_pips_input * point);
                triggerDistPrice = MathMax(triggerDistPrice, stopLevelPriceDist + point);
                // Ensure at least StopLevel + 1pt

                stepDistPrice = MathMax(actual_step_pips_input * point, triggerDistPrice * 0.5);
                stepDistPrice = MathMax(stepDistPrice, stopLevelPriceDist + point); 

                if(启用诊断日志)
                {
                    static datetime lastLog = 0;
                    if(TimeCurrent() - lastLog > 60)
                    {
                        string msgTS = StringFormat("Trailing Stop '箱体内K线平均比': AvgBodyPrice=%.*f, Factor=%.2f. TriggerPrice=%.*f (%.1f pips), StepPrice=%.*f (%.1f pips)",
                                       
                                                    digits, avg_body_price_diff, g_BoxKLineAvgHeightMultiplier, 
                                                    digits, triggerDistPrice, triggerDistPrice/point, 
                             
                                                       digits, stepDistPrice, stepDistPrice/point);
                        DiagPrint(msgTS);
                        lastLog = TimeCurrent();
                    }
                }
            }
            else
            {
                triggerDistPrice = MathMax(actual_trigger_pips_input * point, stopLevelPriceDist + point);
                stepDistPrice    = MathMax(actual_step_pips_input * point, stopLevelPriceDist + point);
                if(启用诊断日志)
                {
                    static datetime lastLogFB = 0;
                    if(TimeCurrent() - lastLogFB > 60)
                    {
                        string msgFB = StringFormat("CheckTrailingStop: Fallback to input points for '箱体内K线平均比' (AvgBody=%.*f or Multiplier=%.2f invalid). Trigger=%.1f pips, Step=%.1f pips",
                                   
                                                 digits, avg_body_price_diff, g_BoxKLineAvgHeightMultiplier, triggerDistPrice/point, stepDistPrice/point);
                        DiagPrint(msgFB);
                        lastLogFB = TimeCurrent();
                    }
                }
            }
        }
        else
        {
            triggerDistPrice = MathMax(actual_trigger_pips_input * point, stopLevelPriceDist + point);
            stepDistPrice    = MathMax(actual_step_pips_input * point, stopLevelPriceDist + point);
            if(启用诊断日志)
            {
                static datetime lastLogFB2 = 0;
                if(TimeCurrent() - lastLogFB2 > 60)
                {
                    string msgFB2 = StringFormat("CheckTrailingStop: Fallback to input points for '箱体内K线平均比' (no active box). Trigger=%.1f pips, Step=%.1f pips",
                                            
                                                 triggerDistPrice/point, stepDistPrice/point);
                    DiagPrint(msgFB2);
                    lastLogFB2 = TimeCurrent();
                }
            }
        }
    }
    else 
    {
        // For other modes, use the direct input parameters or implement their specific logic
        triggerDistPrice = MathMax(actual_trigger_pips_input * point, stopLevelPriceDist + point);
        stepDistPrice    = MathMax(actual_step_pips_input * point, stopLevelPriceDist + point);
    }
    
    if (triggerDistPrice <= stopLevelPriceDist) triggerDistPrice = stopLevelPriceDist + point;
    // Min trigger
    if (stepDistPrice <= point) stepDistPrice = MathMax(point, stopLevelPriceDist/2.0);
    // Min step, ensure it's meaningful

    int total = PositionsTotal();
    for(int i = 0; i < total; i++)
    {
        if(!g_Position.SelectByIndex(i)) continue;
        if(g_Position.Symbol() != _Symbol) continue;
        if(g_Position.Magic() != 魔术号) continue;
        
        ulong ticket = g_Position.Ticket();
        // 检查是否允许移动止损
        if(!IsOrderAllowTrailing(ticket)) continue;
        
        double openPrice = g_Position.PriceOpen();
        double currentSL = g_Position.StopLoss();
        double currentTP = g_Position.TakeProfit();
        
        if(g_Position.PositionType() == POSITION_TYPE_BUY)
        {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            // 【优化】改为基于当前价格的持续提损，而不是只看开仓价
            // 只要浮盈达到触发距离，就持续跟随价格提损
            double currentProfit = bid - openPrice;
            // 当前浮盈（价格差）

            if (currentProfit >= triggerDistPrice) // 浮盈达到触发距离
            {
                // 【TradingView跳跃式移动止损逻辑】
                double boxHeight = boxTop - boxBot;
                double newSL_candidate = 0.0;

                if (hasValidBox && boxHeight > 0 && 移动止损方式 == 模式_箱体高度)
                {
                    // TradingView跳跃式逻辑：jumps = floor((profit - triggerDist) / stepDist)
                    // slOffset = TrailOffsetRatio * boxHeight + jumps * stepDist
                    // finalSL = openPrice + slOffset
                    int jumps = (int)MathFloor((currentProfit - triggerDistPrice) / stepDistPrice);
                    double offsetDist = boxHeight * 箱体高度回撤倍数;  // TrailOffsetRatio
                    double slOffset = offsetDist + (jumps * stepDistPrice);
                    newSL_candidate = NormalizeDouble(openPrice + slOffset, digits);
                }
                else
                {
                    // 传统逻辑（固定点数模式或其他模式）
                    newSL_candidate = NormalizeDouble(bid - stepDistPrice, digits);
                }

                // 【关键优化】只要新止损比旧止损好，就提损（无需其他条件）
                // 确保新止损：1)大于旧止损 2)不低于开仓价（保本）3)距离当前价足够远
                // 【修复】与MT4一致：只要大于旧止损即可（不需要+point）
                if((currentSL == 0.0 || newSL_candidate > currentSL) && newSL_candidate >= openPrice) 
                {
                    if (MathAbs(newSL_candidate - bid) >= stopLevelPriceDist )
                    {
                        // 检查止盈距离（如果有止盈的话）
                        bool tpOk = (currentTP == 0 || MathAbs(newSL_candidate - currentTP) >= stopLevelPriceDist);
                        if (tpOk)
                        {
                            if(g_Trade.PositionModify(ticket, newSL_candidate, currentTP))
                            {
                 
                                double oldSL = currentSL;
                                // 保存旧止损用于日志
                                
                                // 诊断：移动止损
                                DiagPrint_TrailingStop(ticket, oldSL, newSL_candidate, currentProfit);
                            }
                            else if(启用诊断日志)
                            {
              
                                string msgFail = StringFormat("【提损失败-多】#%d: 目标SL:%.5f, 错误:%d (Bid:%.5f, TP:%.5f)",
                                                              ticket, newSL_candidate, GetLastError(), bid, currentTP);
                                DiagPrint(msgFail);
                            }
                        }
                        else if(启用诊断日志)
                        {
                          
                            string msgTP = StringFormat("【提损跳过-多】#%d: 新SL %.5f 太接近TP %.5f (距离:%.0f点 < 最小:%.0f点)",
                                                       ticket, newSL_candidate, currentTP, MathAbs(newSL_candidate - currentTP)/point, stopLevelPriceDist/point);
                            DiagPrint(msgTP);
                        }
                    }
                    else if(启用诊断日志)
                    {
                        string msgDist = StringFormat("【提损跳过-多】#%d: 新SL %.5f 距离Bid %.5f 太近 (距离:%.0f点 < 最小:%.0f点)",
   
                                                      ticket, newSL_candidate, bid, MathAbs(newSL_candidate - bid)/point, stopLevelPriceDist/point);
                        DiagPrint(msgDist);
                    }
                }
                else if(启用诊断日志)
                {
                    static datetime lastSkipLog = 0;
                    if(TimeCurrent() - lastSkipLog > 10) // 每10秒最多输出一次
                    {
                        string msgSkip = StringFormat("【提损跳过-多】#%d: 条件不满足 (更好:%s, 保本:%s, 当前SL:%.5f, 新SL:%.5f, Bid:%.5f, 开仓:%.5f)",
                                        
                                                     ticket, ((currentSL == 0.0 || newSL_candidate > currentSL) ? "是" : "否"), 
                                                     (newSL_candidate >= openPrice ? "是" : "否"), currentSL, newSL_candidate, bid, openPrice);
                        DiagPrint(msgSkip);
                        lastSkipLog = TimeCurrent();
                    }
                }
            }
            else if(启用诊断日志)
            {
                static datetime lastProfitLog = 0;
                if(TimeCurrent() - lastProfitLog > 30) // 每30秒最多输出一次
                {
                    string msgProfit = StringFormat("【提损等待-多】#%d: 浮盈 %.0f点 < 触发 %.0f点 (Bid:%.5f, 开仓:%.5f)",
                                                
                                                    ticket, currentProfit/point, triggerDistPrice/point, bid, openPrice);
                    DiagPrint(msgProfit);
                    lastProfitLog = TimeCurrent();
                }
            }
        }
        else if(g_Position.PositionType() == POSITION_TYPE_SELL)
        {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            // 【优化】改为基于当前价格的持续提损，而不是只看开仓价
            double currentProfit = openPrice - ask;
            // 当前浮盈（价格差）

            if (currentProfit >= triggerDistPrice) // 浮盈达到触发距离
            {
                // 【TradingView跳跃式移动止损逻辑】
                double boxHeight = boxTop - boxBot;
                double newSL_candidate = 0.0;

                if (hasValidBox && boxHeight > 0 && 移动止损方式 == 模式_箱体高度)
                {
                    // TradingView跳跃式逻辑：jumps = floor((profit - triggerDist) / stepDist)
                    // slOffset = TrailOffsetRatio * boxHeight + jumps * stepDist
                    // finalSL = openPrice - slOffset (卖出订单)
                    int jumps = (int)MathFloor((currentProfit - triggerDistPrice) / stepDistPrice);
                    double offsetDist = boxHeight * 箱体高度回撤倍数;  // TrailOffsetRatio
                    double slOffset = offsetDist + (jumps * stepDistPrice);
                    newSL_candidate = NormalizeDouble(openPrice - slOffset, digits);
                }
                else
                {
                    // 传统逻辑（固定点数模式或其他模式）
                    newSL_candidate = NormalizeDouble(ask + stepDistPrice, digits);
                }

                // 【关键优化】只要新止损比旧止损好，就提损
                // 确保新止损：1)小于旧止损（或旧止损为0）2)不高于开仓价（保本）3)距离当前价足够远
                // 【修复】与MT4一致：只要小于旧止损即可（不需要-point）
                bool betterThanOldSL = (currentSL == 0.0 || newSL_candidate < currentSL);
                bool notAboveOpen = (newSL_candidate <= openPrice);
                
                if(betterThanOldSL && notAboveOpen)
                {
                    if (MathAbs(newSL_candidate - ask) >= stopLevelPriceDist)
                    {
                        // 检查止盈距离（如果有止盈的话）
      
                        bool tpOk = (currentTP == 0 || MathAbs(newSL_candidate - currentTP) >= stopLevelPriceDist);
                        if (tpOk)
                        {
                            if(g_Trade.PositionModify(ticket, newSL_candidate, currentTP))
                            {
                 
                                double oldSL = currentSL;
                                // 保存旧止损用于日志
                                
                                // 【优化】移除冗余的currentSL更新，下次循环会自动读取最新值
                                // if(g_Position.SelectByTicket(ticket))
 
                                // {
                                //    currentSL = g_Position.StopLoss();
                                // 更新当前止损
                                // }
                                
                                if(启用诊断日志)
  
                                {
                                    string msgOkS = StringFormat("【持续提损-空】#%d: SL %.5f→%.5f (Ask:%.5f, 浮盈:%.0f点, 步长:%.0f点)",
                          
                                                                       ticket, oldSL, newSL_candidate, ask, currentProfit/point, stepDistPrice/point);
                                    DiagPrint(msgOkS);
                                }
                            }
                            else if(启用诊断日志)
                            {
              
                                string msgFailS = StringFormat("【提损失败-空】#%d: 目标SL:%.5f, 错误:%d (Ask:%.5f, TP:%.5f)",
                                                               ticket, newSL_candidate, GetLastError(), ask, currentTP);
                                DiagPrint(msgFailS);
                            }
                        }
                        else if(启用诊断日志)
                        {
                          
                            string msgTP = StringFormat("【提损跳过-空】#%d: 新SL %.5f 太接近TP %.5f (距离:%.0f点 < 最小:%.0f点)",
                                                       ticket, newSL_candidate, currentTP, MathAbs(newSL_candidate - currentTP)/point, stopLevelPriceDist/point);
                            DiagPrint(msgTP);
                        }
                    }
                    else if(启用诊断日志)
                    {
                        string msgDist = StringFormat("【提损跳过-空】#%d: 新SL %.5f 距离Ask %.5f 太近 (距离:%.0f点 < 最小:%.0f点)",
   
                                                      ticket, newSL_candidate, ask, MathAbs(newSL_candidate - ask)/point, stopLevelPriceDist/point);
                        DiagPrint(msgDist);
                    }
                }
                else if(启用诊断日志)
                {
                    static datetime lastSkipLog = 0;
                    if(TimeCurrent() - lastSkipLog > 10) // 每10秒最多输出一次
                    {
                        string msgSkip = StringFormat("【提损跳过-空】#%d: 条件不满足 (更好:%s, 保本:%s, 当前SL:%.5f, 新SL:%.5f, Ask:%.5f, 开仓:%.5f)",
                                        
                                                     ticket, ((currentSL == 0.0 || newSL_candidate < currentSL) ? "是" : "否"), (notAboveOpen ? "是" : "否"), 
                                                     currentSL, newSL_candidate, ask, openPrice);
                        DiagPrint(msgSkip);
                        lastSkipLog = TimeCurrent();
                    }
                }
            }
            else if(启用诊断日志)
            {
                static datetime lastProfitLog = 0;
                if(TimeCurrent() - lastProfitLog > 30) // 每30秒最多输出一次
                {
                    string msgProfit = StringFormat("【提损等待-空】#%d: 浮盈 %.0f点 < 触发 %.0f点 (Ask:%.5f, 开仓:%.5f)",
                                                
                                                    ticket, currentProfit/point, triggerDistPrice/point, ask, openPrice);
                    DiagPrint(msgProfit);
                    lastProfitLog = TimeCurrent();
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 判断是否在交易时间                                                 |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
    // 缓存交易时间检查（每分钟最多检查一次）
    static bool cachedResult = true;
    static datetime lastCheckTime = 0;
    datetime currentTime = TimeCurrent();
    
    if(currentTime - lastCheckTime < 60)
        return cachedResult;
    lastCheckTime = currentTime;
    
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    int currentMinutes = dt.hour * 60 + dt.min;
    
    string tradeWindowsStart[5];
    string tradeWindowsEnd[5];
    tradeWindowsStart[0] = TradeTime1_Start; tradeWindowsEnd[0] = TradeTime1_End;
    tradeWindowsStart[1] = TradeTime2_Start; tradeWindowsEnd[1] = TradeTime2_End;
    tradeWindowsStart[2] = TradeTime3_Start; tradeWindowsEnd[2] = TradeTime3_End;
    tradeWindowsStart[3] = TradeTime4_Start; tradeWindowsEnd[3] = TradeTime4_End;
    tradeWindowsStart[4] = TradeTime5_Start; tradeWindowsEnd[4] = TradeTime5_End;
    
    bool isActiveInAnyWindow = false;
    bool anyWindowConfigured = false;
    for(int i = 0; i < 5; i++)
    {
        bool configured = !(tradeWindowsStart[i] == "00:00" && tradeWindowsEnd[i] == "00:00");
        if(configured)
        {
            anyWindowConfigured = true;
            if(IsWithinWindow(tradeWindowsStart[i], tradeWindowsEnd[i], currentMinutes))
            {
                isActiveInAnyWindow = true;
                break;
            }
        }
    }
    
    if(!anyWindowConfigured)
    {
        cachedResult = true;
        return true;
    }
    
    cachedResult = isActiveInAnyWindow;
    return isActiveInAnyWindow;
}

//+------------------------------------------------------------------+
//| 判断当前分钟数是否在窗口内                                         |
//+------------------------------------------------------------------+
bool IsWithinWindow(string startTimeStr, string endTimeStr, int currentServerMinutes)
{
    int startMinutes = ConvertTimeStringToMinutes(startTimeStr);
    int endMinutes = ConvertTimeStringToMinutes(endTimeStr);
    if(startMinutes == -1 || endMinutes == -1) return false;
    
    if(startMinutes < endMinutes)
    {
        return (currentServerMinutes >= startMinutes && currentServerMinutes < endMinutes);
    }
    else if(startMinutes > endMinutes)
    {
        return (currentServerMinutes >= startMinutes || currentServerMinutes < endMinutes);
    }
    else
    {
        if(startMinutes == 0 && endMinutes == 0 && 
           startTimeStr == "00:00" && endTimeStr == "00:00")
        {
            return false;
        }
        return true;
    }
}

//+------------------------------------------------------------------+
//| 将时间字符串转为分钟数                                             |
//+------------------------------------------------------------------+
int ConvertTimeStringToMinutes(string timestr)
{
    if(StringLen(timestr) != 5) return -1;
    if(StringGetCharacter(timestr, 2) != ':') return -1;
    string hourStr = StringSubstr(timestr, 0, 2);
    string minStr = StringSubstr(timestr, 3, 2);
    
    int h = (int)StringToInteger(hourStr);
    int m = (int)StringToInteger(minStr);
    if(h < 0 || h > 23 || m < 0 || m > 59) return -1;
    return h * 60 + m;
}

//+------------------------------------------------------------------+
//| 检查窗口结束后关闭订单                                             |
//+------------------------------------------------------------------+
void CheckAndCloseOrdersAfterWindow1End()
{
    if(TradeTime1_Start == "00:00" && TradeTime1_End == "00:00")
        return;
    datetime serverTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(serverTime, dt);
    
    // 检查是否新的一天
    if(g_lastWindowCloseCheckDate != 0)
    {
        MqlDateTime lastDt;
        TimeToStruct(g_lastWindowCloseCheckDate, lastDt);
        
        if(dt.year != lastDt.year || dt.mon != lastDt.mon || dt.day != lastDt.day)
        {
            g_windowClosedToday = false;
            g_lastWindowCloseCheckDate = serverTime;
        }
    }
    else
    {
        g_lastWindowCloseCheckDate = serverTime;
    }
    
    if(g_windowClosedToday) return;
    
    int currentMinutes = dt.hour * 60 + dt.min;
    int window1EndMinutes = ConvertTimeStringToMinutes(TradeTime1_End);
    int window1StartMinutes = ConvertTimeStringToMinutes(TradeTime1_Start);
    
    if(window1EndMinutes == -1 || window1StartMinutes == -1) return;
    
    bool justPassedEndTime = false;
    if(window1StartMinutes < window1EndMinutes)
    {
        justPassedEndTime = (currentMinutes >= window1EndMinutes && 
                            currentMinutes < window1EndMinutes + 5);
    }
    else
    {
        if(window1EndMinutes < window1StartMinutes)
        {
            justPassedEndTime = (currentMinutes >= window1EndMinutes && 
                                currentMinutes < window1EndMinutes + 5);
        }
    }
    
    if(justPassedEndTime)
    {
        if(g_cachedHasOrders)
        {
             // MQL4 behavior: Only remove pending orders, hold positions
             // PrintFormat("【检测到】第一交易窗口已结束，删除所有挂单（持仓单保留）");
             RemoveAllPendingOrders();
             
             // Do NOT reset box state here if we are holding positions, 
             // because we might want to manage them (trailing stop etc).
             // But MQL4 logic for window end is just "RemoveAllPendingOrders".
             // It marks windowClosedToday = true.
             
             g_windowClosedToday = true;
        }
    }
}

//+------------------------------------------------------------------+
//| 显示统计面板 (增强版 - MT4完整功能移植)                           |
//+------------------------------------------------------------------+
void ShowStatistics()
{
    // 性能优化：限制面板更新频率（每3秒最多一次）
    static datetime lastShowTime = 0;
    datetime currentTime = TimeCurrent();
    if(currentTime - lastShowTime < 3)
        return;

    lastShowTime = currentTime;

    UpdateStatPanel();
}

//+------------------------------------------------------------------+
//| 更新统计面板数据                                                 |
//+------------------------------------------------------------------+
void UpdateStatPanel()
{
    CollectStatistics();

    int xyd = Panel_X, yyd = Panel_Y;
    int hang = 最近交易笔数 * 2 + 12; // 增加更多统计行
    double ratio = (double)文本大小 / 11.0;

    int scaledX = (int)MathRound(xyd * ratio);
    int scaledY = (int)MathRound(yyd * ratio);
    int scaledWidth = (int)MathRound(220.0 * ratio);
    int scaledHeight = (int)MathRound(行间距 * (double)hang * ratio);

    string bgName = statPrefix + "BG";
    if(ObjectFind(0, bgName) < 0)
    {
        ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, scaledX);
        ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, scaledY);
        ObjectSetInteger(0, bgName, OBJPROP_XSIZE, scaledWidth);
        ObjectSetInteger(0, bgName, OBJPROP_YSIZE, scaledHeight);
        ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, 背景颜色);
        ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
        ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
    }

    int k = 0;

    // 显示标题
    DrawStatText(k, "=== 交易统计面板 ===", "", 文本颜色);
    k++;
    DrawStatText(k, "----------------------------", "", 分隔线颜色);
    k++;

    // 显示最近交易
    ShowRecentTrades(k);

    DrawStatText(k, "↑↑↑最新单↑↑↑", "", 文本颜色);
    k++;

    DrawStatText(k, "----------------------------", "", 分隔线颜色);
    k++;

    // 显示汇总统计
    double winRate = CalculateWinRate();
    color profitColor = (zyk > 0.0 ? clrLimeGreen : clrDeepPink);
    color winRateColor = (winRate >= 50 ? clrLimeGreen : clrDeepPink);

    DrawStatText(k, "● 总收入：" + DoubleToString(zyk, 2) + " USD", "", profitColor);
    k++;

    DrawStatText(k, "● 胜率：" + DoubleToString(winRate, 1) + "% (" + IntegerToString(ylvol) + "/" + IntegerToString(avol) + ")", "", winRateColor);
    k++;

    // 新增：显示当前状态
    string statusInfo = GetCurrentStatusInfo();
    DrawStatText(k, statusInfo, "", 文本颜色);
    k++;

    DrawStatText(k, "----------------------------", "", 分隔线颜色);
    k++;

    // 新增：显示箱体信息
    if(g_hasBox)
    {
        string boxInfo = StringFormat("● 箱体: %s [%.1f-%.1f]",
                                    g_boxName,
                                    g_boxBot,
                                    g_boxTop);
        DrawStatText(k, boxInfo, "", clrDodgerBlue);
        k++;
    }

    // 新增：显示马丁信息
    if(启用马丁 && (g_martinCount > 0 || g_boxMartinCount > 0))
    {
        string martinInfo = StringFormat("● 马丁: 全局%d 箱体%d",
                                       g_martinCount,
                                       g_boxMartinCount);
        DrawStatText(k, martinInfo, "", clrOrange);
        k++;
    }

    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| 绘制统计文本                                                     |
//+------------------------------------------------------------------+
void DrawStatText(int index, string text1, string text2, color clr)
{
    CreateStatLabel(index, text1, text2, clr);
}

//+------------------------------------------------------------------+
//| 计算胜率                                                         |
//+------------------------------------------------------------------+
double CalculateWinRate()
{
    if(avol == 0) return 0.0;
    return ((double)ylvol / (double)avol) * 100.0;
}

//+------------------------------------------------------------------+
//| 显示最近交易                                                     |
//+------------------------------------------------------------------+
void ShowRecentTrades(int &k)
{
    for(int n = 最近交易笔数 - 1; n >= 0; n--)
    {
        if(n < 0 || n >= ArraySize(type)) break;
        int tVal = type[n];
        if(tVal < 0) continue;

        double ykVal = yingkui[n];
        string tStr = (tVal == 0 ? "多单" : "空单");
        string ykStr = (ykVal >= 0.0 ? "盈利" : "亏损");
        color clr = (ykVal > 0.0 ? clrLimeGreen : clrDeepPink);
        string content = StringFormat("%s %s %.2f USD", tStr, ykStr, ykVal);
        string mark = (ykVal > 0.0 ? "✓" : "✗");

        DrawStatText(k, content, mark, clr);
        k++;

        DrawStatText(k, "----------------------------", "", 分隔线颜色);
        k++;
    }
}

//+------------------------------------------------------------------+
//| 获取当前状态信息                                                 |
//+------------------------------------------------------------------+
string GetCurrentStatusInfo()
{
    string status = "● 状态: ";

    bool hasPosition = HasOpenPosition();
    bool hasOrders = HasPendingOrders();
    bool inTradingTime = IsTradingTime();

    if(hasPosition)
        status += "持仓中";
    else if(hasOrders)
        status += "挂单中";
    else if(g_hasBox)
        status += "箱体待触发";
    else
        status += "等待箱体";

    if(!inTradingTime)
        status += " (非交易时间)";

    if(g_isBoxLocked)
        status += " [箱体锁定]";

    return status;
}

//+------------------------------------------------------------------+
//| 创建统计标签                                                       |
//+------------------------------------------------------------------+
void CreateStatLabel(int index, string text1, string text2, color clr)
{
    double ratio = (double)文本大小 / 11.0;
    int xyd = 5, yyd = 25;
    
    double offsetXA = xyd + 10.0;
    double offsetXB = xyd + 190.0;
    double offsetY = yyd + 26.0 + index * (double)行间距;
    
    int iOffXA = (int)MathRound(offsetXA * ratio);
    int iOffXB = (int)MathRound(offsetXB * ratio);
    int iOffY = (int)MathRound(offsetY * ratio);
    int scaledFontSize = (int)MathRound(文本大小 * ratio);
    string labelName1 = statPrefix + "A_" + IntegerToString(index);
    if(ObjectFind(0, labelName1) < 0)
    {
        ObjectCreate(0, labelName1, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, labelName1, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, labelName1, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
        ObjectSetInteger(0, labelName1, OBJPROP_SELECTABLE, false);
    }
    
    ObjectSetInteger(0, labelName1, OBJPROP_XDISTANCE, iOffXA);
    ObjectSetInteger(0, labelName1, OBJPROP_YDISTANCE, iOffY);
    ObjectSetInteger(0, labelName1, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, labelName1, OBJPROP_FONTSIZE, scaledFontSize);
    ObjectSetString(0, labelName1, OBJPROP_TEXT, text1);
    
    if(text2 != "")
    {
        string labelName2 = statPrefix + "B_" + IntegerToString(index);
        if(ObjectFind(0, labelName2) < 0)
        {
            ObjectCreate(0, labelName2, OBJ_LABEL, 0, 0, 0);
            ObjectSetInteger(0, labelName2, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, labelName2, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
            ObjectSetInteger(0, labelName2, OBJPROP_SELECTABLE, false);
        }
        
        ObjectSetInteger(0, labelName2, OBJPROP_XDISTANCE, iOffXB);
        ObjectSetInteger(0, labelName2, OBJPROP_YDISTANCE, iOffY);
        ObjectSetInteger(0, labelName2, OBJPROP_COLOR, clr);
        ObjectSetInteger(0, labelName2, OBJPROP_FONTSIZE, scaledFontSize);
        ObjectSetString(0, labelName2, OBJPROP_TEXT, text2);
    }
}

//+------------------------------------------------------------------+
//| 收集统计数据                                                       |
//+------------------------------------------------------------------+
void CollectStatistics()
{
    // 性能优化：限制统计查询频率（每5秒最多一次）
    static datetime lastCollectTime = 0;
    datetime currentTime = TimeCurrent();
    if(currentTime - lastCollectTime < 5)
        return;
    
    lastCollectTime = currentTime;
    
    ArrayInitialize(type, -1);
    ArrayInitialize(yingkui, 0.0);
    for(int i = 0; i < ArraySize(orderSymbol); i++)
        orderSymbol[i] = "";
    datetime startTime = currentTime - 86400 * 7; // 最近7天（减少查询范围）
    if(!HistorySelect(startTime, currentTime))
        return;
    zyk = 0.0;
    avol = 0;
    ylvol = 0;
    int recentCount = 0;
    
    int totalDeals = HistoryDealsTotal();
    for(int i = totalDeals - 1; i >= 0; i--)
    {
        ulong dealTicket = HistoryDealGetTicket(i);
        if(dealTicket == 0) continue;
        
        if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) continue;
        if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != 魔术号) continue;
        
        long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        if(dealEntry != DEAL_ENTRY_OUT) continue;
        
        long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
        if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL) continue;
        double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        double swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
        double commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
        double totalProfit = profit + swap + commission;
        
        avol++;
        if(totalProfit > 0) ylvol++;
        zyk += totalProfit;
        if(recentCount < 最近交易笔数)
        {
            type[recentCount] = (dealType == DEAL_TYPE_BUY ? 0 : 1);
            yingkui[recentCount] = totalProfit;
            orderSymbol[recentCount] = _Symbol;
            recentCount++;
        }
    }
}

//+------------------------------------------------------------------+
//| 删除带前缀的对象                                                   |
//+------------------------------------------------------------------+
void DeleteObjectsWithPrefix(string prefix)
{
    int total = ObjectsTotal(0, 0, -1);
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i, 0, -1);
        if(StringFind(name, prefix) == 0)
        {
            ObjectDelete(0, name);
        }
    }
}

//+------------------------------------------------------------------+
//| 箱体失效管理                                                       |
//+------------------------------------------------------------------+
bool IsBoxInvalidated(string boxName)
{
    for(int i = 0; i < ArraySize(g_invalidatedBoxes); i++)
    {
        if(g_invalidatedBoxes[i] == boxName)
            return true;
    }
    return false;
}

void AddInvalidatedBox(string boxName)
{
    if(boxName == "") return;
    if(IsBoxInvalidated(boxName)) return;
    int size = ArraySize(g_invalidatedBoxes);
    ArrayResize(g_invalidatedBoxes, size + 1);
    g_invalidatedBoxes[size] = boxName;
}

//+------------------------------------------------------------------+
//| 订单追踪管理                                                       |
//+------------------------------------------------------------------+
void AddTrailingTicket(ulong ticket, bool allow)
{
    if(ticket == 0) return;
    for(int i = 0; i < ArraySize(g_OrderTrails); i++)
    {
        if(g_OrderTrails[i].ticket == ticket)
        {
            g_OrderTrails[i].allowTrailing = allow;
            return;
        }
    }
    
    int newIndex = ArraySize(g_OrderTrails);
    ArrayResize(g_OrderTrails, newIndex + 1);
    g_OrderTrails[newIndex].ticket = ticket;
    g_OrderTrails[newIndex].allowTrailing = allow;
    if(启用诊断日志)
        PrintFormat("【移动止损注册】Ticket #%d 已加入追踪列表", ticket);
}

bool IsOrderAllowTrailing(ulong ticket)
{
    for(int i = 0; i < ArraySize(g_OrderTrails); i++)
    {
        if(g_OrderTrails[i].ticket == ticket)
            return g_OrderTrails[i].allowTrailing;
    }
    return false;
}

void RemoveTrailingTicket(ulong ticket)
{
    for(int i = 0; i < ArraySize(g_OrderTrails); i++)
    {
        if(g_OrderTrails[i].ticket == ticket)
        {
            for(int j = i; j < ArraySize(g_OrderTrails) - 1; j++)
                g_OrderTrails[j] = g_OrderTrails[j + 1];
            ArrayResize(g_OrderTrails, ArraySize(g_OrderTrails) - 1);
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Get bar shift by time (MT5 implementation)                       |
//+------------------------------------------------------------------+
int GetBarShift(string symbol, ENUM_TIMEFRAMES timeframe, datetime time)
{
    datetime arr[];
    ArraySetAsSeries(arr, true);
    int copied = CopyTime(symbol, timeframe, 0, Bars(symbol, timeframe), arr);
    if(copied <= 0) return -1;
    for(int i = 0; i < copied; i++)
    {
        if(arr[i] <= time)
            return i;
    }
    
    return -1;
}

//+------------------------------------------------------------------+
//| 【新增】检查箱体订单是否已开仓（标记箱体已激活）                     |
//+------------------------------------------------------------------+
void CheckBoxOrderOpened()
{
    // 如果已经标记为开仓，不需要重复检查
    if(g_boxHasOpenedPosition) return;
    // 如果没有箱体，不需要检查
    if(!g_hasBox && !g_isBoxLocked) return;
    
    // 检查是否有本EA的持仓单
    int total = PositionsTotal();
    for(int i = 0; i < total; i++)
    {
        if(g_Position.SelectByIndex(i))
        {
            if(g_Position.Symbol() == _Symbol && g_Position.Magic() == 魔术号)
            {
                // 发现持仓单，标记箱体已开仓
                if(!g_boxHasOpenedPosition)
          
                {
                    g_boxHasOpenedPosition = true;
                    if(启用诊断日志)
                    {
                        string msgAct = StringFormat("[箱体激活] 检测到持仓单#%d，箱体后续操作不受时间限制", g_Position.Ticket());
                        DiagPrint(msgAct);
                    }
                }
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 计算指定箱体对象内的K线平均实体高度 (价格差)                       |
//+------------------------------------------------------------------+
double GetAveragePriceBodyInBox(string boxObjectName, string sym, ENUM_TIMEFRAMES tf)
{
    if (ObjectFind(0, boxObjectName) < 0)
    {
        PrintFormat("GetAveragePriceBodyInBox: Box object '%s' not found on chart.", boxObjectName);
        return 0.0;
    }

    datetime time1 = (datetime)ObjectGetInteger(0, boxObjectName, OBJPROP_TIME, 0);
    datetime time2 = (datetime)ObjectGetInteger(0, boxObjectName, OBJPROP_TIME, 1);
    if (time1 == 0 || time2 == 0) return 0.0;
    if (time1 > time2) { datetime temp = time1;
        time1 = time2; time2 = temp; } 
    if (time1 == time2) return 0.0;
    double totalBodySum = 0;
    int candleCount = 0;
    int totalBarsOnChartForSymTf = Bars(sym, tf);
    // Iterate backwards from the most recent bar to find bars within the time window
    for (int i = 0; i < totalBarsOnChartForSymTf && i < 5000; i++) 
    {
        datetime barOpenTime = iTime(sym, tf, i);
        if (barOpenTime < time1) break; // Bar is older than box start
        
        if (barOpenTime < time2) // Bar opens before box end time
        {
            if (barOpenTime >= time1) // Bar opens at or after box start time
            {
                double openPrice = 
                    iOpen(sym, tf, i);
                double closePrice = iClose(sym, tf, i);
                if (openPrice != 0 && closePrice != 0)
                {
                    totalBodySum += MathAbs(openPrice - closePrice);
                    candleCount++;
                }
            }
        }
    }
    
    if (candleCount == 0) return 0.0;
    return totalBodySum / candleCount;
}

//+------------------------------------------------------------------+
//| 安全环境检查函数（新增：点差保护）                                  |
//+------------------------------------------------------------------+
bool IsTradeEnvironmentSafe(double boxTop, double boxBot)
{
    // --- 逻辑修改：如果总开关关闭，直接放行，忽略下方所有过滤参数 ---
    if (!启用点差保护) return true;
    double boxHeight = MathAbs(boxTop - boxBot);

    // 1. 最小波动过滤 (如果开关开启，才检查高度)
    if (boxHeight < 最小箱体波动微点 * _Point) {
        // if(启用诊断日志) PrintFormat("【过滤】箱体过小(%.1f pts < %d pts)，放弃开仓", boxHeight/_Point, 最小箱体波动微点);
        return false;
    }

    // 2. 自适应点差保护 (如果开关开启，才检查点差)
    double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
    double ratio = (boxHeight > 0) ? (currentSpread / boxHeight) : 999.0;
    if (ratio > 最大点差占比) {
        // if(启用诊断日志) PrintFormat("【过滤】点差占比过高(%.1f%% > %.1f%%)，放弃开仓", ratio*100, 最大点差占比*100);
        return false;
    }

    // 🔥 新增：智能入场过滤检查
    if(!CheckSmartEntryFilter(boxTop, boxBot)) {
        if(启用诊断日志) PrintFormat("【过滤】智能入场过滤未通过，放弃开仓");
        return false;
    }

    // 🔥 新增：箱体高度过滤检查
    if(!CheckBoxHeightFilter(boxHeight)) {
        if(启用诊断日志) PrintFormat("【过滤】箱体高度过滤未通过，放弃开仓");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| 检查量能过滤                                                     |
//+------------------------------------------------------------------+
bool CheckVolumeFilter()
{
    if(!启用量能过滤) return true;
    int barCount = 量能统计Bar数; 
    if(barCount < 1) barCount = 1;
    if(Bars(_Symbol, PERIOD_H1) <= barCount)
    {
        if(启用诊断日志) PrintFormat("CheckVolumeFilter: Not enough H1 bars (%d). Filter bypassed.", Bars(_Symbol, PERIOD_H1));
        return true; 
    }

    double sumVol = 0.0;
    long volArr[];
    // Get history volumes (from index 1 to barCount)
    if(CopyTickVolume(_Symbol, PERIOD_H1, 1, barCount, volArr) < barCount)
        return true; // Failed to copy
        
    for(int i = 0; i < ArraySize(volArr); i++) 
        sumVol += (double)volArr[i];
    double avgVol = (barCount > 0 ? sumVol / barCount : 0.0);
    // Get current volume (index 0)
    long curVolArr[1];
    if(CopyTickVolume(_Symbol, PERIOD_H1, 0, 1, curVolArr) < 1)
        return true;
        
    double curVol = (double)curVolArr[0];
    bool pass = (curVol >= avgVol * 量能放大倍数); 
    
    if(启用诊断日志)
    {
        if(pass) PrintFormat("Volume filter passed: CurVol H1=%.0f, AvgVol H1=%.0f (min %.0f required)", curVol, avgVol, avgVol * 量能放大倍数);
        else PrintFormat("Volume filter NOT passed: CurVol H1=%.0f, AvgVol H1=%.0f (min %.0f required)", curVol, avgVol, avgVol * 量能放大倍数);
    }
    return pass;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 🔥 新增：智能入场过滤（与TradingView策略一致）                      |
//+------------------------------------------------------------------+
bool CheckSmartEntryFilter(double boxTop, double boxBottom)
{
    if(!启用智能过滤) return true;

    // 1. 成交量过滤：当前成交量 >= 平均成交量 * 1.3
    long volArr[];
    if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, 20, volArr) < 20)
        return true; // 数据不足，放行

    double sumVol = 0.0;
    for(int i = 1; i < 20; i++) // 从索引1开始，排除当前K线
        sumVol += (double)volArr[i];
    double avgVolume = sumVol / 19.0;
    double currentVolume = (double)volArr[0];
    bool volumeOK = (currentVolume >= avgVolume * 最小成交量倍数);

    // 2. 箱体年龄过滤：箱体K线数 <= 30
    bool ageOK = (g_boxBars <= 最大箱体年龄K线数);

    // 3. 波动率过滤：ATR <= 价格 * 2%
    double atr = iATR(_Symbol, PERIOD_CURRENT, ATR周期);
    double avgPrice = (boxTop + boxBottom) / 2.0;
    bool volatilityOK = (atr <= avgPrice * (ATR波动率上限占比 / 100.0));

    bool pass = volumeOK && ageOK && volatilityOK;

    if(启用诊断日志)
    {
        PrintFormat("【智能入场过滤】成交量: %.0f >= %.0f (%s), 箱体年龄: %d <= %d (%s), 波动率: %.5f <= %.5f (%s) => %s",
                    currentVolume, avgVolume * 最小成交量倍数, volumeOK ? "✓" : "✗",
                    g_boxBars, 最大箱体年龄K线数, ageOK ? "✓" : "✗",
                    atr, avgPrice * (ATR波动率上限占比 / 100.0), volatilityOK ? "✓" : "✗",
                    pass ? "通过" : "拒绝");
    }

    return pass;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 🔥 新增：箱体高度过滤（与TradingView策略一致）                      |
//+------------------------------------------------------------------+
bool CheckBoxHeightFilter(double boxHeight)
{
    if(!启用箱体高度过滤) return true;

    // 计算箱体之前N根K线的平均高度
    double totalKlineHeight = 0.0;
    int validBars = 0;

    for(int i = 0; i < 高度过滤回溯K线数; i++)
    {
        int idx = g_boxBars + i; // 从箱体外开始
        if(idx >= Bars(_Symbol, PERIOD_CURRENT)) break;

        double high = iHigh(_Symbol, PERIOD_CURRENT, idx);
        double low = iLow(_Symbol, PERIOD_CURRENT, idx);
        double klineHeight = high - low;

        totalKlineHeight += klineHeight;
        validBars++;
    }

    if(validBars == 0) return true; // 数据不足，放行

    double avgKlineHeight = totalKlineHeight / validBars;
    double maxAllowedBoxHeight = avgKlineHeight * 箱体高度倍数限制;

    bool pass = (boxHeight < maxAllowedBoxHeight);

    if(启用诊断日志)
    {
        PrintFormat("【箱体高度过滤】箱体高度: %.5f < %.5f (平均K线高度 %.5f * %.1f) => %s",
                    boxHeight, maxAllowedBoxHeight, avgKlineHeight, 箱体高度倍数限制,
                    pass ? "通过" : "拒绝");
    }

    return pass;
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 【兜底】确保所有持仓单都在监控列表                                 |
//+------------------------------------------------------------------+
void EnsureAllOrdersTrailing()
{
    int total = PositionsTotal();
    for(int i = 0; i < total; i++)
    {
        if(g_Position.SelectByIndex(i))
        {
            if(g_Position.Symbol() == _Symbol && g_Position.Magic() == 魔术号)
            {
                ulong ticket = g_Position.Ticket();
                // 排除非Buy/Sell类型 (虽然PositionsTotal只包含持仓，但防御性编程)
                if(g_Position.PositionType() == POSITION_TYPE_BUY || g_Position.PositionType() == POSITION_TYPE_SELL)
                {
                    if(!IsOrderAllowTrailing(ticket))
                    {

                        AddTrailingTicket(ticket, true);
                        if(启用诊断日志) DiagPrint(StringFormat("【安全兜底】添加漏网持仓 #%d 到移损监控", ticket));
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| ======================== 背景时段可视化系统 ======================= |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| 初始化背景系统                                                   |
//+------------------------------------------------------------------+
void Bg_Initialize()
{
    g_bgInitialized = true;
    g_lastBgUpdate = 0;
    g_lastAlertCheck = 0;
    g_manualStartTime = 0;
    g_manualEndTime = 0;

    if(启用诊断日志)
        Print("【背景系统】初始化完成 - 时区偏移: 经纪商UTC+", Bg_UtcOffsetBroker,
              " 交易所UTC+", Bg_UtcOffsetSession);
}

//+------------------------------------------------------------------+
//| 解析手动时间设置                                                 |
//+------------------------------------------------------------------+
void Bg_ParseManualTimes()
{
    g_manualStartTime = 0;
    g_manualEndTime = 0;

    if(Bg_ManualStart != "" && Bg_ManualEnd != "")
    {
        // 解析手动开始时间
        string startParts[];
        if(StringSplit(Bg_ManualStart, ':', startParts) == 2)
        {
            int startHour = (int)StringToInteger(startParts[0]);
            int startMin = (int)StringToInteger(startParts[1]);
            if(startHour >= 0 && startHour <= 23 && startMin >= 0 && startMin <= 59)
            {
                g_manualStartTime = startHour * 3600 + startMin * 60;
            }
        }

        // 解析手动结束时间
        string endParts[];
        if(StringSplit(Bg_ManualEnd, ':', endParts) == 2)
        {
            int endHour = (int)StringToInteger(endParts[0]);
            int endMin = (int)StringToInteger(endParts[1]);
            if(endHour >= 0 && endHour <= 23 && endMin >= 0 && endMin <= 59)
            {
                g_manualEndTime = endHour * 3600 + endMin * 60;
            }
        }

        if(启用诊断日志 && g_manualStartTime > 0 && g_manualEndTime > 0)
            PrintFormat("【背景系统】手动时段设置: %s - %s", Bg_ManualStart, Bg_ManualEnd);
    }
}

//+------------------------------------------------------------------+
//| 主更新函数 - 绘制背景和分界线                                     |
//+------------------------------------------------------------------+
void Bg_UpdateBackground()
{
    if(!g_bgInitialized) return;

    // 清除旧对象
    Bg_DeleteAllObjects();

    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);

    // 计算今天和明天的日期
    datetime today = StructToTime(dt);
    dt.day += 1;
    datetime tomorrow = StructToTime(dt);

    // 绘制历史和当前时段
    Bg_DrawSessionBackground(today, false);    // 今天的历史和当前
    Bg_DrawSessionBackground(tomorrow, true);  // 明天的预览（如果启用）

    // 绘制未来天数的预览
    if(Bg_DrawFutureDays > 1)
    {
        for(int i = 2; i <= Bg_DrawFutureDays; i++)
        {
            dt.day += 1;
            datetime futureDay = StructToTime(dt);
            Bg_DrawSessionBackground(futureDay, true);
        }
    }
}

//+------------------------------------------------------------------+
//| 绘制单日交易时段背景                                             |
//+------------------------------------------------------------------+
void Bg_DrawSessionBackground(datetime date, bool isPreview)
{
    MqlDateTime dt;
    TimeToStruct(date, dt);

    // 如果是预览且未启用预览，直接返回
    if(isPreview && Bg_DrawFutureDays == 0) return;

    // 计算时段边界（考虑时区转换）
    datetime sessionStart, sessionEnd, preStart, coolDownEnd;

    if(g_manualStartTime > 0 && g_manualEndTime > 0)
    {
        // 使用手动设置的时间
        sessionStart = date + (int)g_manualStartTime;
        sessionEnd = date + (int)g_manualEndTime;
    }
    else
    {
        // 使用EA的交易时间窗口（这里简化处理，实际应该解析TradeTime参数）
        // 这里暂时使用默认时段作为示例
        sessionStart = date + 9 * 3600;  // 默认9:00开始
        sessionEnd = date + 17 * 3600;   // 默认17:00结束
    }

    // 计算预备期和冷却期（各30分钟）
    preStart = sessionStart - 30 * 60;
    coolDownEnd = sessionEnd + 30 * 60;

    // 绘制预备期背景
    if(Bg_ShowBackground)
        Bg_DrawRectangle(preStart, sessionStart, Bg_PreSessionColor, "Bg_Pre_" + TimeToString(date, TIME_DATE));

    // 绘制活跃期背景
    if(Bg_ShowBackground)
        Bg_DrawRectangle(sessionStart, sessionEnd, Bg_ActiveSessionColor, "Bg_Active_" + TimeToString(date, TIME_DATE));

    // 绘制冷却期背景
    if(Bg_ShowBackground)
        Bg_DrawRectangle(sessionEnd, coolDownEnd, Bg_CoolDownColor, "Bg_Cool_" + TimeToString(date, TIME_DATE));

    // 绘制垂直分界线
    if(Bg_ShowVerticalLine)
    {
        Bg_DrawVerticalLine(sessionStart, Bg_LineColor, "Bg_Line_Start_" + TimeToString(date, TIME_DATE));
        Bg_DrawVerticalLine(sessionEnd, Bg_LineColor, "Bg_Line_End_" + TimeToString(date, TIME_DATE));
    }
}

//+------------------------------------------------------------------+
//| 绘制矩形背景                                                     |
//+------------------------------------------------------------------+
void Bg_DrawRectangle(datetime startTime, datetime endTime, color bgColor, string objName)
{
    if(ObjectFind(0, objName) >= 0) ObjectDelete(0, objName);

    if(!ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, startTime, 0))
        return;

    // 设置矩形属性
    ObjectSetInteger(0, objName, OBJPROP_TIME, 0, startTime);
    ObjectSetInteger(0, objName, OBJPROP_TIME, 1, endTime);
    ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, SymbolInfoDouble(_Symbol, SYMBOL_BID));
    ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, SymbolInfoDouble(_Symbol, SYMBOL_BID));
    ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, Bg_ApplyTransparency(bgColor));
    ObjectSetInteger(0, objName, OBJPROP_BACK, true);
    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| 绘制垂直线                                                       |
//+------------------------------------------------------------------+
void Bg_DrawVerticalLine(datetime time, color lineColor, string objName)
{
    if(ObjectFind(0, objName) >= 0) ObjectDelete(0, objName);

    if(!ObjectCreate(0, objName, OBJ_VLINE, 0, time, 0))
        return;

    ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_BACK, true);
    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| 应用透明度                                                       |
//+------------------------------------------------------------------+
color Bg_ApplyTransparency(color baseColor)
{
    // MT5中透明度通过alpha通道实现
    // 这里简化处理，根据Bg_BackgroundAlpha设置透明度
    int alpha = (int)(255 * (11 - Bg_BackgroundAlpha) / 10.0); // 1级最透明，10级最不透明
    if(alpha < 0) alpha = 0;
    if(alpha > 255) alpha = 255;

    // 提取RGB分量并应用alpha
    int r = (baseColor & 0xFF0000) >> 16;
    int g = (baseColor & 0x00FF00) >> 8;
    int b = baseColor & 0x0000FF;

    return (color)((alpha << 24) | (r << 16) | (g << 8) | b);
}

//+------------------------------------------------------------------+
//| 清除所有背景对象                                                 |
//+------------------------------------------------------------------+
void Bg_DeleteAllObjects()
{
    ObjectsDeleteAll(0, "Bg_");
}

//+------------------------------------------------------------------+
//| 检查提前提醒                                                     |
//+------------------------------------------------------------------+
void Bg_CheckPreSessionAlert()
{
    if(Bg_AlertMinutes <= 0) return;

    datetime currentTime = TimeCurrent();
    if(currentTime - g_lastAlertCheck < 60) return; // 每分钟检查一次
    g_lastAlertCheck = currentTime;

    // 计算下个交易时段开始时间
    datetime nextSessionStart = Bg_GetNextSessionStart();
    if(nextSessionStart == 0) return;

    // 检查是否在提醒时间范围内
    int secondsToStart = (int)(nextSessionStart - currentTime);
    int alertSeconds = Bg_AlertMinutes * 60;

    if(secondsToStart > 0 && secondsToStart <= alertSeconds)
    {
        // 触发提醒（只提醒一次）
        static datetime lastAlertTime = 0;
        if(currentTime - lastAlertTime > alertSeconds) // 防止重复提醒
        {
            string message = StringFormat("交易时段将在%d分钟后开始!", Bg_AlertMinutes);
            Alert(message);
            Print("[背景提醒] ", message);
            MessageBox(message, "交易时段提醒", MB_OK | MB_ICONINFORMATION);
            lastAlertTime = currentTime;
        }
    }
}

//+------------------------------------------------------------------+
//| 获取下个交易时段开始时间                                         |
//+------------------------------------------------------------------+
datetime Bg_GetNextSessionStart()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);

    // 计算今天和明天的时段
    datetime candidates[2];
    candidates[0] = Bg_GetSessionStartForDate(StructToTime(dt));        // 今天
    dt.day += 1;
    candidates[1] = Bg_GetSessionStartForDate(StructToTime(dt));        // 明天

    // 找到最近的未来时段
    for(int i = 0; i < ArraySize(candidates); i++)
    {
        if(candidates[i] > currentTime)
            return candidates[i];
    }

    return 0;
}

//+------------------------------------------------------------------+
//| 获取指定日期的交易时段开始时间                                   |
//+------------------------------------------------------------------+
datetime Bg_GetSessionStartForDate(datetime date)
{
    if(g_manualStartTime > 0)
        return date + (int)g_manualStartTime;

    // 这里可以扩展为解析EA的TradeTime参数
    // 暂时返回默认时间
    return date + 9 * 3600; // 默认9:00
}

