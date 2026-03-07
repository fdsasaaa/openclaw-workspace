import pytesseract
from PIL import Image
import os
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 设置 Tesseract 路径
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# 测试多个关键帧
frames_to_test = [
    'frame_0006.jpg',  # 1分钟处
    'frame_0012.jpg',  # 2分钟处
    'frame_0030.jpg',  # 5分钟处
    'frame_0060.jpg',  # 10分钟处
]

frames_dir = r'C:\OpenClaw_Workspace\workspace\analysis\mt5-video-frames-dense'
output_file = 'ocr-key-frames-results.txt'

print("=== 批量测试关键帧 OCR ===")
print()

with open(output_file, 'w', encoding='utf-8') as f:
    for frame_name in frames_to_test:
        frame_path = os.path.join(frames_dir, frame_name)
        
        if not os.path.exists(frame_path):
            print(f"跳过: {frame_name} (文件不存在)")
            continue
        
        print(f"正在分析: {frame_name}")
        
        try:
            img = Image.open(frame_path)
            text = pytesseract.image_to_string(img, lang='eng')
            
            f.write(f"\n{'='*60}\n")
            f.write(f"帧: {frame_name}\n")
            f.write(f"{'='*60}\n")
            f.write(text)
            f.write("\n")
            
            # 显示前3行
            lines = text.strip().split('\n')[:3]
            for line in lines:
                if line.strip():
                    print(f"  {line}")
            print()
            
        except Exception as e:
            print(f"  错误: {e}")
            print()

print(f"完整结果已保存到: {output_file}")
print()
print("OCR 批量测试完成！")
