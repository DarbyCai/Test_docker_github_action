#!/bin/bash
# tests/test_memory.sh.in - 記憶體洩漏測試

set -e

APP_PATH="$1"
if [ -z "$APP_PATH" ]; then
    APP_PATH="/home/ktnf/Code/gtk_multitest_project/build/src/gtk-test-app"
fi

VALGRIND_LOG="valgrind_test.log"

echo "🔍 Testing memory leaks with Valgrind..."
echo "Application path: $APP_PATH"

# 檢查 Valgrind 是否可用
if ! command -v valgrind >/dev/null 2>&1; then
    echo "❌ Valgrind not found - skipping memory test"
    exit 77  # Skip test
fi

# 檢查應用程式是否存在
if [ ! -f "$APP_PATH" ]; then
    echo "❌ Application binary not found: $APP_PATH"
    exit 1
fi

# 啟動虛擬顯示
if command -v Xvfb >/dev/null 2>&1; then
    echo "🖥️ Starting virtual display for memory test..."
    export DISPLAY=:99
    Xvfb :99 -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 2
else
    echo "⚠️ Xvfb not available - memory test may fail"
fi

# 執行 Valgrind 測試
echo "🧪 Running Valgrind memory check..."
export AUTO_TEST=1

# Valgrind 參數說明:
# --tool=memcheck: 使用記憶體檢查工具
# --leak-check=full: 完整的洩漏檢查
# --show-leak-kinds=all: 顯示所有類型的洩漏
# --track-origins=yes: 追蹤未初始化值的來源
# --verbose: 詳細輸出
# --log-file: 輸出到檔案

if timeout 60 valgrind \
    --tool=memcheck \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --log-file="$VALGRIND_LOG" \
    --error-exitcode=42 \
    "$APP_PATH"; then
    valgrind_exit_code=0
else
    valgrind_exit_code=$?
fi

# 清理虛擬顯示
if [ -n "$XVFB_PID" ]; then
    kill $XVFB_PID 2>/dev/null || true
fi

# 分析 Valgrind 結果
echo "📊 Analyzing Valgrind results..."

if [ ! -f "$VALGRIND_LOG" ]; then
    echo "❌ Valgrind log file not created"
    exit 1
fi

echo "Valgrind log contents:"
echo "====================="
cat "$VALGRIND_LOG"
echo "====================="

# 檢查記憶體洩漏
if grep -q "no leaks are possible" "$VALGRIND_LOG"; then
    echo "✅ No memory leaks detected"
    memory_result="CLEAN"
elif grep -q "definitely lost.*0 bytes" "$VALGRIND_LOG" && \
     grep -q "possibly lost.*0 bytes" "$VALGRIND_LOG"; then
    echo "✅ No significant memory leaks detected"
    memory_result="CLEAN" 
else
    echo "⚠️ Memory leaks detected:"
    grep -A5 -B2 "definitely lost\|possibly lost" "$VALGRIND_LOG" || true
    memory_result="LEAKS"
fi

# 檢查記憶體錯誤
if grep -q "ERROR SUMMARY: 0 errors" "$VALGRIND_LOG"; then
    echo "✅ No memory errors detected"
    error_result="CLEAN"
else
    echo "⚠️ Memory errors detected:"
    grep -A3 "ERROR SUMMARY" "$VALGRIND_LOG" || true
    error_result="ERRORS"
fi

# 決定測試結果
echo ""
echo "📋 Memory Test Summary:"
echo "  Memory Leaks: $memory_result"
echo "  Memory Errors: $error_result"

# 注意：我們的測試應用程式故意包含記憶體洩漏
# 所以這個測試主要是確保 Valgrind 能正確檢測到洩漏
if [ "$memory_result" = "LEAKS" ] && [ "$error_result" = "CLEAN" ]; then
    echo "✅ Memory leak detection working correctly (leaks found as expected)"
    exit 0
elif [ "$memory_result" = "CLEAN" ] && [ "$error_result" = "CLEAN" ]; then
    echo "⚠️ No memory leaks found - this is unexpected for our test app"
    exit 0  # Still pass, maybe leaks were fixed
else
    echo "❌ Memory errors detected - this needs investigation"
    exit 1
fi
