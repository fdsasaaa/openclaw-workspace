//+------------------------------------------------------------------+
//|                                              HQBox_Indicator.mq5 |
//|                                   Based on HQBox Strategy v18.26 |
//|                                      Converted for MT5 by Gemini |
//|                                      Mode: Final Visual Polish   |
//+------------------------------------------------------------------+
#property copyright "HQBox_Optimized_Final"
#property version   "2.03"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

// ══════════════════════════════════════════════════════════════════════════════
// 1. 参数设置
// ══════════════════════════════════════════════════════════════════════════════
input group "=== 核心策略参数 ==="
input int      InpMinDisplayScore = 20;    // [统一] 合格评分阈值
input int      InpTriggerMinBars  = 1;     // 最小K线数量限制
input int      InpDarvasMode      = 3;     // Darvas模式 (3=High/Low)

input group "=== 内部算法参数 ==="
input int      InpPivotStrength   = 2;     // Pivot Strength
input int      InpMinBars         = 5;     // 最小箱体宽度
input int      InpIdealBarsMin    = 15;    // 理想最小K线
input int      InpIdealBarsMax    = 120;   // 理想最大K线
input double   InpMaxBoxATR       = 2.0;   // ATR 阈值
input double   InpMaxBoxATRHard   = 2.5;   // 硬性 ATR 阈值
input double   InpSpikeThreshold  = 0.35;  // 刺透阈值
input double   InpMaxSpikeRatio   = 0.25;  // 最大刺透比例

input group "=== 时间限制 (00:00-00:00无限制) ==="
input int      InpStratStartHour  = 0;     // 开始小时
input int      InpStratStartMin   = 0;     // 开始分钟
input int      InpStratEndHour    = 0;     // 结束小时
input int      InpStratEndMin     = 0;     // 结束分钟

input group "=== 评分权重 ==="
input double   w_flatness      = 0.25;
input double   w_independence  = 0.20;
input double   w_smoothness    = 0.12;
input double   w_space         = 0.13;
input double   w_volume        = 0.12;
input double   w_time          = 0.10;
input double   w_micro         = 0.08;

input group "=== 视觉颜色 ==="
input color    ColorLevel1     = clrGray;          // < 50 分
input color    ColorLevel2     = C'135,206,250';   // >= 50 分 (LightSkyBlue)
input color    ColorLevel3     = clrYellow;        // >= 60 分
input color    ColorLevel4     = clrMagenta;       // >= 70 分

// ══════════════════════════════════════════════════════════════════════════════
// 全局状态变量
// ══════════════════════════════════════════════════════════════════════════════
int    handleATR;

struct StrategyState {
    int    startState;      // 0:Idle, 1:FoundTop, -1:FoundBtm
    int    confirmState;    // 0:Waiting, 1:Confirmed
    double boxTop_v;        // 暂存Top
    double boxBottom_v;     // 暂存Bottom
    datetime boxStartTime;  // 箱体开始时间
    
    // 当前活跃箱体信息
    bool   box_active;      // 对应 TV stratState != 0
    double box_top;
    double box_bottom;
    int    box_start_idx;   
    string currentObjName;  
};

StrategyState g_state; 

// ══════════════════════════════════════════════════════════════════════════════
// 前向声明
// ══════════════════════════════════════════════════════════════════════════════
double GetDarvasPrice(int index, bool isHigh, const double &high[], const double &low[], const double &close[]);
double GetDarvasPivot(int index, bool isHigh, const double &high[], const double &low[], const double &close[]);
double CalculateR2(const double &price[], int startIdx, int count); 
bool   IsTimeValid(datetime dt);
void   UpdateBoxVisuals(int i, int bars_count, double top, double bottom, double score, string name, const datetime &time[]);
string GetPeriodShortName(); // [新增] 获取周期简写

// 评分函数声明
double ScoreFlatness(double aspectRatio, double heightATR);
double ScoreIndependence(int touchesTop, int touchesBtm, double top, double btm, double height, const double &high[], const double &low[], int startIdx, int count);
double ScoreSmoothness(double topR2, double btmR2, double spikeRatio);
double ScoreSpace(double atr, double height);
double ScoreVolume(const long &vol[], int currentVolIdx, int startIdx, int count);
double ScoreTime(int bars);
double ScoreMicro(double spikeRatio, int bars, int touchesTop, int touchesBtm, double topR2, double btmR2);


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    handleATR = iATR(_Symbol, _Period, 14);
    if(handleATR == INVALID_HANDLE) return(INIT_FAILED);
    ResetState();
    return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    // [修正] 根据新的命名格式进行清理
    // 格式：[M15] Rectangle ...
    string prefix = "[" + GetPeriodShortName() + "] Rectangle";
    ObjectsDeleteAll(0, prefix);
    
    // 为了保险，也可以清理旧版名称 (开发过程中的残留)
    ObjectsDeleteAll(0, "HQBox_");
    
    IndicatorRelease(handleATR);
}

