#!/bin/bash
# LitSource Daily Monitor Script
# 基于 last30days-skill，支持 Reddit + Twitter/X

set -e

# 配置
FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/657d16d5-79d1-4150-b869-11383208a8d8"
WORK_DIR="/tmp/litsource-monitor-$(date +%Y%m%d-%H%M%S)"
BRIEF_FILE="$WORK_DIR/brief.md"

# API Keys（从环境变量或 ~/.config/litsource-monitor/.env 读取）
ENV_FILE="$HOME/.config/litsource-monitor/.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs) 2>/dev/null || true
fi

# 创建工作目录
mkdir -p "$WORK_DIR"

# 安装 last30days-skill（使用 fork 版本支持 Kimi）
echo "Installing last30days-skill (Kimi-compatible fork)..."
git clone --depth 1 https://github.com/yandong2023/last30days-skill.git "$WORK_DIR/last30days" 2>/dev/null || true
cd "$WORK_DIR/last30days"
pip install -q -r requirements.txt 2>/dev/null || true

# 写入环境配置（支持 Kimi/DeepSeek 等 OpenAI-compatible API）
if [ -n "$OPENAI_API_KEY" ] || [ -n "$XAI_API_KEY" ]; then
    cat > "$WORK_DIR/last30days/.env" << EOF
OPENAI_API_KEY=${OPENAI_API_KEY:-}
OPENAI_BASE_URL=${OPENAI_BASE_URL:-}
XAI_API_KEY=${XAI_API_KEY:-}
AUTH_TOKEN=${AUTH_TOKEN:-}
CT0=${CT0:-}
EOF
fi

# 开始生成简报
echo "📊 LitSource Daily Brief — $(date +%Y-%m-%d)" > "$BRIEF_FILE"
echo "" >> "$BRIEF_FILE"

# 优化后的关键词列表（更适合 Reddit/Twitter 口语化表达）
# 第一组：学术圈常用
KEYWORDS_ACADEMIC=(
    "citation verification"
    "reference checker"
)

# 第二组：Reddit/Twitter 口语化
KEYWORDS_SOCIAL=(
    "fake citation"
    "AI hallucination paper"
    "made up reference"
    "ChatGPT fake source"
)

# 第三组：竞品监控
KEYWORDS_COMPETITOR=(
    "RefChecker"
    "SourceVerify"
    "VeriExCite"
    "Citalyze"
)

# 构建 last30days 参数
LAST30DAYS_ARGS="--quick"
if [ -n "$OPENAI_API_KEY" ]; then
    LAST30DAYS_ARGS=""  # 有 OpenAI key 时用默认模式（包含 Reddit）
fi

# 函数：执行监控
run_research() {
    local keyword="$1"
    local emoji="$2"
    
    echo "Researching: $keyword..."
    
    # 运行 last30days
    python3 scripts/last30days.py $LAST30DAYS_ARGS "$keyword" > "$WORK_DIR/${keyword// /_}.txt" 2>&1 || true
    
    # 添加到简报
    echo "### $emoji ${keyword}" >> "$BRIEF_FILE"
    echo "" >> "$BRIEF_FILE"
    
    # 提取关键内容
    if [ -s "$WORK_DIR/${keyword// /_}.txt" ]; then
        # 提取关键统计信息
        grep -E "(Found|✓|Research complete)" "$WORK_DIR/${keyword// /_}.txt" | head -5 >> "$BRIEF_FILE" || true
        echo "" >> "$BRIEF_FILE"
        
        # 提取主要内容（限制行数）
        grep -A 3 "^###\|^\*\*HN\|^\*\*Reddit\|^\*\*X" "$WORK_DIR/${keyword// /_}.txt" | head -40 >> "$BRIEF_FILE" || true
        
        # 如果没有提取到内容，显示原始内容的前 30 行
        if ! grep -q "HN\|Reddit\|X" "$BRIEF_FILE" 2>/dev/null; then
            head -30 "$WORK_DIR/${keyword// /_}.txt" >> "$BRIEF_FILE"
        fi
    else
        echo "No results found for today." >> "$BRIEF_FILE"
    fi
    
    echo "" >> "$BRIEF_FILE"
    echo "---" >> "$BRIEF_FILE"
    echo "" >> "$BRIEF_FILE"
}

# 执行学术关键词监控
echo "## 📚 Academic Terms" >> "$BRIEF_FILE"
echo "" >> "$BRIEF_FILE"
for keyword in "${KEYWORDS_ACADEMIC[@]}"; do
    run_research "$keyword" "🔍"
done

# 执行社交关键词监控
echo "## 💬 Social Media Terms" >> "$BRIEF_FILE"
echo "" >> "$BRIEF_FILE"
for keyword in "${KEYWORDS_SOCIAL[@]}"; do
    emoji="💬"
    [[ "$keyword" == *"fake"* ]] && emoji="⚠️"
    [[ "$keyword" == *"hallucination"* ]] && emoji="🤖"
    [[ "$keyword" == *"ChatGPT"* ]] && emoji="💚"
    run_research "$keyword" "$emoji"
done

# 执行竞品监控
echo "## 🏢 Competitors" >> "$BRIEF_FILE"
echo "" >> "$BRIEF_FILE"
for keyword in "${KEYWORDS_COMPETITOR[@]}"; do
    run_research "$keyword" "🛠️"
done

# 发送到飞书
echo "Sending to Feishu..."

BRIEF_PATH="$BRIEF_FILE"

python3 << EOF
import json
import urllib.request
import sys

webhook = "https://open.feishu.cn/open-apis/bot/v2/hook/657d16d5-79d1-4150-b869-11383208a8d8"
brief_path = """$BRIEF_PATH"""

with open(brief_path, "r", encoding="utf-8") as f:
    content = f.read()

if len(content) > 3000:
    content = content[:3000] + "... [truncated]"

payload = {
    "msg_type": "text",
    "content": {
        "text": content
    }
}

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
