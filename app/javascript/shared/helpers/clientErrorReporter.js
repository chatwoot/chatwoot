// [whisker] Lightweight client error reporter
// Captures uncaught errors and sends them to the Whisker backend for debugging.
// Respects privacy: no PII, no secrets. Opt-out via window.__WHISKER_NO_REPORT__.

const ENDPOINT = '/api/v1/client_errors';

let reported = false;

function getWebsiteToken() {
  if (typeof window === 'undefined') return null;
  try {
    // sdk.js sets window.chatwootSettings.websiteToken
    return window.chatwootSettings?.websiteToken || null;
  } catch (_e) {
    return null;
  }
}

function getPlatform() {
  if (typeof document !== 'undefined' && document.querySelector('[data-whisker-pet]')) return 'pet';
  if (window.location.pathname.includes('/app')) return 'dashboard';
  return 'widget';
}

function sendReport(payload) {
  if (window.__WHISKER_NO_REPORT__) return;
  try {
    const body = new URLSearchParams();
    Object.entries(payload).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        body.append(`client_error_report[${key}]`, typeof value === 'object' ? JSON.stringify(value) : value);
      }
    });

    if (navigator.sendBeacon) {
      navigator.sendBeacon(ENDPOINT, body);
    } else {
      fetch(ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body,
        keepalive: true,
      }).catch(() => {});
    }
  } catch (_e) {
    // never break the app because of reporting
  }
}

export function initClientErrorReporter() {
  if (reported || typeof window === 'undefined') return;
  reported = true;

  window.addEventListener('error', event => {
    const error = event.error || {};
    sendReport({
      website_token: getWebsiteToken(),
      platform: getPlatform(),
      message: event.message || 'Unknown error',
      stack: error.stack || null,
      url: window.location?.href || null,
      user_agent: navigator.userAgent,
      metadata: {
        line: event.lineno,
        col: event.colno,
        source: event.filename,
      },
    });
  });

  window.addEventListener('unhandledrejection', event => {
    const reason = event.reason || {};
    sendReport({
      website_token: getWebsiteToken(),
      platform: getPlatform(),
      message: reason.message || 'Unhandled promise rejection',
      stack: reason.stack || null,
      url: window.location?.href || null,
      user_agent: navigator.userAgent,
      metadata: { type: 'unhandledrejection' },
    });
  });
}

export default initClientErrorReporter;
