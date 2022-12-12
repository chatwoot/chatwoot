import global from 'global';
import { logger } from '@storybook/client-logger';
import { FORCE_RE_RENDER, STORY_RENDERED, UPDATE_STORY_ARGS, RESET_STORY_ARGS, UPDATE_GLOBALS } from '@storybook/core-events';
import { addons } from './index';
const {
  window: globalWindow
} = global;
export class HooksContext {
  constructor() {
    this.hookListsMap = void 0;
    this.mountedDecorators = void 0;
    this.prevMountedDecorators = void 0;
    this.currentHooks = void 0;
    this.nextHookIndex = void 0;
    this.currentPhase = void 0;
    this.currentEffects = void 0;
    this.prevEffects = void 0;
    this.currentDecoratorName = void 0;
    this.hasUpdates = void 0;
    this.currentContext = void 0;

    this.renderListener = storyId => {
      if (storyId !== this.currentContext.id) return;
      this.triggerEffects();
      this.currentContext = null;
      this.removeRenderListeners();
    };

    this.init();
  }

  init() {
    this.hookListsMap = new WeakMap();
    this.mountedDecorators = new Set();
    this.prevMountedDecorators = this.mountedDecorators;
    this.currentHooks = [];
    this.nextHookIndex = 0;
    this.currentPhase = 'NONE';
    this.currentEffects = [];
    this.prevEffects = [];
    this.currentDecoratorName = null;
    this.hasUpdates = false;
    this.currentContext = null;
  }

  clean() {
    this.prevEffects.forEach(effect => {
      if (effect.destroy) {
        effect.destroy();
      }
    });
    this.init();
    this.removeRenderListeners();
  }

  getNextHook() {
    const hook = this.currentHooks[this.nextHookIndex];
    this.nextHookIndex += 1;
    return hook;
  }

  triggerEffects() {
    // destroy removed effects
    this.prevEffects.forEach(effect => {
      if (!this.currentEffects.includes(effect) && effect.destroy) {
        effect.destroy();
      }
    }); // trigger added effects

    this.currentEffects.forEach(effect => {
      if (!this.prevEffects.includes(effect)) {
        // eslint-disable-next-line no-param-reassign
        effect.destroy = effect.create();
      }
    });
    this.prevEffects = this.currentEffects;
    this.currentEffects = [];
  }

  addRenderListeners() {
    this.removeRenderListeners();
    const channel = addons.getChannel();
    channel.on(STORY_RENDERED, this.renderListener);
  }

  removeRenderListeners() {
    const channel = addons.getChannel();
    channel.removeListener(STORY_RENDERED, this.renderListener);
  }

}

function hookify(fn) {
  return (...args) => {
    const {
      hooks
    } = typeof args[0] === 'function' ? args[1] : args[0];
    const prevPhase = hooks.currentPhase;
    const prevHooks = hooks.currentHooks;
    const prevNextHookIndex = hooks.nextHookIndex;
    const prevDecoratorName = hooks.currentDecoratorName;
    hooks.currentDecoratorName = fn.name;

    if (hooks.prevMountedDecorators.has(fn)) {
      hooks.currentPhase = 'UPDATE';
      hooks.currentHooks = hooks.hookListsMap.get(fn) || [];
    } else {
      hooks.currentPhase = 'MOUNT';
      hooks.currentHooks = [];
      hooks.hookListsMap.set(fn, hooks.currentHooks);
      hooks.prevMountedDecorators.add(fn);
    }

    hooks.nextHookIndex = 0;
    const prevContext = globalWindow.STORYBOOK_HOOKS_CONTEXT;
    globalWindow.STORYBOOK_HOOKS_CONTEXT = hooks;
    const result = fn(...args);
    globalWindow.STORYBOOK_HOOKS_CONTEXT = prevContext;

    if (hooks.currentPhase === 'UPDATE' && hooks.getNextHook() != null) {
      throw new Error('Rendered fewer hooks than expected. This may be caused by an accidental early return statement.');
    }

    hooks.currentPhase = prevPhase;
    hooks.currentHooks = prevHooks;
    hooks.nextHookIndex = prevNextHookIndex;
    hooks.currentDecoratorName = prevDecoratorName;
    return result;
  };
} // Counter to prevent infinite loops.


