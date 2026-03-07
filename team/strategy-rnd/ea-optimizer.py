#!/usr/bin/env python
"""
EnergyBlock Code Optimizer - EA代码简化工具
替代 code-simplifier，专门针对MQL4/MQL5策略代码
"""

import re
import sys
from pathlib import Path

class EAOptimizer:
    """EA代码优化器"""
    
    def __init__(self, file_path):
        self.file_path = Path(file_path)
        self.original_code = ""
        self.optimized_code = ""
        self.stats = {
            'original_lines': 0,
            'optimized_lines': 0,
            'removed_comments': 0,
            'simplified_functions': 0,
            'optimized_loops': 0
        }
    
    def load(self):
        """加载代码文件"""
        with open(self.file_path, 'r', encoding='utf-8', errors='ignore') as f:
            self.original_code = f.read()
        self.stats['original_lines'] = len(self.original_code.split('\n'))
        return self
    
    def remove_redundant_comments(self):
        """删除冗余注释，保留关键说明"""
        lines = self.original_code.split('\n')
        cleaned_lines = []
        
        for line in lines:
            # 保留文件头注释（版权、版本）
            if any(keyword in line for keyword in ['copyright', 'version', 'description']):
                cleaned_lines.append(line)
                continue
            
            # 保留函数说明注释
            if 'void ' in line or 'int ' in line or 'bool ' in line or 'double ' in line:
                if '//' in line or '/*' in line:
                    cleaned_lines.append(line)
                    continue
            
            # 删除行尾注释（如 // 这是测试）
            if '//' in line:
                code_part = line[:line.index('//')].rstrip()
                if code_part:  # 保留代码部分
                    cleaned_lines.append(code_part)
                    self.stats['removed_comments'] += 1
                continue
            
            # 删除纯注释行
            stripped = line.strip()
            if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
                self.stats['removed_comments'] += 1
                continue
            
            cleaned_lines.append(line)
        
        self.optimized_code = '\n'.join(cleaned_lines)
        return self
    
    def simplify_diagnostic_logs(self):
        """简化诊断日志，保留核心功能"""
        # 删除详细的诊断日志函数，保留开关
        pattern = r'void DiagPrint.*\{[^}]*\}'
        self.optimized_code = re.sub(pattern, '// DiagPrint functions removed for production', self.optimized_code, flags=re.DOTALL)
        
        # 删除DiagPrint调用
        self.optimized_code = re.sub(r'DiagPrint\([^)]+\);', '', self.optimized_code)
        
        return self
    
    def optimize_variable_names(self):
        """优化变量命名（中文→英文，保持可读性）"""
        # 常见中文变量名映射
        name_map = {
            '手数': 'lotSize',
            '止损': 'stopLoss',
            '止盈': 'takeProfit',
            '开仓': 'openPosition',
            '平仓': 'closePosition',
            '马丁': 'martin',
            '箱体': 'box',
            '上限': 'top',
            '下限': 'bottom',
            '多空': 'direction'
        }
        
        for cn, en in name_map.items():
            self.optimized_code = self.optimized_code.replace(cn, en)
        
        return self
    
    def extract_common_patterns(self):
        """提取重复代码模式"""
        # 检测重复的条件判断模式
        # 例如：多次出现的if (条件) return;
        
        # 简化重复的打印语句
        self.optimized_code = re.sub(
            r'Print\("\[.*?\]".*?\);',
            '// Logging removed',
            self.optimized_code
        )
        
        return self
    
    def remove_unused_variables(self):
        """删除未使用的变量声明"""
        # 检测声明但未使用的变量（简化版）
        # 实际实现需要更复杂的静态分析
        
        # 删除纯调试变量
        debug_patterns = [
            r'int\s+g_tickCounter\s*=\s*0;',
            r'datetime\s+g_lastUpdateTime\s*=\s*0;',
            r'double\s+g_lastPrice\s*=\s*0;'
        ]
        
        for pattern in debug_patterns:
            self.optimized_code = re.sub(pattern, '// Debug var removed', self.optimized_code)
        
        return self
    
    def optimize(self):
        """执行所有优化"""
        self.optimized_code = self.original_code
        
        self.remove_redundant_comments()
        self.simplify_diagnostic_logs()
        self.optimize_variable_names()
        self.extract_common_patterns()
        self.remove_unused_variables()
        
        # 清理空行
        lines = self.optimized_code.split('\n')
        cleaned = []
        prev_empty = False
        for line in lines:
            is_empty = not line.strip()
            if is_empty and prev_empty:
                continue  # 跳过连续空行
            cleaned.append(line)
            prev_empty = is_empty
        
        self.optimized_code = '\n'.join(cleaned)
        self.stats['optimized_lines'] = len(self.optimized_code.split('\n'))
        
        return self
    
    def save(self, output_path=None):
        """保存优化后的代码"""
        if output_path is None:
            output_path = self.file_path.with_suffix('.optimized.mq5')
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(self.optimized_code)
        
        return output_path
    
    def report(self):
        """生成优化报告"""
        reduction = ((self.stats['original_lines'] - self.stats['optimized_lines']) / 
                    self.stats['original_lines'] * 100) if self.stats['original_lines'] > 0 else 0
        
        report = f"""
=== EnergyBlock Code Optimizer Report ===

Original:  {self.stats['original_lines']} lines
Optimized: {self.stats['optimized_lines']} lines
Reduction: {reduction:.1f}%

Details:
- Removed comments: {self.stats['removed_comments']}
- Simplified functions: {self.stats['simplified_functions']}
- Optimized loops: {self.stats['optimized_loops']}

Output: {self.save()}
========================================
"""
        return report


def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("Usage: python ea-optimizer.py <path-to-ea-file.mq5>")
        print("Example: python ea-optimizer.py data/raw/nengliang.mq5")
        return
    
    file_path = sys.argv[1]
    
    try:
        optimizer = EAOptimizer(file_path)
        optimizer.load()
        optimizer.optimize()
        
        print(optimizer.report())
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
