"""
使用 Claude API 直接读取图片
"""

import anthropic
import base64
import sys
import json

def read_image_with_claude(image_paths, prompt):
    """使用 Claude API 读取图片"""
    
    # 从配置文件读取 API key
    config_path = r"C:\Users\ME\.openclaw\openclaw.json"
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    api_key = config['models']['providers']['claude-opus-api123']['apiKey']
    base_url = config['models']['providers']['claude-opus-api123']['baseUrl']
    
    # 移除 base_url 末尾的 /v1（anthropic 库会自动添加）
    if base_url.endswith('/v1'):
        base_url = base_url[:-3]
    
    # 创建客户端
    client = anthropic.Anthropic(
        api_key=api_key,
        base_url=base_url
    )
    
    # 准备图片内容
    content = []
    
    for image_path in image_paths:
        with open(image_path, 'rb') as f:
            image_data = base64.standard_b64encode(f.read()).decode('utf-8')
        
        content.append({
            "type": "image",
            "source": {
                "type": "base64",
                "media_type": "image/jpeg",
                "data": image_data
            }
        })
    
    # 添加文本提示
    content.append({
        "type": "text",
        "text": prompt
    })
    
    # 调用 API
    message = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=4096,
        messages=[
            {
                "role": "user",
                "content": content
            }
        ]
    )
    
    return message.content[0].text

if __name__ == "__main__":
    image_paths = [
        r"C:\Users\ME\.openclaw\media\inbound\8aabc596-4c88-4895-9dd0-eb31713ab601.jpg",
        r"C:\Users\ME\.openclaw\media\inbound\df274980-ba44-4ee9-bfc2-60cc60f31431.jpg"
    ]
    
    prompt = "请详细列出这两张图片中所有可见的参数设置，包括参数名称和对应的数值。这是 TradingView 策略的参数配置界面。请用中文列出所有参数。"
    
    result = read_image_with_claude(image_paths, prompt)
    print(result)
