# 2026-03-07 - 飞书连接问题排查与解决

## 问题描述
用户在飞书发送消息，但我没有任何回应。

## 排查过程
1. 检查 Gateway 状态 → 飞书显示 ON/OK
2. 检查日志 → 发现消息已接收但未响应
3. 检查配置 → 发现 `dmPolicy: "pairing"` 但 `allowFrom` 为空

## 根本原因
**飞书 DM 策略设置为 "pairing" 模式，但用户 ID 未添加到白名单**

配置：
```json
{
  "dmPolicy": "pairing",  // 需要配对
  "allowFrom": []         // 白名单为空 → 所有消息被忽略
}
```

## 解决方案
```bash
openclaw config set channels.feishu.allowFrom "ou_889dbc465c49c77583f2f0264e32a421"
openclaw gateway restart
```

## 经验教训

### 🔴 关键配置检查清单
当某个渠道"连接正常但不响应"时，按此顺序检查：

1. **Gateway 状态**
   ```bash
   openclaw status | grep -i <channel>
   ```

2. **日志中是否收到消息**
   ```bash
   openclaw logs | grep "received message"
   ```

3. **策略配置**
   ```bash
   openclaw config get channels.<channel>.dmPolicy
   openclaw config get channels.<channel>.allowFrom
   ```

4. **常见策略模式**
   - `open`: 接受所有消息
   - `pairing`: 需要白名单
   - `allowlist`: 严格白名单

### 📋 预防措施

**初次配置渠道时必须确认：**
- [ ] `dmPolicy` 设置正确
- [ ] 如果是 `pairing`/`allowlist`，添加用户 ID 到 `allowFrom`
- [ ] 重启 Gateway 后测试发送消息
- [ ] 检查日志确认响应

### 🛠️ 快速诊断命令
```bash
# 一键检查所有渠道配置
openclaw config get channels | grep -E "(Policy|allowFrom)"

# 查看最近消息日志
openclaw logs | grep "received message" | tail -10
```

## 相关配置路径
- Telegram: `channels.telegram.allowFrom`
- 飞书: `channels.feishu.allowFrom`
- Discord: `channels.discord.allowFrom`

## 记录时间
2026-03-07 13:37

## 状态
✅ 已解决
