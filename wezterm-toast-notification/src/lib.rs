mod dbus;
mod macos;
mod windows;

#[derive(Debug, Clone)]
pub struct ToastNotification {
    pub title: String,
    pub message: String,
    pub url: Option<String>,
    pub click_arguments: Option<String>,
    pub timeout: Option<std::time::Duration>,
}

impl ToastNotification {
    pub fn show(self) {
        show(self)
    }
}

#[cfg(windows)]
type ToastActivationHandler = std::sync::Arc<dyn Fn(String) + Send + Sync + 'static>;
#[cfg(windows)]
static TOAST_ACTIVATION_HANDLER: std::sync::OnceLock<ToastActivationHandler> =
    std::sync::OnceLock::new();

#[cfg(windows)]
use crate::windows as backend;
#[cfg(all(not(target_os = "macos"), not(windows)))]
use dbus as backend;
#[cfg(target_os = "macos")]
use macos as backend;

mod nop {
    use super::*;

    #[allow(dead_code)]
    pub fn show_notif(_: ToastNotification) -> Result<(), Box<dyn std::error::Error>> {
        Ok(())
    }
}

pub fn show(notif: ToastNotification) {
    if let Err(err) = backend::show_notif(notif) {
        log::error!("Failed to show notification: {}", err);
    }
}

pub fn set_toast_activation_handler<F>(handler: F)
where
    F: Fn(String) + Send + Sync + 'static,
{
    #[cfg(windows)]
    if TOAST_ACTIVATION_HANDLER
        .set(std::sync::Arc::new(handler))
        .is_err()
    {
        log::warn!("toast activation handler was already set");
    }

    #[cfg(not(windows))]
    let _ = handler;
}

#[cfg(windows)]
pub(crate) fn dispatch_toast_activation(arguments: String) {
    if let Some(handler) = TOAST_ACTIVATION_HANDLER.get() {
        handler(arguments);
    }
}

pub fn persistent_toast_notification_with_click_to_open_url(title: &str, message: &str, url: &str) {
    show(ToastNotification {
        title: title.to_string(),
        message: message.to_string(),
        url: Some(url.to_string()),
        click_arguments: None,
        timeout: None,
    });
}

pub fn persistent_toast_notification_with_click_arguments(
    title: &str,
    message: &str,
    arguments: &str,
) {
    show(ToastNotification {
        title: title.to_string(),
        message: message.to_string(),
        url: None,
        click_arguments: Some(arguments.to_string()),
        timeout: None,
    });
}

pub fn persistent_toast_notification(title: &str, message: &str) {
    show(ToastNotification {
        title: title.to_string(),
        message: message.to_string(),
        url: None,
        click_arguments: None,
        timeout: None,
    });
}

#[cfg(target_os = "macos")]
pub use macos::initialize as macos_initialize;
