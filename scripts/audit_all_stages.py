#!/usr/bin/env python
"""
OpenClaw 1-10阶段建设成果完整检测脚本
自动验证所有文件、目录、配置、功能是否落实
"""
import os
import json
from pathlib import Path
from datetime import datetime

class OpenClawAuditor:
    def __init__(self, base_path=r"C:\OpenClaw_Workspace"):
        self.base_path = Path(base_path)
        self.run_path = Path(r"C:\Users\ME\.openclaw")
        self.results = []
        self.warnings = []
        self.errors = []
        
    def log(self, status, item, detail=""):
        """记录检查结果"""
        entry = {
            "status": status,
            "item": item,
            "detail": detail,
            "timestamp": datetime.now().isoformat()
        }
        self.results.append(entry)
        if status == "ERROR":
            self.errors.append(entry)
        elif status == "WARNING":
            self.warnings.append(entry)
        return entry
    
    def check_file_exists(self, relative_path, required=True):
        """检查文件是否存在"""
        full_path = self.base_path / relative_path
        exists = full_path.exists()
        
        if required:
            status = "OK" if exists else "ERROR"
        else:
            status = "OK" if exists else "INFO"
            
        self.log(status, f"文件: {relative_path}", 
                f"{'存在' if exists else '缺失'} ({full_path})")
        return exists
    
    def check_directory_exists(self, relative_path, required=True):
        """检查目录是否存在"""
        full_path = self.base_path / relative_path
        exists = full_path.exists() and full_path.is_dir()
        
        if required:
            status = "OK" if exists else "ERROR"
        else:
            status = "OK" if exists else "INFO"
            
        self.log(status, f"目录: {relative_path}",
                f"{'存在' if exists else '缺失'}")
        return exists
    
    def check_file_size(self, relative_path, min_size=0):
        """检查文件大小"""
        full_path = self.base_path / relative_path
        if not full_path.exists():
            self.log("ERROR", f"文件大小: {relative_path}", "文件不存在")
            return False
            
        size = full_path.stat().st_size
        ok = size >= min_size
        
        self.log("OK" if ok else "WARNING", 
                f"文件大小: {relative_path}",
                f"{size} bytes (要求≥{min_size})")
        return ok
    
    def run_full_audit(self):
        """执行完整审计"""
        print("="*70)
        print("OpenClaw 1-10阶段建设成果完整检测")
        print("="*70)
        print(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"检测路径: {self.base_path}")
        print()
        
        # ==================== 阶段1检测 ====================
        print("\n【阶段1】环境与路径规范化")
        print("-"*70)
        
        # 核心报告文件
        self.check_file_exists("reports/stage1_environment_path_report.md")
        self.check_file_exists("reports/pre_business_checklist.md")
        self.check_file_exists("reports/stage1_final_selfcheck_report.md")
        
        # 数据文件
        self.check_file_exists("Data/market_data.csv")
        self.check_file_size("Data/market_data.csv", 100000)  # 至少100KB
        
        # 脚本修复
        self.check_file_exists("step02/01-ea-optimize.ps1")
        
        # ==================== 阶段2检测 ====================
        print("\n【阶段2】基础核心能力层")
        print("-"*70)
        
        self.check_file_exists("reports/stage2_core_capability_report.md")
        
        # ==================== 阶段3检测 ====================
        print("\n【阶段3】安全与记忆层")
        print("-"*70)
        
        # 规范文件
        self.check_file_exists("configs/execution-rules.md")
        self.check_file_exists("configs/security-reminder.md")
        self.check_file_exists("configs/memory-spec.md")
        self.check_file_exists("configs/backup-strategy.md")
        
        # 检查规范文件大小（确保有内容）
        for config in ["execution-rules.md", "security-reminder.md", 
                      "memory-spec.md", "backup-strategy.md"]:
            self.check_file_size(f"configs/{config}", 1000)
        
        # ==================== 阶段4检测 ====================
        print("\n【阶段4】执行与效率层")
        print("-"*70)
        
        self.check_file_exists("reports/stage4_execution_efficiency_report.md")
        
        # Python依赖检查
        try:
            import pandas
            self.log("OK", "Python依赖: pandas", f"版本 {pandas.__version__}")
        except:
            self.log("ERROR", "Python依赖: pandas", "未安装")
            
        try:
            import backtrader
            self.log("OK", "Python依赖: backtrader", f"版本 {backtrader.__version__}")
        except:
            self.log("ERROR", "Python依赖: backtrader", "未安装")
        
        # ==================== 阶段5检测 ====================
        print("\n【阶段5】多实例协作规划")
        print("-"*70)
        
        self.check_file_exists("reports/stage5_multi_agent_plan.md")
        
        # ==================== 阶段6-10检测 ====================
        print("\n【阶段6-10】部署与业务适配")
        print("-"*70)
        
        self.check_file_exists("reports/stage6-10_evaluation_plan.md")
        self.check_file_exists("reports/FINAL_stage6-10_implementation_summary.md")
        self.check_file_exists("memory/evolution-stage6.md")
        self.check_file_exists("memory/evolution-stage8.md")
        self.check_file_exists("memory/mt4-cli-verification.md")
        
        # EA业务资源
        self.check_file_exists("templates/ea-prompt-gold-intraday.txt")
        self.check_file_exists("ea-backtests/test_strategy.py")
        
        # ==================== 目录结构检测 ====================
        print("\n【目录结构完整性】")
        print("-"*70)
        
        required_dirs = [
            "backup",
            "cache",
            "configs",
            "Data",
            "ea-backtests",
            "ea-reports",
            "ea-scripts",
            "logs",
            "memory",
            "projects",
            "reports",
            "skills",
            "step02",
            "temp",
            "templates",
            "workspace",
        ]
        
        for dir_name in required_dirs:
            self.check_directory_exists(dir_name)
        
        # ==================== 汇总报告检测 ====================
        print("\n【汇总报告】")
        print("-"*70)
        
        self.check_file_exists("reports/FINAL_1-5_stages_summary.md")
        
        # ==================== 生成检测报告 ====================
        print("\n" + "="*70)
        print("检测结果汇总")
        print("="*70)
        
        total = len(self.results)
        ok_count = len([r for r in self.results if r["status"] == "OK"])
        warning_count = len(self.warnings)
        error_count = len(self.errors)
        
        print(f"总检查项: {total}")
        print(f"[OK] 通过: {ok_count}")
        print(f"[WARN] 警告: {warning_count}")
        print(f"[ERR] 错误: {error_count}")
        print()
        
        if error_count == 0:
            print("*** 所有关键建设成果已落实！ ***")
        elif error_count <= 3:
            print(">>> 大部分建设成果已落实，存在少量问题需处理")
        else:
            print("!!! 建设成果存在较多缺失，需补充实施 !!!")
        
        # 保存详细报告
        self.save_report()
        
        return error_count == 0
    
    def save_report(self):
        """保存检测报告"""
        report_path = self.base_path / "reports" / f"audit_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        report_data = {
            "audit_time": datetime.now().isoformat(),
            "base_path": str(self.base_path),
            "summary": {
                "total": len(self.results),
                "ok": len([r for r in self.results if r["status"] == "OK"]),
                "warning": len(self.warnings),
                "error": len(self.errors)
            },
            "results": self.results,
            "errors": self.errors,
            "warnings": self.warnings
        }
        
        with open(report_path, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, ensure_ascii=False, indent=2)
        
        print(f"\n详细检测报告已保存: {report_path}")
        
        # 同时生成文本报告
        txt_path = self.base_path / "reports" / f"audit_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        with open(txt_path, 'w', encoding='utf-8') as f:
            f.write("="*70 + "\n")
            f.write("OpenClaw 建设成果检测报告\n")
            f.write("="*70 + "\n\n")
            f.write(f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"检测路径: {self.base_path}\n\n")
            f.write(f"总检查项: {len(self.results)}\n")
            f.write(f"通过: {report_data['summary']['ok']}\n")
            f.write(f"警告: {report_data['summary']['warning']}\n")
            f.write(f"错误: {report_data['summary']['error']}\n\n")
            
            f.write("="*70 + "\n")
            f.write("详细结果\n")
            f.write("="*70 + "\n\n")
            
            for r in self.results:
                icon = "[OK]" if r["status"] == "OK" else "[WARN]" if r["status"] == "WARNING" else "[ERR]" if r["status"] == "ERROR" else "[INFO]"
                f.write(f"{icon} [{r['status']}] {r['item']}\n")
                if r['detail']:
                    f.write(f"   详情: {r['detail']}\n")
                f.write("\n")
        
        print(f"文本报告已保存: {txt_path}")

if __name__ == "__main__":
    auditor = OpenClawAuditor()
    success = auditor.run_full_audit()
    exit(0 if success else 1)
