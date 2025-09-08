cmake_minimum_required(VERSION 3.16)
project(gtk-memory-test VERSION 1.0.0 LANGUAGES C)

#hi

# 設定 C 標準
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# 設定編譯類型
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# 編譯選項
set(CMAKE_C_FLAGS_DEBUG "-g -O0 -Wall -Wextra -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE "-O2 -DNDEBUG")

# 找尋 GTK3
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)

# 設定包含目錄
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${GTK3_INCLUDE_DIRS})

# 設定連結目錄
link_directories(${GTK3_LIBRARY_DIRS})

# 編譯選項
add_compile_options(${GTK3_CFLAGS_OTHER})

# 添加子目錄
add_subdirectory(src)

# 安裝設定
install(TARGETS gtk-test-app
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib/static)

# CPack 設定 (用於打包)
set(CPACK_PACKAGE_NAME "gtk-memory-test")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION "GTK Memory Test Application")
set(CPACK_PACKAGE_CONTACT "your-email@example.com")
include(CPack)

# 測試支援
enable_testing()
add_subdirectory(tests)

# 自定義目標
add_custom_target(run
    COMMAND ${CMAKE_BINARY_DIR}/src/gtk-test-app
    DEPENDS gtk-test-app
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running GTK test application"
)

# Memory test 目標
add_custom_target(memtest
    COMMAND valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all 
            --track-origins=yes --log-file=valgrind.log 
            ${CMAKE_BINARY_DIR}/src/gtk-test-app || true
    DEPENDS gtk-test-app
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Running memory leak test with Valgrind"
)

# Docker build 目標
add_custom_target(docker-build
    COMMAND docker build -t gtk-cmake-test:latest -f ${CMAKE_SOURCE_DIR}/docker/Dockerfile.ubuntu .
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building Docker image"
)

# 顯示配置資訊
message(STATUS "")
message(STATUS "Configuration Summary:")
message(STATUS "  Project Name: ${PROJECT_NAME}")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  Install Prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  GTK3 Version: ${GTK3_VERSION}")
message(STATUS "")
