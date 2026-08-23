// Pinia-backed store facade.
//
// Replaces the former compatibility shim with a real Pinia store that still
// exposes the classic namespaced getter/dispatch/commit API the dashboard,
// widget, survey and v3 apps consume via `$store` and `composables/store`.
// Store modules are plain `{ state, getters, actions, mutations }` objects;
// each is registered as a Pinia store so state is reactive and getters are
// computed/cached by Pinia (no JSON deep-clone, no per-access state copy, no
// linear key scans).
//
// The facade is a single source of truth for both the app and the isolated
// test stores that previously built a store directly.

import { createPinia, defineStore } from 'pinia';
import { reactive, inject, watch, getCurrentInstance } from 'vue';

const StoreKey = Symbol('chatwoot-store');

function normalizeState(state) {
  if (typeof state === 'function') return state();
  return state == null ? {} : { ...state };
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

// Shallow copy where arrays are cloned so getters that sort/filter in place
// never mutate the reactive source. Pinia getters are cached as computed, so
// this only runs when a getter's dependencies actually change.
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
  const moduleDefs = {};

  // Root getters/mutations/actions (used by isolated test stores).
  const rootGetters = {};
  const rootMutations = {};
  const rootActions = {};

  if (options.getters) Object.assign(rootGetters, options.getters);
  if (options.mutations) Object.assign(rootMutations, options.mutations);
  if (options.actions) Object.assign(rootActions, options.actions);

  // Root-level state (used by isolated test stores) is merged at the top level
  // alongside any module states.
  const rootStateDef = options.state ? normalizeState(options.state) : {};

  Object.entries(modules).forEach(([name, mod]) => {
    moduleDefs[name] = {
      namespaced: mod.namespaced === true,
      state: mod.state,
      getters: mod.getters || {},
      actions: mod.actions || {},
      mutations: mod.mutations || {},
    };
  });

  // Build namespaced registries (mirrors classic namespaced module semantics).
  const gettersDef = {};
  const mutations = {};
  const actions = {};

  Object.entries(rootGetters).forEach(([name, fn]) => {
    gettersDef[name] = { fn, moduleName: '__root__', isNamespaced: false };
  });
  Object.entries(rootMutations).forEach(([name, fn]) => {
    mutations[name] = { fn, moduleName: '__root__' };
  });
  Object.entries(rootActions).forEach(([name, fn]) => {
    actions[name] = { fn, moduleName: '__root__', isNamespaced: false };
  });

  Object.entries(moduleDefs).forEach(([moduleName, def]) => {
    if (def.getters) {
      Object.entries(def.getters).forEach(([getterName, fn]) => {
        const key = def.namespaced ? `${moduleName}/${getterName}` : getterName;
        gettersDef[key] = { fn, moduleName, isNamespaced: def.namespaced };
        if (!def.namespaced) {
          gettersDef[`${moduleName}/${getterName}`] = {
            fn,
            moduleName,
            isNamespaced: false,
          };
        }
      });
    }
    if (def.mutations) {
      Object.entries(def.mutations).forEach(([mutName, fn]) => {
        const key = def.namespaced ? `${moduleName}/${mutName}` : mutName;
        mutations[key] = { fn, moduleName };
        if (!def.namespaced) {
          mutations[`${moduleName}/${mutName}`] = { fn, moduleName };
        }
        if (!mutations[mutName]) mutations[mutName] = { fn, moduleName };
      });
    }
    if (def.actions) {
      Object.entries(def.actions).forEach(([actionName, fn]) => {
        const key = def.namespaced ? `${moduleName}/${actionName}` : actionName;
        actions[key] = { fn, moduleName, isNamespaced: def.namespaced };
        if (!def.namespaced) {
          actions[`${moduleName}/${actionName}`] = {
            fn,
            moduleName,
            isNamespaced: false,
          };
        }
      });
    }
  });

  // Register every getter as a real Pinia getter keyed by its namespaced name
  // so getters referencing sibling/root getters resolve through the store.
  const piniaGetters = {};
  Object.entries(gettersDef).forEach(
    ([key, { fn, moduleName, isNamespaced }]) => {
      piniaGetters[key] = function getter(state) {
        const moduleState =
          moduleName === '__root__' ? state : state[moduleName];
        const safeModuleState = safeStateCopy(moduleState);
        const localGetters = new Proxy(
          {},
          {
            get: (_, g) => {
              if (typeof g !== 'string') return undefined;
              const localKey =
                isNamespaced && moduleName ? `${moduleName}/${g}` : g;
              if (localKey === key) return undefined;
              return this[localKey] ?? this[g];
            },
          }
        );
        return fn(safeModuleState, localGetters, state, this);
      };
    }
  );

  const useRootStore = defineStore('rootStore', {
    state: () => {
      const s = { ...rootStateDef };
      Object.entries(moduleDefs).forEach(([name, def]) => {
        s[name] = normalizeState(def.state);
      });
      if (!s.route) {
        s.route = reactive({
          params: {},
          query: {},
          path: '',
          name: '',
          meta: {},
        });
      }
      return s;
    },

    getters: piniaGetters,

    actions: {
      $commit(type, payload) {
        let entry = mutations[type];
        if (!entry) {
          const foundKey = Object.keys(mutations).find(
            k => k === type || k.endsWith(`/${type}`)
          );
          if (foundKey) entry = mutations[foundKey];
        }
        if (!entry) {
          // eslint-disable-next-line no-console
          console.warn(`[store] unknown mutation: ${type}`);
          return;
        }
        const { fn, moduleName } = entry;
        const modState =
          moduleName === '__root__'
            ? this.$state
            : (this.$state[moduleName] ?? this.$state);
        fn(modState, payload);
      },

      $dispatch(type, payload) {
        let entry = actions[type];
        if (!entry) {
          const foundKey = Object.keys(actions).find(
            k => k === type || k.endsWith(`/${type}`)
          );
          if (foundKey) entry = actions[foundKey];
        }
        if (!entry) {
          // eslint-disable-next-line no-console
          console.warn(`[store] unknown action: ${type}`);
          return Promise.resolve();
        }
        const { fn, moduleName } = entry;
        const modState =
          moduleName === '__root__'
            ? this.$state
            : (this.$state[moduleName] ?? this.$state);
        const localGetters = new Proxy(
          {},
          {
            get: (_, g) => {
              if (typeof g !== 'string') return undefined;
              const localKey =
                entry.isNamespaced && moduleName ? `${moduleName}/${g}` : g;
              return this[localKey] ?? this[g];
            },
          }
        );
        const context = {
          state: modState,
          getters: localGetters,
          rootState: this.$state,
          rootGetters: this,
          commit: (localType, localPayload) =>
            this.$commit(localType, localPayload),
          dispatch: (localType, localPayload) =>
            this.$dispatch(localType, localPayload),
        };
        const result = fn(context, payload);
        return result instanceof Promise ? result : Promise.resolve(result);
      },
    },
  });

  let rootStoreInstance = null;
  const pinia = createPinia();
  const getRootStore = () => {
    if (!rootStoreInstance) rootStoreInstance = useRootStore(pinia);
    return rootStoreInstance;
  };

  const store = {
    get state() {
      return getRootStore().$state;
    },

    getters: new Proxy(
      {},
      {
        get: (_target, key) => {
          if (typeof key !== 'string') return undefined;
          const root = getRootStore();
          if (gettersDef[key]) return root[key];
          const found = Object.keys(gettersDef).find(
            k => k === key || k.endsWith(`/${key}`)
          );
          return found ? root[found] : undefined;
        },
        has: (_target, key) => {
          if (typeof key !== 'string') return false;
          return (
            key in gettersDef ||
            Object.keys(gettersDef).some(
              k => k === key || k.endsWith(`/${key}`)
            )
          );
        },
        ownKeys: () => Reflect.ownKeys(gettersDef),
        getOwnPropertyDescriptor: (_target, key) => {
          if (key in gettersDef)
            return { enumerable: true, configurable: true };
          return undefined;
        },
      }
    ),

    commit(type, payload) {
      getRootStore().$commit(type, payload);
    },

    dispatch(type, payload) {
      return getRootStore().$dispatch(type, payload);
    },

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

// Mirrors the router into `store.state.route` so getters that read
// `rootState.route.params` keep working. The route object is replaced on every
// navigation because reference watchers (`$watch('$store.state.route', ...)`)
// rely on that reference change to detect navigation.
export function sync(store, router) {
  if (!store || !router) return () => {};

  const apply = route => {
    const r = route || router.currentRoute?.value || {};
    const nextRoute = reactive({
      params: r.params ? { ...r.params } : {},
      query: r.query ? { ...r.query } : {},
      path: r.path || '',
      name: r.name || '',
      meta: r.meta ? { ...r.meta } : {},
      hash: r.hash || '',
      fullPath: r.fullPath || r.path || '',
    });
    store.state.route = nextRoute;
  };

  try {
    apply(router.currentRoute?.value);
  } catch (_) {} // eslint-disable-line no-empty

  let stop = () => {};
  try {
    if (router.afterEach) {
      const off = router.afterEach((to /* , from */) => apply(to));
      stop = () => off();
    } else if (router.currentRoute) {
      const unwatch = watch(router.currentRoute, apply, {
        immediate: false,
        deep: false,
      });
      stop = () => unwatch();
    }
  } catch (_) {} // eslint-disable-line no-empty

  return stop;
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
