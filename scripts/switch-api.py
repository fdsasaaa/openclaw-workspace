"""
OpenClaw API 快速切换工具
使用方法：python switch-api.py [口令]

支持的口令：
- opus: 切换到 Claude Opus 4-6 (api123)
- yunyi: 切换到 GPT 5.4 (yunyi)
- claude: 切换到 Claude Sonnet 4-6 (yunyi)
- add [name] [base_url] [api_key] [model_id]: 添加新的 API
"""

import json
import sys
import os
from datetime import datetime
from pathlib import Path

CONFIG_PATH = Path.home() / ".openclaw" / "openclaw.json"

# 预设的 API 配置
PRESETS = {
    "opus": {
        "provider": "claude-opus-api123",
        "model": "claude-opus-api123/claude-opus-4-6",
        "name": "Claude Opus 4.6"
    },
    "yunyi": {
        "provider": "yunyi",
        "model": "yunyi/gpt-5.4",
        "name": "GPT 5.4"
    },
    "claude": {
        "provider": "claude-yunyi",
        "model": "claude-yunyi/claude-sonnet-4-6",
        "name": "Claude Sonnet 4.6"
    }
}

def backup_config():
    """备份当前配置"""
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = CONFIG_PATH.with_suffix(f".json.backup.{timestamp}")
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"[OK] Config backed up to: {backup_path}")
    return backup_path

def load_config():
    """读取配置文件"""
    with open(CONFIG_PATH, 'r', encoding='utf-8-sig') as f:
        return json.load(f)

def save_config(config):
    """保存配置文件"""
    with open(CONFIG_PATH, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print("[OK] Configuration saved")

def switch_model(preset_name):
    """切换模型"""
    if preset_name not in PRESETS:
        print(f"[ERROR] Unknown preset: {preset_name}")
        print(f"Available presets: {', '.join(PRESETS.keys())}")
        return False
    
    preset = PRESETS[preset_name]
    backup_config()
    
    config = load_config()
    config["agents"]["defaults"]["model"]["primary"] = preset["model"]
    
    save_config(config)
    print(f"[OK] Switched to: {preset['name']}")
    print(f"     Model: {preset['model']}")
    print("\nNext step: openclaw gateway restart")
    return True

def add_api(name, base_url, api_key, model_id, context_window=200000, max_tokens=8192):
    """添加新的 API 配置"""
    backup_config()
    
    config = load_config()
    
    # 添加 provider
    provider_name = f"custom-{name}"
    config["models"]["providers"][provider_name] = {
        "baseUrl": base_url,
        "apiKey": api_key,
        "auth": "api-key",
        "api": "anthropic-messages",
        "headers": {},
        "authHeader": "x-api-key",
        "models": [
            {
                "id": model_id,
                "name": f"{model_id} ({name})",
                "contextWindow": context_window,
                "maxTokens": max_tokens
            }
        ]
    }
    
    # 添加到可选模型
    model_full_name = f"{provider_name}/{model_id}"
    config["agents"]["defaults"]["models"][model_full_name] = {
        "alias": name
    }
    
    save_config(config)
    print(f"[OK] Added API: {name}")
    print(f"     Provider: {provider_name}")
    print(f"     Model: {model_full_name}")
    print(f"     Alias: {name}")
    print(f"\nUsage: python switch-api.py {name}")
    print("Next step: openclaw gateway restart")
    
    # 更新预设列表
    PRESETS[name] = {
        "provider": provider_name,
        "model": model_full_name,
        "name": f"{model_id} ({name})"
    }
    
    return True

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        print("\n当前可用的口令:")
        for key, preset in PRESETS.items():
            print(f"  {key}: {preset['name']}")
        return
    
    command = sys.argv[1].lower()
    
    if command == "add":
        if len(sys.argv) < 6:
            print("用法: python switch-api.py add [name] [base_url] [api_key] [model_id]")
            print("示例: python switch-api.py add myapi https://api.example.com/v1 sk-xxx claude-opus-4-6")
            return
        
        name = sys.argv[2]
        base_url = sys.argv[3]
        api_key = sys.argv[4]
        model_id = sys.argv[5]
        
        add_api(name, base_url, api_key, model_id)
    else:
        switch_model(command)

if __name__ == "__main__":
    main()
