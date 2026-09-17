import { loadScript } from 'dashboard/helper/DOMHelpers';

export const loadFacebookSdk = async () => {
  return loadScript('https://connect.facebook.net/en_US/sdk.js', {
    async: true,
    defer: true,
    crossOrigin: 'anonymous',
  });
};

export const initializeFacebook = (appId, apiVersion) => {
  const version = apiVersion || 'v22.0';
  return new Promise(resolve => {
    const init = () => {
      window.FB.init({
        appId,
        autoLogAppEvents: true,
        xfbml: true,
        version,
      });
      resolve();
    };

    if (window.FB) {
      init();
    } else {
      window.fbAsyncInit = init;
    }
  });
};

// Only waba_id is guaranteed: Meta's coexistence FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING
// event documents data: { waba_id } alone — no business_id or phone_number_id.
export const isValidBusinessData = businessData => {
  return Boolean(businessData && businessData.waba_id);
};

const COEXISTENCE_FINISH_EVENT = 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING';

const FINISH_EVENTS = ['FINISH', COEXISTENCE_FINISH_EVENT];

// Terminal events that end the flow without a Cloud API phone number we can build an
// inbox from. Embedded Signup v4 can emit any of them depending on the products
// enabled on the configuration; without an explicit branch the popup simply closes
// and the caller waits on a promise that never settles.
const UNSUPPORTED_FINISH_EVENTS = [
  'FINISH_ONLY_WABA',
  'FINISH_OBO_MIGRATION',
  'FINISH_GRANT_ONLY_API_ACCESS',
];

export const SIGNUP_RESULT = Object.freeze({
  FINISH: 'finish',
  UNSUPPORTED: 'unsupported',
  CANCEL: 'cancel',
  ERROR: 'error',
  IGNORE: 'ignore',
});

// Maps a WA_EMBEDDED_SIGNUP payload onto the outcomes callers act on. v4 spells the
// explicit failure event `ERROR` where v3 used `error`, and also reports user-facing
// failures as a CANCEL carrying an error_message — a bare CANCEL is a deliberate
// dismissal, so the two have to be told apart rather than both read as "cancelled".
export const classifySignupEvent = data => {
  const event = data?.event;
  if (typeof event !== 'string') return { type: SIGNUP_RESULT.IGNORE };

  const errorMessage = data?.error_message;

  if (FINISH_EVENTS.includes(event)) {
    return {
      type: SIGNUP_RESULT.FINISH,
      isCoexistence: event === COEXISTENCE_FINISH_EVENT,
    };
  }

  if (UNSUPPORTED_FINISH_EVENTS.includes(event)) {
    return { type: SIGNUP_RESULT.UNSUPPORTED };
  }

  if (event.toUpperCase() === 'ERROR') {
    return { type: SIGNUP_RESULT.ERROR, errorMessage };
  }

  if (event === 'CANCEL') {
    return errorMessage
      ? { type: SIGNUP_RESULT.ERROR, errorMessage }
      : { type: SIGNUP_RESULT.CANCEL };
  }

  return { type: SIGNUP_RESULT.IGNORE };
};

export const createMessageHandler = onEmbeddedSignupData => {
  return event => {
    if (!event.origin.endsWith('facebook.com')) return;

    try {
      let data;
      if (typeof event.data === 'string') {
        data = JSON.parse(event.data);
      } else if (typeof event.data === 'object' && event.data !== null) {
        data = event.data;
      } else {
        return;
      }

      if (data.type === 'WA_EMBEDDED_SIGNUP') {
        onEmbeddedSignupData(data);
      }
    } catch {
      // Ignore non-JSON or irrelevant messages
    }
  };
};

export const initWhatsAppEmbeddedSignup = configId => {
  return new Promise((resolve, reject) => {
    window.FB.login(
      response => {
        if (response.authResponse && response.authResponse.code) {
          resolve(response.authResponse.code);
        } else if (response.error) {
          reject(new Error(response.error));
        } else {
          reject(new Error('Login cancelled'));
        }
      },
      {
        config_id: configId,
        response_type: 'code',
        override_default_response_type: true,
        extras: {
          setup: {},
          featureType: 'whatsapp_business_app_onboarding',
          sessionInfoVersion: '3',
        },
      }
    );
  });
};

export const setupFacebookSdk = async (appId, apiVersion) => {
  const version = apiVersion || 'v22.0';
  await loadFacebookSdk();
  await initializeFacebook(appId, version);
};
