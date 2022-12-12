function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

import React, { useContext, useEffect, useState, useCallback } from 'react';
import mapValues from 'lodash/mapValues';
import { ArgsTable as PureArgsTable, ArgsTableError, TabbedArgsTable } from '@storybook/components';
import { addons } from '@storybook/addons';
import { filterArgTypes } from '@storybook/store';
import Events from '@storybook/core-events';
import { DocsContext } from './DocsContext';
import { CURRENT_SELECTION, PRIMARY_STORY } from './types';
import { getComponentName } from './utils';
import { lookupStoryId } from './Story';
import { useStory } from './useStory';

const getContext = (storyId, context) => {
  const story = context.storyById(storyId);

  if (!story) {
    throw new Error(`Unknown story: ${storyId}`);
  }

  return context.getStoryContext(story);
};

const useArgs = (storyId, context) => {
  const channel = addons.getChannel();
  const storyContext = getContext(storyId, context);
  const [args, setArgs] = useState(storyContext.args);
  useEffect(() => {
    const cb = changed => {
      if (changed.storyId === storyId) {
        setArgs(changed.args);
      }
    };

    channel.on(Events.STORY_ARGS_UPDATED, cb);
    return () => channel.off(Events.STORY_ARGS_UPDATED, cb);
  }, [storyId]);
  const updateArgs = useCallback(updatedArgs => channel.emit(Events.UPDATE_STORY_ARGS, {
    storyId,
    updatedArgs
  }), [storyId]);
  const resetArgs = useCallback(argNames => channel.emit(Events.RESET_STORY_ARGS, {
    storyId,
    argNames
  }), [storyId]);
  return [args, updateArgs, resetArgs];
};

const useGlobals = (storyId, context) => {
  const channel = addons.getChannel();
  const storyContext = getContext(storyId, context);
  const [globals, setGlobals] = useState(storyContext.globals);
  useEffect(() => {
    const cb = changed => {
      setGlobals(changed.globals);
    };

    channel.on(Events.GLOBALS_UPDATED, cb);
    return () => channel.off(Events.GLOBALS_UPDATED, cb);
  }, []);
  return [globals];
};

export const extractComponentArgTypes = (component, {
  id,
  storyById
}, include, exclude) => {
  const {
    parameters
  } = storyById(id);
  const {
    extractArgTypes
  } = parameters.docs || {};

  if (!extractArgTypes) {
    throw new Error(ArgsTableError.ARGS_UNSUPPORTED);
  }

  let argTypes = extractArgTypes(component);
  argTypes = filterArgTypes(argTypes, include, exclude);
  return argTypes;
};

const isShortcut = value => {
  return value && [CURRENT_SELECTION, PRIMARY_STORY].includes(value);
};

export const getComponent = (props = {}, {
  id,
  storyById
}) => {
  const {
    of
  } = props;
  const {
    story
  } = props;
  const {
    component
  } = storyById(id);

  if (isShortcut(of) || isShortcut(story)) {
    return component || null;
  }

  if (!of) {
    throw new Error(ArgsTableError.NO_COMPONENT);
  }

  return of;
};

const addComponentTabs = (tabs, components, context, include, exclude, sort) => Object.assign({}, tabs, mapValues(components, comp => ({
  rows: extractComponentArgTypes(comp, context, include, exclude),
  sort
})));

export const StoryTable = props => {
  const context = useContext(DocsContext);
  const {
    id: currentId,
    componentStories
  } = context;
  const {
    story: storyName,
    component,
    subcomponents,
    showComponent,
    include,
    exclude,
    sort
  } = props;

  try {
    let storyId;

    switch (storyName) {
      case CURRENT_SELECTION:
        {
          storyId = currentId;
          break;
        }

      case PRIMARY_STORY:
        {
          const primaryStory = componentStories()[0];
          storyId = primaryStory.id;
          break;
        }

      default:
        {
          storyId = lookupStoryId(storyName, context);
        }
    }

    const story = useStory(storyId, context); // eslint-disable-next-line prefer-const

    let [args, updateArgs, resetArgs] = useArgs(storyId, context);
    const [globals] = useGlobals(storyId, context);
    if (!story) return /*#__PURE__*/React.createElement(PureArgsTable, {
      isLoading: true,
      updateArgs: updateArgs,
      resetArgs: resetArgs
    });
    const argTypes = filterArgTypes(story.argTypes, include, exclude);
    const mainLabel = getComponentName(component) || 'Story';
    let tabs = {
      [mainLabel]: {
        rows: argTypes,
        args,
        globals,
        updateArgs,
        resetArgs
      }
    }; // Use the dynamically generated component tabs if there are no controls

    const storyHasArgsWithControls = argTypes && Object.values(argTypes).find(v => !!(v !== null && v !== void 0 && v.control));

    if (!storyHasArgsWithControls) {
      updateArgs = null;
      resetArgs = null;
      tabs = {};
    }

    if (component && (!storyHasArgsWithControls || showComponent)) {
      tabs = addComponentTabs(tabs, {
        [mainLabel]: component
      }, context, include, exclude);
    }

    if (subcomponents) {
      if (Array.isArray(subcomponents)) {
        throw new Error(`Unexpected subcomponents array. Expected an object whose keys are tab labels and whose values are components.`);
      }

      tabs = addComponentTabs(tabs, subcomponents, context, include, exclude);
    }

    return /*#__PURE__*/React.createElement(TabbedArgsTable, {
      tabs: tabs,
      sort: sort
    });
  } catch (err) {
    return /*#__PURE__*/React.createElement(PureArgsTable, {
      error: err.message
    });
  }
};
export const ComponentsTable = props => {
  const context = useContext(DocsContext);
  const {
    components,
    include,
    exclude,
    sort
  } = props;
  const tabs = addComponentTabs({}, components, context, include, exclude);
  return /*#__PURE__*/React.createElement(TabbedArgsTable, {
    tabs: tabs,
    sort: sort
  });
};
export const ArgsTable = props => {
  const context = useContext(DocsContext);
  const {
    id,
    storyById
  } = context;
  const {
    parameters: {
      controls
    },
    subcomponents
  } = storyById(id);
  const {
    include,
    exclude,
    components,
    sort: sortProp
  } = props;
  const {
    story: storyName
  } = props;
  const sort = sortProp || (controls === null || controls === void 0 ? void 0 : controls.sort);
  const main = getComponent(props, context);

  if (storyName) {
    return /*#__PURE__*/React.createElement(StoryTable, _extends({}, props, {
      component: main,
      subcomponents,
      sort
    }));
  }

  if (!components && !subcomponents) {
    let mainProps;

    try {
      mainProps = {
        rows: extractComponentArgTypes(main, context, include, exclude)
      };
    } catch (err) {
      mainProps = {
        error: err.message
      };
    }

    return /*#__PURE__*/React.createElement(PureArgsTable, _extends({}, mainProps, {
      sort: sort
    }));
  }

  if (components) {
    return /*#__PURE__*/React.createElement(ComponentsTable, _extends({}, props, {
      components,
      sort
    }));
  }

  const mainLabel = getComponentName(main);
  return /*#__PURE__*/React.createElement(ComponentsTable, _extends({}, props, {
    components: Object.assign({
      [mainLabel]: main
    }, subcomponents),
    sort: sort
  }));
};
ArgsTable.defaultProps = {
  of: CURRENT_SELECTION
};