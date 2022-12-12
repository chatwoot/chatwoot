# Storybook PostMessage Channel

Storybook PostMessage Channel is a channel for Storybook that can be used when the Storybook Renderer runs inside an iframe or a child window.
A channel can be created using the `createChannel` function.

```js
import createChannel from '@storybook/channel-postmessage';

const channel = createChannel({ key: 'postmsg-key' });
```

* * *

For more information visit: [storybook.js.org](https://storybook.js.org)
