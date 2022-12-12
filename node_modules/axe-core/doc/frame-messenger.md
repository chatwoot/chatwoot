# Frame Messenger

Axe frameMessenger can be used to configure how axe-core communicates information between frames. By default, axe-core uses `window.postMessage()`. Since other scripts on the page may also use `window.postMessage`, axe-core's use of it can sometimes disrupt page functionality. This can be avoided by providing `axe.frameMessenger()` a way to communicate to frames that does not use `window.postMessage`.

Tools like browser extensions and testing environments often have different channels through which information can be communicated. `axe.frameMessenger` must be set up in **every frame** axe-core is included.

```js
axe.frameMessenger({
  // Called to initialize message handling
  open(topicHandler) {
    // Start listening for "axe-core" events
    const unsubscribe = bridge.subscribe('axe-core', data => {
      topicHandler(data);
    });
    // Tell axe how to close the connection if it needs to
    return unsubscribe;
  },

  // Called when axe needs to send a message to another frame
  async post(frameWindow, data, replyHandler) {
    // Send a message to another frame for "axe-core"
    const replies = bridge.send(frameWindow, 'axe-core', data);
    // Async handling replies as they come back
    for await (let data of replies) {
      replyHandler(data);
    }
  }
});
```

## axe.frameMessenger({ open })

`open` is a function that should setup the communication channel with iframes. It is passed a `topicHandler` function, which must be called when a message is received from another frame.

The `topicHandler` function takes two arguments: the `data` object and a callback function that is called when the subscribed listener completes. The `data` object is exclusively passed data that can be serialized with `JSON.stringify()`, which depending on the system may need to be used.

The `open` function can `return` an optional cleanup function, which is called when another frameMessenger is registered.

## axe.frameMessenger({ post })

`post` is a function that dictates how axe-core communicates with frames. It is passed three arguments: `frameWindow`, which is the frames `contentWindow`, the `data` object, and a `replyHandler` that must be called when responses are received.

**note**: Currently, axe-core will only call `replyHandler` once, so promises can also be used here. This may change in the future, so it is preferable to make it possible for `replyHandler` to be called multiple times.
