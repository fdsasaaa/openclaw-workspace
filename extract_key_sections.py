import sys
import re

# 读取文件
with open(r'C:\OpenClaw_Workspace\workspace\openclaw_truth.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 提取关键段落（使用正则表达式）
patterns = [
    r'Real Example #\d+:.*?(?=Real Example|The Hidden|Where Most|$)',
    r'Where Most Real Value.*?(?=The Hidden|The Biggest|$)',
    r'So.*?Can You Really Make Money.*?(?=The Bottom|$)',
]

results = []
for pattern in patterns:
    matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)
    results.extend(matches)

# 清理 HTML 标签
def clean_html(text):
    text = re.sub(r'<[^>]+>', ' ', text)
    text = re.sub(r'\s+', ' ', text)
    text = re.sub(r'&[a-z]+;', '', text)
    return text.strip()

# 输出
for i, text in enumerate(results[:10]):
    cleaned = clean_html(text)
    if len(cleaned) > 100:
        print(f"\n{'='*60}")
        print(f"段落 {i+1}:")
        print(f"{'='*60}")
        print(cleaned[:800])
