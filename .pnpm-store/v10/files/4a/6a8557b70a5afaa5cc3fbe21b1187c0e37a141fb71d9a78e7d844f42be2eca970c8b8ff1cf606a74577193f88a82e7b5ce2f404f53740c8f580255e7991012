(function (exports, core, vue, shared) {
  'use strict';

  const OnClickOutside = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "OnClickOutside",
    props: ["as", "options"],
    emits: ["trigger"],
    setup(props, { slots, emit }) {
      const target = vue.ref();
      core.onClickOutside(target, (e) => {
        emit("trigger", e);
      }, props.options);
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default());
      };
    }
  });

  const defaultWindow = shared.isClient ? window : void 0;

  function unrefElement(elRef) {
    var _a;
    const plain = shared.toValue(elRef);
    return (_a = plain == null ? void 0 : plain.$el) != null ? _a : plain;
  }

  function useEventListener(...args) {
    let target;
    let events;
    let listeners;
    let options;
    if (typeof args[0] === "string" || Array.isArray(args[0])) {
      [events, listeners, options] = args;
      target = defaultWindow;
    } else {
      [target, events, listeners, options] = args;
    }
    if (!target)
      return shared.noop;
    if (!Array.isArray(events))
      events = [events];
    if (!Array.isArray(listeners))
      listeners = [listeners];
    const cleanups = [];
    const cleanup = () => {
      cleanups.forEach((fn) => fn());
      cleanups.length = 0;
    };
    const register = (el, event, listener, options2) => {
      el.addEventListener(event, listener, options2);
      return () => el.removeEventListener(event, listener, options2);
    };
    const stopWatch = vue.watch(
      () => [unrefElement(target), shared.toValue(options)],
      ([el, options2]) => {
        cleanup();
        if (!el)
          return;
        const optionsClone = shared.isObject(options2) ? { ...options2 } : options2;
        cleanups.push(
          ...events.flatMap((event) => {
            return listeners.map((listener) => register(el, event, listener, optionsClone));
          })
        );
      },
      { immediate: true, flush: "post" }
    );
    const stop = () => {
      stopWatch();
      cleanup();
    };
    shared.tryOnScopeDispose(stop);
    return stop;
  }

  let _iOSWorkaround = false;
  function onClickOutside(target, handler, options = {}) {
    const { window = defaultWindow, ignore = [], capture = true, detectIframe = false } = options;
    if (!window)
      return shared.noop;
    if (shared.isIOS && !_iOSWorkaround) {
      _iOSWorkaround = true;
      Array.from(window.document.body.children).forEach((el) => el.addEventListener("click", shared.noop));
      window.document.documentElement.addEventListener("click", shared.noop);
    }
    let shouldListen = true;
    const shouldIgnore = (event) => {
      return shared.toValue(ignore).some((target2) => {
        if (typeof target2 === "string") {
          return Array.from(window.document.querySelectorAll(target2)).some((el) => el === event.target || event.composedPath().includes(el));
        } else {
          const el = unrefElement(target2);
          return el && (event.target === el || event.composedPath().includes(el));
        }
      });
    };
    function hasMultipleRoots(target2) {
      const vm = shared.toValue(target2);
      return vm && vm.$.subTree.shapeFlag === 16;
    }
    function checkMultipleRoots(target2, event) {
      const vm = shared.toValue(target2);
      const children = vm.$.subTree && vm.$.subTree.children;
      if (children == null || !Array.isArray(children))
        return false;
      return children.some((child) => child.el === event.target || event.composedPath().includes(child.el));
    }
    const listener = (event) => {
      const el = unrefElement(target);
      if (event.target == null)
        return;
      if (!(el instanceof Element) && hasMultipleRoots(target) && checkMultipleRoots(target, event))
        return;
      if (!el || el === event.target || event.composedPath().includes(el))
        return;
      if (event.detail === 0)
        shouldListen = !shouldIgnore(event);
      if (!shouldListen) {
        shouldListen = true;
        return;
      }
      handler(event);
    };
    let isProcessingClick = false;
    const cleanup = [
      useEventListener(window, "click", (event) => {
        if (!isProcessingClick) {
          isProcessingClick = true;
          setTimeout(() => {
            isProcessingClick = false;
          }, 0);
          listener(event);
        }
      }, { passive: true, capture }),
      useEventListener(window, "pointerdown", (e) => {
        const el = unrefElement(target);
        shouldListen = !shouldIgnore(e) && !!(el && !e.composedPath().includes(el));
      }, { passive: true }),
      detectIframe && useEventListener(window, "blur", (event) => {
        setTimeout(() => {
          var _a;
          const el = unrefElement(target);
          if (((_a = window.document.activeElement) == null ? void 0 : _a.tagName) === "IFRAME" && !(el == null ? void 0 : el.contains(window.document.activeElement))) {
            handler(event);
          }
        }, 0);
      })
    ].filter(Boolean);
    const stop = () => cleanup.forEach((fn) => fn());
    return stop;
  }

  const vOnClickOutside = {
    mounted(el, binding) {
      const capture = !binding.modifiers.bubble;
      if (typeof binding.value === "function") {
        el.__onClickOutside_stop = onClickOutside(el, binding.value, { capture });
      } else {
        const [handler, options] = binding.value;
        el.__onClickOutside_stop = onClickOutside(el, handler, Object.assign({ capture }, options));
      }
    },
    unmounted(el) {
      el.__onClickOutside_stop();
    }
  };

  function createKeyPredicate(keyFilter) {
    if (typeof keyFilter === "function")
      return keyFilter;
    else if (typeof keyFilter === "string")
      return (event) => event.key === keyFilter;
    else if (Array.isArray(keyFilter))
      return (event) => keyFilter.includes(event.key);
    return () => true;
  }
  function onKeyStroke(...args) {
    let key;
    let handler;
    let options = {};
    if (args.length === 3) {
      key = args[0];
      handler = args[1];
      options = args[2];
    } else if (args.length === 2) {
      if (typeof args[1] === "object") {
        key = true;
        handler = args[0];
        options = args[1];
      } else {
        key = args[0];
        handler = args[1];
      }
    } else {
      key = true;
      handler = args[0];
    }
    const {
      target = defaultWindow,
      eventName = "keydown",
      passive = false,
      dedupe = false
    } = options;
    const predicate = createKeyPredicate(key);
    const listener = (e) => {
      if (e.repeat && shared.toValue(dedupe))
        return;
      if (predicate(e))
        handler(e);
    };
    return useEventListener(target, eventName, listener, passive);
  }

  const vOnKeyStroke = {
    mounted(el, binding) {
      var _a, _b;
      const keys = (_b = (_a = binding.arg) == null ? void 0 : _a.split(",")) != null ? _b : true;
      if (typeof binding.value === "function") {
        onKeyStroke(keys, binding.value, {
          target: el
        });
      } else {
        const [handler, options] = binding.value;
        onKeyStroke(keys, handler, {
          target: el,
          ...options
        });
      }
    }
  };

  const DEFAULT_DELAY = 500;
  const DEFAULT_THRESHOLD = 10;
  function onLongPress(target, handler, options) {
    var _a, _b;
    const elementRef = vue.computed(() => unrefElement(target));
    let timeout;
    let posStart;
    let startTimestamp;
    let hasLongPressed = false;
    function clear() {
      if (timeout) {
        clearTimeout(timeout);
        timeout = void 0;
      }
      posStart = void 0;
      startTimestamp = void 0;
      hasLongPressed = false;
    }
    function onRelease(ev) {
      var _a2, _b2, _c;
      const [_startTimestamp, _posStart, _hasLongPressed] = [startTimestamp, posStart, hasLongPressed];
      clear();
      if (!(options == null ? void 0 : options.onMouseUp) || !_posStart || !_startTimestamp)
        return;
      if (((_a2 = options == null ? void 0 : options.modifiers) == null ? void 0 : _a2.self) && ev.target !== elementRef.value)
        return;
      if ((_b2 = options == null ? void 0 : options.modifiers) == null ? void 0 : _b2.prevent)
        ev.preventDefault();
      if ((_c = options == null ? void 0 : options.modifiers) == null ? void 0 : _c.stop)
        ev.stopPropagation();
      const dx = ev.x - _posStart.x;
      const dy = ev.y - _posStart.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      options.onMouseUp(ev.timeStamp - _startTimestamp, distance, _hasLongPressed);
    }
    function onDown(ev) {
      var _a2, _b2, _c, _d;
      if (((_a2 = options == null ? void 0 : options.modifiers) == null ? void 0 : _a2.self) && ev.target !== elementRef.value)
        return;
      clear();
      if ((_b2 = options == null ? void 0 : options.modifiers) == null ? void 0 : _b2.prevent)
        ev.preventDefault();
      if ((_c = options == null ? void 0 : options.modifiers) == null ? void 0 : _c.stop)
        ev.stopPropagation();
      posStart = {
        x: ev.x,
        y: ev.y
      };
      startTimestamp = ev.timeStamp;
      timeout = setTimeout(
        () => {
          hasLongPressed = true;
          handler(ev);
        },
        (_d = options == null ? void 0 : options.delay) != null ? _d : DEFAULT_DELAY
      );
    }
    function onMove(ev) {
      var _a2, _b2, _c, _d;
      if (((_a2 = options == null ? void 0 : options.modifiers) == null ? void 0 : _a2.self) && ev.target !== elementRef.value)
        return;
      if (!posStart || (options == null ? void 0 : options.distanceThreshold) === false)
        return;
      if ((_b2 = options == null ? void 0 : options.modifiers) == null ? void 0 : _b2.prevent)
        ev.preventDefault();
      if ((_c = options == null ? void 0 : options.modifiers) == null ? void 0 : _c.stop)
        ev.stopPropagation();
      const dx = ev.x - posStart.x;
      const dy = ev.y - posStart.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      if (distance >= ((_d = options == null ? void 0 : options.distanceThreshold) != null ? _d : DEFAULT_THRESHOLD))
        clear();
    }
    const listenerOptions = {
      capture: (_a = options == null ? void 0 : options.modifiers) == null ? void 0 : _a.capture,
      once: (_b = options == null ? void 0 : options.modifiers) == null ? void 0 : _b.once
    };
    const cleanup = [
      useEventListener(elementRef, "pointerdown", onDown, listenerOptions),
      useEventListener(elementRef, "pointermove", onMove, listenerOptions),
      useEventListener(elementRef, ["pointerup", "pointerleave"], onRelease, listenerOptions)
    ];
    const stop = () => cleanup.forEach((fn) => fn());
    return stop;
  }

  const OnLongPress = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "OnLongPress",
    props: ["as", "options"],
    emits: ["trigger"],
    setup(props, { slots, emit }) {
      const target = vue.ref();
      onLongPress(
        target,
        (e) => {
          emit("trigger", e);
        },
        props.options
      );
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default());
      };
    }
  });

  const vOnLongPress = {
    mounted(el, binding) {
      if (typeof binding.value === "function")
        onLongPress(el, binding.value, { modifiers: binding.modifiers });
      else
        onLongPress(el, ...binding.value);
    }
  };

  const UseActiveElement = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseActiveElement",
    setup(props, { slots }) {
      const data = vue.reactive({
        element: core.useActiveElement()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseBattery = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseBattery",
    setup(props, { slots }) {
      const data = vue.reactive(core.useBattery(props));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseBrowserLocation = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseBrowserLocation",
    setup(props, { slots }) {
      const data = vue.reactive(core.useBrowserLocation());
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseClipboard = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseClipboard",
    props: [
      "source",
      "read",
      "navigator",
      "copiedDuring",
      "legacy"
    ],
    setup(props, { slots }) {
      const data = vue.reactive(core.useClipboard(props));
      return () => {
        var _a;
        return (_a = slots.default) == null ? void 0 : _a.call(slots, data);
      };
    }
  });

  const _global = typeof globalThis !== "undefined" ? globalThis : typeof window !== "undefined" ? window : typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : {};
  const globalKey = "__vueuse_ssr_handlers__";
  const handlers = /* @__PURE__ */ getHandlers();
  function getHandlers() {
    if (!(globalKey in _global))
      _global[globalKey] = _global[globalKey] || {};
    return _global[globalKey];
  }
  function getSSRHandler(key, fallback) {
    return handlers[key] || fallback;
  }

  function useMounted() {
    const isMounted = vue.ref(false);
    const instance = vue.getCurrentInstance();
    if (instance) {
      vue.onMounted(() => {
        isMounted.value = true;
      }, instance);
    }
    return isMounted;
  }

  function useSupported(callback) {
    const isMounted = useMounted();
    return vue.computed(() => {
      isMounted.value;
      return Boolean(callback());
    });
  }

  function useMediaQuery(query, options = {}) {
    const { window = defaultWindow } = options;
    const isSupported = useSupported(() => window && "matchMedia" in window && typeof window.matchMedia === "function");
    let mediaQuery;
    const matches = vue.ref(false);
    const handler = (event) => {
      matches.value = event.matches;
    };
    const cleanup = () => {
      if (!mediaQuery)
        return;
      if ("removeEventListener" in mediaQuery)
        mediaQuery.removeEventListener("change", handler);
      else
        mediaQuery.removeListener(handler);
    };
    const stopWatch = vue.watchEffect(() => {
      if (!isSupported.value)
        return;
      cleanup();
      mediaQuery = window.matchMedia(shared.toValue(query));
      if ("addEventListener" in mediaQuery)
        mediaQuery.addEventListener("change", handler);
      else
        mediaQuery.addListener(handler);
      matches.value = mediaQuery.matches;
    });
    shared.tryOnScopeDispose(() => {
      stopWatch();
      cleanup();
      mediaQuery = void 0;
    });
    return matches;
  }

  function usePreferredDark(options) {
    return useMediaQuery("(prefers-color-scheme: dark)", options);
  }

  function guessSerializerType(rawInit) {
    return rawInit == null ? "any" : rawInit instanceof Set ? "set" : rawInit instanceof Map ? "map" : rawInit instanceof Date ? "date" : typeof rawInit === "boolean" ? "boolean" : typeof rawInit === "string" ? "string" : typeof rawInit === "object" ? "object" : !Number.isNaN(rawInit) ? "number" : "any";
  }

  const StorageSerializers = {
    boolean: {
      read: (v) => v === "true",
      write: (v) => String(v)
    },
    object: {
      read: (v) => JSON.parse(v),
      write: (v) => JSON.stringify(v)
    },
    number: {
      read: (v) => Number.parseFloat(v),
      write: (v) => String(v)
    },
    any: {
      read: (v) => v,
      write: (v) => String(v)
    },
    string: {
      read: (v) => v,
      write: (v) => String(v)
    },
    map: {
      read: (v) => new Map(JSON.parse(v)),
      write: (v) => JSON.stringify(Array.from(v.entries()))
    },
    set: {
      read: (v) => new Set(JSON.parse(v)),
      write: (v) => JSON.stringify(Array.from(v))
    },
    date: {
      read: (v) => new Date(v),
      write: (v) => v.toISOString()
    }
  };
  const customStorageEventName = "vueuse-storage";
  function useStorage(key, defaults, storage, options = {}) {
    var _a;
    const {
      flush = "pre",
      deep = true,
      listenToStorageChanges = true,
      writeDefaults = true,
      mergeDefaults = false,
      shallow,
      window = defaultWindow,
      eventFilter,
      onError = (e) => {
        console.error(e);
      },
      initOnMounted
    } = options;
    const data = (shallow ? vue.shallowRef : vue.ref)(typeof defaults === "function" ? defaults() : defaults);
    if (!storage) {
      try {
        storage = getSSRHandler("getDefaultStorage", () => {
          var _a2;
          return (_a2 = defaultWindow) == null ? void 0 : _a2.localStorage;
        })();
      } catch (e) {
        onError(e);
      }
    }
    if (!storage)
      return data;
    const rawInit = shared.toValue(defaults);
    const type = guessSerializerType(rawInit);
    const serializer = (_a = options.serializer) != null ? _a : StorageSerializers[type];
    const { pause: pauseWatch, resume: resumeWatch } = shared.pausableWatch(
      data,
      () => write(data.value),
      { flush, deep, eventFilter }
    );
    if (window && listenToStorageChanges) {
      shared.tryOnMounted(() => {
        if (storage instanceof Storage)
          useEventListener(window, "storage", update);
        else
          useEventListener(window, customStorageEventName, updateFromCustomEvent);
        if (initOnMounted)
          update();
      });
    }
    if (!initOnMounted)
      update();
    function dispatchWriteEvent(oldValue, newValue) {
      if (window) {
        const payload = {
          key,
          oldValue,
          newValue,
          storageArea: storage
        };
        window.dispatchEvent(storage instanceof Storage ? new StorageEvent("storage", payload) : new CustomEvent(customStorageEventName, {
          detail: payload
        }));
      }
    }
    function write(v) {
      try {
        const oldValue = storage.getItem(key);
        if (v == null) {
          dispatchWriteEvent(oldValue, null);
          storage.removeItem(key);
        } else {
          const serialized = serializer.write(v);
          if (oldValue !== serialized) {
            storage.setItem(key, serialized);
            dispatchWriteEvent(oldValue, serialized);
          }
        }
      } catch (e) {
        onError(e);
      }
    }
    function read(event) {
      const rawValue = event ? event.newValue : storage.getItem(key);
      if (rawValue == null) {
        if (writeDefaults && rawInit != null)
          storage.setItem(key, serializer.write(rawInit));
        return rawInit;
      } else if (!event && mergeDefaults) {
        const value = serializer.read(rawValue);
        if (typeof mergeDefaults === "function")
          return mergeDefaults(value, rawInit);
        else if (type === "object" && !Array.isArray(value))
          return { ...rawInit, ...value };
        return value;
      } else if (typeof rawValue !== "string") {
        return rawValue;
      } else {
        return serializer.read(rawValue);
      }
    }
    function update(event) {
      if (event && event.storageArea !== storage)
        return;
      if (event && event.key == null) {
        data.value = rawInit;
        return;
      }
      if (event && event.key !== key)
        return;
      pauseWatch();
      try {
        if ((event == null ? void 0 : event.newValue) !== serializer.write(data.value))
          data.value = read(event);
      } catch (e) {
        onError(e);
      } finally {
        if (event)
          vue.nextTick(resumeWatch);
        else
          resumeWatch();
      }
    }
    function updateFromCustomEvent(event) {
      update(event.detail);
    }
    return data;
  }

  const CSS_DISABLE_TRANS = "*,*::before,*::after{-webkit-transition:none!important;-moz-transition:none!important;-o-transition:none!important;-ms-transition:none!important;transition:none!important}";
  function useColorMode(options = {}) {
    const {
      selector = "html",
      attribute = "class",
      initialValue = "auto",
      window = defaultWindow,
      storage,
      storageKey = "vueuse-color-scheme",
      listenToStorageChanges = true,
      storageRef,
      emitAuto,
      disableTransition = true
    } = options;
    const modes = {
      auto: "",
      light: "light",
      dark: "dark",
      ...options.modes || {}
    };
    const preferredDark = usePreferredDark({ window });
    const system = vue.computed(() => preferredDark.value ? "dark" : "light");
    const store = storageRef || (storageKey == null ? shared.toRef(initialValue) : useStorage(storageKey, initialValue, storage, { window, listenToStorageChanges }));
    const state = vue.computed(() => store.value === "auto" ? system.value : store.value);
    const updateHTMLAttrs = getSSRHandler(
      "updateHTMLAttrs",
      (selector2, attribute2, value) => {
        const el = typeof selector2 === "string" ? window == null ? void 0 : window.document.querySelector(selector2) : unrefElement(selector2);
        if (!el)
          return;
        const classesToAdd = /* @__PURE__ */ new Set();
        const classesToRemove = /* @__PURE__ */ new Set();
        let attributeToChange = null;
        if (attribute2 === "class") {
          const current = value.split(/\s/g);
          Object.values(modes).flatMap((i) => (i || "").split(/\s/g)).filter(Boolean).forEach((v) => {
            if (current.includes(v))
              classesToAdd.add(v);
            else
              classesToRemove.add(v);
          });
        } else {
          attributeToChange = { key: attribute2, value };
        }
        if (classesToAdd.size === 0 && classesToRemove.size === 0 && attributeToChange === null)
          return;
        let style;
        if (disableTransition) {
          style = window.document.createElement("style");
          style.appendChild(document.createTextNode(CSS_DISABLE_TRANS));
          window.document.head.appendChild(style);
        }
        for (const c of classesToAdd) {
          el.classList.add(c);
        }
        for (const c of classesToRemove) {
          el.classList.remove(c);
        }
        if (attributeToChange) {
          el.setAttribute(attributeToChange.key, attributeToChange.value);
        }
        if (disableTransition) {
          window.getComputedStyle(style).opacity;
          document.head.removeChild(style);
        }
      }
    );
    function defaultOnChanged(mode) {
      var _a;
      updateHTMLAttrs(selector, attribute, (_a = modes[mode]) != null ? _a : mode);
    }
    function onChanged(mode) {
      if (options.onChanged)
        options.onChanged(mode, defaultOnChanged);
      else
        defaultOnChanged(mode);
    }
    vue.watch(state, onChanged, { flush: "post", immediate: true });
    shared.tryOnMounted(() => onChanged(state.value));
    const auto = vue.computed({
      get() {
        return emitAuto ? store.value : state.value;
      },
      set(v) {
        store.value = v;
      }
    });
    return Object.assign(auto, { store, system, state });
  }

  const UseColorMode = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseColorMode",
    props: ["selector", "attribute", "modes", "onChanged", "storageKey", "storage", "emitAuto"],
    setup(props, { slots }) {
      const mode = useColorMode(props);
      const data = vue.reactive({
        mode,
        system: mode.system,
        store: mode.store
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDark = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDark",
    props: ["selector", "attribute", "valueDark", "valueLight", "onChanged", "storageKey", "storage"],
    setup(props, { slots }) {
      const isDark = core.useDark(props);
      const data = vue.reactive({
        isDark,
        toggleDark: shared.useToggle(isDark)
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDeviceMotion = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDeviceMotion",
    setup(props, { slots }) {
      const data = vue.reactive(core.useDeviceMotion());
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDeviceOrientation = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDeviceOrientation",
    setup(props, { slots }) {
      const data = vue.reactive(core.useDeviceOrientation());
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDevicePixelRatio = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDevicePixelRatio",
    setup(props, { slots }) {
      const data = vue.reactive({
        pixelRatio: core.useDevicePixelRatio()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDevicesList = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDevicesList",
    props: ["onUpdated", "requestPermissions", "constraints"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useDevicesList(props));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDocumentVisibility = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDocumentVisibility",
    setup(props, { slots }) {
      const data = vue.reactive({
        visibility: core.useDocumentVisibility()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseDraggable = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseDraggable",
    props: [
      "storageKey",
      "storageType",
      "initialValue",
      "exact",
      "preventDefault",
      "stopPropagation",
      "pointerTypes",
      "as",
      "handle",
      "axis",
      "onStart",
      "onMove",
      "onEnd",
      "disabled",
      "buttons",
      "containerElement"
    ],
    setup(props, { slots }) {
      const target = vue.ref();
      const handle = vue.computed(() => {
        var _a;
        return (_a = props.handle) != null ? _a : target.value;
      });
      const containerElement = vue.computed(() => {
        var _a;
        return (_a = props.containerElement) != null ? _a : void 0;
      });
      const disabled = vue.computed(() => !!props.disabled);
      const storageValue = props.storageKey && core.useStorage(
        props.storageKey,
        shared.toValue(props.initialValue) || { x: 0, y: 0 },
        core.isClient ? props.storageType === "session" ? sessionStorage : localStorage : void 0
      );
      const initialValue = storageValue || props.initialValue || { x: 0, y: 0 };
      const onEnd = (position, event) => {
        var _a;
        (_a = props.onEnd) == null ? void 0 : _a.call(props, position, event);
        if (!storageValue)
          return;
        storageValue.value.x = position.x;
        storageValue.value.y = position.y;
      };
      const data = vue.reactive(core.useDraggable(target, {
        ...props,
        handle,
        initialValue,
        onEnd,
        disabled,
        containerElement
      }));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target, style: `touch-action:none;${data.style}` }, slots.default(data));
      };
    }
  });

  const UseElementBounding = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseElementBounding",
    props: ["box", "as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive(core.useElementBounding(target));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  function useElementHover(el, options = {}) {
    const {
      delayEnter = 0,
      delayLeave = 0,
      window = defaultWindow
    } = options;
    const isHovered = vue.ref(false);
    let timer;
    const toggle = (entering) => {
      const delay = entering ? delayEnter : delayLeave;
      if (timer) {
        clearTimeout(timer);
        timer = void 0;
      }
      if (delay)
        timer = setTimeout(() => isHovered.value = entering, delay);
      else
        isHovered.value = entering;
    };
    if (!window)
      return isHovered;
    useEventListener(el, "mouseenter", () => toggle(true), { passive: true });
    useEventListener(el, "mouseleave", () => toggle(false), { passive: true });
    return isHovered;
  }

  const vElementHover = {
    mounted(el, binding) {
      const value = binding.value;
      if (typeof value === "function") {
        const isHovered = useElementHover(el);
        vue.watch(isHovered, (v) => value(v));
      } else {
        const [handler, options] = value;
        const isHovered = useElementHover(el, options);
        vue.watch(isHovered, (v) => handler(v));
      }
    }
  };

  const UseElementSize = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseElementSize",
    props: ["width", "height", "box", "as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive(core.useElementSize(target, { width: props.width, height: props.height }, { box: props.box }));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  function useResizeObserver(target, callback, options = {}) {
    const { window = defaultWindow, ...observerOptions } = options;
    let observer;
    const isSupported = useSupported(() => window && "ResizeObserver" in window);
    const cleanup = () => {
      if (observer) {
        observer.disconnect();
        observer = void 0;
      }
    };
    const targets = vue.computed(() => {
      const _targets = shared.toValue(target);
      return Array.isArray(_targets) ? _targets.map((el) => unrefElement(el)) : [unrefElement(_targets)];
    });
    const stopWatch = vue.watch(
      targets,
      (els) => {
        cleanup();
        if (isSupported.value && window) {
          observer = new ResizeObserver(callback);
          for (const _el of els) {
            if (_el)
              observer.observe(_el, observerOptions);
          }
        }
      },
      { immediate: true, flush: "post" }
    );
    const stop = () => {
      cleanup();
      stopWatch();
    };
    shared.tryOnScopeDispose(stop);
    return {
      isSupported,
      stop
    };
  }

  function useElementSize(target, initialSize = { width: 0, height: 0 }, options = {}) {
    const { window = defaultWindow, box = "content-box" } = options;
    const isSVG = vue.computed(() => {
      var _a, _b;
      return (_b = (_a = unrefElement(target)) == null ? void 0 : _a.namespaceURI) == null ? void 0 : _b.includes("svg");
    });
    const width = vue.ref(initialSize.width);
    const height = vue.ref(initialSize.height);
    const { stop: stop1 } = useResizeObserver(
      target,
      ([entry]) => {
        const boxSize = box === "border-box" ? entry.borderBoxSize : box === "content-box" ? entry.contentBoxSize : entry.devicePixelContentBoxSize;
        if (window && isSVG.value) {
          const $elem = unrefElement(target);
          if ($elem) {
            const rect = $elem.getBoundingClientRect();
            width.value = rect.width;
            height.value = rect.height;
          }
        } else {
          if (boxSize) {
            const formatBoxSize = Array.isArray(boxSize) ? boxSize : [boxSize];
            width.value = formatBoxSize.reduce((acc, { inlineSize }) => acc + inlineSize, 0);
            height.value = formatBoxSize.reduce((acc, { blockSize }) => acc + blockSize, 0);
          } else {
            width.value = entry.contentRect.width;
            height.value = entry.contentRect.height;
          }
        }
      },
      options
    );
    shared.tryOnMounted(() => {
      const ele = unrefElement(target);
      if (ele) {
        width.value = "offsetWidth" in ele ? ele.offsetWidth : initialSize.width;
        height.value = "offsetHeight" in ele ? ele.offsetHeight : initialSize.height;
      }
    });
    const stop2 = vue.watch(
      () => unrefElement(target),
      (ele) => {
        width.value = ele ? initialSize.width : 0;
        height.value = ele ? initialSize.height : 0;
      }
    );
    function stop() {
      stop1();
      stop2();
    }
    return {
      width,
      height,
      stop
    };
  }

  const vElementSize = {
    mounted(el, binding) {
      var _a;
      const handler = typeof binding.value === "function" ? binding.value : (_a = binding.value) == null ? void 0 : _a[0];
      const options = typeof binding.value === "function" ? [] : binding.value.slice(1);
      const { width, height } = useElementSize(el, ...options);
      vue.watch([width, height], ([width2, height2]) => handler({ width: width2, height: height2 }));
    }
  };

  const UseElementVisibility = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseElementVisibility",
    props: ["as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive({
        isVisible: core.useElementVisibility(target)
      });
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  function useIntersectionObserver(target, callback, options = {}) {
    const {
      root,
      rootMargin = "0px",
      threshold = 0,
      window = defaultWindow,
      immediate = true
    } = options;
    const isSupported = useSupported(() => window && "IntersectionObserver" in window);
    const targets = vue.computed(() => {
      const _target = shared.toValue(target);
      return (Array.isArray(_target) ? _target : [_target]).map(unrefElement).filter(shared.notNullish);
    });
    let cleanup = shared.noop;
    const isActive = vue.ref(immediate);
    const stopWatch = isSupported.value ? vue.watch(
      () => [targets.value, unrefElement(root), isActive.value],
      ([targets2, root2]) => {
        cleanup();
        if (!isActive.value)
          return;
        if (!targets2.length)
          return;
        const observer = new IntersectionObserver(
          callback,
          {
            root: unrefElement(root2),
            rootMargin,
            threshold
          }
        );
        targets2.forEach((el) => el && observer.observe(el));
        cleanup = () => {
          observer.disconnect();
          cleanup = shared.noop;
        };
      },
      { immediate, flush: "post" }
    ) : shared.noop;
    const stop = () => {
      cleanup();
      stopWatch();
      isActive.value = false;
    };
    shared.tryOnScopeDispose(stop);
    return {
      isSupported,
      isActive,
      pause() {
        cleanup();
        isActive.value = false;
      },
      resume() {
        isActive.value = true;
      },
      stop
    };
  }

  function useElementVisibility(element, options = {}) {
    const { window = defaultWindow, scrollTarget, threshold = 0 } = options;
    const elementIsVisible = vue.ref(false);
    useIntersectionObserver(
      element,
      (intersectionObserverEntries) => {
        let isIntersecting = elementIsVisible.value;
        let latestTime = 0;
        for (const entry of intersectionObserverEntries) {
          if (entry.time >= latestTime) {
            latestTime = entry.time;
            isIntersecting = entry.isIntersecting;
          }
        }
        elementIsVisible.value = isIntersecting;
      },
      {
        root: scrollTarget,
        window,
        threshold
      }
    );
    return elementIsVisible;
  }

  const vElementVisibility = {
    mounted(el, binding) {
      if (typeof binding.value === "function") {
        const handler = binding.value;
        const isVisible = useElementVisibility(el);
        vue.watch(isVisible, (v) => handler(v), { immediate: true });
      } else {
        const [handler, options] = binding.value;
        const isVisible = useElementVisibility(el, options);
        vue.watch(isVisible, (v) => handler(v), { immediate: true });
      }
    }
  };

  const UseEyeDropper = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseEyeDropper",
    props: {
      sRGBHex: String
    },
    setup(props, { slots }) {
      const data = vue.reactive(core.useEyeDropper());
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseFullscreen = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseFullscreen",
    props: ["as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive(core.useFullscreen(target));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  const UseGeolocation = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseGeolocation",
    props: ["enableHighAccuracy", "maximumAge", "timeout", "navigator"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useGeolocation(props));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseIdle = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseIdle",
    props: ["timeout", "events", "listenForVisibilityChange", "initialState"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useIdle(props.timeout, props));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  function useAsyncState(promise, initialState, options) {
    const {
      immediate = true,
      delay = 0,
      onError = shared.noop,
      onSuccess = shared.noop,
      resetOnExecute = true,
      shallow = true,
      throwError
    } = options != null ? options : {};
    const state = shallow ? vue.shallowRef(initialState) : vue.ref(initialState);
    const isReady = vue.ref(false);
    const isLoading = vue.ref(false);
    const error = vue.shallowRef(void 0);
    async function execute(delay2 = 0, ...args) {
      if (resetOnExecute)
        state.value = initialState;
      error.value = void 0;
      isReady.value = false;
      isLoading.value = true;
      if (delay2 > 0)
        await shared.promiseTimeout(delay2);
      const _promise = typeof promise === "function" ? promise(...args) : promise;
      try {
        const data = await _promise;
        state.value = data;
        isReady.value = true;
        onSuccess(data);
      } catch (e) {
        error.value = e;
        onError(e);
        if (throwError)
          throw e;
      } finally {
        isLoading.value = false;
      }
      return state.value;
    }
    if (immediate)
      execute(delay);
    const shell = {
      state,
      isReady,
      isLoading,
      error,
      execute
    };
    function waitUntilIsLoaded() {
      return new Promise((resolve, reject) => {
        shared.until(isLoading).toBe(false).then(() => resolve(shell)).catch(reject);
      });
    }
    return {
      ...shell,
      then(onFulfilled, onRejected) {
        return waitUntilIsLoaded().then(onFulfilled, onRejected);
      }
    };
  }

  async function loadImage(options) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      const { src, srcset, sizes, class: clazz, loading, crossorigin, referrerPolicy } = options;
      img.src = src;
      if (srcset)
        img.srcset = srcset;
      if (sizes)
        img.sizes = sizes;
      if (clazz)
        img.className = clazz;
      if (loading)
        img.loading = loading;
      if (crossorigin)
        img.crossOrigin = crossorigin;
      if (referrerPolicy)
        img.referrerPolicy = referrerPolicy;
      img.onload = () => resolve(img);
      img.onerror = reject;
    });
  }
  function useImage(options, asyncStateOptions = {}) {
    const state = useAsyncState(
      () => loadImage(shared.toValue(options)),
      void 0,
      {
        resetOnExecute: true,
        ...asyncStateOptions
      }
    );
    vue.watch(
      () => shared.toValue(options),
      () => state.execute(asyncStateOptions.delay),
      { deep: true }
    );
    return state;
  }

  const UseImage = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseImage",
    props: [
      "src",
      "srcset",
      "sizes",
      "as",
      "alt",
      "class",
      "loading",
      "crossorigin",
      "referrerPolicy"
    ],
    setup(props, { slots }) {
      const data = vue.reactive(useImage(props));
      return () => {
        if (data.isLoading && slots.loading)
          return slots.loading(data);
        else if (data.error && slots.error)
          return slots.error(data.error);
        if (slots.default)
          return slots.default(data);
        return vue.h(props.as || "img", props);
      };
    }
  });

  function resolveElement(el) {
    if (typeof Window !== "undefined" && el instanceof Window)
      return el.document.documentElement;
    if (typeof Document !== "undefined" && el instanceof Document)
      return el.documentElement;
    return el;
  }

  const ARRIVED_STATE_THRESHOLD_PIXELS = 1;
  function useScroll(element, options = {}) {
    const {
      throttle = 0,
      idle = 200,
      onStop = shared.noop,
      onScroll = shared.noop,
      offset = {
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      },
      eventListenerOptions = {
        capture: false,
        passive: true
      },
      behavior = "auto",
      window = defaultWindow,
      onError = (e) => {
        console.error(e);
      }
    } = options;
    const internalX = vue.ref(0);
    const internalY = vue.ref(0);
    const x = vue.computed({
      get() {
        return internalX.value;
      },
      set(x2) {
        scrollTo(x2, void 0);
      }
    });
    const y = vue.computed({
      get() {
        return internalY.value;
      },
      set(y2) {
        scrollTo(void 0, y2);
      }
    });
    function scrollTo(_x, _y) {
      var _a, _b, _c, _d;
      if (!window)
        return;
      const _element = shared.toValue(element);
      if (!_element)
        return;
      (_c = _element instanceof Document ? window.document.body : _element) == null ? void 0 : _c.scrollTo({
        top: (_a = shared.toValue(_y)) != null ? _a : y.value,
        left: (_b = shared.toValue(_x)) != null ? _b : x.value,
        behavior: shared.toValue(behavior)
      });
      const scrollContainer = ((_d = _element == null ? void 0 : _element.document) == null ? void 0 : _d.documentElement) || (_element == null ? void 0 : _element.documentElement) || _element;
      if (x != null)
        internalX.value = scrollContainer.scrollLeft;
      if (y != null)
        internalY.value = scrollContainer.scrollTop;
    }
    const isScrolling = vue.ref(false);
    const arrivedState = vue.reactive({
      left: true,
      right: false,
      top: true,
      bottom: false
    });
    const directions = vue.reactive({
      left: false,
      right: false,
      top: false,
      bottom: false
    });
    const onScrollEnd = (e) => {
      if (!isScrolling.value)
        return;
      isScrolling.value = false;
      directions.left = false;
      directions.right = false;
      directions.top = false;
      directions.bottom = false;
      onStop(e);
    };
    const onScrollEndDebounced = shared.useDebounceFn(onScrollEnd, throttle + idle);
    const setArrivedState = (target) => {
      var _a;
      if (!window)
        return;
      const el = ((_a = target == null ? void 0 : target.document) == null ? void 0 : _a.documentElement) || (target == null ? void 0 : target.documentElement) || unrefElement(target);
      const { display, flexDirection } = getComputedStyle(el);
      const scrollLeft = el.scrollLeft;
      directions.left = scrollLeft < internalX.value;
      directions.right = scrollLeft > internalX.value;
      const left = Math.abs(scrollLeft) <= (offset.left || 0);
      const right = Math.abs(scrollLeft) + el.clientWidth >= el.scrollWidth - (offset.right || 0) - ARRIVED_STATE_THRESHOLD_PIXELS;
      if (display === "flex" && flexDirection === "row-reverse") {
        arrivedState.left = right;
        arrivedState.right = left;
      } else {
        arrivedState.left = left;
        arrivedState.right = right;
      }
      internalX.value = scrollLeft;
      let scrollTop = el.scrollTop;
      if (target === window.document && !scrollTop)
        scrollTop = window.document.body.scrollTop;
      directions.top = scrollTop < internalY.value;
      directions.bottom = scrollTop > internalY.value;
      const top = Math.abs(scrollTop) <= (offset.top || 0);
      const bottom = Math.abs(scrollTop) + el.clientHeight >= el.scrollHeight - (offset.bottom || 0) - ARRIVED_STATE_THRESHOLD_PIXELS;
      if (display === "flex" && flexDirection === "column-reverse") {
        arrivedState.top = bottom;
        arrivedState.bottom = top;
      } else {
        arrivedState.top = top;
        arrivedState.bottom = bottom;
      }
      internalY.value = scrollTop;
    };
    const onScrollHandler = (e) => {
      var _a;
      if (!window)
        return;
      const eventTarget = (_a = e.target.documentElement) != null ? _a : e.target;
      setArrivedState(eventTarget);
      isScrolling.value = true;
      onScrollEndDebounced(e);
      onScroll(e);
    };
    useEventListener(
      element,
      "scroll",
      throttle ? shared.useThrottleFn(onScrollHandler, throttle, true, false) : onScrollHandler,
      eventListenerOptions
    );
    shared.tryOnMounted(() => {
      try {
        const _element = shared.toValue(element);
        if (!_element)
          return;
        setArrivedState(_element);
      } catch (e) {
        onError(e);
      }
    });
    useEventListener(
      element,
      "scrollend",
      onScrollEnd,
      eventListenerOptions
    );
    return {
      x,
      y,
      isScrolling,
      arrivedState,
      directions,
      measure() {
        const _element = shared.toValue(element);
        if (window && _element)
          setArrivedState(_element);
      }
    };
  }

  function useInfiniteScroll(element, onLoadMore, options = {}) {
    var _a;
    const {
      direction = "bottom",
      interval = 100,
      canLoadMore = () => true
    } = options;
    const state = vue.reactive(useScroll(
      element,
      {
        ...options,
        offset: {
          [direction]: (_a = options.distance) != null ? _a : 0,
          ...options.offset
        }
      }
    ));
    const promise = vue.ref();
    const isLoading = vue.computed(() => !!promise.value);
    const observedElement = vue.computed(() => {
      return resolveElement(shared.toValue(element));
    });
    const isElementVisible = useElementVisibility(observedElement);
    function checkAndLoad() {
      state.measure();
      if (!observedElement.value || !isElementVisible.value || !canLoadMore(observedElement.value))
        return;
      const { scrollHeight, clientHeight, scrollWidth, clientWidth } = observedElement.value;
      const isNarrower = direction === "bottom" || direction === "top" ? scrollHeight <= clientHeight : scrollWidth <= clientWidth;
      if (state.arrivedState[direction] || isNarrower) {
        if (!promise.value) {
          promise.value = Promise.all([
            onLoadMore(state),
            new Promise((resolve) => setTimeout(resolve, interval))
          ]).finally(() => {
            promise.value = null;
            vue.nextTick(() => checkAndLoad());
          });
        }
      }
    }
    const stop = vue.watch(
      () => [state.arrivedState[direction], isElementVisible.value],
      checkAndLoad,
      { immediate: true }
    );
    shared.tryOnUnmounted(stop);
    return {
      isLoading,
      reset() {
        vue.nextTick(() => checkAndLoad());
      }
    };
  }

  const vInfiniteScroll = {
    mounted(el, binding) {
      if (typeof binding.value === "function")
        useInfiniteScroll(el, binding.value);
      else
        useInfiniteScroll(el, ...binding.value);
    }
  };

  const vIntersectionObserver = {
    mounted(el, binding) {
      if (typeof binding.value === "function")
        useIntersectionObserver(el, binding.value);
      else
        useIntersectionObserver(el, ...binding.value);
    }
  };

  const UseMouse = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseMouse",
    props: ["touch", "resetOnTouchEnds", "initialValue"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useMouse(props));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseMouseInElement = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseMouseElement",
    props: ["handleOutside", "as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive(core.useMouseInElement(target, props));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  const UseMousePressed = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseMousePressed",
    props: ["touch", "initialValue", "as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive(core.useMousePressed({ ...props, target }));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  const UseNetwork = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseNetwork",
    setup(props, { slots }) {
      const data = vue.reactive(core.useNetwork());
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseNow = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseNow",
    props: ["interval"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useNow({ ...props, controls: true }));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseObjectUrl = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseObjectUrl",
    props: [
      "object"
    ],
    setup(props, { slots }) {
      const object = shared.toRef(props, "object");
      const url = core.useObjectUrl(object);
      return () => {
        if (slots.default && url.value)
          return slots.default(url);
      };
    }
  });

  const UseOffsetPagination = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseOffsetPagination",
    props: [
      "total",
      "page",
      "pageSize",
      "onPageChange",
      "onPageSizeChange",
      "onPageCountChange"
    ],
    emits: [
      "page-change",
      "page-size-change",
      "page-count-change"
    ],
    setup(props, { slots, emit }) {
      const data = vue.reactive(core.useOffsetPagination({
        ...props,
        onPageChange(...args) {
          var _a;
          (_a = props.onPageChange) == null ? void 0 : _a.call(props, ...args);
          emit("page-change", ...args);
        },
        onPageSizeChange(...args) {
          var _a;
          (_a = props.onPageSizeChange) == null ? void 0 : _a.call(props, ...args);
          emit("page-size-change", ...args);
        },
        onPageCountChange(...args) {
          var _a;
          (_a = props.onPageCountChange) == null ? void 0 : _a.call(props, ...args);
          emit("page-count-change", ...args);
        }
      }));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseOnline = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseOnline",
    setup(props, { slots }) {
      const data = vue.reactive({
        isOnline: core.useOnline()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UsePageLeave = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePageLeave",
    setup(props, { slots }) {
      const data = vue.reactive({
        isLeft: core.usePageLeave()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UsePointer = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePointer",
    props: [
      "pointerTypes",
      "initialValue",
      "target"
    ],
    setup(props, { slots }) {
      const el = vue.ref(null);
      const data = vue.reactive(core.usePointer({
        ...props,
        target: props.target === "self" ? el : defaultWindow
      }));
      return () => {
        if (slots.default)
          return slots.default(data, { ref: el });
      };
    }
  });

  const UsePointerLock = /* #__PURE__ */ vue.defineComponent({
    name: "UsePointerLock",
    props: ["as"],
    setup(props, { slots }) {
      const target = vue.ref();
      const data = vue.reactive(core.usePointerLock(target));
      return () => {
        if (slots.default)
          return vue.h(props.as || "div", { ref: target }, slots.default(data));
      };
    }
  });

  const UsePreferredColorScheme = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePreferredColorScheme",
    setup(props, { slots }) {
      const data = vue.reactive({
        colorScheme: core.usePreferredColorScheme()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UsePreferredContrast = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePreferredContrast",
    setup(props, { slots }) {
      const data = vue.reactive({
        contrast: core.usePreferredContrast()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UsePreferredDark = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePreferredDark",
    setup(props, { slots }) {
      const data = vue.reactive({
        prefersDark: core.usePreferredDark()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UsePreferredLanguages = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePreferredLanguages",
    setup(props, { slots }) {
      const data = vue.reactive({
        languages: core.usePreferredLanguages()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UsePreferredReducedMotion = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UsePreferredReducedMotion",
    setup(props, { slots }) {
      const data = vue.reactive({
        motion: core.usePreferredReducedMotion()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const vResizeObserver = {
    mounted(el, binding) {
      if (typeof binding.value === "function")
        useResizeObserver(el, binding.value);
      else
        useResizeObserver(el, ...binding.value);
    }
  };

  function useMutationObserver(target, callback, options = {}) {
    const { window = defaultWindow, ...mutationOptions } = options;
    let observer;
    const isSupported = useSupported(() => window && "MutationObserver" in window);
    const cleanup = () => {
      if (observer) {
        observer.disconnect();
        observer = void 0;
      }
    };
    const targets = vue.computed(() => {
      const value = shared.toValue(target);
      const items = (Array.isArray(value) ? value : [value]).map(unrefElement).filter(shared.notNullish);
      return new Set(items);
    });
    const stopWatch = vue.watch(
      () => targets.value,
      (targets2) => {
        cleanup();
        if (isSupported.value && targets2.size) {
          observer = new MutationObserver(callback);
          targets2.forEach((el) => observer.observe(el, mutationOptions));
        }
      },
      { immediate: true, flush: "post" }
    );
    const takeRecords = () => {
      return observer == null ? void 0 : observer.takeRecords();
    };
    const stop = () => {
      stopWatch();
      cleanup();
    };
    shared.tryOnScopeDispose(stop);
    return {
      isSupported,
      stop,
      takeRecords
    };
  }

  function useCssVar(prop, target, options = {}) {
    const { window = defaultWindow, initialValue, observe = false } = options;
    const variable = vue.ref(initialValue);
    const elRef = vue.computed(() => {
      var _a;
      return unrefElement(target) || ((_a = window == null ? void 0 : window.document) == null ? void 0 : _a.documentElement);
    });
    function updateCssVar() {
      var _a;
      const key = shared.toValue(prop);
      const el = shared.toValue(elRef);
      if (el && window && key) {
        const value = (_a = window.getComputedStyle(el).getPropertyValue(key)) == null ? void 0 : _a.trim();
        variable.value = value || initialValue;
      }
    }
    if (observe) {
      useMutationObserver(elRef, updateCssVar, {
        attributeFilter: ["style", "class"],
        window
      });
    }
    vue.watch(
      [elRef, () => shared.toValue(prop)],
      (_, old) => {
        if (old[0] && old[1])
          old[0].style.removeProperty(old[1]);
        updateCssVar();
      },
      { immediate: true }
    );
    vue.watch(
      variable,
      (val) => {
        var _a;
        const raw_prop = shared.toValue(prop);
        if (((_a = elRef.value) == null ? void 0 : _a.style) && raw_prop) {
          if (val == null)
            elRef.value.style.removeProperty(raw_prop);
          else
            elRef.value.style.setProperty(raw_prop, val);
        }
      }
    );
    return variable;
  }

  const topVarName = "--vueuse-safe-area-top";
  const rightVarName = "--vueuse-safe-area-right";
  const bottomVarName = "--vueuse-safe-area-bottom";
  const leftVarName = "--vueuse-safe-area-left";
  function useScreenSafeArea() {
    const top = vue.ref("");
    const right = vue.ref("");
    const bottom = vue.ref("");
    const left = vue.ref("");
    if (shared.isClient) {
      const topCssVar = useCssVar(topVarName);
      const rightCssVar = useCssVar(rightVarName);
      const bottomCssVar = useCssVar(bottomVarName);
      const leftCssVar = useCssVar(leftVarName);
      topCssVar.value = "env(safe-area-inset-top, 0px)";
      rightCssVar.value = "env(safe-area-inset-right, 0px)";
      bottomCssVar.value = "env(safe-area-inset-bottom, 0px)";
      leftCssVar.value = "env(safe-area-inset-left, 0px)";
      update();
      useEventListener("resize", shared.useDebounceFn(update));
    }
    function update() {
      top.value = getValue(topVarName);
      right.value = getValue(rightVarName);
      bottom.value = getValue(bottomVarName);
      left.value = getValue(leftVarName);
    }
    return {
      top,
      right,
      bottom,
      left,
      update
    };
  }
  function getValue(position) {
    return getComputedStyle(document.documentElement).getPropertyValue(position);
  }

  const UseScreenSafeArea = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseScreenSafeArea",
    props: {
      top: Boolean,
      right: Boolean,
      bottom: Boolean,
      left: Boolean
    },
    setup(props, { slots }) {
      const {
        top,
        right,
        bottom,
        left
      } = useScreenSafeArea();
      return () => {
        if (slots.default) {
          return vue.h("div", {
            style: {
              paddingTop: props.top ? top.value : "",
              paddingRight: props.right ? right.value : "",
              paddingBottom: props.bottom ? bottom.value : "",
              paddingLeft: props.left ? left.value : "",
              boxSizing: "border-box",
              maxHeight: "100vh",
              maxWidth: "100vw",
              overflow: "auto"
            }
          }, slots.default());
        }
      };
    }
  });

  const vScroll = {
    mounted(el, binding) {
      if (typeof binding.value === "function") {
        const handler = binding.value;
        const state = useScroll(el, {
          onScroll() {
            handler(state);
          },
          onStop() {
            handler(state);
          }
        });
      } else {
        const [handler, options] = binding.value;
        const state = useScroll(el, {
          ...options,
          onScroll(e) {
            var _a;
            (_a = options.onScroll) == null ? void 0 : _a.call(options, e);
            handler(state);
          },
          onStop(e) {
            var _a;
            (_a = options.onStop) == null ? void 0 : _a.call(options, e);
            handler(state);
          }
        });
      }
    }
  };

  function checkOverflowScroll(ele) {
    const style = window.getComputedStyle(ele);
    if (style.overflowX === "scroll" || style.overflowY === "scroll" || style.overflowX === "auto" && ele.clientWidth < ele.scrollWidth || style.overflowY === "auto" && ele.clientHeight < ele.scrollHeight) {
      return true;
    } else {
      const parent = ele.parentNode;
      if (!parent || parent.tagName === "BODY")
        return false;
      return checkOverflowScroll(parent);
    }
  }
  function preventDefault(rawEvent) {
    const e = rawEvent || window.event;
    const _target = e.target;
    if (checkOverflowScroll(_target))
      return false;
    if (e.touches.length > 1)
      return true;
    if (e.preventDefault)
      e.preventDefault();
    return false;
  }
  const elInitialOverflow = /* @__PURE__ */ new WeakMap();
  function useScrollLock(element, initialState = false) {
    const isLocked = vue.ref(initialState);
    let stopTouchMoveListener = null;
    let initialOverflow = "";
    vue.watch(shared.toRef(element), (el) => {
      const target = resolveElement(shared.toValue(el));
      if (target) {
        const ele = target;
        if (!elInitialOverflow.get(ele))
          elInitialOverflow.set(ele, ele.style.overflow);
        if (ele.style.overflow !== "hidden")
          initialOverflow = ele.style.overflow;
        if (ele.style.overflow === "hidden")
          return isLocked.value = true;
        if (isLocked.value)
          return ele.style.overflow = "hidden";
      }
    }, {
      immediate: true
    });
    const lock = () => {
      const el = resolveElement(shared.toValue(element));
      if (!el || isLocked.value)
        return;
      if (shared.isIOS) {
        stopTouchMoveListener = useEventListener(
          el,
          "touchmove",
          (e) => {
            preventDefault(e);
          },
          { passive: false }
        );
      }
      el.style.overflow = "hidden";
      isLocked.value = true;
    };
    const unlock = () => {
      const el = resolveElement(shared.toValue(element));
      if (!el || !isLocked.value)
        return;
      if (shared.isIOS)
        stopTouchMoveListener == null ? void 0 : stopTouchMoveListener();
      el.style.overflow = initialOverflow;
      elInitialOverflow.delete(el);
      isLocked.value = false;
    };
    shared.tryOnScopeDispose(unlock);
    return vue.computed({
      get() {
        return isLocked.value;
      },
      set(v) {
        if (v)
          lock();
        else unlock();
      }
    });
  }

  function onScrollLock() {
    let isMounted = false;
    const state = vue.ref(false);
    return (el, binding) => {
      state.value = binding.value;
      if (isMounted)
        return;
      isMounted = true;
      const isLocked = useScrollLock(el, binding.value);
      vue.watch(state, (v) => isLocked.value = v);
    };
  }
  const vScrollLock = onScrollLock();

  const UseTimeAgo = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseTimeAgo",
    props: ["time", "updateInterval", "max", "fullDateFormatter", "messages", "showSecond"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useTimeAgo(() => props.time, { ...props, controls: true }));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseTimestamp = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseTimestamp",
    props: ["immediate", "interval", "offset"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useTimestamp({ ...props, controls: true }));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseVirtualList = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseVirtualList",
    props: [
      "list",
      "options",
      "height"
    ],
    setup(props, { slots, expose }) {
      const { list: listRef } = vue.toRefs(props);
      const { list, containerProps, wrapperProps, scrollTo } = core.useVirtualList(listRef, props.options);
      expose({ scrollTo });
      if (containerProps.style && typeof containerProps.style === "object" && !Array.isArray(containerProps.style))
        containerProps.style.height = props.height || "300px";
      return () => vue.h("div", { ...containerProps }, [
        vue.h("div", { ...wrapperProps.value }, list.value.map((item) => vue.h("div", { style: { overflow: "hidden", height: item.height } }, slots.default ? slots.default(item) : "Please set content!")))
      ]);
    }
  });

  const UseWindowFocus = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseWindowFocus",
    setup(props, { slots }) {
      const data = vue.reactive({
        focused: core.useWindowFocus()
      });
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  const UseWindowSize = /* @__PURE__ */ /* #__PURE__ */ vue.defineComponent({
    name: "UseWindowSize",
    props: ["initialWidth", "initialHeight"],
    setup(props, { slots }) {
      const data = vue.reactive(core.useWindowSize(props));
      return () => {
        if (slots.default)
          return slots.default(data);
      };
    }
  });

  exports.OnClickOutside = OnClickOutside;
  exports.OnLongPress = OnLongPress;
  exports.UseActiveElement = UseActiveElement;
  exports.UseBattery = UseBattery;
  exports.UseBrowserLocation = UseBrowserLocation;
  exports.UseClipboard = UseClipboard;
  exports.UseColorMode = UseColorMode;
  exports.UseDark = UseDark;
  exports.UseDeviceMotion = UseDeviceMotion;
  exports.UseDeviceOrientation = UseDeviceOrientation;
  exports.UseDevicePixelRatio = UseDevicePixelRatio;
  exports.UseDevicesList = UseDevicesList;
  exports.UseDocumentVisibility = UseDocumentVisibility;
  exports.UseDraggable = UseDraggable;
  exports.UseElementBounding = UseElementBounding;
  exports.UseElementSize = UseElementSize;
  exports.UseElementVisibility = UseElementVisibility;
  exports.UseEyeDropper = UseEyeDropper;
  exports.UseFullscreen = UseFullscreen;
  exports.UseGeolocation = UseGeolocation;
  exports.UseIdle = UseIdle;
  exports.UseImage = UseImage;
  exports.UseMouse = UseMouse;
  exports.UseMouseInElement = UseMouseInElement;
  exports.UseMousePressed = UseMousePressed;
  exports.UseNetwork = UseNetwork;
  exports.UseNow = UseNow;
  exports.UseObjectUrl = UseObjectUrl;
  exports.UseOffsetPagination = UseOffsetPagination;
  exports.UseOnline = UseOnline;
  exports.UsePageLeave = UsePageLeave;
  exports.UsePointer = UsePointer;
  exports.UsePointerLock = UsePointerLock;
  exports.UsePreferredColorScheme = UsePreferredColorScheme;
  exports.UsePreferredContrast = UsePreferredContrast;
  exports.UsePreferredDark = UsePreferredDark;
  exports.UsePreferredLanguages = UsePreferredLanguages;
  exports.UsePreferredReducedMotion = UsePreferredReducedMotion;
  exports.UseScreenSafeArea = UseScreenSafeArea;
  exports.UseTimeAgo = UseTimeAgo;
  exports.UseTimestamp = UseTimestamp;
  exports.UseVirtualList = UseVirtualList;
  exports.UseWindowFocus = UseWindowFocus;
  exports.UseWindowSize = UseWindowSize;
  exports.VOnClickOutside = vOnClickOutside;
  exports.VOnLongPress = vOnLongPress;
  exports.vElementHover = vElementHover;
  exports.vElementSize = vElementSize;
  exports.vElementVisibility = vElementVisibility;
  exports.vInfiniteScroll = vInfiniteScroll;
  exports.vIntersectionObserver = vIntersectionObserver;
  exports.vOnClickOutside = vOnClickOutside;
  exports.vOnKeyStroke = vOnKeyStroke;
  exports.vOnLongPress = vOnLongPress;
  exports.vResizeObserver = vResizeObserver;
  exports.vScroll = vScroll;
  exports.vScrollLock = vScrollLock;

})(this.VueUse = this.VueUse || {}, VueUse, Vue, VueUse);
