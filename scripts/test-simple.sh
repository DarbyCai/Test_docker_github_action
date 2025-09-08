#!/bin/bash

# scripts/test-simple.sh
# 簡化版的 Docker 測試腳本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐳 Simple Docker Test for GTK CMake Project${NC}"
echo ""

# 清理本地 build 目錄
if [ -d "build" ]; then
    echo -e "${YELLOW}🧹 Cleaning local build directory...${NC}"
    rm -rf build
fi

# 測試 Ubuntu 22.04
echo -e "${YELLOW}📦 Testing Ubuntu 22.04...${NC}"
if docker build --build-arg UBUNTU_VERSION=22.04 -t gtk-simple-test -f docker/Dockerfile.ubuntu .; then
    echo -e "${GREEN}✅ Ubuntu 22.04 build successful${NC}"
    
    if docker run --rm gtk-simple-test; then
        echo -e "${GREEN}✅ Ubuntu 22.04 test PASSED${NC}"
    else
        echo -e "${RED}❌ Ubuntu 22.04 test FAILED${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Ubuntu 22.04 build FAILED${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📦 Testing Rocky Linux 9...${NC}"
if docker build --build-arg ROCKY_VERSION=9 -t gtk-rocky-test -f docker/Dockerfile.rocky .; then
    echo -e "${GREEN}✅ Rocky Linux 9 build successful${NC}"
    
    if docker run --rm gtk-rocky-test; then
        echo -e "${GREEN}✅ Rocky Linux 9 test PASSED${NC}"
    else
        echo -e "${RED}❌ Rocky Linux 9 test FAILED${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Rocky Linux 9 build FAILED${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All simple tests passed!${NC}"
echo ""
echo "Next steps:"
echo "1. Run full test suite: ./scripts/test-docker-complete.sh"
echo "2. Run memory leak tests:"
echo "   docker run --rm gtk-simple-test /workspace/memory-test.sh"
echo "   docker run --rm gtk-rocky-test /workspace/memory-test.sh"

# 清理
docker rmi gtk-simple-test gtk-rocky-test >/dev/null 2>&1 || true
