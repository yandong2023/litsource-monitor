# LitSource Daily Monitor

基于 [last30days-skill](https://github.com/mvanhorn/last30days-skill) 的每日研究监控系统，专门追踪引用验证、学术诚信相关话题。

## 监控内容

| 关键词 | 用途 |
|--------|------|
| **citation verification** | 引用验证工具讨论 |
| **hallucinated citation** | AI 生成虚假引用话题 |
| **RefChecker** | 竞品动态 |
| **SourceVerify** | 竞品动态 |

## 数据源

- ✅ **Hacker News** (免费) - 技术社区讨论
- ⏳ **Brave Web Search** (需 API Key) - 网页搜索
- ⏳ **Reddit** (需 ScrapeCreators/OpenAI) - 社区讨论

## 部署步骤

### 1. Fork/创建仓库

将本仓库推送到你的 GitHub 账号。

### 2. 配置飞书 Webhook

1. 打开你的飞书群
2. 设置 → 群机器人 → 添加机器人 → **自定义机器人**
3. 复制 Webhook URL

### 3. 配置 GitHub Secrets

进入仓库 → Settings → Secrets and variables → Actions → New repository secret：

| Secret Name | Value |
|-------------|-------|
| `FEISHU_WEBHOOK` | 你的飞书机器人 Webhook URL |

### 4. 手动测试

进入仓库 → Actions → Daily Research Monitor → Run workflow

等待 2-3 分钟，检查飞书是否收到消息。

### 5. 自动运行

配置完成后，每天北京时间 **10:00** 会自动运行并推送简报。

## 添加监控关键词

编辑 `.github/workflows/daily-monitor.yml`，复制一段 Research 步骤，修改关键词即可。

## 费用

当前配置：**完全免费**
- Hacker News API：免费
- GitHub Actions：每月 2000 分钟免费额度（足够用）

## 升级选项

| 数据源 | 费用 | 配置方式 |
|--------|------|----------|
| Brave Web Search | 免费（2000次/月） | 添加 `BRAVE_API_KEY` 到 Secrets |
| ScrapeCreators | $29/月 | 添加 `SCRAPECREATORS_API_KEY` 到 Secrets |
| OpenAI API | 按量付费 | 添加 `OPENAI_API_KEY` 到 Secrets |

## 查看历史简报

每次运行会生成 Artifact，可在 Actions 页面下载历史报告。

## 故障排查

### 没有收到飞书消息
1. 检查 `FEISHU_WEBHOOK` 是否正确配置
2. 查看 Actions 日志中的 "Send to Feishu" 步骤
3. 确认飞书机器人没有被禁言

### 数据太少
- Hacker News 对某些话题讨论较少，这是正常的
- 可考虑添加 Brave API Key 扩展数据源

---

Powered by [last30days-skill](https://github.com/mvanhorn/last30days-skill)
