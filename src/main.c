#include <gtk/gtk.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#ifndef APP_VERSION
#define APP_VERSION "1.0.0"
#endif

// 全域變數用於測試記憶體洩漏
static char *global_memory_leak = NULL;
static int allocation_counter = 0;

// 按鈕點擊回調函數
static void on_button_clicked(GtkWidget *button, gpointer user_data) {
    GtkWidget *label = GTK_WIDGET(user_data);
    allocation_counter++;
    
    // 故意的記憶體洩漏（測試用）
    char *leak_memory = malloc(1024 * 10); // 10KB
    if (leak_memory) {
        snprintf(leak_memory, 1024 * 10, "Leaked memory block #%d", allocation_counter);
        // 故意不呼叫 free(leak_memory) - 這是記憶體洩漏
    }
    
    // 更新標籤文字
    char label_text[256];
    snprintf(label_text, sizeof(label_text), 
             "Clicked %d times\nAllocated %d memory blocks", 
             allocation_counter, allocation_counter);
    gtk_label_set_text(GTK_LABEL(label), label_text);
    
    printf("Button clicked %d times, allocated memory block\n", allocation_counter);
}

// 清理記憶體的按鈕回調
static void on_cleanup_clicked(GtkWidget *button, gpointer user_data) {
    GtkWidget *label = GTK_WIDGET(user_data);
    
    // 釋放全域記憶體（如果有的話）
    if (global_memory_leak) {
        free(global_memory_leak);
        global_memory_leak = NULL;
    }
    
    gtk_label_set_text(GTK_LABEL(label), "Memory cleaned up\n(Note: Previous leaks remain)");
    printf("Cleanup attempted - global memory freed\n");
}

// 應用程式啟動回調
static void on_activate(GtkApplication* app, gpointer user_data) {
    GtkWidget *window;
    GtkWidget *button_leak;
    GtkWidget *button_cleanup;
    GtkWidget *label;
    GtkWidget *box;
    GtkWidget *header_bar;
    
    // 創建主視窗
    window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "GTK Memory Test Application");
    gtk_window_set_default_size(GTK_WINDOW(window), 500, 300);
    gtk_window_set_resizable(GTK_WINDOW(window), TRUE);
    
    // 創建 HeaderBar
    header_bar = gtk_header_bar_new();
    gtk_header_bar_set_show_close_button(GTK_HEADER_BAR(header_bar), TRUE);
    gtk_header_bar_set_title(GTK_HEADER_BAR(header_bar), "Memory Test");
    gtk_header_bar_set_subtitle(GTK_HEADER_BAR(header_bar), "Version " APP_VERSION);
    gtk_window_set_titlebar(GTK_WINDOW(window), header_bar);
    
    // 創建垂直盒子
    box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_set_border_width(GTK_CONTAINER(box), 20);
    gtk_container_add(GTK_CONTAINER(window), box);
    
    // 創建資訊標籤
    label = gtk_label_new("Click the button to create memory leaks\nfor testing purposes");
    gtk_label_set_justify(GTK_LABEL(label), GTK_JUSTIFY_CENTER);
    gtk_box_pack_start(GTK_BOX(box), label, TRUE, TRUE, 10);
    
    // 創建洩漏記憶體按鈕
    button_leak = gtk_button_new_with_label("🚨 Create Memory Leak");
    gtk_widget_set_size_request(button_leak, -1, 50);
    g_signal_connect(button_leak, "clicked", G_CALLBACK(on_button_clicked), label);
    gtk_box_pack_start(GTK_BOX(box), button_leak, FALSE, FALSE, 5);
    
    // 創建清理按鈕
    button_cleanup = gtk_button_new_with_label("🧹 Attempt Cleanup");
    gtk_widget_set_size_request(button_cleanup, -1, 50);
    g_signal_connect(button_cleanup, "clicked", G_CALLBACK(on_cleanup_clicked), label);
    gtk_box_pack_start(GTK_BOX(box), button_cleanup, FALSE, FALSE, 5);
    
    // 初始記憶體分配（用於測試）
    global_memory_leak = malloc(1024 * 50); // 50KB
    if (global_memory_leak) {
        strcpy(global_memory_leak, "Initial global allocation for memory leak testing");
    }
    
    printf("GTK Memory Test Application started (version %s)\n", APP_VERSION);
    printf("Initial memory allocated: 50KB\n");
    
#ifdef DEBUG_MODE
    printf("DEBUG: Application compiled in debug mode\n");
#endif
    
    // 顯示所有元件
    gtk_widget_show_all(window);
    
    // 自動測試模式：如果設定了環境變數，5秒後自動關閉
    if (getenv("AUTO_TEST")) {
        printf("AUTO_TEST mode detected - will close in 5 seconds\n");
        g_timeout_add(5000, (GSourceFunc)g_application_quit, app);
    }
}

// 應用程式關閉時的清理
static void on_shutdown(GtkApplication* app, gpointer user_data) {
    printf("Application shutting down...\n");
    
    // 釋放全域記憶體（如果還存在）
    if (global_memory_leak) {
        free(global_memory_leak);
        global_memory_leak = NULL;
        printf("Global memory cleaned up on shutdown\n");
    }
    
    printf("Note: %d memory leaks were intentionally created for testing\n", allocation_counter);
}

int main(int argc, char **argv) {
    GtkApplication *app;
    int status;
    
    printf("Starting GTK Memory Test Application v%s\n", APP_VERSION);
    printf("Built with CMake\n");
    
#ifdef DEBUG_MODE
    printf("Debug build - memory debugging enabled\n");
#endif
    
    // 創建 GTK 應用程式
    app = gtk_application_new("com.example.gtk-cmake-memory-test", G_APPLICATION_FLAGS_NONE);
    
    // 連接信號
    g_signal_connect(app, "activate", G_CALLBACK(on_activate), NULL);
    g_signal_connect(app, "shutdown", G_CALLBACK(on_shutdown), NULL);
    
    // 執行應用程式
    status = g_application_run(G_APPLICATION(app), argc, argv);
    
    // 清理
    g_object_unref(app);
    
    printf("Application exited with status: %d\n", status);
    return status;
}