void ResetState() {
    g_state.startState = 0;
    g_state.confirmState = 0;
    g_state.boxTop_v = 0;
    g_state.boxBottom_v = 0;
    g_state.boxStartTime = 0;
    g_state.box_active = false;
    g_state.box_top = 0;
    g_state.box_bottom = 0;
    g_state.box_start_idx = 0;
    g_state.currentObjName = "";
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if(rates_total < InpIdealBarsMax + 20) return 0;

    // 1. 设置为正序 (0=最旧, rates_total-1=最新)
    ArraySetAsSeries(time, false);
    ArraySetAsSeries(open, false);
    ArraySetAsSeries(high, false);
    ArraySetAsSeries(low, false);
    ArraySetAsSeries(close, false);
    ArraySetAsSeries(tick_volume, false);

    double atrArr[];
    ArraySetAsSeries(atrArr, false); 
    if(CopyBuffer(handleATR, 0, 0, rates_total, atrArr) <= 0) return 0;

    int start_i = prev_calculated;
    if(prev_calculated == 0) {
        ResetState();
        // 清理当前周期的所有相关对象
        string prefix = "[" + GetPeriodShortName() + "] Rectangle";
        ObjectsDeleteAll(0, prefix);
        start_i = InpIdealBarsMax; 
    } else {
        start_i = prev_calculated - 1;
    }

    // ==========================================================================
    // 核心状态机循环 (Forward Loop)
    // ==========================================================================
    for(int i = start_i; i < rates_total; i++)
    {
        // 基础数据
        double hiPrice = GetDarvasPrice(i, true, high, low, close);
        double loPrice = GetDarvasPrice(i, false, high, low, close);
        
        // Pivot 检测
        double upPivot = GetDarvasPivot(i, true, high, low, close);
        double loPivot = GetDarvasPivot(i, false, high, low, close);
        
        datetime pivotTime = 0;
        if (i - InpPivotStrength >= 0) pivotTime = time[i - InpPivotStrength];

        // ---------------------------------------------------
        // 状态机逻辑
        // ---------------------------------------------------
        
        if (!g_state.box_active) 
        {
            // --- 状态 0: 寻找第一个 Pivot ---
            if (g_state.startState == 0) {
                if (InpDarvasMode < 2 && upPivot > 0) {
                    g_state.boxTop_v = upPivot;
                    g_state.startState = 1;
                    g_state.boxStartTime = pivotTime;
                } 
                else if (InpDarvasMode >= 2) {
                    if (upPivot > 0) {
                        g_state.boxTop_v = upPivot;
                        g_state.startState = 1;
                        g_state.boxStartTime = pivotTime;
                    } else if (loPivot > 0) {
                        g_state.boxBottom_v = loPivot;
                        g_state.startState = -1;
                        g_state.boxStartTime = pivotTime;
                    }
                }
            }

            // --- 状态 1/-1: 等待第二个相反 Pivot 确认 ---
            if (g_state.startState != 0 && g_state.confirmState == 0) {
                if (g_state.startState > 0 && loPivot > 0 && time[i] > g_state.boxStartTime) {
                    g_state.confirmState = 1;
                    g_state.boxBottom_v = loPivot;
                }
                else if (g_state.startState < 0 && upPivot > 0 && time[i] > g_state.boxStartTime) {
                    g_state.confirmState = 1;
                    g_state.boxTop_v = upPivot;
                }
            }

            // --- 确认形成新箱体 ---
            if (g_state.startState != 0 && g_state.confirmState != 0) {
                double tempTop = MathMax(g_state.boxTop_v, g_state.boxBottom_v);
                double tempBtm = MathMin(g_state.boxTop_v, g_state.boxBottom_v);
                
                bool valid = (tempTop > tempBtm) && (tempTop > 0) && (tempBtm > 0);
                double height = tempTop - tempBtm;
                if (height < SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 5) valid = false;

                if (!IsTimeValid(time[i])) valid = false;

                if (valid) {
                    g_state.box_active = true;
                    g_state.box_top = tempTop;
                    g_state.box_bottom = tempBtm;
                    
                    int bars = 0;
                    for(int k=0; k<InpIdealBarsMax; k++) {
                        int idx = i - k;
                        if (idx < 0) break;
                        bool isInside = (high[idx] <= tempTop + height*0.05) && (low[idx] >= tempBtm - height*0.05);
                        if (k==0 || isInside) bars++;
                        else break;
                    }
                    bars = MathMax(InpMinBars, bars);
                    g_state.box_start_idx = i - bars + 1; 
                    
                    // 【修正】生成新的对象名称格式：[周期前缀] Rectangle [时间字符串]_Rect
                    string periodStr = GetPeriodShortName();
                    string timeStr   = TimeToString(time[i], TIME_DATE|TIME_MINUTES); // 格式：yyyy.mm.dd hh:mi
                    g_state.currentObjName = StringFormat("[%s] Rectangle [%s]_Rect", periodStr, timeStr);
                    
                } else {
                    g_state.startState = 0;
                    g_state.confirmState = 0;
                    g_state.boxTop_v = 0;
                    g_state.boxBottom_v = 0;
                }
            }
        }

        // ---------------------------------------------------
        // 活跃箱体监控与绘制
        // ---------------------------------------------------
        if (g_state.box_active) {
            double bh = g_state.box_top - g_state.box_bottom;
            bool broken = false;
            
            if (hiPrice > g_state.box_top || loPrice < g_state.box_bottom) {
                broken = true;
            }

            int current_bars = i - g_state.box_start_idx + 1;
            
            int touchesTop = 0;
            int touchesBtm = 0;
            int spikes = 0;
            
            for(int k=0; k < current_bars; k++) {
                int idx = g_state.box_start_idx + k;
                if(idx > i) break;
                
                if(MathAbs(high[idx] - g_state.box_top) < bh * 0.05) touchesTop++;
                if(MathAbs(low[idx] - g_state.box_bottom) < bh * 0.05) touchesBtm++;
                if(high[idx] > g_state.box_top + bh * InpSpikeThreshold || low[idx] < g_state.box_bottom - bh * InpSpikeThreshold) spikes++;
            }
            
            double spikeRatio = (double)spikes / (double)MathMax(1, current_bars);
            double topR2 = CalculateR2(high, g_state.box_start_idx, current_bars); 
            double btmR2 = CalculateR2(low, g_state.box_start_idx, current_bars);

            double currentATR = atrArr[i];
            if(currentATR == 0) currentATR = bh * 0.5;
            double safeATR = (currentATR > 0) ? currentATR : bh * 0.5;

            // 评分
            double qual_flatness     = ScoreFlatness((double)current_bars/bh, bh/safeATR);
            double qual_independence = ScoreIndependence(touchesTop, touchesBtm, g_state.box_top, g_state.box_bottom, bh, high, low, g_state.box_start_idx, current_bars);
            double qual_smoothness   = ScoreSmoothness(topR2, btmR2, spikeRatio);
            double qual_space        = ScoreSpace(safeATR, bh);
            double qual_volume       = ScoreVolume(tick_volume, i, g_state.box_start_idx, current_bars);
            double qual_time         = ScoreTime(current_bars);
            double qual_micro        = ScoreMicro(spikeRatio, current_bars, touchesTop, touchesBtm, topR2, btmR2);
            
            double totalScore = qual_flatness * w_flatness + 
                                qual_independence * w_independence + 
                                qual_smoothness * w_smoothness + 
                                qual_space * w_space + 
                                qual_volume * w_volume + 
                                qual_time * w_time + 
                                qual_micro * w_micro;

            // 绘制/更新箱体 (分数和长度达标才绘制)
            if (totalScore >= InpMinDisplayScore && current_bars >= InpTriggerMinBars) {
                // 如果分数达标，UpdateBoxVisuals 会使用上面生成的 currentObjName 进行绘制
                UpdateBoxVisuals(i, current_bars, g_state.box_top, g_state.box_bottom, totalScore, g_state.currentObjName, time);
            }

            if (broken) {
                g_state.box_active = false;
                g_state.startState = 0;
                g_state.confirmState = 0;
                g_state.boxTop_v = 0;
                g_state.boxBottom_v = 0;
            }
        }
    }

    return(rates_total);
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. 核心算法函数
// ══════════════════════════════════════════════════════════════════════════════

// [新增] 获取周期简写字符串
string GetPeriodShortName() {
    string p = EnumToString(_Period);
    // EnumToString 返回 "PERIOD_M15", 我们去掉 "PERIOD_"
    if(StringFind(p, "PERIOD_") == 0) {
        return StringSubstr(p, 7);
    }
    return p;
}

double GetDarvasPrice(int index, bool isHigh, const double &high[], const double &low[], const double &close[]) {
    if (InpDarvasMode == 0 || InpDarvasMode == 2 || InpDarvasMode == 4) {
        return isHigh ? high[index] : low[index];
    } else {
        return close[index];
    }
}

double GetDarvasPivot(int index, bool isHigh, const double &high[], const double &low[], const double &close[]) {
    int pStr = InpPivotStrength;
    int length = pStr + 2;
    int pivotIdx = index - pStr;
    if (pivotIdx < 0) return 0.0; 

    double pivotVal = isHigh ? high[pivotIdx] : low[pivotIdx];
    
    bool isPivot = true;
    for(int k=0; k < length; k++) {
        int checkIdx = index - k;
        if (checkIdx < 0) continue;
        
        double checkVal = isHigh ? high[checkIdx] : low[checkIdx];
        
        if (isHigh) {
            if (checkVal > pivotVal) { isPivot = false; break; }
        } else {
            if (checkVal < pivotVal) { isPivot = false; break; }
        }
    }
    return isPivot ? pivotVal : 0.0;
}

void UpdateBoxVisuals(int i, int bars_count, double top, double bottom, double score, string name, const datetime &timeArr[]) {
    color baseColor = ColorLevel1;
    int width = 1;
    if(score >= 70) { baseColor = ColorLevel4; width = 2; }
    else if(score >= 60) { baseColor = ColorLevel3; width = 3; }
    else if(score >= 50) { baseColor = ColorLevel2; width = 1; }
    
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
    }
    
    int start_idx = i - bars_count + 1;
    
    ObjectSetInteger(0, name, OBJPROP_TIME, 0, timeArr[start_idx]);
    ObjectSetDouble(0, name, OBJPROP_PRICE, 0, top);
    ObjectSetInteger(0, name, OBJPROP_TIME, 1, timeArr[i]); 
    ObjectSetDouble(0, name, OBJPROP_PRICE, 1, bottom);
    
    ObjectSetInteger(0, name, OBJPROP_COLOR, baseColor);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_FILL, true);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    
    string lblName = name + "_lbl";
    if(ObjectFind(0, lblName) < 0) ObjectCreate(0, lblName, OBJ_TEXT, 0, 0, 0);
    
    ObjectSetInteger(0, lblName, OBJPROP_TIME, timeArr[i]); 
    ObjectSetDouble(0, lblName, OBJPROP_PRICE, top);
    ObjectSetString(0, lblName, OBJPROP_TEXT, DoubleToString(score, 0));
    ObjectSetInteger(0, lblName, OBJPROP_COLOR, baseColor);
    ObjectSetInteger(0, lblName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
}

