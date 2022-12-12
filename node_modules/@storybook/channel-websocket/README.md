# Storybook Websocket Channel

Storybook Websocket Channel is a channel for Storybook that can be used when the Storybook Renderer should communicate with the Storybook Manager over the network.
A channel can be created using the `createChannel` function.

```js
import createChannel from '@storybook/channel-websocket';

const channel = createChannel({ url: 'ws://localhost:9001' });
```

* * *

For more information visit: [storybook.js.org](https://storybook.js.org)
