#!/usr/bin/env python
"""
迁移现有知识库到增强版（阶段2）- 简化实现
"""

import json
import numpy as np
from pathlib import Path
from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import pickle

base_path = Path("C:\\OpenClaw_Workspace\\knowledge")

# 读取现有文档
index_file = base_path / "kb-index.json"
with open(index_file, 'r', encoding='utf-8') as f:
    old_index = json.load(f)

documents = old_index.get("documents", [])
print(f"Found {len(documents)} documents to migrate\n")

# 读取所有文档内容
texts = []
valid_docs = []

for doc in documents:
    try:
        with open(doc["path"], 'r', encoding='utf-8') as f:
            content = f.read()
        texts.append(content)
        valid_docs.append(doc)
        print(f"Loaded: {doc['id']}")
    except Exception as e:
        print(f"Error loading {doc['id']}: {e}")

# 构建TF-IDF向量
print("\nBuilding TF-IDF vectors...")
vectorizer = TfidfVectorizer(max_features=1000, stop_words='english', ngram_range=(1, 2))
doc_vectors = vectorizer.fit_transform(texts)

print(f"Vector shape: {doc_vectors.shape}")

# 保存增强索引
enhanced_index = {
    "version": "2.0",
    "type": "enhanced",
    "last_update": datetime.now().isoformat(),
    "documents": valid_docs,
    "vectorized": True,
    "vector_shape": doc_vectors.shape
}

with open(base_path / "kb-index-enhanced.json", 'w', encoding='utf-8') as f:
    json.dump(enhanced_index, f, ensure_ascii=False, indent=2)

# 保存向量
with open(base_path / "kb-vectors.pkl", 'wb') as f:
    pickle.dump({
        "vectorizer": vectorizer,
        "vectors": doc_vectors,
        "documents": valid_docs
    }, f)

print("\n✅ Migration complete!")
print(f"Enhanced index: {base_path / 'kb-index-enhanced.json'}")
print(f"Vectors: {base_path / 'kb-vectors.pkl'}")
