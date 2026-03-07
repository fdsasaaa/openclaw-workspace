import pytesseract
from PIL import Image, ImageEnhance, ImageFilter
import cv2
import numpy as np
import os
import sys

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 设置 Tesseract 路径
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

def preprocess_image(image_path):
    """图像预处理以提高OCR准确率"""
    # 使用OpenCV读取
    img = cv2.imread(image_path)
    
    # 转换为灰度
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    # 增加对比度
    gray = cv2.convertScaleAbs(gray, alpha=1.5, beta=0)
    
    # 去噪
    denoised = cv2.fastNlMeansDenoising(gray)
    
    # 二值化
    _, binary = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    return binary

# 测试一个关键帧（1分钟处，应该有更多界面元素）
frame_path = r'C:\OpenClaw_Workspace\workspace\analysis\mt5-video-frames-dense\frame_0006.jpg'

print("=== 测试改进的 OCR（带图像预处理）===")
print(f"正在分析: {os.path.basename(frame_path)}")
print()

try:
    # 原始OCR
    print("1. 原始图像 OCR:")
    print("-" * 50)
    img_original = Image.open(frame_path)
    text_original = pytesseract.image_to_string(img_original, lang='eng')
    print(text_original[:200] if len(text_original) > 200 else text_original)
    print()
    
    # 预处理后OCR
    print("2. 预处理后 OCR:")
    print("-" * 50)
    img_processed = preprocess_image(frame_path)
    text_processed = pytesseract.image_to_string(img_processed, lang='eng')
    print(text_processed[:200] if len(text_processed) > 200 else text_processed)
    print()
    
    # 尝试中文OCR
    print("3. 中文+英文 OCR:")
    print("-" * 50)
    text_chi = pytesseract.image_to_string(img_original, lang='chi_sim+eng')
    print(text_chi[:200] if len(text_chi) > 200 else text_chi)
    print()
    
    # 保存预处理后的图像
    cv2.imwrite('preprocessed_frame.jpg', img_processed)
    print("预处理后的图像已保存到: preprocessed_frame.jpg")
    
    print()
    print("OCR 改进测试完成！")
    
except Exception as e:
    print(f"错误: {e}")
    import traceback
    traceback.print_exc()
