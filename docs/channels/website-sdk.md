---
path: "/docs/website-sdk"
title: "Sending Information into Chatwoot"
---


Additional information about a contact is always useful, Chatwoot website SDK ensures that you can send the additional info you have about the user.

If you have installed our code on your website, SDK would expose `window.$chatwoot` object.

To hide the bubble, you can use the following setting. Please not if you use this, then you have to trigger the widget by yourself.

```js
window.chatwootSettings = {
  hideMessageBubble: false,
  position: 'left', // This can be left or right
}
```

### To trigger widget without displaying bubble

```js
window.$chatwoot.toggle()
```

### To set the user in the widget

```js
window.$chatwoot.setUser('identifier_key', {
  email: 'email@example.com',
  name: 'name',
  avatar_url: '',
})
```

`setUser` accepts an identifier which can be a `user_id` in your database or any unique parameter which represents a user. You can pass email, name, avatar_url as params, support for additional parameters are in progress.

Make sure that you reset the session when the user logouts of your app.

### To set labels on the conversation

Please note that the labels will be set on a conversation, if the user has not started a conversation, then the following items will not have any effect.

```js
window.$chatwoot.addLabel('support-ticket')

window.$chatwoot.removeLabel('support-ticket')
```

### To refresh the session (use this while you logout user from your app)

```js
window.$chatwoot.reset()
```
