---
path: '/docs/website-sdk'
title: 'Sending Information into Chatwoot'
---

Additional information about a contact is always useful. The Chatwoot Website SDK ensures that you can send additional information that you have about the user.

If you have installed our code on your website, the SDK would expose `window.$chatwoot` object.

In order to make sure that the SDK has been loaded completely, please make sure that you listen to `chatwoot:ready` event as follows:

```js
window.addEventListener('chatwoot:ready', function () {
  // Use window.$chatwoot here
  // ...
});
```

To hide the bubble, you can use the setting mentioned below. **Note**: If you use this, then you have to trigger the widget by yourself.

```js
window.chatwootSettings = {
  hideMessageBubble: false,
  position: 'left', // This can be left or right
  locale: 'en', // Language to be set
  type: 'standard', // [standard, expanded_bubble]
};
```

Chatwoot support 2 designs for for the widget

1. Standard (default)

![Standard-bubble](./images/sdk/standard-bubble.gif)

2. Expanded bubble

![Expanded-bubble](./images/sdk/expanded-bubble.gif)

### To trigger widget without displaying bubble

```js
window.$chatwoot.toggle();
```

### To set the user in the widget

```js
window.$chatwoot.setUser('identifier_key', {
  email: 'email@example.com',
  name: 'name',
  avatar_url: '',
});
```

`setUser` accepts an identifier which can be a `user_id` in your database or any unique parameter which represents a user. You can pass email, name, avatar_url as params. Support for additional parameters is in progress.

Make sure that you reset the session when the user logs out of your app.

### To set language manually

```js
window.$chatwoot.setLocale('en');
```

To set the language manually, use the `setLocale` function.

### To set labels on the conversation

Please note that the labels will be set on a conversation if the user has not started a conversation. In that case, the following items will not have any effect:

```js
window.$chatwoot.addLabel('support-ticket');

window.$chatwoot.removeLabel('support-ticket');
```

### To refresh the session (use this while you logout the user from your app)

```js
window.$chatwoot.reset();
```
