// There can only be 1 default export per entry point and it has to be directly from public_api
// Exporting this twice in order to to be able to import it like { addons } instead of 'addons'
// prefer import { addons } from '@storybook/addons' over import addons from '@storybook/addons'
//
// See index.ts
import { addons } from './index';
export * from './make-decorator';
export * from './index';
export * from './types';
export * from './storybook-channel-mock';
export * from './hooks';
export default addons;