# src/CMakeLists.txt

# 收集所有源文件
file(GLOB_RECURSE SOURCES 
    "${CMAKE_CURRENT_SOURCE_DIR}/*.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
)

# 創建執行文件
add_executable(gtk-test-app ${SOURCES})

# 連結 GTK3 函式庫
target_link_libraries(gtk-test-app ${GTK3_LIBRARIES})

# 設定編譯定義
target_compile_definitions(gtk-test-app PRIVATE
    $<$<CONFIG:Debug>:DEBUG_MODE>
    $<$<CONFIG:Release>:RELEASE_MODE>
    APP_VERSION="${PROJECT_VERSION}"
)

# 設定包含目錄
target_include_directories(gtk-test-app PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${GTK3_INCLUDE_DIRS}
)

# 設定編譯選項
target_compile_options(gtk-test-app PRIVATE ${GTK3_CFLAGS_OTHER})

# 設定執行時路徑
if(UNIX AND NOT APPLE)
    set_target_properties(gtk-test-app PROPERTIES
        INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib"
        INSTALL_RPATH_USE_LINK_PATH TRUE
    )
endif()

# Debug 版本的額外設定
if(CMAKE_BUILD_TYPE MATCHES Debug)
    target_compile_definitions(gtk-test-app PRIVATE MEMORY_DEBUG)
    # 可以加入更多 debug 符號
    target_compile_options(gtk-test-app PRIVATE -ggdb3)
endif()
