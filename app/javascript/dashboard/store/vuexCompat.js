// Pinia-era Vuex compatibility layer
// Provides Vuex 4 `createStore` / `mapHelpers` / `useStore` on Vue 3 reactivity
// so existing modules run without the `vuex` npm package. Production Vite
// is aliased to this file (vite.config.ts); tests are also aliased via
// vite.shared.ts so the suite validates the compat layer.

import { reactive, inject, computed, getCurrentInstance } from 'vue';

const StoreKey = Symbol('vuex-compat-store');

function cloneState(state) {
  if (typeof state === 'function') return state();
  if (state == null) return {};
  return JSON.parse(JSON.stringify(state));
}

function normalizeMapArgs(arg1, arg2) {
  if (typeof arg1 === 'string') {
    const namespace = arg1.endsWith('/') ? arg1.slice(0, -1) : arg1;
    if (Array.isArray(arg2)) {
      const map = {};
      arg2.forEach(k => {
        map[k] = `${namespace}/${k}`;
      });
      return map;
    }
    if (arg2 && typeof arg2 === 'object') {
      const map = {};
      Object.entries(arg2).forEach(([local, getterKey]) => {
        map[local] = `${namespace}/${getterKey}`;
      });
      return map;
    }
    return {};
  }
  if (Array.isArray(arg1)) {
    const map = {};
    arg1.forEach(k => {
      map[k] = k;
    });
    return map;
  }
  if (arg1 && typeof arg1 === 'object') {
    return { ...arg1 };
  }
  return {};
}

// Create a safe shallow copy where arrays are cloned so in-place
// `Array.sort()` inside getters does not mutate the reactive source.
// Reads from reactive source so computed tracks dependencies.
function safeStateCopy(reactiveState) {
  if (!reactiveState || typeof reactiveState !== 'object') return reactiveState;
  const copy = Array.isArray(reactiveState)
    ? [...reactiveState]
    : { ...reactiveState };
  Object.keys(copy).forEach(k => {
    if (Array.isArray(copy[k])) copy[k] = [...copy[k]];
  });
  return copy;
}

