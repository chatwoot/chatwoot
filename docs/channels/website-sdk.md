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

If you are using expanded bubble, you can customize the text used in the bubble by setting `launcherTitle` parameter on chatwootSettings as described below.

```js
window.chatwootSettings = {
  type: 'expanded_bubble',
  launcherTitle: 'Chat with us'
}
```

### To enable popout window

Inorder to enable the popout window, add the following configuration to `chatwootSettings`. This option is disabled by default.

```js
window.chatwootSettings = {
  // ...Other Config
  showPopoutButton: true,
}
```

### To trigger widget without displaying bubble

```js
window.$chatwoot.toggle();
```

### To set the user in the widget

```js
window.$chatwoot.setUser('<unique-identifier-key-of-the-user>', {
  email: '<email-address-of-the-user@your-domain.com>',
  name: '<name-of-the-user>',
  avatar_url: '<avatar-url-of-the-user>',
});
```

`setUser` accepts an identifier which can be a `user_id` in your database or any unique parameter which represents a user. You can pass email, name, avatar_url as params. Support for additional parameters is in progress.

Make sure that you reset the session when the user logs out of your app.

### Set custom attributes

Inorder to set additional information about the customer you can use customer attributes field.

To set a custom attributes call `setCustomAttributes` as follows

```js
window.$chatwoot.setCustomAttributes({
  accountId: 1,
  pricingPlan: 'paid',

  // You can pass any key value pair here.
  // Value should either be a string or a number.
  // You need to flatten nested JSON structure while using this function
});
```

You can view these information in the sidepanel of a conversation.

To delete a custom attribute, use `deleteCustomAttribute` as follows

```js
window.$chatwoot.deleteCustomAttribute('attribute-name');
```

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
