#!/bin/bash

# scripts/test-docker.sh
# CMake版本的 Docker 多平台測試腳本

set -e

echo "🐳 Starting CMake-based Docker multi-platform tests..."

# 測試配置
UBUNTU_VERSIONS=("20.04" "22.04" "24.04")
ROCKY_VERSIONS=("8" "9")

# 顏色輸出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 結果追蹤
declare -a RESULTS
failed_tests=0

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║    GTK CMake Multi-Platform Tester    ║"
    echo "║                                        ║"
    echo "║  Testing GTK app with CMake build     ║"
    echo "║  Date: $(date +'%Y-%m-%d %H:%M:%S')           ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

test_ubuntu() {
    local version=$1
    local test_name="Ubuntu-${version}"
    
    echo -e "${YELLOW}�� Testing ${test_name}...${NC}"
    
    # 建立 Docker image
    echo "🏗️ Building Docker image for ${test_name}..."
    if docker build \
        --build-arg UBUNTU_VERSION=${version} \
        -t gtk-cmake-test:ubuntu-${version} \
        -f docker/Dockerfile.ubuntu \
        --progress=plain \
        . >/dev/null 2>&1; then
        echo "✅ Docker image built successfully"
    else
        echo "❌ Docker image build failed"
        RESULTS+=("${test_name}: BUILD_FAILED")
        return 1
    fi
    
    # 執行基本測試
    echo "🧪 Running application test..."
    if docker run --rm \
        --name "test-${test_name,,}" \
        gtk-cmake-test:ubuntu-${version}; then
        echo -e "${GREEN}✅ ${test_name} - Application test PASSED${NC}"
        basic_result="PASSED"
    else
        echo -e "${RED}❌ ${test_name} - Application test FAILED${NC}"
        basic_result="FAILED"
        ((failed_tests++))
    fi
    
    # 執行記憶體測試
    echo "🔍 Running memory leak test..."
    if docker run --rm \
        --name "memtest-${test_name,,}" \
        gtk-cmake-test:ubuntu-${version} \
        /workspace/memory-test.sh; then
        echo -e "${GREEN}✅ ${test_name} - Memory test PASSED${NC}"
        memory_result="PASSED"
    else
        echo -e "${YELLOW}⚠️ ${test_name} - Memory leaks detected (expected)${NC}"
        memory_result="LEAKS_FOUND"
    fi
    
    RESULTS+=("${test_name}: App=${basic_result}, Memory=${memory_result}")
    echo ""
}

test_rocky() {
    local version=$1
    local test_name="Rocky-${version}"
    
    echo -e "${YELLOW}📦 Testing ${test_name}...${NC}"
    
    # 建立 Docker image
    echo "🏗️ Building Docker image for ${test_name}..."
    if docker build \
        --build-arg ROCKY_VERSION=${version} \
        -t gtk-cmake-test:rocky-${version} \
        -f docker/Dockerfile.rocky \
        --progress=plain \
        . >/dev/null 2>&1; then
        echo "✅ Docker image built successfully"
    else
        echo "❌ Docker image build failed"
        RESULTS+=("${test_name}: BUILD_FAILED")
        return 1
    fi
    
    # 執行基本測試
    echo "🧪 Running application test..."
    if docker run --rm \
        --name "test-${test_name,,}" \
        gtk-cmake-test:rocky-${version}; then
        echo -e "${GREEN}✅ ${test_name} - Application test PASSED${NC}"
        basic_result="PASSED"
    else
        echo -e "${RED}❌ ${test_name} - Application test FAILED${NC}"
        basic_result="FAILED"
        ((failed_tests++))
    fi
    
    # 執行記憶體測試
    echo "🔍 Running memory leak test..."
    if docker run --rm \
        --name "memtest-${test_name,,}" \
        gtk-cmake-test:rocky-${version} \
        /workspace/memory-test.sh; then
        echo -e "${GREEN}✅ ${test_name} - Memory test PASSED${NC}"
        memory_result="PASSED"
    else
        echo -e "${YELLOW}⚠️ ${test_name} - Memory leaks detected (expected)${NC}"
        memory_result="LEAKS_FOUND"
    fi
    
    RESULTS+=("${test_name}: App=${basic_result}, Memory=${memory_result}")
    echo ""
}

cleanup_docker() {
    echo "🧹 Cleaning up Docker resources..."
    
    # 清理測試容器
    docker ps -a --filter "name=test-" --filter "name=memtest-" -q | xargs -r docker rm -f >/dev/null 2>&1 || true
    
    # 可選：清理測試映像（取消註解以啟用）
    # docker images "gtk-cmake-test:*" -q | xargs -r docker rmi -f >/dev/null 2>&1 || true
    
    echo "Docker cleanup completed"
}

