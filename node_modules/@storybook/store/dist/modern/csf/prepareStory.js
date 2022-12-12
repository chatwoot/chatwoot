import "core-js/modules/es.array.reduce.js";
import dedent from 'ts-dedent';
import deprecate from 'util-deprecate';
import global from 'global';
import { includeConditionalArg } from '@storybook/csf';
import { combineParameters } from '../parameters';
import { applyHooks } from '../hooks';
import { defaultDecorateStory } from '../decorators';
import { groupArgsByTarget, NO_TARGET_NAME } from '../args';
import { getValuesFromArgTypes } from './getValuesFromArgTypes';
const argTypeDefaultValueWarning = deprecate(() => {}, dedent`
  \`argType.defaultValue\` is deprecated and will be removed in Storybook 7.0.

  https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#no-longer-inferring-default-values-of-args`); // Combine all the metadata about a story (both direct and inherited from the component/global scope)
// into a "renderable" story function, with all decorators applied, parameters passed as context etc
//
// Note that this story function is *stateless* in the sense that it does not track args or globals
// Instead, it is expected these are tracked separately (if necessary) and are passed into each invocation.

export function prepareStory(storyAnnotations, componentAnnotations, projectAnnotations) {
  var _global$FEATURES;

  // NOTE: in the current implementation we are doing everything once, up front, rather than doing
  // anything at render time. The assumption is that as we don't load all the stories at once, this
  // will have a limited cost. If this proves misguided, we can refactor it.
  const {
    id,
    name
  } = storyAnnotations;
  const {
    title
  } = componentAnnotations;
  const parameters = combineParameters(projectAnnotations.parameters, componentAnnotations.parameters, storyAnnotations.parameters);
  const decorators = [...(storyAnnotations.decorators || []), ...(componentAnnotations.decorators || []), ...(projectAnnotations.decorators || [])]; // Currently it is only possible to set these globally

  const {
    applyDecorators = defaultDecorateStory,
    argTypesEnhancers = [],
    argsEnhancers = []
  } = projectAnnotations;
  const loaders = [...(projectAnnotations.loaders || []), ...(componentAnnotations.loaders || []), ...(storyAnnotations.loaders || [])]; // The render function on annotations *has* to be an `ArgsStoryFn`, so when we normalize
  // CSFv1/2, we use a new field called `userStoryFn` so we know that it can be a LegacyStoryFn

  const render = storyAnnotations.userStoryFn || storyAnnotations.render || componentAnnotations.render || projectAnnotations.render;
  const passedArgTypes = combineParameters(projectAnnotations.argTypes, componentAnnotations.argTypes, storyAnnotations.argTypes);
  const {
    passArgsFirst = true
  } = parameters; // eslint-disable-next-line no-underscore-dangle

  parameters.__isArgsStory = passArgsFirst && render.length > 0; // Pull out args[X] into initialArgs for argTypes enhancers

  const passedArgs = Object.assign({}, projectAnnotations.args, componentAnnotations.args, storyAnnotations.args);
  const contextForEnhancers = {
    componentId: componentAnnotations.id,
    title,
    kind: title,
    // Back compat
    id,
    name,
    story: name,
    // Back compat
    component: componentAnnotations.component,
    subcomponents: componentAnnotations.subcomponents,
    parameters,
    initialArgs: passedArgs,
    argTypes: passedArgTypes
  };
  contextForEnhancers.argTypes = argTypesEnhancers.reduce((accumulatedArgTypes, enhancer) => enhancer(Object.assign({}, contextForEnhancers, {
    argTypes: accumulatedArgTypes
  })), contextForEnhancers.argTypes); // Add argTypes[X].defaultValue to initial args (note this deprecated)
  // We need to do this *after* the argTypesEnhancers as they may add defaultValues

  const defaultArgs = getValuesFromArgTypes(contextForEnhancers.argTypes);

  if (Object.keys(defaultArgs).length > 0) {
    argTypeDefaultValueWarning();
  }

  const initialArgsBeforeEnhancers = Object.assign({}, defaultArgs, passedArgs);
  contextForEnhancers.initialArgs = argsEnhancers.reduce((accumulatedArgs, enhancer) => Object.assign({}, accumulatedArgs, enhancer(Object.assign({}, contextForEnhancers, {
    initialArgs: accumulatedArgs
  }))), initialArgsBeforeEnhancers); // Add some of our metadata into parameters as we used to do this in 6.x and users may be relying on it

  if (!((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.breakingChangesV7)) {
    contextForEnhancers.parameters = Object.assign({}, contextForEnhancers.parameters, {
      __id: id,
      globals: projectAnnotations.globals,
      globalTypes: projectAnnotations.globalTypes,
      args: contextForEnhancers.initialArgs,
      argTypes: contextForEnhancers.argTypes
    });
  }

  const applyLoaders = async context => {
    const loadResults = await Promise.all(loaders.map(loader => loader(context)));
    const loaded = Object.assign({}, ...loadResults);
    return Object.assign({}, context, {
      loaded
    });
  };

  const undecoratedStoryFn = context => {
    const mappedArgs = Object.entries(context.args).reduce((acc, [key, val]) => {
      var _context$argTypes$key;

      const mapping = (_context$argTypes$key = context.argTypes[key]) === null || _context$argTypes$key === void 0 ? void 0 : _context$argTypes$key.mapping;
      acc[key] = mapping && val in mapping ? mapping[val] : val;
      return acc;
    }, {});
    const includedArgs = Object.entries(mappedArgs).reduce((acc, [key, val]) => {
      const argType = context.argTypes[key] || {};
      if (includeConditionalArg(argType, mappedArgs, context.globals)) acc[key] = val;
      return acc;
    }, {});
    const includedContext = Object.assign({}, context, {
      args: includedArgs
    });
    const {
      passArgsFirst: renderTimePassArgsFirst = true
    } = context.parameters;
    return renderTimePassArgsFirst ? render(includedContext.args, includedContext) : render(includedContext);
  };

  const decoratedStoryFn = applyHooks(applyDecorators)(undecoratedStoryFn, decorators);

  const unboundStoryFn = context => {
    var _global$FEATURES2;

    let finalContext = context;

    if ((_global$FEATURES2 = global.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.argTypeTargetsV7) {
      const argsByTarget = groupArgsByTarget(Object.assign({
        args: context.args
      }, context));
      finalContext = Object.assign({}, context, {
        allArgs: context.args,
        argsByTarget,
        args: argsByTarget[NO_TARGET_NAME] || {}
      });
    }

    return decoratedStoryFn(finalContext);
  };

  const playFunction = storyAnnotations.play;
  return Object.freeze(Object.assign({}, contextForEnhancers, {
    originalStoryFn: render,
    undecoratedStoryFn,
    unboundStoryFn,
    applyLoaders,
    playFunction
  }));
}