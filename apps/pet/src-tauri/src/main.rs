// [whisker] Desktop Pet — Pawly
// Transparent always-on-top window with a draggable pet sprite

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Get the main window and make it draggable
            let window = app.get_webview_window("main").unwrap();
            window.set_always_on_top(true).ok();
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_notification_count,
            open_inbox,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Whisker Pet");
}

#[tauri::command]
fn get_notification_count() -> u32 {
    // TODO: Connect to Whisker API to get unread message count
    0
}

#[tauri::command]
fn open_inbox() {
    // TODO: Open the default browser to the Whisker dashboard
    let _ = open::that("http://localhost:3000/app");
}
