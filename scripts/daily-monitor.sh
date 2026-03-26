#!/bin/bash
# LitSource Daily Monitor Script
# 基于 last30days-skill 的简化版本

set -e

# 配置
FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/657d16d5-79d1-4150-b869-11383208a8d8"
WORK_DIR="/tmp/litsource-monitor-$(date +%Y%m%d-%H%M%S)"
BRIEF_FILE="$WORK_DIR/brief.md"

# 创建工作目录
mkdir -p "$WORK_DIR"

# 安装 last30days-skill
echo "Installing last30days-skill..."
git clone --depth 1 https://github.com/mvanhorn/last30days-skill.git "$WORK_DIR/last30days" 2>/dev/null || true
cd "$WORK_DIR/last30days"
pip install -q -r requirements.txt 2>/dev/null || true

# 开始生成简报
echo "📊 LitSource Daily Brief — $(date +%Y-%m-%d)" > "$BRIEF_FILE"
echo "" >> "$BRIEF_FILE"

# 监控关键词列表
KEYWORDS=(
    "citation verification"
    "hallucinated citation"
    "RefChecker"
    "SourceVerify"
)

# 执行监控
for keyword in "${KEYWORDS[@]}"; do
    echo "Researching: $keyword..."
    
    # 运行 last30days（默认模式，包含 HN）
    python3 scripts/last30days.py --quick "$keyword" > "$WORK_DIR/${keyword// /_}.txt" 2>&1 || true
    
    # 添加到简报
    emoji="🔍"
    [[ "$keyword" == *"hallucinated"* ]] && emoji="🤖"
    [[ "$keyword" == *"RefChecker"* ]] && emoji="🛠️"
    [[ "$keyword" == *"SourceVerify"* ]] && emoji="🔎"
    
    echo "### $emoji ${keyword}" >> "$BRIEF_FILE"
    echo "" >> "$BRIEF_FILE"
    
    # 提取前 60 行关键内容
    if [ -s "$WORK_DIR/${keyword// /_}.txt" ]; then
        head -60 "$WORK_DIR/${keyword// /_}.txt" >> "$BRIEF_FILE"
    else
        echo "No results found for today." >> "$BRIEF_FILE"
    fi
    
    echo "" >> "$BRIEF_FILE"
    echo "---" >> "$BRIEF_FILE"
    echo "" >> "$BRIEF_FILE"
done

# 发送到飞书
echo "Sending to Feishu..."

# 保存简报路径供 Python 使用
BRIEF_PATH="$BRIEF_FILE"

# 使用 Python 安全地构建 JSON 并发送
python3 << EOF
import json
import urllib.request
import sys

webhook = "https://open.feishu.cn/open-apis/bot/v2/hook/657d16d5-79d1-4150-b869-11383208a8d8"
brief_path = """$BRIEF_PATH"""

# 读取简报内容
with open(brief_path, "r", encoding="utf-8") as f:
    content = f.read()

# 限制长度
if len(content) > 3000:
    content = content[:3000] + "... [truncated]"

# 构建消息
payload = {
    "msg_type": "text",
    "content": {
        "text": content
    }
}

# 发送
try:
    req = urllib.request.Request(
        webhook,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        print(resp.read().decode())
        print("Message sent successfully")
except Exception as e:
    print(f"Failed to send: {e}")
    sys.exit(1)
EOF

# 清理
rm -rf "$WORK_DIR"

echo "Done!"
