import type { Globals, GlobalTypes } from '@storybook/csf';
import type { ModuleFn } from '../index';
export interface SubState {
    globals?: Globals;
    globalTypes?: GlobalTypes;
}
export interface SubAPI {
    getGlobals: () => Globals;
    getGlobalTypes: () => GlobalTypes;
    updateGlobals: (newGlobals: Globals) => void;
}
export declare const init: ModuleFn;
