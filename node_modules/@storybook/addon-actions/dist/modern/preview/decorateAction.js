import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
export const decorateAction = _decorators => {
  return deprecate(() => {}, dedent`
    decorateAction is no longer supported as of Storybook 6.0.
  `);
};
const deprecatedCallback = deprecate(() => {}, 'decorate.* is no longer supported as of Storybook 6.0.');
export const decorate = _decorators => {
  return deprecate(() => {
    return {
      action: deprecatedCallback,
      actions: deprecatedCallback,
      withActions: deprecatedCallback
    };
  }, dedent`
    decorate is deprecated, please configure addon-actions using the addParameter api:
      
      addParameters({
        actions: {
          handles: options
        },
      });
    `);
};