generate_report() {
    local report_file="docker-test-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# GTK CMake Docker Test Report

**Generated:** $(date)
**Build System:** CMake + Ninja
**Test Script:** $0

## Test Results Summary

EOF

    echo "| Platform | Application Test | Memory Test |" >> "$report_file"
    echo "|----------|------------------|-------------|" >> "$report_file"
    
    for result in "${RESULTS[@]}"; do
        platform=$(echo "$result" | cut -d: -f1)
        details=$(echo "$result" | cut -d: -f2)
        
        if [[ "$details" == *"BUILD_FAILED"* ]]; then
            echo "| $platform | ❌ Build Failed | - |" >> "$report_file"
        else
            app_status=$(echo "$details" | grep -o "App=[^,]*" | cut -d= -f2)
            mem_status=$(echo "$details" | grep -o "Memory=[^,]*" | cut -d= -f2)
            
            case "$app_status" in
                "PASSED") app_icon="✅ Passed" ;;
                "FAILED") app_icon="❌ Failed" ;;
                *) app_icon="❓ Unknown" ;;
            esac
            
            case "$mem_status" in
                "PASSED") mem_icon="✅ Clean" ;;
                "LEAKS_FOUND") mem_icon="⚠️ Leaks Found" ;;
                *) mem_icon="❓ Unknown" ;;
            esac
            
            echo "| $platform | $app_icon | $mem_icon |" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

## Build Information

- **CMake Version:** $(cmake --version 2>/dev/null | head -1 || echo "Not available")
- **Docker Version:** $(docker --version 2>/dev/null || echo "Not available")
- **Test Date:** $(date)
- **Failed Tests:** $failed_tests

## Notes

- Memory leaks are intentionally included in the test application
- ✅ Passed: Application runs without errors
- ⚠️ Leaks Found: Expected behavior for test application
- ❌ Failed: Application failed to start or crashed

EOF

    echo -e "${GREEN}📄 Detailed report saved to: $report_file${NC}"
}

# 主要執行流程
main() {
    print_header
    
    # 檢查必要工具
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
        exit 1
    fi
    
    # 檢查 Docker daemon
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon not running. Please start Docker.${NC}"
        exit 1
    fi
    
    # 檢查專案檔案
    if [ ! -f "CMakeLists.txt" ] || [ ! -d "src" ]; then
        echo -e "${RED}❌ Not in project root directory or missing CMake files${NC}"
        exit 1
    fi
    
    echo "🚀 Starting multi-platform tests..."
    echo ""
    
    # 測試 Ubuntu 版本
    echo -e "${BLUE}📋 Testing Ubuntu versions...${NC}"
    for version in "${UBUNTU_VERSIONS[@]}"; do
        test_ubuntu "$version"
    done
    
    # 測試 Rocky Linux 版本
    echo -e "${BLUE}📋 Testing Rocky Linux versions...${NC}"
    for version in "${ROCKY_VERSIONS[@]}"; do
        test_rocky "$version"
    done
    
    # 顯示結果摘要
    echo -e "${BLUE}📊 Test Results Summary:${NC}"
    echo "┌─────────────────────────────────────────────────┐"
    printf "│ %-15s │ %-15s │ %-15s │\n" "Platform" "App Test" "Memory Test"
    echo "├─────────────────────────────────────────────────┤"
    
    for result in "${RESULTS[@]}"; do
        platform=$(echo "$result" | cut -d: -f1)
        details=$(echo "$result" | cut -d: -f2)
        
        if [[ "$details" == *"BUILD_FAILED"* ]]; then
            printf "│ %-15s │ %-15s │ %-15s │\n" "$platform" "❌ Build Failed" "-"
        else
            app_status=$(echo "$details" | grep -o "App=[^,]*" | cut -d= -f2)
            mem_status=$(echo "$details" | grep -o "Memory=[^,]*" | cut -d= -f2)
            
            [[ "$app_status" == "PASSED" ]] && app_display="✅ Passed" || app_display="❌ Failed"
            [[ "$mem_status" == "PASSED" ]] && mem_display="✅ Clean" || mem_display="⚠️ Leaks"
            
            printf "│ %-15s │ %-15s │ %-15s │\n" "$platform" "$app_display" "$mem_display"
        fi
    done
    
    echo "└─────────────────────────────────────────────────┘"
    
    # 最終結果
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 All application tests passed!${NC}"
        echo -e "${YELLOW}📝 Note: Memory leaks are expected in test application${NC}"
        final_result=0
    else
        echo -e "${RED}❌ $failed_tests application test(s) failed${NC}"
        final_result=1
    fi
    
    # 生成報告
    generate_report
    
    # 詢問是否清理 Docker
    echo ""
    read -p "Clean up Docker images and containers? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_docker
    fi
    
    echo -e "${GREEN}✅ Docker testing completed${NC}"
    exit $final_result
}

# 信號處理 - 清理資源
trap cleanup_docker EXIT INT TERM

# 執行主程式
main "$@"
