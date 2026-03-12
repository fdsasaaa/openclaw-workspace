"""
生成只做多单的TradingView策略版本
"""

import re

def generate_long_only_version():
    """生成只做多单的策略版本"""
    
    # 读取原始文件
    input_file = r'G:\其他计算机\租用笔记本\！杠杆\tradingview策略\tradingview策略13（适配黄金版本）.txt'
    output_file = r'C:\OpenClaw_Workspace\workspace\ai\tradingview策略13（优化版-只做多单）.txt'
    
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print(f'读取原始文件，长度: {len(content)} 字符')
    
    # 1. 找到并注释掉 Break_Short 相关的代码块
    # 查找包含 Break_Short 和 strategy.entry 的代码块
    
    # 2. 找到并注释掉 Martin_Short 相关的代码块
    
    # 3. 找到 Short 方向的所有 strategy.entry 调用并注释掉
    
    # 使用正则表达式找到 Short 相关的入场
    short_patterns = [
        r'if Break_Short.*?\{[^}]*strategy\.entry\([^)]*\).*?\}',
        r'if Martin_Short.*?\{[^}]*strategy\.entry\([^)]*\).*?\}',
        r'strategy\.entry\([^)]*short[^)]*\)',
    ]
    
    modified_content = content
    
    # 统计修改
    modifications = []
    
    # 方法：找到所有的 if ... strategy.entry 代码块并检查是否包含 Short 关键词
    lines = content.split('\n')
    new_lines = []
    skip_until_brace = 0
    in_short_block = False
    
    for i, line in enumerate(lines):
        # 检测是否是 Break_Short 或 Martin_Short 相关的代码
        if ('if Break_Short' in line or 'if Martin_Short' in line) and 'strategy.entry' not in line:
            # 这是一个条件判断开始，检查接下来的几行
            # 简单处理：注释掉这行
            new_lines.append('// [LONG_ONLY] ' + line)
            in_short_block = True
            modifications.append(f'注释: {line.strip()[:60]}')
        elif in_short_block:
            # 我们在一个 short block 中
            if 'strategy.entry' in line and ('short' in line.lower() or 'Short' in line):
                # 这是 short 方向的入场
                new_lines.append('// [LONG_ONLY] ' + line)
                modifications.append(f'注释 Short entry: {line.strip()[:60]}')
            else:
                new_lines.append(line)
            
            # 检测 block 结束
            if line.strip() == '}' and i > 0 and 'if' in lines[i-1]:
                in_short_block = False
        else:
            new_lines.append(line)
    
    modified_content = '\n'.join(new_lines)
    
    # 更好的方法：直接替换关键的 Short 相关代码
    # 使用更直接的字符串替换
    
    # 找到 Break_Short 的 strategy.entry 并注释掉
    break_short_pattern = r'(if Break_Short.*?\n)(.*?)(strategy\.entry\([^)]*\))'
    
    # 找到 Martin_Short 的 strategy.entry 并注释掉
    martin_short_pattern = r'(if Martin_Short.*?\n)(.*?)(strategy\.entry\([^)]*\))'
    
    # 使用更简单的方法：直接在关键位置添加注释
    simple_modifications = [
        ('if Break_Short and f_boxValid()', '// [LONG_ONLY] if Break_Short and f_boxValid()'),
        ('strategy.entry("Box Short", strategy.short,', '// [LONG_ONLY] strategy.entry("Box Short", strategy.short,'),
    ]
    
    for old, new in simple_modifications:
        if old in content:
            modified_content = modified_content.replace(old, new)
            modifications.append(f'Replaced: {old[:50]}...')
    
    # 保存文件
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(modified_content)
    
    print(f'\n完成！')
    print(f'输出文件: {output_file}')
    print(f'修改次数: {len(modifications)}')
    
    if modifications:
        print(f'\n修改详情:')
        for i, mod in enumerate(modifications[:10], 1):
            print(f'  {i}. {mod}')
        if len(modifications) > 10:
            print(f'  ... 还有 {len(modifications) - 10} 处修改')

if __name__ == '__main__':
    generate_long_only_version()
