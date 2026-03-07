import pytesseract
from PIL import Image
import cv2
import os
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 设置 Tesseract 路径
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def preprocess_image(image_path):
    """图像预处理以提高OCR准确率"""
    img = cv2.imread(image_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray = cv2.convertScaleAbs(gray, alpha=1.5, beta=0)
    denoised = cv2.fastNlMeansDenoising(gray)
    _, binary = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    return binary

# 批量分析所有帧
frames_dir = r'C:\OpenClaw_Workspace\workspace\analysis\mt5-video-frames-dense'
output_file = 'mt5-video-full-ocr-analysis.txt'

print("=== 批量分析所有192帧 ===")
print("这可能需要5-10分钟...")
print()

frame_files = sorted([f for f in os.listdir(frames_dir) if f.endswith('.jpg')])
total_frames = len(frame_files)

with open(output_file, 'w', encoding='utf-8') as f:
    f.write("MT5 视频完整 OCR 分析\n")
    f.write("="*80 + "\n\n")
    
    for i, frame_name in enumerate(frame_files, 1):
        frame_path = os.path.join(frames_dir, frame_name)
        
        # 计算时间戳
        frame_num = int(frame_name.replace('frame_', '').replace('.jpg', ''))
        time_seconds = frame_num * 10
        minutes = time_seconds // 60
        seconds = time_seconds % 60
        timestamp = f"{minutes:02d}:{seconds:02d}"
        
        if i % 10 == 0:
            print(f"进度: {i}/{total_frames} ({i*100//total_frames}%)")
        
        try:
            # 预处理并OCR
            img_processed = preprocess_image(frame_path)
            text = pytesseract.image_to_string(img_processed, lang='eng+chi_sim')
            
            # 写入文件
            f.write(f"\n{'='*80}\n")
            f.write(f"帧: {frame_name} | 时间: {timestamp}\n")
            f.write(f"{'='*80}\n")
            f.write(text)
            f.write("\n")
            
        except Exception as e:
            f.write(f"错误: {e}\n")

print()
print(f"✓ 完成！结果已保存到: {output_file}")
print(f"  总帧数: {total_frames}")
print(f"  文件大小: {os.path.getsize(output_file) / 1024:.2f} KB")