double CalculateR2(const double &price[], int startIdx, int count) {
    if(count <= 2) return 0.5;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    for(int k = 0; k < count; k++) {
        double x = (double)k;
        double y = price[startIdx + k]; 
        sumX += x; sumY += y; sumXY += x * y; sumX2 += x * x; sumY2 += y * y;
    }
    double n = (double)count;
    double val = (n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY);
    double denom = MathSqrt(MathAbs(val));
    if(denom < 0.0001) return 0.0;
    return ((n * sumXY - sumX * sumY) / denom) * ((n * sumXY - sumX * sumY) / denom);
}

bool IsTimeValid(datetime dt) {
    if(InpStratStartHour == 0 && InpStratStartMin == 0 && InpStratEndHour == 0 && InpStratEndMin == 0) return true;
    MqlDateTime mdt; TimeToStruct(dt, mdt);
    int cur = mdt.hour * 60 + mdt.min;
    int st = InpStratStartHour * 60 + InpStratStartMin;
    int ed = InpStratEndHour * 60 + InpStratEndMin;
    if(st <= ed) return (cur >= st && cur < ed);
    else return (cur >= st || cur < ed);
}

double ScoreFlatness(double aspectRatio, double heightATR) {
    double score = 0.0;
    double AspectTarget = 4.5;
    double MinAspect = 2.5;
    if (aspectRatio >= AspectTarget) score += 60;
    else if (aspectRatio >= MinAspect) {
        score += 35 + ((aspectRatio - MinAspect) / (AspectTarget - MinAspect)) * 25;
    } else if (aspectRatio >= MinAspect * 0.7) {
        score += (aspectRatio / MinAspect) * 25;
    } else score += 10;
    double tightTarget = 1.2;
    if (heightATR <= tightTarget) score += 40;
    else if (heightATR <= InpMaxBoxATR) {
        score += 20 + (1.0 - (heightATR - tightTarget) / (InpMaxBoxATR - tightTarget)) * 20;
    } else if (heightATR <= InpMaxBoxATRHard) {
        score += (1.0 - (heightATR - InpMaxBoxATR) / (InpMaxBoxATRHard - InpMaxBoxATR)) * 20;
    }
    if (heightATR > 2.0) score *= 0.75;
    return MathMin(100.0, score);
}

