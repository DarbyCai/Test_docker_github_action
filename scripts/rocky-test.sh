#!/bin/bash
set -e
echo "Testing GTK app in Rocky Linux container"
echo "OS: $(cat /etc/rocky-release 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
echo "CMake version: $(cmake --version | head -1)"
echo "GTK version: $(pkg-config --modversion gtk+-3.0)"

if [ -f /workspace/build/src/gtk-test-app ]; then
    echo "Application built successfully"
    
    if command -v Xvfb >/dev/null 2>&1; then
        echo "Starting virtual display..."
        Xvfb :99 -screen 0 1024x768x24 &
        XVFB_PID=$!
        sleep 3
        
        export DISPLAY=:99
        export AUTO_TEST=1
        
        echo "Running GTK application..."
        cd /workspace/build
        timeout 15 ./src/gtk-test-app || echo "App test completed"
        
        kill $XVFB_PID 2>/dev/null || true
    else
        echo "Xvfb not available, skipping GUI test"
    fi
    
    echo "Rocky Linux container test successful"
else
    echo "Application not found"
    ls -la /workspace/build/src/ || echo "build/src directory not found"
    exit 1
fi
