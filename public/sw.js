/* eslint-disable no-restricted-globals, no-console */
self.addEventListener('push', event => {
  console.log(event, event.data.json());
  let notification = event.data && event.data.json();
  let icon = '/favicon-512x512.png';

  event.waitUntil(
    self.registration.showNotification(notification.title, {
      icon,
      tag: notification.type,
    })
  );
});
