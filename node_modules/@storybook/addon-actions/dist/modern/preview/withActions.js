// Based on http://backbonejs.org/docs/backbone.html#section-164
import global from 'global';
import { useEffect, makeDecorator } from '@storybook/addons';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { actions } from './actions';
import { PARAM_KEY } from '../constants';
const {
  document,
  Element
} = global;
const delegateEventSplitter = /^(\S+)\s*(.*)$/;
const isIE = Element != null && !Element.prototype.matches;
const matchesMethod = isIE ? 'msMatchesSelector' : 'matches';
const root = document && document.getElementById('root');

const hasMatchInAncestry = (element, selector) => {
  if (element[matchesMethod](selector)) {
    return true;
  }

  const parent = element.parentElement;

  if (!parent) {
    return false;
  }

  return hasMatchInAncestry(parent, selector);
};

const createHandlers = (actionsFn, ...handles) => {
  const actionsObject = actionsFn(...handles);
  return Object.entries(actionsObject).map(([key, action]) => {
    const [_, eventName, selector] = key.match(delegateEventSplitter);
    return {
      eventName,
      handler: e => {
        if (!selector || hasMatchInAncestry(e.target, selector)) {
          action(e);
        }
      }
    };
  });
};

const applyEventHandlers = deprecate((actionsFn, ...handles) => {
  useEffect(() => {
    if (root != null) {
      const handlers = createHandlers(actionsFn, ...handles);
      handlers.forEach(({
        eventName,
        handler
      }) => root.addEventListener(eventName, handler));
      return () => handlers.forEach(({
        eventName,
        handler
      }) => root.removeEventListener(eventName, handler));
    }

    return undefined;
  }, [root, actionsFn, handles]);
}, dedent`
    withActions(options) is deprecated, please configure addon-actions using the addParameter api:

    addParameters({
      actions: {
        handles: options
      },
    });
  `);

const applyDeprecatedOptions = (actionsFn, options) => {
  if (options) {
    applyEventHandlers(actionsFn, options);
  }
};

export const withActions = makeDecorator({
  name: 'withActions',
  parameterName: PARAM_KEY,
  skipIfNoParametersOrOptions: true,
  wrapper: (getStory, context, {
    parameters,
    options
  }) => {
    applyDeprecatedOptions(actions, options);
    if (parameters && parameters.handles) applyEventHandlers(actions, ...parameters.handles);
    return getStory(context);
  }
});