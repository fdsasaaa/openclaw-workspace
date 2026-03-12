"""
粗筛规则 - 快速排除明显不适合交易的市场环境
"""

from datetime import datetime, time
from typing import Dict, Optional

class CoarseFilter:
    def __init__(self, config: Optional[Dict] = None):
        """
        初始化粗筛规则
        
        参数:
            config: 配置参数字典
        """
        self.config = config or {}
        
        # 默认参数
        self.atr_min_ratio = self.config.get('atr_min_ratio', 0.5)
        self.atr_max_ratio = self.config.get('atr_max_ratio', 2.0)
        self.volume_min_ratio = self.config.get('volume_min_ratio', 0.7)
    
    def filter(self, market_data: Dict) -> str:
        """
        应用粗筛规则
        
        参数:
            market_data: 市场数据字典
                - ma20: 20 周期移动平均线
                - ma50: 50 周期移动平均线
                - atr: 当前 ATR
                - atr_avg: ATR 平均值
                - volume: 当前成交量
                - volume_avg: 成交量平均值
                - timestamp: 时间戳
        
        返回:
            决策结果: LONG_ONLY / SHORT_ONLY / BOTH / NONE
        """
        # 1. 趋势过滤
        trend_result = self._trend_filter(market_data)
        
        # 2. 波动率过滤
        if not self._volatility_filter(market_data):
            return "NONE"
        
        # 3. 成交量过滤
        if not self._volume_filter(market_data):
            return "NONE"
        
        # 4. 时间过滤
        if not self._time_filter(market_data):
            return "NONE"
        
        return trend_result
    
    def _trend_filter(self, market_data: Dict) -> str:
        """
        趋势过滤
        
        逻辑:
            - MA20 > MA50 → 上升趋势 → LONG_ONLY
            - MA20 < MA50 → 下降趋势 → SHORT_ONLY
            - 趋势不明确 → BOTH
        """
        ma20 = market_data.get('ma20')
        ma50 = market_data.get('ma50')
        
        if ma20 is None or ma50 is None:
            return "BOTH"  # 数据不足，允许双边
        
        # 计算趋势强度（MA 差值占价格的百分比）
        price = market_data.get('close', market_data.get('price', 0))
        if price == 0:
            return "BOTH"
        
        trend_strength = abs(ma20 - ma50) / price
        
        # 如果趋势强度 < 0.1%，认为趋势不明确
        if trend_strength < 0.001:
            return "BOTH"
        
        if ma20 > ma50:
            return "LONG_ONLY"
        elif ma20 < ma50:
            return "SHORT_ONLY"
        else:
            return "BOTH"
    
    def _volatility_filter(self, market_data: Dict) -> bool:
        """
        波动率过滤
        
        逻辑:
            - ATR 过小（< 平均值 * 0.5）→ 拒绝
            - ATR 过大（> 平均值 * 2.0）→ 拒绝
        
        返回:
            True: 通过过滤
            False: 拒绝
        """
        atr = market_data.get('atr')
        atr_avg = market_data.get('atr_avg')
        
        if atr is None or atr_avg is None or atr_avg == 0:
            return True  # 数据不足，默认通过
        
        # 检查 ATR 是否在合理范围内
        if atr < atr_avg * self.atr_min_ratio:
            return False  # 波动率过小
        
        if atr > atr_avg * self.atr_max_ratio:
            return False  # 波动率过大
        
        return True
    
    def _volume_filter(self, market_data: Dict) -> bool:
        """
        成交量过滤
        
        逻辑:
            - Volume < 平均值 * 0.7 → 拒绝
        
        返回:
            True: 通过过滤
            False: 拒绝
        """
        volume = market_data.get('volume')
        volume_avg = market_data.get('volume_avg')
        
        if volume is None or volume_avg is None or volume_avg == 0:
            return True  # 数据不足，默认通过
        
        # 检查成交量是否足够
        if volume < volume_avg * self.volume_min_ratio:
            return False  # 成交量过小
        
        return True
    
    def _time_filter(self, market_data: Dict) -> bool:
        """
        时间过滤
        
        逻辑:
            - 周末 → 拒绝
            - 重大新闻时段 → 拒绝（待实现）
        
        返回:
            True: 通过过滤
            False: 拒绝
        """
        timestamp = market_data.get('timestamp')
        
        if timestamp is None:
            return True  # 数据不足，默认通过
        
        # 转换为 datetime
        if isinstance(timestamp, (int, float)):
            dt = datetime.fromtimestamp(timestamp)
        elif isinstance(timestamp, datetime):
            dt = timestamp
        else:
            return True  # 无法解析，默认通过
        
        # 检查是否是周末
        if dt.weekday() >= 5:  # 5=周六, 6=周日
            return False
        
        # TODO: 检查是否是重大新闻时段
        # 需要接入新闻日历 API
        
        return True
    
    def get_reason(self, market_data: Dict) -> str:
        """
        获取过滤原因（用于日志）
        
        返回:
            原因描述
        """
        reasons = []
        
        # 趋势
        trend = self._trend_filter(market_data)
        if trend == "LONG_ONLY":
            reasons.append("上升趋势")
        elif trend == "SHORT_ONLY":
            reasons.append("下降趋势")
        else:
            reasons.append("趋势不明确")
        
        # 波动率
        if not self._volatility_filter(market_data):
            atr = market_data.get('atr', 0)
            atr_avg = market_data.get('atr_avg', 0)
            if atr < atr_avg * self.atr_min_ratio:
                reasons.append("波动率过小")
            else:
                reasons.append("波动率过大")
        
        # 成交量
        if not self._volume_filter(market_data):
            reasons.append("成交量不足")
        
        # 时间
        if not self._time_filter(market_data):
            reasons.append("不适合交易时段")
        
        return ", ".join(reasons)

# 测试代码
if __name__ == "__main__":
    filter = CoarseFilter()
    
    # 测试案例 1：上升趋势，波动率正常
    test_data_1 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0016,
        'atr_avg': 0.0015,
        'volume': 1000,
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp()
    }
    
    result_1 = filter.filter(test_data_1)
    reason_1 = filter.get_reason(test_data_1)
    print(f"测试 1: {result_1} - {reason_1}")
    
    # 测试案例 2：波动率过小
    test_data_2 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0005,  # 过小
        'atr_avg': 0.0015,
        'volume': 1000,
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp()
    }
    
    result_2 = filter.filter(test_data_2)
    reason_2 = filter.get_reason(test_data_2)
    print(f"测试 2: {result_2} - {reason_2}")
    
    # 测试案例 3：成交量不足
    test_data_3 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0016,
        'atr_avg': 0.0015,
        'volume': 500,  # 过小
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp()
    }
    
    result_3 = filter.filter(test_data_3)
    reason_3 = filter.get_reason(test_data_3)
    print(f"测试 3: {result_3} - {reason_3}")
    
    print("\n粗筛规则测试完成")
