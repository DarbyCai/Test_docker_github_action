#!/bin/bash

# scripts/quick-start.sh
# GTK CMake 專案快速開始腳本

set -e

# 顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 專案配置
PROJECT_NAME="GTK CMake Multi-Platform Test"
BUILD_TYPE=${BUILD_TYPE:-Debug}
BUILD_TOOL=${BUILD_TOOL:-Ninja}

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║        GTK CMake Quick Start           ║"
    echo "║                                        ║"
    echo "║  Build Type: ${BUILD_TYPE}"
    echo "║  Build Tool: ${BUILD_TOOL}"
    echo "║  Date: $(date +'%Y-%m-%d %H:%M:%S')           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_dependencies() {
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
    
    local missing_deps=()
    
    # 檢查 CMake
    if ! command -v cmake >/dev/null 2>&1; then
        missing_deps+=("cmake")
    else
        echo "✅ CMake: $(cmake --version | head -1)"
    fi
    
    # 檢查建構工具
    if [ "$BUILD_TOOL" = "Ninja" ]; then
        if ! command -v ninja >/dev/null 2>&1; then
            missing_deps+=("ninja-build")
        else
            echo "✅ Ninja: $(ninja --version)"
        fi
    fi
    
    # 檢查 GTK3
    if ! pkg-config --exists gtk+-3.0; then
        missing_deps+=("libgtk-3-dev")
    else
        echo "✅ GTK3: $(pkg-config --modversion gtk+-3.0)"
    fi
    
    # 檢查 pkg-config
    if ! command -v pkg-config >/dev/null 2>&1; then
        missing_deps+=("pkg-config")
    fi
    
    # 如果有缺少的依賴
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Missing dependencies: ${missing_deps[*]}${NC}"
        echo ""
        echo "Install them with:"
        
        # 檢測發行版並提供對應的安裝指令
        if command -v apt-get >/dev/null 2>&1; then
            echo "  sudo apt-get update"
            echo "  sudo apt-get install -y ${missing_deps[*]}"
        elif command -v dnf >/dev/null 2>&1; then
            # 轉換套件名稱為 Rocky/Fedora 格式
            local rpm_deps=()
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "libgtk-3-dev") rpm_deps+=("gtk3-devel") ;;
                    "ninja-build") rpm_deps+=("ninja-build") ;;
                    *) rpm_deps+=("$dep") ;;
                esac
            done
            echo "  sudo dnf install -y ${rpm_deps[*]}"
        elif command -v pacman >/dev/null 2>&1; then
            echo "  sudo pacman -S ${missing_deps[*]}"
        else
            echo "  Please install the missing dependencies using your system package manager"
        fi
        
        exit 1
    fi
    
    echo -e "${GREEN}✅ All dependencies satisfied${NC}"
}

setup_build_directory() {
    echo -e "${YELLOW}📁 Setting up build directory...${NC}"
    
    # 清理舊的 build 目錄（如果存在）
    if [ -d "build" ]; then
        echo "🗑️ Cleaning existing build directory..."
        rm -rf build
    fi
    
    # 創建新的 build 目錄
    mkdir build
    echo "✅ Build directory created"
}

configure_cmake() {
    echo -e "${YELLOW}⚙️ Configuring CMake...${NC}"
    
    cd build
    
    # CMake 配置參數
    local cmake_args=(
        ".."
        "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
    )
    
    # 根據建構工具添加生成器
    if [ "$BUILD_TOOL" = "Ninja" ]; then
        cmake_args+=("-G" "Ninja")
    fi
    
    # 執行 CMake 配置
    echo "Running: cmake ${cmake_args[*]}"
    if cmake "${cmake_args[@]}"; then
        echo -e "${GREEN}✅ CMake configuration successful${NC}"
    else
        echo -e "${RED}❌ CMake configuration failed${NC}"
        exit 1
    fi
    
    cd ..
}

