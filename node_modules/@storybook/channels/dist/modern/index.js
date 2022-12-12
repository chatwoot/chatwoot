import "core-js/modules/web.immediate.js";
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';

const generateRandomId = () => {
  // generates a random 13 character string
  return Math.random().toString(16).slice(2);
};

export class Channel {
  constructor({
    transport,
    async = false
  } = {}) {
    this.isAsync = void 0;
    this.sender = generateRandomId();
    this.events = {};
    this.data = {};
    this.transport = void 0;
    this.addPeerListener = deprecate((eventName, listener) => {
      this.addListener(eventName, listener);
    }, dedent`
      channel.addPeerListener is deprecated
    `);
    this.isAsync = async;

    if (transport) {
      this.transport = transport;
      this.transport.setHandler(event => this.handleEvent(event));
    }
  }

  get hasTransport() {
    return !!this.transport;
  }

  addListener(eventName, listener) {
    this.events[eventName] = this.events[eventName] || [];
    this.events[eventName].push(listener);
  }

  emit(eventName, ...args) {
    const event = {
      type: eventName,
      args,
      from: this.sender
    };
    let options = {};

    if (args.length >= 1 && args[0] && args[0].options) {
      options = args[0].options;
    }

    const handler = () => {
      if (this.transport) {
        this.transport.send(event, options);
      }

      this.handleEvent(event);
    };

    if (this.isAsync) {
      // todo I'm not sure how to test this
      setImmediate(handler);
    } else {
      handler();
    }
  }

  last(eventName) {
    return this.data[eventName];
  }

  eventNames() {
    return Object.keys(this.events);
  }

  listenerCount(eventName) {
    const listeners = this.listeners(eventName);
    return listeners ? listeners.length : 0;
  }

  listeners(eventName) {
    const listeners = this.events[eventName];
    return listeners || undefined;
  }

  once(eventName, listener) {
    const onceListener = this.onceListener(eventName, listener);
    this.addListener(eventName, onceListener);
  }

  removeAllListeners(eventName) {
    if (!eventName) {
      this.events = {};
    } else if (this.events[eventName]) {
      delete this.events[eventName];
    }
  }

  removeListener(eventName, listener) {
    const listeners = this.listeners(eventName);

    if (listeners) {
      this.events[eventName] = listeners.filter(l => l !== listener);
    }
  }

  on(eventName, listener) {
    this.addListener(eventName, listener);
  }

  off(eventName, listener) {
    this.removeListener(eventName, listener);
  }

  handleEvent(event) {
    const listeners = this.listeners(event.type);

    if (listeners && listeners.length) {
      listeners.forEach(fn => {
        fn.apply(event, event.args);
      });
    }

    this.data[event.type] = event.args;
  }

  onceListener(eventName, listener) {
    const onceListener = (...args) => {
      this.removeListener(eventName, onceListener);
      return listener(...args);
    };

    return onceListener;
  }

}
export default Channel;