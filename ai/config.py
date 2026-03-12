"""
XAUUSD 专用配置 - 针对黄金交易优化的参数
"""

# XAUUSD 特性
# - 波动率大（ATR 约 5-15 美元）
# - 点差大（20-50 点）
# - 受新闻影响大
# - 欧美盘活跃

XAUUSD_CONFIG = {
    'coarse': {
        # 波动率阈值（放宽）
        'atr_min_ratio': 0.3,  # 黄金波动大，放宽下限
        'atr_max_ratio': 3.0,  # 允许更大波动
        
        # 成交量阈值（放宽）
        'volume_min_ratio': 0.5,  # 黄金成交量波动大
    },
    
    'fine': {
        # RSI 阈值（放宽）
        'rsi_overbought': 75,  # 黄金趋势性强
        'rsi_oversold': 25,
        
        # 箱体质量阈值（放宽）
        'min_box_score': 70,  # 黄金箱体质量标准放宽
        
        # 价格位置阈值
        'price_position_threshold': 0.2,
    }
}

# EURUSD 配置（对比用）
EURUSD_CONFIG = {
    'coarse': {
        'atr_min_ratio': 0.5,
        'atr_max_ratio': 2.0,
        'volume_min_ratio': 0.7,
    },
    
    'fine': {
        'rsi_overbought': 70,
        'rsi_oversold': 30,
        'min_box_score': 80,
        'price_position_threshold': 0.2,
    }
}

# 根据品种选择配置
def get_config(symbol: str):
    """
    根据交易品种获取配置
    
    参数:
        symbol: 交易品种（XAUUSD, EURUSD 等）
    
    返回:
        配置字典
    """
    if symbol == "XAUUSD":
        return XAUUSD_CONFIG
    elif symbol == "EURUSD":
        return EURUSD_CONFIG
    else:
        # 默认使用 EURUSD 配置
        return EURUSD_CONFIG

if __name__ == "__main__":
    print("XAUUSD 配置:")
    print(XAUUSD_CONFIG)
    
    print("\nEURUSD 配置:")
    print(EURUSD_CONFIG)