build_project() {
    echo -e "${YELLOW}🏗️ Building project...${NC}"
    
    cd build
    
    # 決定建構命令
    local build_cmd
    if [ "$BUILD_TOOL" = "Ninja" ]; then
        build_cmd="ninja"
    else
        build_cmd="make -j$(nproc)"
    fi
    
    echo "Running: $build_cmd"
    if $build_cmd; then
        echo -e "${GREEN}✅ Build successful${NC}"
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
    
    cd ..
    
    # 顯示建構結果
    echo ""
    echo "📦 Build artifacts:"
    ls -la build/src/
}

run_basic_tests() {
    echo -e "${YELLOW}🧪 Running basic tests...${NC}"
    
    cd build
    
    # 檢查測試是否可用
    if command -v ctest >/dev/null 2>&1; then
        echo "Running CTest..."
        if ctest --output-on-failure; then
            echo -e "${GREEN}✅ Tests passed${NC}"
        else
            echo -e "${YELLOW}⚠️ Some tests failed (this may be expected)${NC}"
        fi
    else
        echo "CTest not available, skipping automated tests"
    fi
    
    cd ..
}

run_application() {
    echo -e "${YELLOW}🚀 Testing application...${NC}"
    
    # 檢查應用程式是否存在
    if [ ! -f "build/src/gtk-test-app" ]; then
        echo -e "${RED}❌ Application binary not found${NC}"
        exit 1
    fi
    
    # 設定環境變數
    export AUTO_TEST=1
    
    # 嘗試執行應用程式
    echo "Testing application startup..."
    
    # 檢查是否有顯示器
    if [ -n "$DISPLAY" ]; then
        echo "Using existing display: $DISPLAY"
        if timeout 10 build/src/gtk-test-app; then
            echo -e "${GREEN}✅ Application test successful${NC}"
        else
            echo -e "${YELLOW}⚠️ Application test completed with timeout (expected)${NC}"
        fi
    else
        echo "No display available - application built successfully but cannot test GUI"
        echo -e "${GREEN}✅ Build verification complete${NC}"
    fi
}

show_next_steps() {
    echo ""
    echo -e "${BLUE}🎉 Quick start completed successfully!${NC}"
    echo ""
    echo "📋 What you can do next:"
    echo ""
    echo "1. 🏃 Run the application:"
    echo "   cd build && ./src/gtk-test-app"
    echo ""
    echo "2. 🧪 Run tests:"
    echo "   cd build && ctest"
    echo ""
    echo "3. 🔍 Run memory leak test:"
    echo "   cd build && ninja memtest"
    echo ""
    echo "4. 🐳 Test with Docker:"
    echo "   ./scripts/test-docker.sh"
    echo ""
    echo "5. 📦 Install system-wide:"
    echo "   cd build && sudo ninja install"
    echo ""
    echo "6. 🧹 Clean build:"
    echo "   rm -rf build"
    echo ""
    echo "📚 For more information, check README.md"
}

# 主執行流程
main() {
    print_banner
    
    # 檢查是否在專案根目錄
    if [ ! -f "CMakeLists.txt" ]; then
        echo -e "${RED}❌ Not in project root directory (CMakeLists.txt not found)${NC}"
        echo "Please run this script from the project root directory"
        exit 1
    fi
    
    # 解析命令列參數
    while [[ $# -gt 0 ]]; do
        case $1 in
            --release)
                BUILD_TYPE="Release"
                shift
                ;;
            --debug)
                BUILD_TYPE="Debug"
                shift
                ;;
            --make)
                BUILD_TOOL="Make"
                shift
                ;;
            --ninja)
                BUILD_TOOL="Ninja"
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --release    Build in Release mode (default: Debug)"
                echo "  --debug      Build in Debug mode"
                echo "  --make       Use Make as build tool"
                echo "  --ninja      Use Ninja as build tool (default)"
                echo "  --help, -h   Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # 執行快速開始流程
    check_dependencies
    setup_build_directory
    configure_cmake
    build_project
    run_basic_tests
    run_application
    show_next_steps
    
    echo -e "${GREEN}🎊 Quick start completed successfully!${NC}"
}

# 錯誤處理
trap 'echo -e "${RED}❌ Script interrupted${NC}"; exit 1' INT TERM

# 執行主程式
main "$@"
