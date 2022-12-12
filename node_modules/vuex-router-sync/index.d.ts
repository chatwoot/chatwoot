import {Store} from 'vuex';
import VueRouter = require('vue-router');

interface SyncOptions {
  moduleName: string;
}

export declare function sync(store: Store<any>, router: VueRouter, options?: SyncOptions): void;
