#!/bin/bash
# talk.sh — 핸즈프리 Claude 음성 루프 (폰 Termux 전용)
# 사용법: talk  (설치: ln -s ~/termux-bridge/local/talk.sh ~/bin/talk)
#
# 루프: termux-speech-to-text → claude -p → termux-tts-speak
# 과금 0원. 전부 로컬.

clean_for_tts() {
    # 코드블록 제거 → 마크다운 기호 제거 → 빈줄 제거
    python3 -c "
import sys, re
text = sys.stdin.read()
# 코드블록 제거
text = re.sub(r'\`\`\`.*?\`\`\`', '', text, flags=re.DOTALL)
text = re.sub(r'\`[^\`]+\`', '', text)
# 마크다운 기호 제거
text = re.sub(r'[#*_~>|]', '', text)
# 연속 공백/줄바꿈 정리
text = re.sub(r'\n{3,}', '\n\n', text)
text = re.sub(r'[ \t]+', ' ', text)
# 빈 줄 제거
lines = [l.strip() for l in text.splitlines() if l.strip()]
print('\n'.join(lines))
"
}

SAY() {
    termux-tts-speak "$1"
}

echo "🎙️  Claude 음성 루프 시작"
echo "    말하면 Claude가 답하고 읽어줌"
echo "    '종료' '그만' '멈춰' 말하면 끝"
echo "    Ctrl+C로도 종료"
echo ""

SAY "준비됐어. 말해봐."

while true; do
    echo "👂 듣는 중..."

    # STT — 안드로이드 내장 엔진
    RAW=$(termux-speech-to-text 2>/dev/null)
    TEXT=$(echo "$RAW" | jq -r '.transcript // empty' 2>/dev/null)

    if [ -z "$TEXT" ]; then
        echo "❌ 인식 실패. 다시..."
        SAY "다시 말해줘"
        continue
    fi

    echo "🗣️  [나] $TEXT"

    # 종료 명령
    if echo "$TEXT" | grep -qP '(종료|그만|멈춰|스톱|stop|exit|quit)'; then
        SAY "알겠어, 종료할게."
        echo "👋 종료"
        break
    fi

    echo "💭 Claude 생각 중..."

    # Claude 원샷 응답
    RESPONSE=$(claude -p "$TEXT" 2>/dev/null)

    if [ -z "$RESPONSE" ]; then
        SAY "응답을 못 받았어."
        continue
    fi

    echo ""
    echo "🤖 [Claude]"
    echo "$RESPONSE"
    echo ""

    # TTS 읽기
    CLEAN=$(echo "$RESPONSE" | clean_for_tts)
    SAY "$CLEAN"
done