double ScoreIndependence(int touchesTop, int touchesBtm, double top, double btm, double height, const double &high[], const double &low[], int startIdx, int count) {
    double score = 100.0;
    if (touchesTop < 2 || touchesTop > 8) score -= 15;
    if (touchesBtm < 2 || touchesBtm > 8) score -= 15;
    int lookBack = 10;
    int overlapCount = 0;
    double buffer = height * 0.3; 
    for(int k = 0; k < lookBack; k++) {
        int idx = startIdx + 1 + k; 
        if(idx >= startIdx + count) break;
        double midPrice = (high[idx] + low[idx]) / 2.0;
        double barRange = high[idx] - low[idx];
        bool priceOverlap = midPrice < (top + buffer) && midPrice > (btm - buffer);
        bool isFlat = barRange < height * 1.2;
        if (priceOverlap && isFlat) overlapCount++;
    }
    if (overlapCount > 6) score -= 40;
    else if (overlapCount > 4) score -= 25;
    else if (overlapCount > 2) score -= 10;
    else score += 15;
    return MathMax(0.0, MathMin(100.0, score));
}

double ScoreSmoothness(double topR2, double btmR2, double spikeRatio) {
    double avgR2 = (topR2 + btmR2) / 2.0;
    double score = 0.0;
    if (avgR2 >= 0.5) score = 80 + (avgR2 - 0.5) * 40;
    else if (avgR2 >= 0.2) score = 40 + (avgR2 - 0.2) * 133.33;
    else score = avgR2 * 400;
    score -= spikeRatio * 30;
    return MathMax(0.0, MathMin(100.0, score));
}

