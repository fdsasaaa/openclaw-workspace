#!/usr/bin/env python
"""
EnergyBlock 文档自动抓取工具 - 简化版
直接创建知识库文档
"""

import json
from datetime import datetime
from pathlib import Path

base_path = Path("C:\\OpenClaw_Workspace\\knowledge")
index_file = base_path / "kb-index.json"

# 加载或创建索引
if index_file.exists():
    with open(index_file, 'r', encoding='utf-8') as f:
        index = json.load(f)
else:
    index = {"version": "1.0", "last_update": None, "documents": []}

# 定义要创建的文档
documents = [
    {
        "category": "mt5-docs",
        "filename": "mql5-quickref.md",
        "content": """# MQL5快速参考

## 核心函数
- OrderSend() - 发送订单
- OrderModify() - 修改订单  
- OrderClose() - 平仓
- PositionSelect() - 选择持仓

## 数据类型
- int, double, string, bool, datetime

## 事件函数
- OnInit() - 初始化
- OnTick() - 每tick执行
- OnDeinit() - 卸载
"""
    },
    {
        "category": "pine-script", 
        "filename": "pine-basics.md",
        "content": """# Pine Script基础

## 声明
//@version=5
study("My Indicator")

## 内置变量
- close, open, high, low, volume

## 常用指标
- ta.sma() - 简单移动平均
- ta.ema() - 指数移动平均
- ta.rsi() - RSI指标
- ta.macd() - MACD

## 策略
- strategy.entry() - 开仓
- strategy.close() - 平仓
- strategy.exit() - 止盈止损
"""
    },
    {
        "category": "ea-templates",
        "filename": "box-strategy-guide.md", 
        "content": """# 箱体策略开发指南

## 识别箱体
1. 找出N周期内的最高/最低点
2. 确认多次测试边界
3. 边界收敛形成箱体

## 入场条件
- 突破上边界 + 确认 → 做多
- 突破下边界 + 确认 → 做空

## 风险控制
- 必须设置止损
- 限制马丁次数 ≤ 2
- 监控账户余额
- 避开重大新闻

## 优化方向
- 添加趋势过滤器
- 优化突破确认逻辑
- 改进止损位置
- 调整交易时段
"""
    },
    {
        "category": "trading-rules",
        "filename": "risk-management.md",
        "content": """# 风险管理规则

## 资金管理
- 单笔风险 ≤ 2%
- 日最大亏损 ≤ 5%
- 连续3次亏损停止
- 盈利5%后降仓

## 马丁策略（如使用）
- 最大加仓2次
- 倍数1.4
- 总仓位 ≤ 20%
- 设置绝对止损线

## 交易时段
- 避开亚洲盘
- 避开重大新闻
- 最佳：伦敦纽约重叠

## 记录要求
- 截图记录
- 入场理由
- 情绪状态
- 每周复盘
"""
    }
]

# 创建文档并更新索引
print("Creating Knowledge Base Documents...\n")

for doc in documents:
    # 创建目录
    doc_dir = base_path / doc["category"]
    doc_dir.mkdir(parents=True, exist_ok=True)
    
    # 保存文档
    doc_path = doc_dir / doc["filename"]
    with open(doc_path, 'w', encoding='utf-8') as f:
        f.write(doc["content"])
    
    # 更新索引
    doc_info = {
        "id": f"{doc['category']}/{doc['filename']}",
        "category": doc["category"],
        "filename": doc["filename"],
        "path": str(doc_path),
        "added_at": datetime.now().isoformat()
    }
    
    # 避免重复
    index["documents"] = [d for d in index["documents"] if d["id"] != doc_info["id"]]
    index["documents"].append(doc_info)
    
    print(f"Created: {doc_info['id']}")

# 保存索引
index["last_update"] = datetime.now().isoformat()
with open(index_file, 'w', encoding='utf-8') as f:
    json.dump(index, f, ensure_ascii=False, indent=2)

print(f"\nTotal: {len(index['documents'])} documents")
print(f"Index: {index_file}")
print("Knowledge Base initialized!")
