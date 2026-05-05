use wasm_bindgen::prelude::*;

/// WASM entry point - called from Swift via WKWebView or from the iOS
/// embedded WKWebView JavaScript bridge. Returns a JSON string.
#[wasm_bindgen]
pub fn compile_mql(source: &str) -> String {
    match mql_compiler::compile(source) {
        Ok(plan) => serde_json::json!({"ok": true, "plan": plan}).to_string(),
        Err(e) => serde_json::json!({"ok": false, "error": e.to_string()}).to_string(),
    }
}
