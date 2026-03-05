#!/usr/bin/env python
"""
EnergyBlock Bindings路由器
根据规则将任务路由到对应SubAgent
"""

import json
import re
import subprocess
import uuid
from pathlib import Path
from datetime import datetime

class BindingsRouter:
    """Bindings任务路由器"""
    
    def __init__(self, config_path="C:\\OpenClaw_Workspace\\bindings\\rules\\routing-config.json"):
        self.config_path = Path(config_path)
        with open(self.config_path, 'r', encoding='utf-8') as f:
            self.config = json.load(f)
    
    def route(self, task_description):
        """根据任务描述路由到对应Agent"""
        task_lower = task_description.lower()
        
        # 按优先级排序规则
        rules = sorted(self.config['rules'], key=lambda x: x['priority'], reverse=True)
        
        for rule in rules:
            pattern = rule['pattern']
            if re.search(pattern, task_lower):
                target = rule['target']
                if target == "main":
                    return {
                        "routed": False,
                        "target": "main",
                        "reason": "Fallback to main agent"
                    }
                
                # 生成任务ID
                task_id = str(uuid.uuid4())[:8]
                
                # 启动SubAgent（后台）
                self._launch_subagent(target, task_description, task_id)
                
                return {
                    "routed": True,
                    "target": target,
                    "taskId": task_id,
                    "rule": rule['name'],
                    "status": "launched"
                }
        
        return {
            "routed": False,
            "target": "main",
            "reason": "No matching rule"
        }
    
    def _launch_subagent(self, agent_name, task, task_id):
        """启动SubAgent（后台执行）"""
        script_path = "C:\\OpenClaw_Workspace\\bindings\\subagent-runner.ps1"
        
        # 使用PowerShell后台启动
        cmd = [
            "powershell.exe",
            "-WindowStyle", "Hidden",
            "-ExecutionPolicy", "Bypass",
            "-File", script_path,
            "-AgentName", agent_name,
            "-Task", f'"{task}"',
            "-TaskId", task_id
        ]
        
        # 后台启动，不等待
        subprocess.Popen(cmd, creationflags=subprocess.CREATE_NEW_CONSOLE)
    
    def check_notifications(self):
        """检查SubAgent完成的通知"""
        notify_dir = Path("C:\\OpenClaw_Workspace\\bindings\\notifications")
        if not notify_dir.exists():
            return []
        
        notifications = []
        for f in notify_dir.glob("*.json"):
            with open(f, 'r', encoding='utf-8') as file:
                notifications.append(json.load(file))
            # 读取后删除或归档
            f.unlink()
        
        return notifications
    
    def get_agent_status(self, agent_name):
        """获取SubAgent状态"""
        log_dir = Path(f"C:\\OpenClaw_Workspace\\agents\\{agent_name}\\memory\\logs")
        if not log_dir.exists():
            return {"status": "not_initialized"}
        
        # 统计运行中的任务
        running = list(log_dir.glob("*-result.json"))
        
        return {
            "agent": agent_name,
            "completed_tasks": len(running),
            "log_dir": str(log_dir)
        }


def main():
    """测试路由器"""
    router = BindingsRouter()
    
    # 测试任务
    test_tasks = [
        "帮我回测这个EA策略",
        "分析历史数据",
        "生成一篇营销文案",
        "普通的问候"
    ]
    
    print("Bindings路由测试:\n")
    for task in test_tasks:
        result = router.route(task)
        print(f"任务: {task}")
        print(f"路由: {result}")
        print()


if __name__ == "__main__":
    main()
