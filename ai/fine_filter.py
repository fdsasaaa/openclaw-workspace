"""
精筛规则 - 在粗筛基础上细致优化
"""

from typing import Dict, Optional

class FineFilter:
    def __init__(self, config: Optional[Dict] = None):
        """
        初始化精筛规则
        
        参数:
            config: 配置参数字典
        """
        self.config = config or {}
        
        # 默认参数
        self.rsi_overbought = self.config.get('rsi_overbought', 70)
        self.rsi_oversold = self.config.get('rsi_oversold', 30)
        self.min_box_score = self.config.get('min_box_score', 80)
        self.price_position_threshold = self.config.get('price_position_threshold', 0.2)
    
    def filter(self, market_data: Dict, coarse_result: str) -> str:
        """
        应用精筛规则
        
        参数:
            market_data: 市场数据字典
                - rsi: RSI 指标
                - box_score: 箱体评分
                - price: 当前价格
                - box_upper: 箱体上边界
                - box_lower: 箱体下边界
            coarse_result: 粗筛结果
        
        返回:
            决策结果: LONG_ONLY / SHORT_ONLY / BOTH / NONE
        """
        # 如果粗筛已拒绝，直接返回
        if coarse_result == "NONE":
            return "NONE"
        
        # 1. 箱体质量过滤
        if not self._box_quality_filter(market_data):
            return "NONE"
        
        # 2. RSI 超买超卖过滤
        rsi_result = self._rsi_filter(market_data)
        if rsi_result != "BOTH":
            return rsi_result
        
        # 3. 价格位置过滤
        price_result = self._price_position_filter(market_data)
        if price_result != "BOTH":
            return price_result
        
        # 所有精筛规则通过，返回粗筛结果
        return coarse_result
    
    def _box_quality_filter(self, market_data: Dict) -> bool:
        """
        箱体质量过滤
        
        逻辑:
            - 箱体评分 < 80 → 拒绝
        
        返回:
            True: 通过过滤
            False: 拒绝
        """
        box_score = market_data.get('box_score')
        
        if box_score is None:
            return True  # 数据不足，默认通过
        
        if box_score < self.min_box_score:
            return False  # 箱体质量不足
        
        return True
    
    def _rsi_filter(self, market_data: Dict) -> str:
        """
        RSI 超买超卖过滤
        
        逻辑:
            - RSI > 70 → 超买 → SHORT_ONLY
            - RSI < 30 → 超卖 → LONG_ONLY
            - 30 <= RSI <= 70 → BOTH
        
        返回:
            决策结果
        """
        rsi = market_data.get('rsi')
        
        if rsi is None:
            return "BOTH"  # 数据不足，默认通过
        
        if rsi > self.rsi_overbought:
            return "SHORT_ONLY"  # 超买，只做空
        elif rsi < self.rsi_oversold:
            return "LONG_ONLY"  # 超卖，只做多
        else:
            return "BOTH"  # 正常范围
    
    def _price_position_filter(self, market_data: Dict) -> str:
        """
        价格位置过滤
        
        逻辑:
            - 价格接近上边界（> 中间 + 20%）→ SHORT_ONLY
            - 价格接近下边界（< 中间 - 20%）→ LONG_ONLY
            - 价格在中间位置 → BOTH
        
        返回:
            决策结果
        """
        price = market_data.get('price') or market_data.get('close')
        box_upper = market_data.get('box_upper')
        box_lower = market_data.get('box_lower')
        
        if price is None or box_upper is None or box_lower is None:
            return "BOTH"  # 数据不足，默认通过
        
        # 计算箱体中间位置和高度
        box_middle = (box_upper + box_lower) / 2
        box_height = box_upper - box_lower
        
        if box_height == 0:
            return "BOTH"
        
        # 计算价格相对位置
        upper_threshold = box_middle + box_height * self.price_position_threshold
        lower_threshold = box_middle - box_height * self.price_position_threshold
        
        if price > upper_threshold:
            return "SHORT_ONLY"  # 接近上边界，只做空
        elif price < lower_threshold:
            return "LONG_ONLY"  # 接近下边界，只做多
        else:
            return "BOTH"  # 中间位置，允许双边
    
    def get_reason(self, market_data: Dict, coarse_result: str) -> str:
        """
        获取过滤原因（用于日志）
        
        返回:
            原因描述
        """
        if coarse_result == "NONE":
            return "粗筛已拒绝"
        
        reasons = []
        
        # 箱体质量
        if not self._box_quality_filter(market_data):
            reasons.append("箱体质量不足")
            return ", ".join(reasons)
        
        # RSI
        rsi_result = self._rsi_filter(market_data)
        if rsi_result == "SHORT_ONLY":
            reasons.append("RSI 超买")
        elif rsi_result == "LONG_ONLY":
            reasons.append("RSI 超卖")
        
        # 价格位置
        price_result = self._price_position_filter(market_data)
        if price_result == "SHORT_ONLY":
            reasons.append("价格接近上边界")
        elif price_result == "LONG_ONLY":
            reasons.append("价格接近下边界")
        
        if not reasons:
            reasons.append("所有精筛规则通过")
        
        return ", ".join(reasons)

# 测试代码
if __name__ == "__main__":
    filter = FineFilter()
    
    # 测试案例 1：RSI 超买
    test_data_1 = {
        'rsi': 75,
        'box_score': 85,
        'price': 1.1540,
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_1 = filter.filter(test_data_1, "BOTH")
    reason_1 = filter.get_reason(test_data_1, "BOTH")
    print(f"测试 1: {result_1} - {reason_1}")
    
    # 测试案例 2：箱体质量不足
    test_data_2 = {
        'rsi': 50,
        'box_score': 75,  # 低于 80
        'price': 1.1540,
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_2 = filter.filter(test_data_2, "BOTH")
    reason_2 = filter.get_reason(test_data_2, "BOTH")
    print(f"测试 2: {result_2} - {reason_2}")
    
    # 测试案例 3：价格接近上边界
    test_data_3 = {
        'rsi': 50,
        'box_score': 85,
        'price': 1.1580,  # 接近上边界
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_3 = filter.filter(test_data_3, "BOTH")
    reason_3 = filter.get_reason(test_data_3, "BOTH")
    print(f"测试 3: {result_3} - {reason_3}")
    
    # 测试案例 4：所有规则通过
    test_data_4 = {
        'rsi': 50,
        'box_score': 85,
        'price': 1.1550,  # 中间位置
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_4 = filter.filter(test_data_4, "LONG_ONLY")
    reason_4 = filter.get_reason(test_data_4, "LONG_ONLY")
    print(f"测试 4: {result_4} - {reason_4}")
    
    print("\n精筛规则测试完成")