export function createStore(options = {}) {
  const modules = options.modules || {};
  const initialRootState = options.state ? cloneState(options.state) : {};
  const state = reactive({ ...initialRootState });
  const rawStates = { __root__: state };
  const gettersDef = {};
  const mutations = {};
  const actions = {};

  // Handle root getters/mutations/actions (used by isolated test stores)
  if (options.getters) {
    Object.entries(options.getters).forEach(([getterName, fn]) => {
      gettersDef[getterName] = {
        fn,
        moduleName: '__root__',
        isNamespaced: false,
      };
    });
  }
  if (options.mutations) {
    Object.entries(options.mutations).forEach(([mutName, fn]) => {
      mutations[mutName] = { fn, moduleName: '__root__' };
    });
  }
  if (options.actions) {
    Object.entries(options.actions).forEach(([actionName, fn]) => {
      actions[actionName] = { fn, moduleName: '__root__', isNamespaced: false };
    });
  }

  Object.entries(modules).forEach(([moduleName, mod]) => {
    const modState = cloneState(mod.state);
    const reactiveState = reactive(modState);
    rawStates[moduleName] = reactiveState;
    state[moduleName] = reactiveState;
    const isNamespaced = mod.namespaced === true;

    if (mod.getters) {
      Object.entries(mod.getters).forEach(([getterName, fn]) => {
        const key = isNamespaced ? `${moduleName}/${getterName}` : getterName;
        gettersDef[key] = { fn, moduleName, isNamespaced };
        if (!isNamespaced) {
          gettersDef[`${moduleName}/${getterName}`] = {
            fn,
            moduleName,
            isNamespaced,
          };
        }
      });
    }
    if (mod.mutations) {
      Object.entries(mod.mutations).forEach(([mutName, fn]) => {
        const key = isNamespaced ? `${moduleName}/${mutName}` : mutName;
        mutations[key] = { fn, moduleName };
        if (!isNamespaced) {
          mutations[`${moduleName}/${mutName}`] = { fn, moduleName };
        }
        if (!mutations[mutName]) mutations[mutName] = { fn, moduleName };
      });
    }
    if (mod.actions) {
      Object.entries(mod.actions).forEach(([actionName, fn]) => {
        const key = isNamespaced ? `${moduleName}/${actionName}` : actionName;
        actions[key] = { fn, moduleName, isNamespaced };
        if (!isNamespaced) {
          actions[`${moduleName}/${actionName}`] = {
            fn,
            moduleName,
            isNamespaced,
          };
        }
      });
    }
  });

  if (!state.route) {
    state.route = reactive({
      params: {},
      query: {},
      path: '',
      name: '',
      meta: {},
    });
  }

  // Cache computed wrappers for getters to avoid re-evaluating on every access
  // and to give Vue proper caching semantics.
  const computedCache = {};
  const evaluating = new Set();

  function evaluateGetter(fullKey) {
    const entry = gettersDef[fullKey];
    if (!entry) {
      const found = Object.keys(gettersDef).find(
        k => k === fullKey || k.endsWith(`/${fullKey}`)
      );
      if (!found) return undefined;
      return evaluateGetter(found);
    }
    if (evaluating.has(fullKey)) return undefined;
    evaluating.add(fullKey);
    try {
      const { fn, moduleName } = entry;
      const isNamespaced = modules[moduleName]?.namespaced === true;
      const moduleState =
        moduleName && rawStates[moduleName] ? rawStates[moduleName] : state;
      const safeModuleState = safeStateCopy(moduleState);
      const rawRootState = state;

      const localGetters = new Proxy(
        {},
        {
          get(_, g) {
            if (typeof g !== 'string') return undefined;
            const localKey =
              isNamespaced && moduleName ? `${moduleName}/${g}` : g;
            if (localKey === fullKey) return undefined;
            if (gettersDef[localKey]) {
              const c = getComputedGetter(localKey); // eslint-disable-line no-use-before-define
              return c ? c.value : undefined;
            }
            if (gettersDef[g]) {
              const c = getComputedGetter(g); // eslint-disable-line no-use-before-define
              return c ? c.value : undefined;
            }
            return undefined;
          },
        }
      );

      // eslint-disable-next-line no-use-before-define, prettier/prettier
      const result = fn(safeModuleState, localGetters, rawRootState, gettersProxy);
      return result;
    } finally {
      evaluating.delete(fullKey);
    }
  }

  function getComputedGetter(fullKey) {
    if (computedCache[fullKey]) return computedCache[fullKey];
    const entry = gettersDef[fullKey];
    if (!entry) return null;
    const c = computed(() => evaluateGetter(fullKey));
    computedCache[fullKey] = c;
    return c;
  }

  const gettersProxy = new Proxy(
    {},
    {
      get(_target, key) {
        if (typeof key !== 'string') return undefined;
        // exact match first
        if (gettersDef[key]) {
          const c = getComputedGetter(key);
          return c ? c.value : undefined;
        }
        // fallback: bare key suffix match for non-namespaced access
        const found = Object.keys(gettersDef).find(
          k => k === key || k.endsWith(`/${key}`)
        );
        if (found) {
          const c = getComputedGetter(found);
          return c ? c.value : undefined;
        }
        return undefined;
      },
      has(_target, key) {
        if (typeof key !== 'string') return false;
        return (
          key in gettersDef ||
          Object.keys(gettersDef).some(k => k === key || k.endsWith(`/${key}`))
        );
      },
      ownKeys() {
        return Reflect.ownKeys(gettersDef);
      },
      getOwnPropertyDescriptor(_target, key) {
        if (key in gettersDef) return { enumerable: true, configurable: true };
        return undefined;
      },
    }
  );

  function commit(type, payload, _options) {
    void _options; // eslint-disable-line no-void
    let entry = mutations[type];
    if (!entry) {
      const foundKey = Object.keys(mutations).find(
        k => k === type || k.endsWith(`/${type}`)
      );
      if (foundKey) entry = mutations[foundKey];
    }
    if (!entry) {
      // eslint-disable-next-line no-console
      console.warn(`[vuexCompat] unknown mutation: ${type}`);
      return;
    }
    const { fn, moduleName } = entry;
    const modState = rawStates[moduleName] || state[moduleName];
    fn(modState, payload);
  }

  function dispatch(type, payload) {
    let entry = actions[type];
    if (!entry) {
      const foundKey = Object.keys(actions).find(
        k => k === type || k.endsWith(`/${type}`)
      );
      if (foundKey) entry = actions[foundKey];
    }
    if (!entry) {
      // eslint-disable-next-line no-console
      console.warn(`[vuexCompat] unknown action: ${type}`);
      return Promise.resolve();
    }
    const { fn, moduleName } = entry;
    const modState = rawStates[moduleName] || state[moduleName];
    const localGetters = new Proxy(
      {},
      {
        get(_, g) {
          if (typeof g !== 'string') return undefined;
          const isNamespaced = modules[moduleName]?.namespaced === true;
          const localKey =
            isNamespaced && moduleName ? `${moduleName}/${g}` : g;
          if (gettersDef[localKey]) {
            const c = getComputedGetter(localKey);
            return c ? c.value : undefined;
          }
          if (gettersDef[g]) {
            const c = getComputedGetter(g);
            return c ? c.value : undefined;
          }
          return undefined;
        },
      }
    );
    const context = {
      state: modState,
      getters: localGetters,
      rootState: state,
      rootGetters: gettersProxy,
      commit(localType, localPayload, opts) {
        const isNamespaced = modules[moduleName]?.namespaced === true;
        const namespaced =
          isNamespaced && moduleName ? `${moduleName}/${localType}` : localType;
        if (mutations[namespaced])
          return commit(namespaced, localPayload, opts);
        return commit(localType, localPayload, opts);
      },
      dispatch(localType, localPayload) {
        const isNamespaced = modules[moduleName]?.namespaced === true;
        const namespaced =
          isNamespaced && moduleName ? `${moduleName}/${localType}` : localType;
        if (actions[namespaced]) return dispatch(namespaced, localPayload);
        return dispatch(localType, localPayload);
      },
    };
    const result = fn(context, payload);
    return result instanceof Promise ? result : Promise.resolve(result);
  }

  const store = {
    state,
    getters: gettersProxy,
    commit,
    dispatch,
    subscribe() {
      return () => {};
    },
    install(app) {
      app.config.globalProperties.$store = store;
      app.provide(StoreKey, store);
    },
  };

  if (options.plugins && options.plugins.length) {
    options.plugins.forEach(p => {
      try {
        p(store);
      } catch (_) {
        // ignore plugin errors
      }
    });
  }

  return store;
}

