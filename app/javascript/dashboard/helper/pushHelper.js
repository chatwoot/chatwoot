/* eslint-disable no-console */

export const verifyServiceWorkerExistence = (callback = () => {}) => {
  if (!('serviceWorker' in navigator)) {
    // Service Worker isn't supported on this browser, disable or hide UI.
    return;
  }

  if (!('PushManager' in window)) {
    // Push isn't supported on this browser, disable or hide UI.
    return;
  }

  navigator.serviceWorker
    .register('/sw.js')
    .then(registration => callback(registration))
    .catch(registrationError => {
      // eslint-disable-next-line
      console.log('SW registration failed: ', registrationError);
    });
};

export const hasPushPermissions = () => {
  if ('Notification' in window) {
    console.log(Notification);
    return Notification.permission === 'granted';
  }
  return false;
};

const generateKeys = str =>
  btoa(String.fromCharCode.apply(null, new Uint8Array(str)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

export const requestPushPermissions = () => {
  if (!('Notification' in window)) {
    console.error('This browser does not support desktop notification');
  } else if (Notification.permission === 'granted') {
    console.log('Permission to receive notifications has been granted');
  } else if (Notification.permission !== 'denied') {
    Notification.requestPermission(permission => {
      if (permission === 'granted') {
        navigator.serviceWorker.ready.then(serviceWorkerRegistration => {
          serviceWorkerRegistration.pushManager
            .subscribe({
              userVisibleOnly: true,
              applicationServerKey: window.chatwootConfig.vapidPublicKey,
            })
            .then(subscription => {
              var data = {
                endpoint: subscription.endpoint,
                p256dh: generateKeys(subscription.getKey('p256dh')),
                auth: generateKeys(subscription.getKey('auth')),
              };
              console.log(data);
            });
        });
      }
    });
  }
};
