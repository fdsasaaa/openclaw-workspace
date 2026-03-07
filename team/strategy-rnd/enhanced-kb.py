#!/usr/bin/env python
"""
EnergyBlock 增强知识库 - 阶段2实现
使用scikit-learn实现轻量级语义搜索（TF-IDF + 余弦相似度）
作为ChromaDB的轻量替代方案
"""

import json
import numpy as np
from pathlib import Path
from datetime import datetime
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import pickle

class EnhancedKnowledgeBase:
    """增强知识库 - 支持语义搜索"""
    
    def __init__(self, base_path="C:\\OpenClaw_Workspace\\knowledge"):
        self.base_path = Path(base_path)
        self.index_file = self.base_path / "kb-index-enhanced.json"
        self.vectors_file = self.base_path / "kb-vectors.pkl"
        self.documents = []
        self.vectorizer = None
        self.doc_vectors = None
        self._load()
    
    def _load(self):
        """加载索引和向量"""
        # 加载文档索引
        if self.index_file.exists():
            with open(self.index_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.documents = data.get("documents", [])
        
        # 加载预计算的向量
        if self.vectors_file.exists():
            with open(self.vectors_file, 'rb') as f:
                saved = pickle.load(f)
                self.vectorizer = saved.get("vectorizer")
                self.doc_vectors = saved.get("vectors")
    
    def _save(self):
        """保存索引和向量"""
        # 保存索引
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump({
                "version": "2.0",
                "last_update": datetime.now().isoformat(),
                "documents": self.documents
            }, f, ensure_ascii=False, indent=2)
        
        # 保存向量
        if self.vectorizer and self.doc_vectors is not None:
            with open(self.vectors_file, 'wb') as f:
                pickle.dump({
                    "vectorizer": self.vectorizer,
                    "vectors": self.doc_vectors
                }, f)
    
    def _build_vectors(self):
        """构建文档向量（TF-IDF）"""
        if not self.documents:
            return
        
        # 读取所有文档内容
        texts = []
        for doc in self.documents:
            try:
                with open(doc["path"], 'r', encoding='utf-8') as f:
                    texts.append(f.read())
            except:
                texts.append("")
        
        # 构建TF-IDF向量
        self.vectorizer = TfidfVectorizer(
            max_features=1000,
            stop_words='english',
            ngram_range=(1, 2)
        )
        self.doc_vectors = self.vectorizer.fit_transform(texts)
        
        print(f"Built vectors for {len(texts)} documents")
        print(f"Vector shape: {self.doc_vectors.shape}")
    
    def add_document(self, category, filename, content, metadata=None):
        """添加文档"""
        doc_dir = self.base_path / category
        doc_dir.mkdir(parents=True, exist_ok=True)
        
        doc_path = doc_dir / filename
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        doc_info = {
            "id": f"{category}/{filename}",
            "category": category,
            "filename": filename,
            "path": str(doc_path),
            "added_at": datetime.now().isoformat(),
            "metadata": metadata or {},
            "content_preview": content[:100] + "..." if len(content) > 100 else content
        }
        
        # 避免重复
        self.documents = [d for d in self.documents if d["id"] != doc_info["id"]]
        self.documents.append(doc_info)
        
        # 重新构建向量
        self._build_vectors()
        self._save()
        
        return doc_info
    
    def semantic_search(self, query, category=None, top_k=5):
        """语义搜索（基于TF-IDF余弦相似度）"""
        if not self.vectorizer or self.doc_vectors is None:
            print("Knowledge base not built. Please add documents first.")
            return []
        
        # 过滤文档
        docs_to_search = self.documents
        if category:
            docs_to_search = [d for d in self.documents if d["category"] == category]
            if not docs_to_search:
                return []
        
        # 获取这些文档的索引
        doc_indices = [i for i, d in enumerate(self.documents) 
                      if d in docs_to_search]
        
        # 查询向量化
        query_vec = self.vectorizer.transform([query])
        
        # 计算相似度
        similarities = cosine_similarity(
            query_vec, 
            self.doc_vectors[doc_indices]
        ).flatten()
        
        # 排序并返回top_k
        top_indices = np.argsort(similarities)[::-1][:top_k]
        
        results = []
        for idx in top_indices:
            if similarities[idx] > 0:  # 只返回有相似度的
                doc_idx = doc_indices[idx]
                doc = self.documents[doc_idx]
                
                # 读取完整内容用于预览
                try:
                    with open(doc["path"], 'r', encoding='utf-8') as f:
                        content = f.read()
                except:
                    content = ""
                
                # 找到匹配段落
                preview = self._extract_relevant_section(content, query)
                
                results.append({
                    "document": doc,
                    "score": float(similarities[idx]),
                    "preview": preview
                })
        
        return results
    
    def _extract_relevant_section(self, content, query, window=2):
        """提取与查询相关的段落"""
        lines = content.split('\n')
        query_words = query.lower().split()
        
        best_score = 0
        best_start = 0
        
        for i in range(len(lines)):
            # 计算这一段的相关性
            section = '\n'.join(lines[max(0,i-window):min(len(lines),i+window+1)])
            score = sum(1 for word in query_words if word in section.lower())
            
            if score > best_score:
                best_score = score
                best_start = max(0, i - window)
        
        # 返回最佳段落
        end = min(len(lines), best_start + 2*window + 1)
        return '\n'.join(lines[best_start:end])
    
    def keyword_search(self, query, category=None, limit=5):
        """关键词搜索（阶段1的保留功能）"""
        results = []
        query_lower = query.lower()
        
        for doc in self.documents:
            if category and doc["category"] != category:
                continue
            
            try:
                with open(doc["path"], 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if query_lower in content.lower():
                    score = content.lower().count(query_lower)
                    preview = self._extract_relevant_section(content, query)
                    
                    results.append({
                        "document": doc,
                        "score": score,
                        "preview": preview
                    })
            except:
                continue
        
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:limit]
    
    def get_stats(self):
        """获取统计信息"""
        return {
            "total_documents": len(self.documents),
            "categories": list(set(d["category"] for d in self.documents)),
            "vectorized": self.doc_vectors is not None,
            "vector_shape": self.doc_vectors.shape if self.doc_vectors is not None else None
        }


def main():
    """测试"""
    kb = EnhancedKnowledgeBase()
    
    print("=== Enhanced Knowledge Base (Stage 2) ===\n")
    
    # 显示统计
    stats = kb.get_stats()
    print(f"Documents: {stats['total_documents']}")
    print(f"Categories: {stats['categories']}")
    print(f"Vectorized: {stats['vectorized']}")
    if stats['vector_shape']:
        print(f"Vector shape: {stats['vector_shape']}")
    
    # 测试搜索
    if stats['total_documents'] > 0:
        print("\n=== Semantic Search Test ===")
        results = kb.semantic_search("风险控制", top_k=3)
        for i, r in enumerate(results, 1):
            print(f"\n{i}. {r['document']['id']} (score: {r['score']:.3f})")
            print(f"   {r['preview']}")


if __name__ == "__main__":
    main()
