"""
规则引擎 - 整合粗筛和精筛规则
"""

from typing import Dict, Optional
from coarse_filter import CoarseFilter
from fine_filter import FineFilter

class RuleEngine:
    def __init__(self, config: Optional[Dict] = None):
        """
        初始化规则引擎
        
        参数:
            config: 配置参数字典
        """
        self.config = config or {}
        
        # 初始化粗筛和精筛
        self.coarse_filter = CoarseFilter(self.config.get('coarse', {}))
        self.fine_filter = FineFilter(self.config.get('fine', {}))
    
    def decide(self, market_data: Dict) -> Dict:
        """
        做出交易决策
        
        参数:
            market_data: 市场数据字典
        
        返回:
            决策结果字典:
                - decision: LONG_ONLY / SHORT_ONLY / BOTH / NONE
                - coarse_result: 粗筛结果
                - fine_result: 精筛结果
                - coarse_reason: 粗筛原因
                - fine_reason: 精筛原因
        """
        # 1. 粗筛
        coarse_result = self.coarse_filter.filter(market_data)
        coarse_reason = self.coarse_filter.get_reason(market_data)
        
        # 2. 精筛
        fine_result = self.fine_filter.filter(market_data, coarse_result)
        fine_reason = self.fine_filter.get_reason(market_data, coarse_result)
        
        return {
            'decision': fine_result,
            'coarse_result': coarse_result,
            'fine_result': fine_result,
            'coarse_reason': coarse_reason,
            'fine_reason': fine_reason
        }
    
    def get_summary(self, result: Dict) -> str:
        """
        获取决策摘要（用于日志）
        
        参数:
            result: decide() 返回的结果
        
        返回:
            摘要字符串
        """
        decision = result['decision']
        coarse_reason = result['coarse_reason']
        fine_reason = result['fine_reason']
        
        summary = f"决策: {decision}\n"
        summary += f"粗筛: {result['coarse_result']} ({coarse_reason})\n"
        summary += f"精筛: {result['fine_result']} ({fine_reason})"
        
        return summary

# 测试代码
if __name__ == "__main__":
    from datetime import datetime
    
    engine = RuleEngine()
    
    print("=" * 50)
    print("规则引擎测试")
    print("=" * 50)
    
    # 测试案例 1：理想情况（所有规则通过）
    print("\n测试 1: 理想情况")
    test_data_1 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0016,
        'atr_avg': 0.0015,
        'volume': 1000,
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp(),
        'rsi': 50,
        'box_score': 85,
        'price': 1.1550,
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_1 = engine.decide(test_data_1)
    print(engine.get_summary(result_1))
    
    # 测试案例 2：粗筛拒绝（波动率过小）
    print("\n测试 2: 粗筛拒绝（波动率过小）")
    test_data_2 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0005,  # 过小
        'atr_avg': 0.0015,
        'volume': 1000,
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp(),
        'rsi': 50,
        'box_score': 85,
        'price': 1.1550,
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_2 = engine.decide(test_data_2)
    print(engine.get_summary(result_2))
    
    # 测试案例 3：精筛修改（RSI 超买）
    print("\n测试 3: 精筛修改（RSI 超买）")
    test_data_3 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0016,
        'atr_avg': 0.0015,
        'volume': 1000,
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp(),
        'rsi': 75,  # 超买
        'box_score': 85,
        'price': 1.1550,
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_3 = engine.decide(test_data_3)
    print(engine.get_summary(result_3))
    
    # 测试案例 4：精筛拒绝（箱体质量不足）
    print("\n测试 4: 精筛拒绝（箱体质量不足）")
    test_data_4 = {
        'ma20': 1.1550,
        'ma50': 1.1500,
        'close': 1.1540,
        'atr': 0.0016,
        'atr_avg': 0.0015,
        'volume': 1000,
        'volume_avg': 1200,
        'timestamp': datetime.now().timestamp(),
        'rsi': 50,
        'box_score': 75,  # 低于 80
        'price': 1.1550,
        'box_upper': 1.1600,
        'box_lower': 1.1500
    }
    
    result_4 = engine.decide(test_data_4)
    print(engine.get_summary(result_4))
    
    print("\n" + "=" * 50)
    print("规则引擎测试完成")
    print("=" * 50)