double ScoreSpace(double atr, double height) {
    double safeHeight = (height <= 0) ? atr : height;
    double ratio = (3 * atr) / safeHeight;
    double score = 0.0;
    if (ratio >= 3) score = 100;
    else if (ratio >= 2) score = 70 + (ratio - 2) * 30;
    else if (ratio >= 1) score = 30 + (ratio - 1) * 40;
    else score = ratio * 30;
    return score;
}

double ScoreVolume(const long &vol[], int currentVolIdx, int startIdx, int count) {
    double totalVol = 0;
    for(int k = 0; k < count; k++) totalVol += (double)vol[startIdx + k];
    if(count == 0) return 50.0;
    double avgVol = totalVol / count;
    double currentVol = (double)vol[currentVolIdx]; 
    if(avgVol == 0) return 50.0;
    double ratio = currentVol / avgVol;
    if (ratio >= 1.5) return 100.0;
    else if (ratio >= 1.0) return 50 + (ratio - 1.0) / 0.5 * 50;
    else return ratio * 50;
}

double ScoreTime(int bars) {
    if (bars >= InpIdealBarsMin && bars <= InpIdealBarsMax) return 100.0;
    else if (bars < InpIdealBarsMin) return ((double)bars / InpIdealBarsMin) * 70;
    else return MathMax(30.0, 100 - (double)(bars - InpIdealBarsMax) / 2);
}

double ScoreMicro(double spikeRatio, int bars, int touchesTop, int touchesBtm, double topR2, double btmR2) {
    double score = 70.0;
    double effRatio = spikeRatio;
    if (bars < 8) effRatio *= 0.5;
    if (effRatio > InpMaxSpikeRatio) score -= (effRatio - InpMaxSpikeRatio) * 100;
    score -= MathAbs(touchesTop - touchesBtm) * 5;
    if (bars <= 6 && (topR2 > 0.8 || btmR2 > 0.8)) score += 15;
    return MathMax(0.0, MathMin(100.0, score));
}
//+------------------------------------------------------------------+
