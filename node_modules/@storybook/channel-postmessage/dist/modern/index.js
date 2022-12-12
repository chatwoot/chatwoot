import global from 'global';
import * as EVENTS from '@storybook/core-events';
import Channel from '@storybook/channels';
import { logger, pretty } from '@storybook/client-logger';
import { isJSON, parse, stringify } from 'telejson';
import qs from 'qs';
const {
  window: globalWindow,
  document,
  location
} = global;
export const KEY = 'storybook-channel';
const defaultEventOptions = {
  allowFunction: true,
  maxDepth: 25
}; // TODO: we should export a method for opening child windows here and keep track of em.
// that way we can send postMessage to child windows as well, not just iframe
// https://stackoverflow.com/questions/6340160/how-to-get-the-references-of-all-already-opened-child-windows

export class PostmsgTransport {
  constructor(config) {
    this.config = config;
    this.buffer = void 0;
    this.handler = void 0;
    this.connected = void 0;
    this.buffer = [];
    this.handler = null;
    globalWindow.addEventListener('message', this.handleEvent.bind(this), false); // Check whether the config.page parameter has a valid value

    if (config.page !== 'manager' && config.page !== 'preview') {
      throw new Error(`postmsg-channel: "config.page" cannot be "${config.page}"`);
    }
  }

  setHandler(handler) {
    this.handler = (...args) => {
      handler.apply(this, args);

      if (!this.connected && this.getLocalFrame().length) {
        this.flush();
        this.connected = true;
      }
    };
  }
  /**
   * Sends `event` to the associated window. If the window does not yet exist
   * the event will be stored in a buffer and sent when the window exists.
   * @param event
   */


  send(event, options) {
    const {
      target,
      // telejson options
      allowRegExp,
      allowFunction,
      allowSymbol,
      allowDate,
      allowUndefined,
      allowClass,
      maxDepth,
      space,
      lazyEval
    } = options || {};
    const eventOptions = Object.fromEntries(Object.entries({
      allowRegExp,
      allowFunction,
      allowSymbol,
      allowDate,
      allowUndefined,
      allowClass,
      maxDepth,
      space,
      lazyEval
    }).filter(([k, v]) => typeof v !== 'undefined'));
    const stringifyOptions = Object.assign({}, defaultEventOptions, global.CHANNEL_OPTIONS || {}, eventOptions); // backwards compat: convert depth to maxDepth

    if (options && Number.isInteger(options.depth)) {
      stringifyOptions.maxDepth = options.depth;
    }

    const frames = this.getFrames(target);
    const query = qs.parse(location.search, {
      ignoreQueryPrefix: true
    });
    const data = stringify({
      key: KEY,
      event,
      refId: query.refId
    }, stringifyOptions);

    if (!frames.length) {
      return new Promise((resolve, reject) => {
        this.buffer.push({
          event,
          resolve,
          reject
        });
      });
    }

    if (this.buffer.length) {
      this.flush();
    }

    frames.forEach(f => {
      try {
        f.postMessage(data, '*');
      } catch (e) {
        console.error('sending over postmessage fail');
      }
    });
    return Promise.resolve(null);
  }

  flush() {
    const {
      buffer
    } = this;
    this.buffer = [];
    buffer.forEach(item => {
      this.send(item.event).then(item.resolve).catch(item.reject);
    });
  }

  getFrames(target) {
    if (this.config.page === 'manager') {
      const nodes = [...document.querySelectorAll('iframe[data-is-storybook][data-is-loaded]')];
      const list = nodes.filter(e => {
        try {
          return !!e.contentWindow && e.dataset.isStorybook !== undefined && e.id === target;
        } catch (er) {
          return false;
        }
      }).map(e => e.contentWindow);
      return list.length ? list : this.getCurrentFrames();
    }

    if (globalWindow && globalWindow.parent && globalWindow.parent !== globalWindow) {
      return [globalWindow.parent];
    }

    return [];
  }

  getCurrentFrames() {
    if (this.config.page === 'manager') {
      const list = [...document.querySelectorAll('[data-is-storybook="true"]')];
      return list.map(e => e.contentWindow);
    }

    if (globalWindow && globalWindow.parent) {
      return [globalWindow.parent];
    }

    return [];
  }

  getLocalFrame() {
    if (this.config.page === 'manager') {
      const list = [...document.querySelectorAll('#storybook-preview-iframe')];
      return list.map(e => e.contentWindow);
    }

    if (globalWindow && globalWindow.parent) {
      return [globalWindow.parent];
    }

    return [];
  }

  handleEvent(rawEvent) {
    try {
      const {
        data
      } = rawEvent;
      const {
        key,
        event,
        refId
      } = typeof data === 'string' && isJSON(data) ? parse(data, global.CHANNEL_OPTIONS || {}) : data;

      if (key === KEY) {
        const pageString = this.config.page === 'manager' ? `<span style="color: #37D5D3; background: black"> manager </span>` : `<span style="color: #1EA7FD; background: black"> preview </span>`;
        const eventString = Object.values(EVENTS).includes(event.type) ? `<span style="color: #FF4785">${event.type}</span>` : `<span style="color: #FFAE00">${event.type}</span>`;

        if (refId) {
          event.refId = refId;
        }

        event.source = this.config.page === 'preview' ? rawEvent.origin : getEventSourceUrl(rawEvent);

        if (!event.source) {
          pretty.error(`${pageString} received ${eventString} but was unable to determine the source of the event`);
          return;
        }

        const message = `${pageString} received ${eventString} (${data.length})`;
        pretty.debug(location.origin !== event.source ? message : `${message} <span style="color: gray">(on ${location.origin} from ${event.source})</span>`, ...event.args);
        this.handler(event);
      }
    } catch (error) {
      logger.error(error);
    }
  }

}

const getEventSourceUrl = event => {
  const frames = [...document.querySelectorAll('iframe[data-is-storybook]')]; // try to find the originating iframe by matching it's contentWindow
  // This might not be cross-origin safe

  const [frame, ...remainder] = frames.filter(element => {
    try {
      return element.contentWindow === event.source;
    } catch (err) {// continue
    }

    const src = element.getAttribute('src');
    let origin;

    try {
      ({
        origin
      } = new URL(src, document.location));
    } catch (err) {
      return false;
    }

    return origin === event.origin;
  });

  if (frame && remainder.length === 0) {
    const src = frame.getAttribute('src');
    const {
      protocol,
      host,
      pathname
    } = new URL(src, document.location);
    return `${protocol}//${host}${pathname}`;
  }

  if (remainder.length > 0) {
    // If we found multiple matches, there's going to be trouble
    logger.error('found multiple candidates for event source');
  } // If we found no frames of matches


  return null;
};
/**
 * Creates a channel which communicates with an iframe or child window.
 */


export default function createChannel({
  page
}) {
  const transport = new PostmsgTransport({
    page
  });
  return new Channel({
    transport
  });
}