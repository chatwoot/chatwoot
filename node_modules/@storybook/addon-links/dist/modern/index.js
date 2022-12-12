import dedent from 'ts-dedent';
let hasWarned = false;
export function LinkTo() {
  if (!hasWarned) {
    // eslint-disable-next-line no-console
    console.error(dedent`
      LinkTo has moved to addon-links/react:
      import LinkTo from '@storybook/addon-links/react';
    `);
    hasWarned = true;
  }

  return null;
}
export { linkTo, hrefTo, withLinks, navigate } from './utils';

if (module && module.hot && module.hot.decline) {
  module.hot.decline();
}