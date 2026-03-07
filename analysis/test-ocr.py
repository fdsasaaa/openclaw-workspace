import pytesseract
from PIL import Image
import os
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 设置 Tesseract 路径
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# 测试第一帧
frame_path = r'C:\OpenClaw_Workspace\workspace\analysis\mt5-video-frames-dense\frame_0001.jpg'

print("=== 测试 OCR 功能 ===")
print(f"正在分析: {os.path.basename(frame_path)}")
print()

try:
    img = Image.open(frame_path)
    text = pytesseract.image_to_string(img, lang='eng')
    
    print("提取的文字：")
    print("-" * 50)
    print(text)
    print("-" * 50)
    print()
    print("OCR 测试成功！")
    
    # 保存到文件
    output_file = 'ocr-test-result.txt'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(text)
    print(f"结果已保存到: {output_file}")
    
except Exception as e:
    print(f"OCR 测试失败: {e}")
