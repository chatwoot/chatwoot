import global from 'global';
import { Channel } from '@storybook/channels';
import { logger } from '@storybook/client-logger';
import { isJSON, parse, stringify } from 'telejson';
const {
  WebSocket
} = global;
export class WebsocketTransport {
  constructor({
    url,
    onError
  }) {
    this.socket = void 0;
    this.handler = void 0;
    this.buffer = [];
    this.isReady = false;
    this.connect(url, onError);
  }

  setHandler(handler) {
    this.handler = handler;
  }

  send(event) {
    if (!this.isReady) {
      this.sendLater(event);
    } else {
      this.sendNow(event);
    }
  }

  sendLater(event) {
    this.buffer.push(event);
  }

  sendNow(event) {
    const data = stringify(event, {
      maxDepth: 15,
      allowFunction: true
    });
    this.socket.send(data);
  }

  flush() {
    const {
      buffer
    } = this;
    this.buffer = [];
    buffer.forEach(event => this.send(event));
  }

  connect(url, onError) {
    this.socket = new WebSocket(url);

    this.socket.onopen = () => {
      this.isReady = true;
      this.flush();
    };

    this.socket.onmessage = ({
      data
    }) => {
      const event = typeof data === 'string' && isJSON(data) ? parse(data) : data;
      this.handler(event);
    };

    this.socket.onerror = e => {
      if (onError) {
        onError(e);
      }
    };
  }

}
export default function createChannel({
  url,
  async = false,
  onError = err => logger.warn(err)
}) {
  const transport = new WebsocketTransport({
    url,
    onError
  });
  return new Channel({
    transport,
    async
  });
}