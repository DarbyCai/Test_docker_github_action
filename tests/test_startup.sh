#!/bin/bash
# tests/test_startup.sh.in - 應用程式啟動測試

set -e

APP_PATH="$1"
if [ -z "$APP_PATH" ]; then
    APP_PATH="/home/ktnf/Code/gtk_multitest_project/build/src/gtk-test-app"
fi

echo "🧪 Testing GTK application startup..."
echo "Application path: $APP_PATH"

# 檢查應用程式是否存在
if [ ! -f "$APP_PATH" ]; then
    echo "❌ Application binary not found: $APP_PATH"
    exit 1
fi

# 檢查是否可執行
if [ ! -x "$APP_PATH" ]; then
    echo "❌ Application is not executable: $APP_PATH"
    exit 1
fi

# 啟動虛擬顯示
if command -v Xvfb >/dev/null 2>&1; then
    echo "🖥️ Starting virtual display..."
    export DISPLAY=:99
    Xvfb :99 -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 2
    echo "Virtual display started (PID: $XVFB_PID)"
else
    echo "⚠️ Xvfb not available - skipping display setup"
fi

# 執行應用程式測試
echo "🚀 Running application in AUTO_TEST mode..."
export AUTO_TEST=1

if timeout 15 "$APP_PATH"; then
    echo "✅ Application started and closed successfully"
    test_result=0
else
    echo "❌ Application test failed or timeout"
    test_result=1
fi

# 清理虛擬顯示
if [ -n "$XVFB_PID" ]; then
    kill $XVFB_PID 2>/dev/null || true
    echo "Virtual display cleaned up"
fi

if [ $test_result -eq 0 ]; then
    echo "🎉 Startup test PASSED"
else
    echo "💥 Startup test FAILED"
fi

exit $test_result
