#!/usr/bin/env python
"""
EnergyBlock 知识库检索工具
实现QMD-like的本地文档检索功能
"""

import json
import sys
from pathlib import Path

def search_knowledge_base(query, category=None, limit=5):
    """搜索知识库"""
    base_path = Path("C:\\OpenClaw_Workspace\\knowledge")
    index_file = base_path / "kb-index.json"
    
    if not index_file.exists():
        print("Knowledge base not initialized. Run: init-knowledge-base.py")
        return []
    
    with open(index_file, 'r', encoding='utf-8') as f:
        index = json.load(f)
    
    results = []
    query_lower = query.lower()
    
    for doc in index.get("documents", []):
        if category and doc["category"] != category:
            continue
        
        try:
            with open(doc["path"], 'r', encoding='utf-8') as f:
                content = f.read()
            
            if query_lower in content.lower():
                score = content.lower().count(query_lower)
                # 提取匹配段落
                lines = content.split('\n')
                preview = ""
                for i, line in enumerate(lines):
                    if query_lower in line.lower():
                        start = max(0, i-1)
                        end = min(len(lines), i+3)
                        preview = '\n'.join(lines[start:end])
                        break
                
                results.append({
                    "document": doc,
                    "score": score,
                    "preview": preview[:300]
                })
        except:
            continue
    
    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:limit]


def main():
    if len(sys.argv) < 2:
        print("Usage: python kb-search.py <query> [category]")
        print("Example: python kb-search.py '马丁' trading-rules")
        print("Categories: mt5-docs, pine-script, ea-templates, trading-rules")
        return
    
    query = sys.argv[1]
    category = sys.argv[2] if len(sys.argv) > 2 else None
    
    print(f"Searching for: '{query}'")
    if category:
        print(f"Category: {category}")
    print()
    
    results = search_knowledge_base(query, category)
    
    if not results:
        print("No results found.")
        return
    
    print(f"Found {len(results)} results:\n")
    for i, r in enumerate(results, 1):
        print(f"{i}. {r['document']['id']} (relevance: {r['score']})")
        print(f"   {r['preview']}")
        print()


if __name__ == "__main__":
    main()
