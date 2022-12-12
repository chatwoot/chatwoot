import global from 'global';
import { Channel } from '@storybook/channels';
import { logger } from '@storybook/client-logger';
import { mockChannel } from './storybook-channel-mock';
import { types } from './types';
export { Channel };
export class AddonStore {
  constructor() {
    this.loaders = {};
    this.elements = {};
    this.config = {};
    this.channel = void 0;
    this.serverChannel = void 0;
    this.promise = void 0;
    this.resolve = void 0;

    this.getChannel = () => {
      // this.channel should get overwritten by setChannel. If it wasn't called (e.g. in non-browser environment), set a mock instead.
      if (!this.channel) {
        this.setChannel(mockChannel());
      }

      return this.channel;
    };

    this.getServerChannel = () => {
      if (!this.serverChannel) {
        throw new Error('Accessing non-existent serverChannel');
      }

      return this.serverChannel;
    };

    this.ready = () => this.promise;

    this.hasChannel = () => !!this.channel;

    this.hasServerChannel = () => !!this.serverChannel;

    this.setChannel = channel => {
      this.channel = channel;
      this.resolve();
    };

    this.setServerChannel = channel => {
      this.serverChannel = channel;
    };

    this.getElements = type => {
      if (!this.elements[type]) {
        this.elements[type] = {};
      }

      return this.elements[type];
    };

    this.addPanel = (name, options) => {
      this.add(name, Object.assign({
        type: types.PANEL
      }, options));
    };

    this.add = (name, addon) => {
      const {
        type
      } = addon;
      const collection = this.getElements(type);
      collection[name] = Object.assign({
        id: name
      }, addon);
    };

    this.setConfig = value => {
      Object.assign(this.config, value);
    };

    this.getConfig = () => this.config;

    this.register = (name, registerCallback) => {
      if (this.loaders[name]) {
        logger.warn(`${name} was loaded twice, this could have bad side-effects`);
      }

      this.loaders[name] = registerCallback;
    };

    this.loadAddons = api => {
      Object.values(this.loaders).forEach(value => value(api));
    };

    this.promise = new Promise(res => {
      this.resolve = () => res(this.getChannel());
    });
  }

} // Enforce addons store to be a singleton

const KEY = '__STORYBOOK_ADDONS';

function getAddonsStore() {
  if (!global[KEY]) {
    global[KEY] = new AddonStore();
  }

  return global[KEY];
} // Exporting this twice in order to to be able to import it like { addons } instead of 'addons'
// prefer import { addons } from '@storybook/addons' over import addons from '@storybook/addons'
//
// See public_api.ts


export const addons = getAddonsStore();