let numberOfRenders = 0;
const RENDER_LIMIT = 25;
export const applyHooks = applyDecorators => (storyFn, decorators) => {
  const decorated = applyDecorators(hookify(storyFn), decorators.map(decorator => hookify(decorator)));
  return context => {
    const {
      hooks
    } = context;
    hooks.prevMountedDecorators = hooks.mountedDecorators;
    hooks.mountedDecorators = new Set([storyFn, ...decorators]);
    hooks.currentContext = context;
    hooks.hasUpdates = false;
    let result = decorated(context);
    numberOfRenders = 1;

    while (hooks.hasUpdates) {
      hooks.hasUpdates = false;
      hooks.currentEffects = [];
      result = decorated(context);
      numberOfRenders += 1;

      if (numberOfRenders > RENDER_LIMIT) {
        throw new Error('Too many re-renders. Storybook limits the number of renders to prevent an infinite loop.');
      }
    }

    hooks.addRenderListeners();
    return result;
  };
};

const areDepsEqual = (deps, nextDeps) => deps.length === nextDeps.length && deps.every((dep, i) => dep === nextDeps[i]);

const invalidHooksError = () => new Error('Storybook preview hooks can only be called inside decorators and story functions.');

function getHooksContextOrNull() {
  return globalWindow.STORYBOOK_HOOKS_CONTEXT || null;
}

function getHooksContextOrThrow() {
  const hooks = getHooksContextOrNull();

  if (hooks == null) {
    throw invalidHooksError();
  }

  return hooks;
}

function useHook(name, callback, deps) {
  const hooks = getHooksContextOrThrow();

  if (hooks.currentPhase === 'MOUNT') {
    if (deps != null && !Array.isArray(deps)) {
      logger.warn(`${name} received a final argument that is not an array (instead, received ${deps}). When specified, the final argument must be an array.`);
    }

    const hook = {
      name,
      deps
    };
    hooks.currentHooks.push(hook);
    callback(hook);
    return hook;
  }

  if (hooks.currentPhase === 'UPDATE') {
    const hook = hooks.getNextHook();

    if (hook == null) {
      throw new Error('Rendered more hooks than during the previous render.');
    }

    if (hook.name !== name) {
      logger.warn(`Storybook has detected a change in the order of Hooks${hooks.currentDecoratorName ? ` called by ${hooks.currentDecoratorName}` : ''}. This will lead to bugs and errors if not fixed.`);
    }

    if (deps != null && hook.deps == null) {
      logger.warn(`${name} received a final argument during this render, but not during the previous render. Even though the final argument is optional, its type cannot change between renders.`);
    }

    if (deps != null && hook.deps != null && deps.length !== hook.deps.length) {
      logger.warn(`The final argument passed to ${name} changed size between renders. The order and size of this array must remain constant.
Previous: ${hook.deps}
Incoming: ${deps}`);
    }

    if (deps == null || hook.deps == null || !areDepsEqual(deps, hook.deps)) {
      callback(hook);
      hook.deps = deps;
    }

    return hook;
  }

  throw invalidHooksError();
}

function useMemoLike(name, nextCreate, deps) {
  const {
    memoizedState
  } = useHook(name, hook => {
    // eslint-disable-next-line no-param-reassign
    hook.memoizedState = nextCreate();
  }, deps);
  return memoizedState;
}
/* Returns a memoized value, see https://reactjs.org/docs/hooks-reference.html#usememo */


export function useMemo(nextCreate, deps) {
  return useMemoLike('useMemo', nextCreate, deps);
}
/* Returns a memoized callback, see https://reactjs.org/docs/hooks-reference.html#usecallback */

export function useCallback(callback, deps) {
  return useMemoLike('useCallback', () => callback, deps);
}

function useRefLike(name, initialValue) {
  return useMemoLike(name, () => ({
    current: initialValue
  }), []);
}
/* Returns a mutable ref object, see https://reactjs.org/docs/hooks-reference.html#useref */


