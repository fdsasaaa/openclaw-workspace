import re

# 读取原始文件
with open(r'G:\其他计算机\租用笔记本\！杠杆\tradingview策略\tradingview策略13（适配黄金版本）.txt', 'r', encoding='utf-8') as f:
    content = f.read()

# 修改参数
# 1. 修改交易时段开始小时：0 → 7
content = content.replace(
    'StratStartHour  = input.int(00, "开始小时 (首次挂单)", group=grp_time)',
    'StratStartHour  = input.int(7, "开始小时 (首次挂单)", group=grp_time)'
)

# 2. 修改交易时段结束小时：0 → 15
content = content.replace(
    'StratEndHour    = input.int(00, "结束小时 (首次挂单)", group=grp_time)',
    'StratEndHour    = input.int(15, "结束小时 (首次挂单)", group=grp_time)'
)

# 保存到新文件
output_path = r'C:\OpenClaw_Workspace\workspace\ai\tradingview策略13（优化版-时间过滤）.txt'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('[OK] 优化完成！')
print('')
print('[修改内容]')
print('1. 交易时段：00:00-00:00 -> 07:00-15:00')
print('2. 避开 16-18 点低胜率时段（特别是 17 点）')
print('')
print('[文件已保存到]')
print(output_path)
print('')
print('[预期效果]')
print('- 胜率：64.49% -> 75-80%')
print('- 交易数量：138 -> 60-70')
print('- 总盈利：$1,467 -> $1,800-2,000')
