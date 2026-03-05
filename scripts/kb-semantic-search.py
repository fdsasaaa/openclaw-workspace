#!/usr/bin/env python
"""
EnergyBlock 语义搜索工具（阶段2）
基于TF-IDF向量相似度实现
"""

import pickle
import json
import numpy as np
from pathlib import Path
from sklearn.metrics.pairwise import cosine_similarity

base_path = Path("C:\\OpenClaw_Workspace\\knowledge")

# 加载向量和索引
try:
    with open(base_path / "kb-vectors.pkl", 'rb') as f:
        data = pickle.load(f)
        vectorizer = data["vectorizer"]
        doc_vectors = data["vectors"]
        documents = data["documents"]
    print(f"Loaded {len(documents)} documents")
    print(f"Vector shape: {doc_vectors.shape}")
except Exception as e:
    print(f"Error loading knowledge base: {e}")
    exit(1)

import sys
if len(sys.argv) < 2:
    print("Usage: python kb-semantic-search.py <query> [top_k]")
    print("Example: python kb-semantic-search.py '马丁策略' 3")
    exit(1)

query = sys.argv[1]
top_k = int(sys.argv[2]) if len(sys.argv) > 2 else 5

print(f"\nSearching for: '{query}'")
print(f"Top {top_k} results:\n")

# 查询向量化
query_vec = vectorizer.transform([query])

# 计算余弦相似度
similarities = cosine_similarity(query_vec, doc_vectors).flatten()

# 获取top_k结果
top_indices = np.argsort(similarities)[::-1][:top_k]

for i, idx in enumerate(top_indices, 1):
    if similarities[idx] <= 0:
        continue
    
    doc = documents[idx]
    score = similarities[idx]
    
    # 读取预览
    try:
        with open(doc["path"], 'r', encoding='utf-8') as f:
            content = f.read()
        preview = content[:200] + "..." if len(content) > 200 else content
    except:
        preview = "[Cannot read file]"
    
    print(f"{i}. {doc['id']}")
    print(f"   Score: {score:.3f}")
    print(f"   Preview: {preview.replace(chr(10), ' ')}")
    print()
