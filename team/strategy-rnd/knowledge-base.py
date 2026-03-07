#!/usr/bin/env python
"""
EnergyBlock Knowledge Base Builder
构建本地RAG知识库，实现QMD-like功能
"""

import os
import json
from pathlib import Path
from datetime import datetime

class KnowledgeBase:
    """本地知识库管理器"""
    
    def __init__(self, base_path="C:\\OpenClaw_Workspace\\knowledge"):
        self.base_path = Path(base_path)
        self.index_file = self.base_path / "kb-index.json"
        self.index = self._load_index()
    
    def _load_index(self):
        """加载索引"""
        if self.index_file.exists():
            with open(self.index_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {"version": "1.0", "last_update": None, "documents": []}
    
    def _save_index(self):
        """保存索引"""
        self.index["last_update"] = datetime.now().isoformat()
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(self.index, f, ensure_ascii=False, indent=2)
    
    def ingest_document(self, category, filename, content, metadata=None):
        """添加文档到知识库"""
        doc_path = self.base_path / category / filename
        
        # 保存文档
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # 更新索引
        doc_info = {
            "id": f"{category}/{filename}",
            "category": category,
            "filename": filename,
            "path": str(doc_path),
            "added_at": datetime.now().isoformat(),
            "metadata": metadata or {}
        }
        
        # 避免重复
        self.index["documents"] = [d for d in self.index["documents"] if d["id"] != doc_info["id"]]
        self.index["documents"].append(doc_info)
        self._save_index()
        
        return doc_info
    
    def search(self, query, category=None, limit=5):
        """简单关键词搜索（阶段1：关键词匹配，阶段2：语义搜索）"""
        results = []
        query_lower = query.lower()
        
        for doc in self.index["documents"]:
            # 类别过滤
            if category and doc["category"] != category:
                continue
            
            # 读取文档内容
            try:
                with open(doc["path"], 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # 简单关键词匹配（阶段1）
                if query_lower in content.lower():
                    # 计算匹配度（出现次数）
                    score = content.lower().count(query_lower)
                    results.append({
                        "document": doc,
                        "score": score,
                        "preview": content[:200] + "..." if len(content) > 200 else content
                    })
            except:
                continue
        
        # 按分数排序
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:limit]
    
    def list_categories(self):
        """列出所有类别"""
        categories = set(d["category"] for d in self.index["documents"])
        return sorted(categories)
    
    def get_stats(self):
        """获取统计信息"""
        return {
            "total_documents": len(self.index["documents"]),
            "categories": self.list_categories(),
            "last_update": self.index["last_update"]
        }


def main():
    """主函数"""
    kb = KnowledgeBase()
    
    print("=== EnergyBlock Knowledge Base ===\n")
    
    # 显示统计
    stats = kb.get_stats()
    print(f"Total documents: {stats['total_documents']}")
    print(f"Categories: {', '.join(stats['categories']) if stats['categories'] else 'None'}")
    print(f"Last update: {stats['last_update'] or 'Never'}")
    
    # 测试搜索
    if stats['total_documents'] > 0:
        print("\n=== Test Search ===")
        results = kb.search("EA", limit=3)
        for r in results:
            print(f"\n{r['document']['id']} (score: {r['score']})")
            print(f"Preview: {r['preview'][:100]}...")


if __name__ == "__main__":
    main()
