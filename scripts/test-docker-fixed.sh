#!/bin/bash

# scripts/test-docker-fixed.sh
# 修正版的 Docker 測試腳本

set -e

echo "🐳 Starting Fixed Docker Multi-Platform Tests..."

# 基本設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 測試配置 - 先測試一個版本
UBUNTU_VERSIONS=("20.04")
# ROCKY_VERSIONS=("9")  # 先註解掉，專注解決 Ubuntu

failed_tests=0

# 檢查前置條件
check_prerequisites() {
    echo -e "${YELLOW}🔍 檢查前置條件...${NC}"
    
    # 檢查 Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found${NC}"
        exit 1
    fi
    
    # 檢查 Docker daemon
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker daemon not running${NC}"
        exit 1
    fi
    
    # 檢查專案檔案
    if [ ! -f "CMakeLists.txt" ] || [ ! -f "src/main.c" ]; then
        echo -e "${RED}❌ Missing project files${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites satisfied${NC}"
}

# 測試基本 Docker 功能
test_basic_docker() {
    echo -e "${YELLOW}🧪 測試基本 Docker 功能...${NC}"
    
    if docker run --rm hello-world >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker basic test passed${NC}"
    else
        echo -e "${RED}❌ Docker basic test failed${NC}"
        exit 1
    fi
}

# 測試 Ubuntu
test_ubuntu() {
    local version=$1
    local test_name="Ubuntu-${version}"
    
    echo ""
    echo -e "${BLUE}📦 Testing ${test_name}...${NC}"
    
    # 先嘗試簡化版本
    echo "🏗️ Building simplified Docker image..."
    
    # 檢查簡化版 Dockerfile 是否存在
    if [ ! -f "docker/Dockerfile.ubuntu.minimal" ]; then
        echo -e "${YELLOW}⚠️ Creating minimal Dockerfile...${NC}"
        
        cat > docker/Dockerfile.ubuntu.minimal << 'EOF'
ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    pkg-config \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY CMakeLists.txt /workspace/
COPY src/ /workspace/src/

RUN echo "=== Building project ===" && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j2 && \
    echo "=== Build successful ==="

CMD echo "Container test successful"
EOF
    fi
    
    # 建構映像
    if docker build \
        --build-arg UBUNTU_VERSION=${version} \
        -t gtk-test-simple:ubuntu-${version} \
        -f docker/Dockerfile.ubuntu.minimal \
        . >/tmp/docker-build.log 2>&1; then
        
        echo -e "${GREEN}✅ Docker image built successfully${NC}"
        
        # 執行測試
        echo "🧪 Running container test..."
        if docker run --rm gtk-test-simple:ubuntu-${version}; then
            echo -e "${GREEN}✅ ${test_name} - Test PASSED${NC}"
        else
            echo -e "${RED}❌ ${test_name} - Test FAILED${NC}"
            ((failed_tests++))
        fi
        
    else
        echo -e "${RED}❌ Docker image build failed for ${test_name}${NC}"
        echo "Build log:"
        cat /tmp/docker-build.log | tail -20
        ((failed_tests++))
    fi
}

# 清理函數
cleanup() {
    echo "🧹 Cleaning up..."
    # 清理測試映像
    docker images "gtk-test-simple:*" -q | xargs -r docker rmi >/dev/null 2>&1 || true
    rm -f /tmp/docker-build.log
}

# 主要執行流程
main() {
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        Fixed Docker Tester           ║${NC}"
    echo -e "${BLUE}║                                      ║${NC}"
    echo -e "${BLUE}║  Simplified multi-platform testing  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""
    
    # 執行檢查和測試
    check_prerequisites
    test_basic_docker
    
    # 測試 Ubuntu 版本
    for version in "${UBUNTU_VERSIONS[@]}"; do
        test_ubuntu "$version"
    done
    
    # 顯示結果
    echo ""
    echo -e "${BLUE}📊 Test Summary:${NC}"
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Test with full Dockerfile: ./scripts/test-docker.sh"
        echo "2. Add Rocky Linux testing"
        echo "3. Set up GitHub Actions"
    else
        echo -e "${RED}❌ $failed_tests test(s) failed${NC}"
        echo ""
        echo "Check the error messages above and:"
        echo "1. Verify all project files exist"
        echo "2. Check Docker daemon status"
        echo "3. Try running the build commands manually"
    fi
}

# 設定清理陷阱
trap cleanup EXIT INT TERM

# 執行主程式
main "$@"
