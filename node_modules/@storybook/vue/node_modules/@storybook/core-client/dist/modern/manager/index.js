import global from 'global';
import renderStorybookUI from '@storybook/ui';
import Provider from './provider';
import { importPolyfills } from './conditional-polyfills';
const {
  document
} = global;
importPolyfills().then(() => {
  const rootEl = document.getElementById('root');
  renderStorybookUI(rootEl, new Provider());
});