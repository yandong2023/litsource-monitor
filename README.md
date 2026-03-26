# LitSource Daily Monitor

基于 [last30days-skill](https://github.com/mvanhorn/last30days-skill) 的每日研究监控系统，追踪引用验证、学术诚信相关话题。

## 监控内容

### 关键词分组

| 分组 | 关键词 | 用途 |
|------|--------|------|
| **学术术语** | citation verification, reference checker | 学术圈正式讨论 |
| **社交媒体** | fake citation, AI hallucination paper, made up reference, ChatGPT fake source | Reddit/Twitter 口语化讨论 |
| **竞品监控** | RefChecker, SourceVerify, VeriExCite, Citalyze | 竞品动态 |

## 数据源

| 平台 | 状态 | 所需配置 |
|------|------|----------|
| **Hacker News** | ✅ 免费可用 | 无需配置 |
| **Reddit** | ⚡ 需 OpenAI API | `OPENAI_API_KEY` |
| **Twitter/X** | ⚡ 需 xAI API 或 Cookie | `XAI_API_KEY` 或 `AUTH_TOKEN/CT0` |
| **Web** | ✅ 助手搜索 | 无需配置 |

## 快速开始

### 1. 基础配置（免费版 - HN 数据）

已部署，每天 10:00 自动运行，无需额外配置。

### 2. 完整配置（推荐 - Reddit + Twitter）

#### 方式 A：OpenAI API（解锁 Reddit）

```bash
# 1. 创建配置目录
mkdir -p ~/.config/litsource-monitor

# 2. 创建配置文件
cat > ~/.config/litsource-monitor/.env << 'EOF'
OPENAI_API_KEY=sk-your-key-here
EOF

# 3. 测试运行
bash scripts/daily-monitor.sh
```

#### 方式 B：xAI API（解锁 Twitter）

```bash
cat > ~/.config/litsource-monitor/.env << 'EOF'
XAI_API_KEY=xai-your-key-here
EOF
```

#### 方式 C：Twitter Cookie（免费解锁 Twitter）

```bash
# 1. 浏览器登录 x.com
# 2. F12 → Application → Cookies → x.com
# 3. 复制 auth_token 和 ct0

cat > ~/.config/litsource-monitor/.env << 'EOF'
AUTH_TOKEN=your-auth-token
CT0=your-ct0-value
EOF
```

## 定时任务

已配置 OpenClaw 定时任务：
- **ID**: a13cd6af-e9e5-4d71-8aa4-1f659a732232
- **时间**: 每天 10:00（北京时间）
- **命令**: `bash /root/.openclaw/workspace/litsource-monitor/scripts/daily-monitor.sh`

### 查看/修改定时任务

```bash
# 查看所有定时任务
openclaw cron list

# 手动触发运行
openclaw cron trigger a13cd6af-e9e5-4d71-8aa4-1f659a732232

# 删除任务（如需重新配置）
openclaw cron remove a13cd6af-e9e5-4d71-8aa4-1f659a732232
```

## 查看结果

每天 10:00 飞书群收到简报，包含：
- 各关键词的搜索结果统计
- HN/Reddit/Twitter 相关讨论摘要
- 竞品动态更新

## 费用预估

| 配置 | 月费用 | 覆盖数据源 |
|------|--------|-----------|
| **免费版** | $0 | HN + Web |
| **Reddit 版** | ~$3-5 | HN + Reddit + Web |
| **完整版** | ~$8-15 | HN + Reddit + Twitter + Web |

## 关键词优化建议

如果某关键词长期无结果，尝试：
1. **更口语化**: `"citation verification"` → `"fake citation"`
2. **加场景**: `"AI paper"` → `"ChatGPT fake source"`
3. **去学术**: `"reference checker"` → `"made up reference"`

## 故障排查

### Reddit 搜索失败
- 检查 `OPENAI_API_KEY` 是否配置正确
- 确认 API key 有余额

### Twitter 搜索失败
- 如果使用 Cookie 方式，检查是否过期（需重新登录获取）
- 如果使用 xAI，确认 `XAI_API_KEY` 有效

### 飞书收不到消息
- 检查 Webhook URL 是否正确
- 确认飞书机器人未被禁言

## GitHub 仓库

https://github.com/yandong2023/litsource-monitor

---

Powered by [last30days-skill](https://github.com/mvanhorn/last30days-skill)
