const { dirname } = require('path');
const resolveFrom = require('resolve-from');

const resolve = resolveFrom.bind(null, __dirname);

// These paths need to be aliased in the manager webpack config to ensure that all
// code running inside the manager uses the *same* version of react[-dom] that we use.
module.exports = {
  '@storybook/addons': dirname(resolve('@storybook/addons/package.json')),
  '@storybook/api': dirname(resolve('@storybook/api/package.json')),
  '@storybook/channels': dirname(resolve('@storybook/channels/package.json')),
  '@storybook/components': dirname(resolve('@storybook/components/package.json')),
  '@storybook/core-events': dirname(resolve('@storybook/core-events/package.json')),
  '@storybook/router': dirname(resolve('@storybook/router/package.json')),
  '@storybook/theming': dirname(resolve('@storybook/theming/package.json')),
  '@storybook/ui': dirname(resolve('@storybook/ui/package.json')),
  react: dirname(resolve('react/package.json')),
  'react-dom': dirname(resolve('react-dom/package.json')),
};
