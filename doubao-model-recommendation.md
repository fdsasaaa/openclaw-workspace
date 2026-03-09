# 豆包（Doubao）模型选择建议

## 🎯 推荐模型

### 最推荐：doubao-vision-pro-32k

**理由：**
- ✅ 支持视觉分析（vision）
- ✅ 支持长上下文（32k tokens）
- ✅ 适合复杂的UI识别任务
- ✅ 输出标准JSON格式

**告诉卖家：**
```
我需要 doubao-vision-pro-32k 模型
用于视觉自动化（Midscene）
```

---

## 📋 其他可选模型

### 1. doubao-vision-pro
- 标准视觉模型
- 适合一般的截图分析
- 性价比高

### 2. doubao-pro-32k
- 高级模型，长上下文
- 可能支持视觉（需要确认）
- 适合复杂任务

### 3. doubao-lite
- 轻量版
- 速度快，成本低
- 可能不支持视觉

---

## ⚠️ 关键问题要问卖家

**竹林应该问卖家：**

1. **"你的豆包API支持视觉分析吗？"**
   - 必须支持图片输入
   - 必须能分析截图

2. **"模型名称是什么？"**
   - 确认具体的模型ID
   - 比如：doubao-vision-pro-32k

3. **"输出的JSON格式是标准英文引号吗？"**
   - 这是关键！
   - 必须是 " 而不是 ""

4. **"如何配置到Midscene？"**
   - 需要API endpoint
   - 需要API key
   - 需要配置示例

---

## 🔧 配置示例

如果卖家提供的是豆包API，配置应该类似：

```bash
# .env 文件
MIDSCENE_MODEL_API_KEY=你的豆包API_key
MIDSCENE_MODEL_NAME=doubao-vision-pro-32k
MIDSCENE_MODEL_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
MIDSCENE_MODEL_FAMILY=openai
```

---

## 💡 虾哥的建议

**竹林，虾哥建议：**

1. **先问卖家这4个问题**
2. **确认支持视觉 + 标准JSON**
3. **要一个测试API key**
4. **虾哥帮你测试是否可用**
5. **确认没问题再购买**

---

**竹林，你现在可以：**
- 把这些问题发给卖家
- 或者告诉虾哥卖家的回复
- 虾哥帮你分析是否合适

🦐
