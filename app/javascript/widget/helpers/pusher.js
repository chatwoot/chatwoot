/* eslint-env browser */
/* eslint no-console: 0 */
import Pusher from 'pusher-js';
import AuthAPI from '../api/auth';
import { PUSHER } from './constants';

// const ding = require('../assets/audio/ding.mp3');

class VuePusher {
  constructor(apiKey, options) {
    this.app = options.app;
    this.pusher = new Pusher(apiKey, options);
    this.channels = [];
  }

  subscribe(channelName) {
    const channel = this.pusher.subscribe(channelName);
    if (!this.channels.includes(channel)) {
      this.channels.push(channelName);
    }
    console.log('******** CHANNELS', channelName, this.channels);
    this.bindEvent(channel);
  }

  unsubscribe(channelName) {
    this.pusher.unsubscribe(channelName);
  }

  bindEvent = channel => {
    channel.bind('message.created', data => {
      // Play sound if incoming
      if (!data.message_type) {
        // new Audio(ding).play();
      }
      console.log('******** INCOMING', data);
      // this.app.$store.dispatch('addMessage', data);
    });

    channel.bind('conversation.created', data => {
      console.log(data);
      // this.app.$store.dispatch('addConversation', data);
    });

    channel.bind('status_change:conversation', data => {
      console.log(data);
      // this.app.$store.dispatch('addConversation', data);
    });

    channel.bind('user:logout', () => {
      AuthAPI.logout();
    });

    channel.bind('page:reload', () => {
      window.location.reload();
    });
  };
}

/* eslint no-param-reassign: ["error", { "props": false }] */
export default {
  init(channel) {
    // Log only if env is testing or development.
    Pusher.logToConsole = PUSHER.logToConsole;
    // Init Pusher
    console.log(PUSHER, channel);
    const options = {
      encrypted: true,
      app: window.WOOT,
      cluster: PUSHER.cluster,
    };
    const pusher = new VuePusher(PUSHER.token, options);
    // Add to global Obj
    pusher.subscribe(channel);
    return pusher.pusher;
  },
};
