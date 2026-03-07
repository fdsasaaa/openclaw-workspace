# Pine Script基础

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
