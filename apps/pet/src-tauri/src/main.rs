// [whisker] Desktop Pet — Pawly
// Transparent always-on-top window with tray icon, API polling, and notifications

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use tauri::{
    menu::{MenuBuilder, MenuItemBuilder},
    tray::TrayIconBuilder,
    Manager,
};

struct AppState {
    api_url: Mutex<String>,
    api_token: Mutex<String>,
    unread_count: Mutex<u32>,
    sound_enabled: Mutex<bool>,
}

#[derive(Serialize, Deserialize)]
struct NotificationResponse {
    count: u32,
}

#[derive(Serialize, Deserialize)]
struct ConversationResponse {
    id: u64,
    display_id: u32,
    status: String,
    unread_count: u32,
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_http::init())
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            let state = AppState {
                api_url: Mutex::new(String::from("http://localhost:3000")),
                api_token: Mutex::new(String::new()),
                unread_count: Mutex::new(0),
                sound_enabled: Mutex::new(true),
            };
            app.manage(state);

            // System tray
            let quit = MenuItemBuilder::new("Quit Pawly").id("quit").build(app)?;
            let show = MenuItemBuilder::new("Show Pet").id("show").build(app)?;
            let open = MenuItemBuilder::new("Open Dashboard").id("open").build(app)?;
            let menu = MenuBuilder::new(app).items(&[&show, &open, &quit]).build()?;

            let _tray = TrayIconBuilder::new()
                .menu(&menu)
                .tooltip("Pawly — Whisker Pet")
                .on_menu_event(move |app, event| match event.id().as_ref() {
                    "quit" => {
                        app.exit(0);
                    }
                    "show" => {
                        if let Some(window) = app.get_webview_window("main") {
                            window.show().ok();
                            window.set_focus().ok();
                        }
                    }
                    "open" => {
                        let _ = open::that("http://localhost:3000/app");
                    }
                    _ => {}
                })
                .build(app)?;

            // Start background polling
            let app_handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                loop {
                    tokio::time::sleep(tokio::time::Duration::from_secs(30)).await;
                    poll_notifications(&app_handle).await;
                }
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_notification_count,
            open_inbox,
            set_api_config,
            get_api_config,
            toggle_sound,
            get_sound_enabled,
        ])
        .run(tauri::generate_context!())
        .expect("error while running Whisker Pet");
}

async fn poll_notifications(app: &tauri::AppHandle) {
    let state = app.state::<AppState>();
    let url = state.api_url.lock().unwrap().clone();
    let token = state.api_token.lock().unwrap().clone();

    if token.is_empty() || url.is_empty() {
        return;
    }

    let client = reqwest::Client::new();
    let result = client
        .get(format!("{}/api/v1/conversations", url))
        .header("Authorization", format!("Bearer {}", token))
        .header("Content-Type", "application/json")
        .query(&[("status", "open"), ("unread_count", "true")])
        .send()
        .await;

    match result {
        Ok(resp) => {
            if let Ok(json) = resp.json::<serde_json::Value>().await {
                let count = json.get("meta").and_then(|m| m.get("unread_count")).and_then(|c| c.as_u64()).unwrap_or(0) as u32;
                let mut unread = state.unread_count.lock().unwrap();
                let old_count = *unread;
                *unread = count;

                // Show desktop notification if count increased
                if count > old_count && count > 0 {
                    if let Some(window) = app.get_webview_window("main") {
                        let _ = window.emit("notification-count", count);
                    }

                    // Send system notification
                    if *state.sound_enabled.lock().unwrap() {
                        let _ = app.notification().builder()
                            .title("Pawly")
                            .body(format!("{} unread message{}", count, if count == 1 { "" } else { "s" }))
                            .show();
                    }
                }
            }
        }
        Err(_) => {}
    }
}

#[tauri::command]
fn get_notification_count(state: tauri::State<AppState>) -> u32 {
    *state.unread_count.lock().unwrap()
}

#[tauri::command]
fn open_inbox() {
    let _ = open::that("http://localhost:3000/app");
}

#[tauri::command]
fn set_api_config(url: String, token: String, state: tauri::State<AppState>) {
    *state.api_url.lock().unwrap() = url;
    *state.api_token.lock().unwrap() = token;
}

#[tauri::command]
fn get_api_config(state: tauri::State<AppState>) -> (String, String) {
    (
        state.api_url.lock().unwrap().clone(),
        state.api_token.lock().unwrap().clone(),
    )
}

#[tauri::command]
fn toggle_sound(state: tauri::State<AppState>) -> bool {
    let mut enabled = state.sound_enabled.lock().unwrap();
    *enabled = !*enabled;
    *enabled
}

#[tauri::command]
fn get_sound_enabled(state: tauri::State<AppState>) -> bool {
    *state.sound_enabled.lock().unwrap()
}