export function mapGetters(arg1, arg2) {
  const map = normalizeMapArgs(arg1, arg2);
  const res = {};
  Object.entries(map).forEach(([localKey, getterKey]) => {
    res[localKey] = function mappedGetter() {
      return this.$store.getters[getterKey];
    };
  });
  return res;
}

export function mapState(arg1, arg2) {
  const map = normalizeMapArgs(arg1, arg2);
  const res = {};
  Object.entries(map).forEach(([localKey, stateKey]) => {
    res[localKey] = function mappedState() {
      if (stateKey.includes('/')) {
        const [mod, key] = stateKey.split('/');
        return this.$store.state[mod]?.[key];
      }
      return this.$store.state[stateKey];
    };
  });
  return res;
}

export function mapActions(arg1, arg2) {
  const map = normalizeMapArgs(arg1, arg2);
  const res = {};
  Object.entries(map).forEach(([localKey, actionKey]) => {
    res[localKey] = function mappedAction(payload) {
      return this.$store.dispatch(actionKey, payload);
    };
  });
  return res;
}

export function mapMutations(arg1, arg2) {
  const map = normalizeMapArgs(arg1, arg2);
  const res = {};
  Object.entries(map).forEach(([localKey, mutationKey]) => {
    res[localKey] = function mappedMutation(payload) {
      return this.$store.commit(mutationKey, payload);
    };
  });
  return res;
}

export function useStore() {
  const injected = inject(StoreKey, null);
  if (injected) return injected;
  const inst = getCurrentInstance();
  if (inst && inst.proxy && inst.proxy.$store) return inst.proxy.$store;
  return null;
}

export const Store = createStore;
export default {
  createStore,
  Store,
  mapGetters,
  mapState,
  mapActions,
  mapMutations,
  useStore,
};