export function useRef(initialValue) {
  return useRefLike('useRef', initialValue);
}

function triggerUpdate() {
  const hooks = getHooksContextOrNull(); // Rerun storyFn if updates were triggered synchronously, force rerender otherwise

  if (hooks != null && hooks.currentPhase !== 'NONE') {
    hooks.hasUpdates = true;
  } else {
    try {
      addons.getChannel().emit(FORCE_RE_RENDER);
    } catch (e) {
      logger.warn('State updates of Storybook preview hooks work only in browser');
    }
  }
}

function useStateLike(name, initialState) {
  const stateRef = useRefLike(name, // @ts-ignore S type should never be function, but there's no way to tell that to TypeScript
  typeof initialState === 'function' ? initialState() : initialState);

  const setState = update => {
    // @ts-ignore S type should never be function, but there's no way to tell that to TypeScript
    stateRef.current = typeof update === 'function' ? update(stateRef.current) : update;
    triggerUpdate();
  };

  return [stateRef.current, setState];
}
/* Returns a stateful value, and a function to update it, see https://reactjs.org/docs/hooks-reference.html#usestate */


export function useState(initialState) {
  return useStateLike('useState', initialState);
}
/* A redux-like alternative to useState, see https://reactjs.org/docs/hooks-reference.html#usereducer */

export function useReducer(reducer, initialArg, init) {
  const initialState = init != null ? () => init(initialArg) : initialArg;
  const [state, setState] = useStateLike('useReducer', initialState);

  const dispatch = action => setState(prevState => reducer(prevState, action));

  return [state, dispatch];
}
/*
  Triggers a side effect, see https://reactjs.org/docs/hooks-reference.html#usestate
  Effects are triggered synchronously after rendering the story
*/

export function useEffect(create, deps) {
  const hooks = getHooksContextOrThrow();
  const effect = useMemoLike('useEffect', () => ({
    create
  }), deps);

  if (!hooks.currentEffects.includes(effect)) {
    hooks.currentEffects.push(effect);
  }
}

/* Accepts a map of Storybook channel event listeners, returns an emit function */
export function useChannel(eventMap, deps = []) {
  const channel = addons.getChannel();
  useEffect(() => {
    Object.entries(eventMap).forEach(([type, listener]) => channel.on(type, listener));
    return () => {
      Object.entries(eventMap).forEach(([type, listener]) => channel.removeListener(type, listener));
    };
  }, [...Object.keys(eventMap), ...deps]);
  return useCallback(channel.emit.bind(channel), [channel]);
}
/* Returns current story context */

export function useStoryContext() {
  const {
    currentContext
  } = getHooksContextOrThrow();

  if (currentContext == null) {
    throw invalidHooksError();
  }

  return currentContext;
}
/* Returns current value of a story parameter */

export function useParameter(parameterKey, defaultValue) {
  const {
    parameters
  } = useStoryContext();

  if (parameterKey) {
    var _parameters$parameter;

    return (_parameters$parameter = parameters[parameterKey]) !== null && _parameters$parameter !== void 0 ? _parameters$parameter : defaultValue;
  }

  return undefined;
}
/* Returns current value of story args */

export function useArgs() {
  const channel = addons.getChannel();
  const {
    id: storyId,
    args
  } = useStoryContext();
  const updateArgs = useCallback(updatedArgs => channel.emit(UPDATE_STORY_ARGS, {
    storyId,
    updatedArgs
  }), [channel, storyId]);
  const resetArgs = useCallback(argNames => channel.emit(RESET_STORY_ARGS, {
    storyId,
    argNames
  }), [channel, storyId]);
  return [args, updateArgs, resetArgs];
}
/* Returns current value of global args */

export function useGlobals() {
  const channel = addons.getChannel();
  const {
    globals
  } = useStoryContext();
  const updateGlobals = useCallback(newGlobals => channel.emit(UPDATE_GLOBALS, {
    globals: newGlobals
  }), [channel]);
  return [globals, updateGlobals];
}