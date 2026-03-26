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

# 提取关键内容（限制长度，避免格式错误）
CONTENT=$(head -n 30 "$BRIEF_FILE" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g' | tr '\n' ' ')

# 如果内容太长，截断
if [ ${#CONTENT} -gt 3000 ]; then
    CONTENT="${CONTENT:0:3000}... [truncated]"
fi

# 构建 JSON 并发送
JSON_PAYLOAD="{\"msg_type\":\"text\",\"content\":{\"text\":\"$CONTENT\"}}"

curl -s -X POST "$FEISHU_WEBHOOK" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    || echo "Failed to send Feishu notification"

# 清理
rm -rf "$WORK_DIR"

echo "Done!"
