import sys
import re
from html.parser import HTMLParser

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text = []
        self.in_script = False
        
    def handle_starttag(self, tag, attrs):
        if tag in ['script', 'style']:
            self.in_script = True
            
    def handle_endtag(self, tag):
        if tag in ['script', 'style']:
            self.in_script = False
            
    def handle_data(self, data):
        if not self.in_script:
            text = data.strip()
            if text and len(text) > 20:
                self.text.append(text)

# 读取文件
with open(r'C:\OpenClaw_Workspace\workspace\openclaw_truth.html', 'r', encoding='utf-8') as f:
    html = f.read()

# 提取文本
parser = TextExtractor()
parser.feed(html)

# 输出前 50 段有意义的文本
for i, text in enumerate(parser.text[:50]):
    if any(keyword in text.lower() for keyword in ['openclaw', 'money', 'make', 'agent', 'skill', 'business']):
        print(f"\n[{i+1}] {text[:200]}")
