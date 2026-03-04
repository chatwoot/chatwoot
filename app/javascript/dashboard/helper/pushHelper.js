/* eslint-disable no-console */
import NotificationSubscriptions from '../api/notificationSubscription';
import auth from '../api/auth';
import { useAlert } from 'dashboard/composables';

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
    return Notification.permission === 'granted';
  }
  return false;
};

const generateKeys = str =>
  btoa(String.fromCharCode.apply(null, new Uint8Array(str)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

const urlBase64ToUint8Array = base64String => {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = `${base64String}${padding}`
    .replace(/-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; i += 1) {
    outputArray[i] = rawData.charCodeAt(i);
  }

  return outputArray;
};

export const getPushSubscriptionPayload = subscription => ({
  subscription_type: 'browser_push',
  subscription_attributes: {
    endpoint: subscription.endpoint,
    p256dh: generateKeys(subscription.getKey('p256dh')),
    auth: generateKeys(subscription.getKey('auth')),
  },
});

export const sendRegistrationToServer = subscription => {
  if (auth.hasAuthCookie()) {
    return NotificationSubscriptions.create({
      notification_subscription: getPushSubscriptionPayload(subscription),
    });
  }
  return null;
};

export const registerSubscription = (onSuccess = () => {}) => {
  if (!window.chatwootConfig.vapidPublicKey) {
    return;
  }
  navigator.serviceWorker.ready
    .then(serviceWorkerRegistration =>
      serviceWorkerRegistration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(
          window.chatwootConfig.vapidPublicKey
        ),
      })
    )
    .then(sendRegistrationToServer)
    .then(() => {
      onSuccess();
    })
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Push subscription registration failed:', error);
      useAlert('This browser does not support desktop notification');
    });
};

export const requestPushPermissions = ({ onSuccess }) => {
  if (!('Notification' in window)) {
    // eslint-disable-next-line no-console
    console.warn('Notification is not supported');
    useAlert('This browser does not support desktop notification');
  } else if (Notification.permission === 'granted') {
    registerSubscription(onSuccess);
  } else if (Notification.permission !== 'denied') {
    Notification.requestPermission(permission => {
      if (permission === 'granted') {
        registerSubscription(onSuccess);
      }
    });
  }
};
