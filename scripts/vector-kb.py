#!/usr/bin/env python
"""
EnergyBlock 向量知识库系统 (阶段2)
使用ChromaDB实现语义搜索
"""

import chromadb
from chromadb.config import Settings
import json
from pathlib import Path
from datetime import datetime

class VectorKnowledgeBase:
    """向量知识库 - 基于ChromaDB"""
    
    def __init__(self, persist_dir="C:\\OpenClaw_Workspace\\knowledge\\chroma_db"):
        self.persist_dir = Path(persist_dir)
        self.persist_dir.mkdir(parents=True, exist_ok=True)
        
        # 初始化ChromaDB客户端
        self.client = chromadb.PersistentClient(path=str(self.persist_dir))
        
        # 获取或创建集合
        self.collection = self.client.get_or_create_collection(
            name="energyblock_kb",
            metadata={"description": "EnergyBlock Strategies Knowledge Base"}
        )
    
    def add_document(self, doc_id, content, metadata=None):
        """添加文档到向量库"""
        self.collection.add(
            ids=[doc_id],
            documents=[content],
            metadatas=[metadata or {}]
        )
        return doc_id
    
    def search(self, query, n_results=5):
        """语义搜索"""
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results
        )
        return results
    
    def list_all(self):
        """列出所有文档"""
        return self.collection.get()


def migrate_from_phase1():
    """从阶段1迁移文档到阶段2向量库"""
    print("迁移知识库到向量存储...\n")
    
    # 读取阶段1的索引
    kb_path = Path("C:\\OpenClaw_Workspace\\knowledge")
    index_file = kb_path / "kb-index.json"
    
    if not index_file.exists():
        print("阶段1知识库未初始化")
        return
    
    with open(index_file, 'r', encoding='utf-8') as f:
        index = json.load(f)
    
    # 创建向量库
    vkb = VectorKnowledgeBase()
    
    # 迁移文档
    for doc in index.get("documents", []):
        try:
            with open(doc["path"], 'r', encoding='utf-8') as f:
                content = f.read()
            
            vkb.add_document(
                doc_id=doc["id"],
                content=content,
                metadata={
                    "category": doc["category"],
                    "filename": doc["filename"],
                    "added_at": doc.get("added_at", datetime.now().isoformat())
                }
            )
            print(f"[OK] Migrated: {doc['id']}")
        except Exception as e:
            print(f"[ERR] Failed: {doc['id']} - {e}")
    
    print(f"\n向量知识库创建完成！")
    print(f"存储位置: {vkb.persist_dir}")
    
    # 显示统计
    all_docs = vkb.list_all()
    print(f"总文档数: {len(all_docs['ids'])}")


def test_semantic_search():
    """测试语义搜索"""
    print("\n测试语义搜索...\n")
    
    vkb = VectorKnowledgeBase()
    
    # 测试查询
    test_queries = [
        "马丁策略风险",
        "箱体突破交易",
        "MQL5订单函数",
        "止损止盈设置"
    ]
    
    for query in test_queries:
        print(f"查询: '{query}'")
        results = vkb.search(query, n_results=2)
        
        for i, (doc_id, distance) in enumerate(zip(results['ids'][0], results['distances'][0])):
            print(f"  {i+1}. {doc_id} (相似度: {1-distance:.3f})")
        print()


if __name__ == "__main__":
    print("="*50)
    print("EnergyBlock 向量知识库系统 (阶段2)")
    print("="*50)
    
    # 迁移现有文档
    migrate_from_phase1()
    
    # 测试语义搜索
    test_semantic_search()
    
    print("\n阶段2部署完成！")
    print("现在可以使用语义搜索功能。")
