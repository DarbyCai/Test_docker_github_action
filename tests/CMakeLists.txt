# tests/CMakeLists.txt

# 尋找測試框架（可選）
find_program(VALGRIND_PROGRAM valgrind)
find_program(XVFB_PROGRAM Xvfb)

# 基本編譯測試
add_test(NAME compile_test
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target gtk-test-app
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

# 應用程式啟動測試
if(XVFB_PROGRAM)
    add_test(NAME app_startup_test
        COMMAND ${CMAKE_SOURCE_DIR}/tests/test_startup.sh ${CMAKE_BINARY_DIR}/src/gtk-test-app
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    set_tests_properties(app_startup_test PROPERTIES
        ENVIRONMENT "DISPLAY=:99"
        TIMEOUT 30
    )
else()
    message(WARNING "Xvfb not found - GUI tests will be skipped")
endif()

# Memory leak 測試
if(VALGRIND_PROGRAM)
    add_test(NAME memory_leak_test
        COMMAND ${CMAKE_SOURCE_DIR}/tests/test_memory.sh ${CMAKE_BINARY_DIR}/src/gtk-test-app
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
    set_tests_properties(memory_leak_test PROPERTIES
        ENVIRONMENT "DISPLAY=:99"
        TIMEOUT 60
    )
else()
    message(WARNING "Valgrind not found - memory tests will be skipped")
endif()

# 建立測試腳本目標
configure_file(
    ${CMAKE_SOURCE_DIR}/tests/test_startup.sh.in
    ${CMAKE_SOURCE_DIR}/tests/test_startup.sh
    @ONLY
)

configure_file(
    ${CMAKE_SOURCE_DIR}/tests/test_memory.sh.in  
    ${CMAKE_SOURCE_DIR}/tests/test_memory.sh
    @ONLY
)
