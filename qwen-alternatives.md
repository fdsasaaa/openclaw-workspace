# Qwen API 替代方案

## 🎯 可用的视觉模型替代方案

### 1. OpenAI GPT-4 Vision / GPT-4o
**优点：**
- ✅ 视觉能力强大
- ✅ JSON格式标准
- ✅ Midscene官方支持
- ✅ 稳定可靠

**缺点：**
- ❌ 需要付费（$0.01/1K tokens）
- ❌ 需要OpenAI API key

**配置示例：**
```
MIDSCENE_MODEL_API_KEY=sk-your-openai-key
MIDSCENE_MODEL_NAME=gpt-4o
MIDSCENE_MODEL_BASE_URL=https://api.openai.com/v1
MIDSCENE_MODEL_FAMILY=openai
```

---

### 2. Anthropic Claude 3.5 Sonnet
**优点：**
- ✅ 视觉能力优秀
- ✅ JSON格式标准
- ✅ Midscene官方支持
- ✅ 响应速度快

**缺点：**
- ❌ 需要付费
- ❌ 需要Anthropic API key

**配置示例：**
```
MIDSCENE_MODEL_API_KEY=sk-ant-your-key
MIDSCENE_MODEL_NAME=claude-3-5-sonnet-20241022
MIDSCENE_MODEL_BASE_URL=https://api.anthropic.com
MIDSCENE_MODEL_FAMILY=anthropic
```

---

### 3. Google Gemini 2.0 Flash
**优点：**
- ✅ 有免费额度（15 RPM）
- ✅ 视觉能力强
- ✅ 响应速度快
- ✅ JSON格式标准

**缺点：**
- ❌ 免费额度有15天使用限制（竹林提到的）
- ❌ 需要Google API key

**配置示例：**
```
MIDSCENE_MODEL_API_KEY=AIza-your-google-key
MIDSCENE_MODEL_NAME=gemini-2.0-flash-exp
MIDSCENE_MODEL_BASE_URL=https://generativelanguage.googleapis.com/v1beta
MIDSCENE_MODEL_FAMILY=gemini
```

---

### 4. 字节跳动 Doubao（豆包）
**优点：**
- ✅ 国内服务，访问快
- ✅ 有免费额度
- ✅ 支持视觉能力
- ✅ 价格便宜

**缺点：**
- ⚠️ 需要验证JSON格式是否标准
- ⚠️ Midscene支持情况未知

**API地址：** https://www.volcengine.com/product/doubao

---

### 5. 阿里云 通义千问 VL（视觉版）
**优点：**
- ✅ 国内服务
- ✅ 有免费额度
- ✅ 支持视觉能力

**缺点：**
- ❌ 可能有和Qwen相同的中文引号问题
- ⚠️ 需要测试

---

### 6. 百度 文心一言 4.0
**优点：**
- ✅ 国内服务
- ✅ 支持视觉能力
- ✅ 有免费额度

**缺点：**
- ⚠️ JSON格式需要验证
- ⚠️ Midscene支持情况未知

---

### 7. OpenRouter（推荐！）
**优点：**
- ✅ 聚合多个模型（GPT-4, Claude, Gemini等）
- ✅ 统一API接口
- ✅ 有免费额度
- ✅ 可以随时切换模型

**缺点：**
- ⚠️ 需要注册OpenRouter账号

**配置示例：**
```
MIDSCENE_MODEL_API_KEY=sk-or-your-openrouter-key
MIDSCENE_MODEL_NAME=anthropic/claude-3.5-sonnet
MIDSCENE_MODEL_BASE_URL=https://openrouter.ai/api/v1
MIDSCENE_MODEL_FAMILY=openai
```

**网址：** https://openrouter.ai/

---

## 🎯 虾哥的推荐

### 最推荐：OpenRouter
**理由：**
1. 可以访问多个模型（GPT-4, Claude, Gemini等）
2. 有免费额度可以测试
3. 统一接口，切换方便
4. 价格透明

### 次推荐：字节跳动 Doubao
**理由：**
1. 国内服务，速度快
2. 价格便宜
3. 有免费额度
4. 需要测试JSON格式

### 备选：直接使用 GPT-4o 或 Claude
**理由：**
1. 最稳定可靠
2. Midscene官方支持
3. 虽然付费，但成本可控（每天约$0.025）

---

## 📝 下一步行动

1. **立即尝试：OpenRouter**
   - 注册账号：https://openrouter.ai/
   - 获取API key
   - 配置Midscene
   - 测试是否可用

2. **备选方案：Doubao**
   - 注册火山引擎账号
   - 获取API key
   - 测试JSON格式

3. **最后方案：付费使用GPT-4o**
   - 如果其他方案都不行
   - 使用OpenAI官方API
   - 成本可控

---

**竹林，虾哥建议先尝试OpenRouter！** 🦐
