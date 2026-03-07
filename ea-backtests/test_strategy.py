#!/usr/bin/env python
"""
EA回测验证脚本 - 黄金日内交易策略
使用 backtrader 框架
"""
import backtrader as bt
import pandas as pd
from datetime import datetime

# 策略定义
class GoldIntradayStrategy(bt.Strategy):
    params = (
        ('ma_fast', 5),
        ('ma_slow', 20),
        ('rsi_period', 14),
        ('rsi_buy', 30),
        ('rsi_sell', 70),
        ('stop_loss', 20),      # 点数
        ('take_profit', 50),    # 点数
    )
    
    def __init__(self):
        # 计算指标
        self.ma_fast = bt.indicators.SMA(period=self.p.ma_fast)
        self.ma_slow = bt.indicators.SMA(period=self.p.ma_slow)
        self.rsi = bt.indicators.RSI(period=self.p.rsi_period)
        
        # 记录交易
        self.order = None
        self.buy_price = None
        
    def next(self):
        if self.order:
            return
            
        # 检查持仓
        if not self.position:
            # 做多条件: MA金叉 + RSI<30
            if self.ma_fast > self.ma_slow and self.rsi < self.p.rsi_buy:
                self.order = self.buy()
                self.buy_price = self.data.close[0]
                print(f'{self.data.datetime.date(0)} BUY @ {self.data.close[0]:.2f}')
                
            # 做空条件: MA死叉 + RSI>70
            elif self.ma_fast < self.ma_slow and self.rsi > self.p.rsi_sell:
                self.order = self.sell()
                self.buy_price = self.data.close[0]
                print(f'{self.data.datetime.date(0)} SELL @ {self.data.close[0]:.2f}')
        else:
            # 平仓逻辑
            if self.position.size > 0:  # 多头持仓
                # 止损或止盈
                if self.data.close[0] < self.buy_price * (1 - self.p.stop_loss/10000) or \
                   self.data.close[0] > self.buy_price * (1 + self.p.take_profit/10000):
                    self.order = self.close()
                    print(f'{self.data.datetime.date(0)} CLOSE LONG @ {self.data.close[0]:.2f}')
                    
            elif self.position.size < 0:  # 空头持仓
                if self.data.close[0] > self.buy_price * (1 + self.p.stop_loss/10000) or \
                   self.data.close[0] < self.buy_price * (1 - self.p.take_profit/10000):
                    self.order = self.close()
                    print(f'{self.data.datetime.date(0)} CLOSE SHORT @ {self.data.close[0]:.2f}')
    
    def notify_order(self, order):
        if order.status in [order.Completed]:
            if order.isbuy():
                print(f'买入执行 @ {order.executed.price:.2f}')
            elif order.issell():
                print(f'卖出执行 @ {order.executed.price:.2f}')
        self.order = None

def run_backtest():
    """执行回测"""
    print("=" * 60)
    print("EA回测验证 - 黄金日内交易策略")
    print("=" * 60)
    
    # 创建Cerebro引擎
    cerebro = bt.Cerebro()
    
    # 添加策略
    cerebro.addstrategy(GoldIntradayStrategy)
    
    # 加载数据
    data_path = r'C:\OpenClaw_Workspace\Data\market_data.csv'
    print(f"\n加载数据: {data_path}")
    
    # 先使用pandas加载和验证数据
    import pandas as pd
    df = pd.read_csv(data_path)
    print(f"数据行数: {len(df)}")
    print(f"数据列: {df.columns.tolist()}")
    print(f"前3行:\n{df.head(3)}")
    
    # 使用pandas feed
    class PandasData(bt.feeds.PandasData):
        params = (
            ('datetime', None),
            ('open', 'open'),
            ('high', 'high'),
            ('low', 'low'),
            ('close', 'close'),
            ('volume', 'volume'),
            ('openinterest', -1),
        )
    
    # 转换datetime列
    df['datetime'] = pd.to_datetime(df['datetime'])
    df.set_index('datetime', inplace=True)
    
    data = PandasData(dataname=df, timeframe=bt.TimeFrame.Minutes, compression=60)
    cerebro.adddata(data)
    
    # 设置初始资金
    cerebro.broker.setcash(100000.0)
    cerebro.broker.setcommission(commission=0.001)  # 0.1%手续费
    
    # 设置交易单位
    cerebro.addsizer(bt.sizers.FixedSize, stake=1)
    
    # 添加分析器
    cerebro.addanalyzer(bt.analyzers.SharpeRatio, _name='sharpe')
    cerebro.addanalyzer(bt.analyzers.DrawDown, _name='drawdown')
    cerebro.addanalyzer(bt.analyzers.TradeAnalyzer, _name='trades')
    
    # 打印初始资金
    print(f"\n初始资金: {cerebro.broker.getvalue():.2f}")
    
    # 运行回测
    print("\n开始回测...")
    results = cerebro.run()
    
    # 打印最终资金
    final_value = cerebro.broker.getvalue()
    print(f"\n最终资金: {final_value:.2f}")
    print(f"收益率: {(final_value/100000 - 1)*100:.2f}%")
    
    # 获取分析结果
    strat = results[0]
    
    # 夏普比率
    sharpe = strat.analyzers.sharpe.get_analysis()
    print(f"夏普比率: {sharpe.get('sharperatio', 'N/A')}")
    
    # 最大回撤
    drawdown = strat.analyzers.drawdown.get_analysis()
    print(f"最大回撤: {drawdown.get('max', {}).get('drawdown', 'N/A')}%")
    
    # 交易统计
    trades = strat.analyzers.trades.get_analysis()
    if trades:
        total = trades.get('total', {}).get('total', 0)
        won = trades.get('won', {}).get('total', 0)
        print(f"总交易次数: {total}")
        print(f"盈利次数: {won}")
        if total > 0:
            print(f"胜率: {won/total*100:.2f}%")
    
    print("\n" + "=" * 60)
    print("回测完成")
    print("=" * 60)
    
    # 保存结果到文件
    report_path = r'C:\OpenClaw_Workspace\ea-reports\backtest_result.txt'
    with open(report_path, 'w') as f:
        f.write(f"EA回测报告 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("=" * 60 + "\n")
        f.write(f"初始资金: 100000.00\n")
        f.write(f"最终资金: {final_value:.2f}\n")
        f.write(f"收益率: {(final_value/100000 - 1)*100:.2f}%\n")
        f.write(f"夏普比率: {sharpe.get('sharperatio', 'N/A')}\n")
        f.write(f"最大回撤: {drawdown.get('max', {}).get('drawdown', 'N/A')}%\n")
    
    print(f"\n报告已保存: {report_path}")

if __name__ == '__main__':
    run_backtest()
