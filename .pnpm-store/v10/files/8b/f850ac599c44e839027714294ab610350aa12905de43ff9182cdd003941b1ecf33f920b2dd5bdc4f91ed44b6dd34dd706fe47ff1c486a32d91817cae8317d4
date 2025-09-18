import { defineComponent, getCurrentInstance, markRaw, watch, watchEffect, reactive, onMounted, onUnmounted, ref, provide, h, inject, computed, toRef, onBeforeUnmount, KeepAlive, Suspense, nextTick, triggerRef, isRef, isReactive, createTextVNode, resolveComponent } from 'vue';
import { createConfig, createNode, error, createMessage, getNode, watchRegistry, stopWatch, resetCount as resetCount$1, clearErrors, setErrors, submitForm, reset, createClasses, generateClassList, warn, isNode, sugar, isDOM, isComponent, isConditional, compile } from '@formkit/core';
export { clearErrors, errorHandler, reset, setErrors, submitForm } from '@formkit/core';
import { cloneAny, extend, undefine, camel, kebab, nodeProps, only, except, oncePerTick, slugify, shallowClone, eq, token, isObject, empty, has, isPojo } from '@formkit/utils';
import { createObserver } from '@formkit/observer';
import * as defaultRules from '@formkit/rules';
import { createValidationPlugin } from '@formkit/validation';
import { createI18nPlugin, en } from '@formkit/i18n';
export { changeLocale } from '@formkit/i18n';
import { createSection, useSchema, localize, resetCounts, createLibraryPlugin, inputs, runtimeProps } from '@formkit/inputs';
import { createIconHandler, createThemePlugin } from '@formkit/themes';
import { register } from '@formkit/dev';

var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res) => function __init() {
  return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var vueBindings, bindings_default;
var init_bindings = __esm({
  "packages/vue/src/bindings.ts"() {
    vueBindings = function vueBindings2(node) {
      node.ledger.count("blocking", (m) => m.blocking);
      const isValid = ref(!node.ledger.value("blocking"));
      node.ledger.count("errors", (m) => m.type === "error");
      const hasErrors = ref(!!node.ledger.value("errors"));
      let hasTicked = false;
      nextTick(() => {
        hasTicked = true;
      });
      const availableMessages = reactive(
        node.store.reduce((store, message3) => {
          if (message3.visible) {
            store[message3.key] = message3;
          }
          return store;
        }, {})
      );
      const validationVisibility = ref(
        node.props.validationVisibility || (node.props.type === "checkbox" ? "dirty" : "blur")
      );
      node.on("prop:validationVisibility", ({ payload }) => {
        validationVisibility.value = payload;
      });
      const hasShownErrors = ref(validationVisibility.value === "live");
      const isRequired = ref(false);
      const checkForRequired = (parsedRules) => {
        isRequired.value = (parsedRules ?? []).some(
          (rule) => rule.name === "required"
        );
      };
      checkForRequired(node.props.parsedRules);
      node.on("prop:parsedRules", ({ payload }) => checkForRequired(payload));
      const items = ref(node.children.map((child) => child.uid));
      const validationVisible = computed(() => {
        if (!context.state)
          return false;
        if (context.state.submitted)
          return true;
        if (!hasShownErrors.value && !context.state.settled) {
          return false;
        }
        switch (validationVisibility.value) {
          case "live":
            return true;
          case "blur":
            return context.state.blurred;
          case "dirty":
            return context.state.dirty;
          default:
            return false;
        }
      });
      const isInvalid = computed(() => {
        return context.state.failing && validationVisible.value;
      });
      const isComplete = computed(() => {
        return context && hasValidation.value ? isValid.value && !hasErrors.value : context.state.dirty && !empty(context.value);
      });
      const hasValidation = ref(
        Array.isArray(node.props.parsedRules) && node.props.parsedRules.length > 0
      );
      node.on("prop:parsedRules", ({ payload: rules }) => {
        hasValidation.value = Array.isArray(rules) && rules.length > 0;
      });
      const messages3 = computed(() => {
        const visibleMessages = {};
        for (const key in availableMessages) {
          const message3 = availableMessages[key];
          if (message3.type !== "validation" || validationVisible.value) {
            visibleMessages[key] = message3;
          }
        }
        return visibleMessages;
      });
      const ui = reactive(
        node.store.reduce((messages4, message3) => {
          if (message3.type === "ui" && message3.visible)
            messages4[message3.key] = message3;
          return messages4;
        }, {})
      );
      const passing = computed(() => !context.state.failing);
      const cachedClasses = reactive({});
      const classes2 = new Proxy(cachedClasses, {
        get(...args) {
          if (!node)
            return "";
          const [target, property] = args;
          let className = Reflect.get(...args);
          if (!className && typeof property === "string") {
            if (!has(target, property) && !property.startsWith("__v")) {
              const observedNode = createObserver(node);
              observedNode.watch((node2) => {
                const rootClasses = typeof node2.config.rootClasses === "function" ? node2.config.rootClasses(property, node2) : {};
                const globalConfigClasses = node2.config.classes ? createClasses(property, node2, node2.config.classes[property]) : {};
                const classesPropClasses = createClasses(
                  property,
                  node2,
                  node2.props[`_${property}Class`]
                );
                const sectionPropClasses = createClasses(
                  property,
                  node2,
                  node2.props[`${property}Class`]
                );
                className = generateClassList(
                  node2,
                  property,
                  rootClasses,
                  globalConfigClasses,
                  classesPropClasses,
                  sectionPropClasses
                );
                target[property] = className ?? "";
              });
            }
          }
          return className;
        }
      });
      node.on("prop:rootClasses", () => {
        const keys = Object.keys(cachedClasses);
        for (const key of keys) {
          delete cachedClasses[key];
        }
      });
      const describedBy = computed(() => {
        if (!node)
          return void 0;
        const describers = [];
        if (context.help) {
          describers.push(`help-${node.props.id}`);
        }
        for (const key in messages3.value) {
          describers.push(`${node.props.id}-${key}`);
        }
        return describers.length ? describers.join(" ") : void 0;
      });
      const value = ref(node.value);
      const _value = ref(node.value);
      const context = reactive({
        _value,
        attrs: node.props.attrs,
        disabled: node.props.disabled,
        describedBy,
        fns: {
          length: (obj) => Object.keys(obj).length,
          number: (value2) => Number(value2),
          string: (value2) => String(value2),
          json: (value2) => JSON.stringify(value2),
          eq: eq
        },
        handlers: {
          blur: (e) => {
            if (!node)
              return;
            node.store.set(
              /* @__PURE__ */ createMessage({ key: "blurred", visible: false, value: true })
            );
            if (typeof node.props.attrs.onBlur === "function") {
              node.props.attrs.onBlur(e);
            }
          },
          touch: () => {
            const doCompare = context.dirtyBehavior === "compare";
            if (node.store.dirty?.value && !doCompare)
              return;
            const isDirty = !eq(node.props._init, node._value);
            if (!isDirty && !doCompare)
              return;
            node.store.set(
              /* @__PURE__ */ createMessage({ key: "dirty", visible: false, value: isDirty })
            );
          },
          DOMInput: (e) => {
            node.input(e.target.value);
            node.emit("dom-input-event", e);
          }
        },
        help: node.props.help,
        id: node.props.id,
        items,
        label: node.props.label,
        messages: messages3,
        didMount: false,
        node: markRaw(node),
        options: node.props.options,
        defaultMessagePlacement: true,
        slots: node.props.__slots,
        state: {
          blurred: false,
          complete: isComplete,
          dirty: false,
          empty: empty(value),
          submitted: false,
          settled: node.isSettled,
          valid: isValid,
          invalid: isInvalid,
          errors: hasErrors,
          rules: hasValidation,
          validationVisible,
          required: isRequired,
          failing: false,
          passing
        },
        type: node.props.type,
        family: node.props.family,
        ui,
        value,
        classes: classes2
      });
      node.on("created", () => {
        if (!eq(context.value, node.value)) {
          _value.value = node.value;
          value.value = node.value;
          triggerRef(value);
          triggerRef(_value);
        }
        (async () => {
          await node.settled;
          if (node)
            node.props._init = cloneAny(node.value);
        })();
      });
      node.on("mounted", () => {
        context.didMount = true;
      });
      node.on("settled", ({ payload: isSettled }) => {
        context.state.settled = isSettled;
      });
      function observeProps(observe) {
        const propNames = Array.isArray(observe) ? observe : Object.keys(observe);
        propNames.forEach((prop) => {
          prop = camel(prop);
          if (!has(context, prop)) {
            context[prop] = node.props[prop];
          }
          node.on(`prop:${prop}`, ({ payload }) => {
            context[prop] = payload;
          });
        });
      }
      const rootProps = () => {
        const props = [
          "__root",
          "help",
          "label",
          "disabled",
          "options",
          "type",
          "attrs",
          "preserve",
          "preserveErrors",
          "id",
          "dirtyBehavior"
        ];
        const iconPattern = /^[a-zA-Z-]+(?:-icon|Icon)$/;
        const matchingProps = Object.keys(node.props).filter((prop) => {
          return iconPattern.test(prop);
        });
        return props.concat(matchingProps);
      };
      observeProps(rootProps());
      function definedAs(definition3) {
        if (definition3.props)
          observeProps(definition3.props);
      }
      node.props.definition && definedAs(node.props.definition);
      node.on("added-props", ({ payload }) => observeProps(payload));
      node.on("input", ({ payload }) => {
        if (node.type !== "input" && !isRef(payload) && !isReactive(payload)) {
          _value.value = shallowClone(payload);
        } else {
          _value.value = payload;
          triggerRef(_value);
        }
      });
      node.on("commitRaw", ({ payload }) => {
        if (node.type !== "input" && !isRef(payload) && !isReactive(payload)) {
          value.value = _value.value = shallowClone(payload);
        } else {
          value.value = _value.value = payload;
          triggerRef(value);
        }
        node.emit("modelUpdated");
      });
      node.on("commit", ({ payload }) => {
        if ((!context.state.dirty || context.dirtyBehavior === "compare") && node.isCreated && hasTicked) {
          if (!node.store.validating?.value) {
            context.handlers.touch();
          } else {
            const receipt = node.on("message-removed", ({ payload: message3 }) => {
              if (message3.key === "validating") {
                context.handlers.touch();
                node.off(receipt);
              }
            });
          }
        }
        if (isComplete && node.type === "input" && hasErrors.value && !undefine(node.props.preserveErrors)) {
          node.store.filter(
            (message3) => !(message3.type === "error" && message3.meta?.autoClear === true)
          );
        }
        if (node.type === "list" && node.sync) {
          items.value = node.children.map((child) => child.uid);
        }
        context.state.empty = empty(payload);
      });
      const updateState = async (message3) => {
        if (message3.type === "ui" && message3.visible && !message3.meta.showAsMessage) {
          ui[message3.key] = message3;
        } else if (message3.visible) {
          availableMessages[message3.key] = message3;
        } else if (message3.type === "state") {
          context.state[message3.key] = !!message3.value;
        }
      };
      node.on("message-added", (e) => updateState(e.payload));
      node.on("message-updated", (e) => updateState(e.payload));
      node.on("message-removed", ({ payload: message3 }) => {
        delete ui[message3.key];
        delete availableMessages[message3.key];
        delete context.state[message3.key];
      });
      node.on("settled:blocking", () => {
        isValid.value = true;
      });
      node.on("unsettled:blocking", () => {
        isValid.value = false;
      });
      node.on("settled:errors", () => {
        hasErrors.value = false;
      });
      node.on("unsettled:errors", () => {
        hasErrors.value = true;
      });
      watch(validationVisible, (value2) => {
        if (value2) {
          hasShownErrors.value = true;
        }
      });
      node.context = context;
      node.emit("context", node, false);
      node.on("destroyed", () => {
        node.context = void 0;
        node = null;
      });
    };
    bindings_default = vueBindings;
  }
});

// packages/vue/src/defaultConfig.ts
var defaultConfig_exports = {};
__export(defaultConfig_exports, {
  defaultConfig: () => defaultConfig
});
var defaultConfig;
var init_defaultConfig = __esm({
  "packages/vue/src/defaultConfig.ts"() {
    init_bindings();
    defaultConfig = (options = {}) => {
      register();
      const {
        rules = {},
        locales = {},
        inputs: inputs$1 = {},
        messages: messages3 = {},
        locale = void 0,
        theme = void 0,
        iconLoaderUrl = void 0,
        iconLoader = void 0,
        icons = {},
        ...nodeOptions
      } = options;
      const validation = createValidationPlugin({
        ...defaultRules,
        ...rules || {}
      });
      const i18n = createI18nPlugin(
        extend({ en, ...locales || {} }, messages3)
      );
      const library = createLibraryPlugin(inputs, inputs$1);
      const themePlugin = createThemePlugin(theme, icons, iconLoaderUrl, iconLoader);
      return extend(
        {
          plugins: [library, themePlugin, bindings_default, i18n, validation],
          ...!locale ? {} : { config: { locale } }
        },
        nodeOptions || {},
        true
      );
    };
  }
});

// packages/vue/src/composables/onSSRComplete.ts
var isServer = typeof window === "undefined";
var ssrCompleteRegistry = /* @__PURE__ */ new Map();
function ssrComplete(app) {
  if (!isServer)
    return;
  const callbacks = ssrCompleteRegistry.get(app);
  if (!callbacks)
    return;
  for (const callback of callbacks) {
    callback();
  }
  callbacks.clear();
  ssrCompleteRegistry.delete(app);
}
function onSSRComplete(app, callback) {
  if (!isServer || !app)
    return;
  if (!ssrCompleteRegistry.has(app))
    ssrCompleteRegistry.set(app, /* @__PURE__ */ new Set());
  ssrCompleteRegistry.get(app)?.add(callback);
}

// packages/vue/src/FormKitSchema.ts
var isServer2 = typeof window === "undefined";
var memo = {};
var memoKeys = {};
var instanceKey;
var instanceScopes = /* @__PURE__ */ new WeakMap();
var raw = "__raw__";
var isClassProp = /[a-zA-Z0-9\-][cC]lass$/;
function getRef(token3, data) {
  const value = ref(null);
  if (token3 === "get") {
    const nodeRefs = {};
    value.value = get.bind(null, nodeRefs);
    return value;
  }
  const path = token3.split(".");
  watchEffect(() => {
    value.value = getValue(
      isRef(data) ? data.value : data,
      path
    );
  });
  return value;
}
function getValue(set, path) {
  if (Array.isArray(set)) {
    for (const subset of set) {
      const value = subset !== false && getValue(subset, path);
      if (value !== void 0)
        return value;
    }
    return void 0;
  }
  let foundValue = void 0;
  let obj = set;
  for (const i in path) {
    const key = path[i];
    if (typeof obj !== "object" || obj === null) {
      foundValue = void 0;
      break;
    }
    const currentValue = obj[key];
    if (Number(i) === path.length - 1 && currentValue !== void 0) {
      foundValue = typeof currentValue === "function" ? currentValue.bind(obj) : currentValue;
      break;
    }
    obj = currentValue;
  }
  return foundValue;
}
function get(nodeRefs, id) {
  if (typeof id !== "string")
    return warn(650);
  if (!(id in nodeRefs))
    nodeRefs[id] = ref(void 0);
  if (nodeRefs[id].value === void 0) {
    nodeRefs[id].value = null;
    const root = getNode(id);
    if (root)
      nodeRefs[id].value = root.context;
    watchRegistry(id, ({ payload: node }) => {
      nodeRefs[id].value = isNode(node) ? node.context : node;
    });
  }
  return nodeRefs[id].value;
}
function parseSchema(library, schema, memoKey) {
  function parseCondition(library2, node) {
    const condition = provider(compile(node.if), { if: true });
    const children = createElements(library2, node.then);
    const alternate = node.else ? createElements(library2, node.else) : null;
    return [condition, children, alternate];
  }
  function parseConditionAttr(attr, _default) {
    const condition = provider(compile(attr.if));
    let b = () => _default;
    let a = () => _default;
    if (typeof attr.then === "object") {
      a = parseAttrs(attr.then, void 0);
    } else if (typeof attr.then === "string" && attr.then?.startsWith("$")) {
      a = provider(compile(attr.then));
    } else {
      a = () => attr.then;
    }
    if (has(attr, "else")) {
      if (typeof attr.else === "object") {
        b = parseAttrs(attr.else);
      } else if (typeof attr.else === "string" && attr.else?.startsWith("$")) {
        b = provider(compile(attr.else));
      } else {
        b = () => attr.else;
      }
    }
    return () => condition() ? a() : b();
  }
  function parseAttrs(unparsedAttrs, bindExp, _default = {}) {
    const explicitAttrs = new Set(Object.keys(unparsedAttrs || {}));
    const boundAttrs = bindExp ? provider(compile(bindExp)) : () => ({});
    const setters = [
      (attrs) => {
        const bound = boundAttrs();
        for (const attr in bound) {
          if (!explicitAttrs.has(attr)) {
            attrs[attr] = bound[attr];
          }
        }
      }
    ];
    if (unparsedAttrs) {
      if (isConditional(unparsedAttrs)) {
        const condition = parseConditionAttr(
          unparsedAttrs,
          _default
        );
        return condition;
      }
      for (let attr in unparsedAttrs) {
        const value = unparsedAttrs[attr];
        let getValue2;
        const isStr = typeof value === "string";
        if (attr.startsWith(raw)) {
          attr = attr.substring(7);
          getValue2 = () => value;
        } else if (isStr && value.startsWith("$") && value.length > 1 && !(value.startsWith("$reset") && isClassProp.test(attr))) {
          getValue2 = provider(compile(value));
        } else if (typeof value === "object" && isConditional(value)) {
          getValue2 = parseConditionAttr(value, void 0);
        } else if (typeof value === "object" && isPojo(value)) {
          getValue2 = parseAttrs(value);
        } else {
          getValue2 = () => value;
        }
        setters.push((attrs) => {
          attrs[attr] = getValue2();
        });
      }
    }
    return () => {
      const attrs = Array.isArray(unparsedAttrs) ? [] : {};
      setters.forEach((setter) => setter(attrs));
      return attrs;
    };
  }
  function parseNode(library2, _node) {
    let element = null;
    let attrs = () => null;
    let condition = false;
    let children = null;
    let alternate = null;
    let iterator = null;
    let resolve = false;
    const node = sugar(_node);
    if (isDOM(node)) {
      element = node.$el;
      attrs = node.$el !== "text" ? parseAttrs(node.attrs, node.bind) : () => null;
    } else if (isComponent(node)) {
      if (typeof node.$cmp === "string") {
        if (has(library2, node.$cmp)) {
          element = library2[node.$cmp];
        } else {
          element = node.$cmp;
          resolve = true;
        }
      } else {
        element = node.$cmp;
      }
      attrs = parseAttrs(node.props, node.bind);
    } else if (isConditional(node)) {
      [condition, children, alternate] = parseCondition(library2, node);
    }
    if (!isConditional(node) && "if" in node) {
      condition = provider(compile(node.if));
    } else if (!isConditional(node) && element === null) {
      condition = () => true;
    }
    if ("children" in node && node.children) {
      if (typeof node.children === "string") {
        if (node.children.startsWith("$slots.")) {
          element = element === "text" ? "slot" : element;
          children = provider(compile(node.children));
        } else if (node.children.startsWith("$") && node.children.length > 1) {
          const value = provider(compile(node.children));
          children = () => String(value());
        } else {
          children = () => String(node.children);
        }
      } else if (Array.isArray(node.children)) {
        children = createElements(library2, node.children);
      } else {
        const [childCondition, c, a] = parseCondition(library2, node.children);
        children = (iterationData) => childCondition && childCondition() ? c && c(iterationData) : a && a(iterationData);
      }
    }
    if (isComponent(node)) {
      if (children) {
        const produceChildren = children;
        children = (iterationData) => {
          return {
            default(slotData2, key) {
              const currentKey = instanceKey;
              if (key)
                instanceKey = key;
              if (slotData2)
                instanceScopes.get(instanceKey)?.unshift(slotData2);
              if (iterationData)
                instanceScopes.get(instanceKey)?.unshift(iterationData);
              const c = produceChildren(iterationData);
              if (slotData2)
                instanceScopes.get(instanceKey)?.shift();
              if (iterationData)
                instanceScopes.get(instanceKey)?.shift();
              instanceKey = currentKey;
              return c;
            }
          };
        };
        children.slot = true;
      } else {
        children = () => ({});
      }
    }
    if ("for" in node && node.for) {
      const values = node.for.length === 3 ? node.for[2] : node.for[1];
      const getValues = typeof values === "string" && values.startsWith("$") ? provider(compile(values)) : () => values;
      iterator = [
        getValues,
        node.for[0],
        node.for.length === 3 ? String(node.for[1]) : null
      ];
    }
    return [condition, element, attrs, children, alternate, iterator, resolve];
  }
  function createSlots(children, iterationData) {
    const slots = children(iterationData);
    const currentKey = instanceKey;
    return Object.keys(slots).reduce((allSlots, slotName) => {
      const slotFn = slots && slots[slotName];
      allSlots[slotName] = (data) => {
        return slotFn && slotFn(data, currentKey) || null;
      };
      return allSlots;
    }, {});
  }
  function createElement(library2, node) {
    const [condition, element, attrs, children, alternate, iterator, resolve] = parseNode(library2, node);
    let createNodes = (iterationData) => {
      if (condition && element === null && children) {
        return condition() ? children(iterationData) : alternate && alternate(iterationData);
      }
      if (element && (!condition || condition())) {
        if (element === "text" && children) {
          return createTextVNode(String(children()));
        }
        if (element === "slot" && children)
          return children(iterationData);
        const el = resolve ? resolveComponent(element) : element;
        const slots = children?.slot ? createSlots(children, iterationData) : null;
        return h(
          el,
          attrs(),
          slots || (children ? children(iterationData) : [])
        );
      }
      return typeof alternate === "function" ? alternate(iterationData) : alternate;
    };
    if (iterator) {
      const repeatedNode = createNodes;
      const [getValues, valueName, keyName] = iterator;
      createNodes = () => {
        const _v = getValues();
        const values = Number.isFinite(_v) ? Array(Number(_v)).fill(0).map((_, i) => i) : _v;
        const fragment = [];
        if (typeof values !== "object")
          return null;
        const instanceScope = instanceScopes.get(instanceKey) || [];
        const isArray = Array.isArray(values);
        for (const key in values) {
          if (isArray && key in Array.prototype)
            continue;
          const iterationData = Object.defineProperty(
            {
              ...instanceScope.reduce(
                (previousIterationData, scopedData) => {
                  if (previousIterationData.__idata) {
                    return { ...previousIterationData, ...scopedData };
                  }
                  return scopedData;
                },
                {}
              ),
              [valueName]: values[key],
              ...keyName !== null ? { [keyName]: isArray ? Number(key) : key } : {}
            },
            "__idata",
            { enumerable: false, value: true }
          );
          instanceScope.unshift(iterationData);
          fragment.push(repeatedNode.bind(null, iterationData)());
          instanceScope.shift();
        }
        return fragment;
      };
    }
    return createNodes;
  }
  function createElements(library2, schema2) {
    if (Array.isArray(schema2)) {
      const els = schema2.map(createElement.bind(null, library2));
      return (iterationData) => els.map((element2) => element2(iterationData));
    }
    const element = createElement(library2, schema2);
    return (iterationData) => element(iterationData);
  }
  const providers = [];
  function provider(compiled, hints = {}) {
    const compiledFns = /* @__PURE__ */ new WeakMap();
    providers.push((callback, key) => {
      compiledFns.set(
        key,
        compiled.provide((tokens) => callback(tokens, hints))
      );
    });
    return () => compiledFns.get(instanceKey)();
  }
  function createInstance(providerCallback, key) {
    memoKey ?? (memoKey = toMemoKey(schema));
    const [render, compiledProviders] = has(memo, memoKey) ? memo[memoKey] : [createElements(library, schema), providers];
    if (!isServer2) {
      memoKeys[memoKey] ?? (memoKeys[memoKey] = 0);
      memoKeys[memoKey]++;
      memo[memoKey] = [render, compiledProviders];
    }
    compiledProviders.forEach((compiledProvider) => {
      compiledProvider(providerCallback, key);
    });
    return () => {
      instanceKey = key;
      return render();
    };
  }
  return createInstance;
}
function useScope(token3, defaultValue) {
  const scopedData = instanceScopes.get(instanceKey) || [];
  let scopedValue = void 0;
  if (scopedData.length) {
    scopedValue = getValue(scopedData, token3.split("."));
  }
  return scopedValue === void 0 ? defaultValue : scopedValue;
}
function slotData(data, key) {
  return new Proxy(data, {
    get(...args) {
      let data2 = void 0;
      const property = args[1];
      if (typeof property === "string") {
        const prevKey = instanceKey;
        instanceKey = key;
        data2 = useScope(property, void 0);
        instanceKey = prevKey;
      }
      return data2 !== void 0 ? data2 : Reflect.get(...args);
    }
  });
}
function createRenderFn(instanceCreator, data, instanceKey2) {
  return instanceCreator(
    (requirements, hints = {}) => {
      return requirements.reduce((tokens, token3) => {
        if (token3.startsWith("slots.")) {
          const slot = token3.substring(6);
          const hasSlot = () => data.slots && has(data.slots, slot) && typeof data.slots[slot] === "function";
          if (hints.if) {
            tokens[token3] = hasSlot;
          } else if (data.slots) {
            const scopedData = slotData(data, instanceKey2);
            tokens[token3] = () => hasSlot() ? data.slots[slot](scopedData) : null;
          }
        } else {
          const value = getRef(token3, data);
          tokens[token3] = () => useScope(token3, value.value);
        }
        return tokens;
      }, {});
    },
    instanceKey2
  );
}
function clean(schema, memoKey, instanceKey2) {
  memoKey ?? (memoKey = toMemoKey(schema));
  memoKeys[memoKey]--;
  if (memoKeys[memoKey] === 0) {
    delete memoKeys[memoKey];
    const [, providers] = memo[memoKey];
    delete memo[memoKey];
    providers.length = 0;
  }
  instanceScopes.delete(instanceKey2);
}
function toMemoKey(schema) {
  return JSON.stringify(schema, (_, value) => {
    if (typeof value === "function") {
      return value.toString();
    }
    return value;
  });
}
var FormKitSchema = /* @__PURE__ */ defineComponent({
  name: "FormKitSchema",
  props: {
    schema: {
      type: [Array, Object],
      required: true
    },
    data: {
      type: Object,
      default: () => ({})
    },
    library: {
      type: Object,
      default: () => ({})
    },
    memoKey: {
      type: String,
      required: false
    }
  },
  emits: ["mounted"],
  setup(props, context) {
    const instance = getCurrentInstance();
    let instanceKey2 = {};
    instanceScopes.set(instanceKey2, []);
    const library = { FormKit: markRaw(FormKit_default), ...props.library };
    let provider = parseSchema(library, props.schema, props.memoKey);
    let render;
    let data;
    if (!isServer2) {
      watch(
        () => props.schema,
        (newSchema, oldSchema) => {
          const oldKey = instanceKey2;
          instanceKey2 = {};
          instanceScopes.set(instanceKey2, []);
          provider = parseSchema(library, props.schema, props.memoKey);
          render = createRenderFn(provider, data, instanceKey2);
          if (newSchema === oldSchema) {
            (instance?.proxy?.$forceUpdate)();
          }
          clean(props.schema, props.memoKey, oldKey);
        },
        { deep: true }
      );
    }
    watchEffect(() => {
      data = Object.assign(reactive(props.data ?? {}), {
        slots: context.slots
      });
      context.slots;
      render = createRenderFn(provider, data, instanceKey2);
    });
    function cleanUp() {
      clean(props.schema, props.memoKey, instanceKey2);
      if (data) {
        if (data.node)
          data.node.destroy();
        data.slots = null;
        data = null;
      }
      render = null;
    }
    onMounted(() => context.emit("mounted"));
    onUnmounted(cleanUp);
    onSSRComplete(getCurrentInstance()?.appContext.app, cleanUp);
    return () => render ? render() : null;
  }
});
var FormKitSchema_default = FormKitSchema;
var isServer3 = typeof window === "undefined";
var parentSymbol = Symbol("FormKitParent");
var componentSymbol = Symbol("FormKitComponentCallback");
var currentSchemaNode = null;
var getCurrentSchemaNode = () => currentSchemaNode;
function FormKit(props, context) {
  const node = useInput(props, context);
  if (!node.props.definition)
    error(600, node);
  if (node.props.definition.component) {
    return () => h(
      node.props.definition?.component,
      {
        context: node.context
      },
      { ...context.slots }
    );
  }
  const schema = ref([]);
  let memoKey = node.props.definition.schemaMemoKey;
  const generateSchema = () => {
    const schemaDefinition = node.props?.definition?.schema;
    if (!schemaDefinition)
      error(601, node);
    if (typeof schemaDefinition === "function") {
      currentSchemaNode = node;
      schema.value = schemaDefinition({ ...props.sectionsSchema || {} });
      currentSchemaNode = null;
      if (memoKey && props.sectionsSchema || "memoKey" in schemaDefinition && typeof schemaDefinition.memoKey === "string") {
        memoKey = (memoKey ?? schemaDefinition?.memoKey) + JSON.stringify(props.sectionsSchema);
      }
    } else {
      schema.value = schemaDefinition;
    }
  };
  generateSchema();
  if (!isServer3) {
    node.on("schema", () => {
      memoKey += "♻️";
      generateSchema();
    });
  }
  context.emit("node", node);
  const definitionLibrary = node.props.definition.library;
  const library = {
    FormKit: markRaw(formkitComponent),
    ...definitionLibrary,
    ...props.library ?? {}
  };
  function didMount() {
    node.emit("mounted");
  }
  context.expose({ node });
  return () => h(
    FormKitSchema,
    {
      schema: schema.value,
      data: node.context,
      onMounted: didMount,
      library,
      memoKey
    },
    { ...context.slots }
  );
}
var formkitComponent = /* @__PURE__ */ defineComponent(
  FormKit,
  {
    props: runtimeProps,
    inheritAttrs: false
  }
);
var FormKit_default = formkitComponent;
var rootSymbol = Symbol();
var FormKitRoot = /* @__PURE__ */ defineComponent((_p, context) => {
  const boundary = ref(null);
  const showBody = ref(false);
  const shadowRoot = ref(void 0);
  const stopWatch2 = watch(boundary, (el) => {
    let parent = el;
    let root = null;
    while (parent = parent?.parentNode) {
      root = parent;
      if (root instanceof ShadowRoot || root instanceof Document) {
        foundRoot(root);
        break;
      }
    }
    stopWatch2();
    showBody.value = true;
  });
  provide(rootSymbol, shadowRoot);
  function foundRoot(root) {
    shadowRoot.value = root;
  }
  return () => showBody.value && context.slots.default ? context.slots.default() : h("template", { ref: boundary });
});
function createPlugin(app, options) {
  app.component(options.alias || "FormKit", FormKit_default).component(options.schemaAlias || "FormKitSchema", FormKitSchema_default);
  return {
    get: getNode,
    setLocale: (locale) => {
      if (options.config?.rootConfig) {
        options.config.rootConfig.locale = locale;
      }
    },
    clearErrors,
    setErrors,
    submit: submitForm,
    reset
  };
}
var optionsSymbol = Symbol.for("FormKitOptions");
var configSymbol = Symbol.for("FormKitConfig");
var plugin = {
  install(app, _options) {
    const options = Object.assign(
      {
        alias: "FormKit",
        schemaAlias: "FormKitSchema"
      },
      typeof _options === "function" ? _options() : _options
    );
    const rootConfig = createConfig(options.config || {});
    options.config = { rootConfig };
    app.config.globalProperties.$formkit = createPlugin(app, options);
    app.provide(optionsSymbol, options);
    app.provide(configSymbol, rootConfig);
    if (typeof window !== "undefined") {
      globalThis.__FORMKIT_CONFIGS__ = (globalThis.__FORMKIT_CONFIGS__ || []).concat([rootConfig]);
    }
  }
};

// packages/vue/src/composables/useInput.ts
var isBrowser = typeof window !== "undefined";
var pseudoProps = [
  // Boolean props
  "ignore",
  "disabled",
  "preserve",
  // String props
  "help",
  "label",
  /^preserve(-e|E)rrors/,
  /^[a-z]+(?:-visibility|Visibility|-behavior|Behavior)$/,
  /^[a-zA-Z-]+(?:-class|Class)$/,
  "prefixIcon",
  "suffixIcon",
  /^[a-zA-Z-]+(?:-icon|Icon)$/
];
var boolProps = ["disabled", "ignore", "preserve"];
function classesToNodeProps(node, props) {
  if (props.classes) {
    Object.keys(props.classes).forEach(
      (key) => {
        if (typeof key === "string") {
          node.props[`_${key}Class`] = props.classes[key];
          if (isObject(props.classes[key]) && key === "inner")
            Object.values(props.classes[key]);
        }
      }
    );
  }
}
function onlyListeners(props) {
  if (!props)
    return {};
  const knownListeners = ["Submit", "SubmitRaw", "SubmitInvalid"].reduce(
    (listeners, listener) => {
      const name = `on${listener}`;
      if (name in props) {
        if (typeof props[name] === "function") {
          listeners[name] = props[name];
        }
      }
      return listeners;
    },
    {}
  );
  return knownListeners;
}
function useInput(props, context, options = {}) {
  const config = Object.assign({}, inject(optionsSymbol) || {}, options);
  const __root = inject(rootSymbol, ref(isBrowser ? document : void 0));
  const __cmpCallback = inject(componentSymbol, () => {
  });
  const instance = getCurrentInstance();
  const listeners = onlyListeners(instance?.vnode.props);
  const isVModeled = ["modelValue", "model-value"].some(
    (prop) => prop in (instance?.vnode.props ?? {})
  );
  let isMounted = false;
  onMounted(() => {
    isMounted = true;
  });
  const value = props.modelValue !== void 0 ? props.modelValue : cloneAny(context.attrs.value);
  function createInitialProps() {
    const initialProps2 = {
      ...nodeProps(props),
      ...listeners,
      type: props.type ?? "text",
      __root: __root.value,
      __slots: context.slots
    };
    const attrs = except(nodeProps(context.attrs), pseudoProps);
    if (!attrs.key)
      attrs.key = token();
    initialProps2.attrs = attrs;
    const propValues = only(nodeProps(context.attrs), pseudoProps);
    for (const propName in propValues) {
      if (boolProps.includes(propName) && propValues[propName] === "") {
        propValues[propName] = true;
      }
      initialProps2[camel(propName)] = propValues[propName];
    }
    const classesProps = { props: {} };
    classesToNodeProps(classesProps, props);
    Object.assign(initialProps2, classesProps.props);
    if (typeof initialProps2.type !== "string") {
      initialProps2.definition = initialProps2.type;
      delete initialProps2.type;
    }
    return initialProps2;
  }
  const initialProps = createInitialProps();
  const parent = initialProps.ignore ? null : props.parent || inject(parentSymbol, null);
  const node = createNode(
    extend(
      config || {},
      {
        name: props.name || void 0,
        value,
        parent,
        plugins: (config.plugins || []).concat(props.plugins ?? []),
        config: props.config || {},
        props: initialProps,
        index: props.index,
        sync: !!undefine(context.attrs.sync || context.attrs.dynamic)
      },
      false,
      true
    )
  );
  __cmpCallback(node);
  if (!node.props.definition)
    error(600, node);
  const lateBoundProps = ref(
    new Set(
      Array.isArray(node.props.__propDefs) ? node.props.__propDefs : Object.keys(node.props.__propDefs ?? {})
    )
  );
  node.on(
    "added-props",
    ({ payload: lateProps }) => {
      const propNames = Array.isArray(lateProps) ? lateProps : Object.keys(lateProps ?? {});
      propNames.forEach((newProp) => lateBoundProps.value.add(newProp));
    }
  );
  const pseudoPropNames = computed(
    () => pseudoProps.concat([...lateBoundProps.value]).reduce((names, prop) => {
      if (typeof prop === "string") {
        names.push(camel(prop));
        names.push(kebab(prop));
      } else {
        names.push(prop);
      }
      return names;
    }, [])
  );
  watchEffect(() => classesToNodeProps(node, props));
  const passThrough = nodeProps(props);
  for (const prop in passThrough) {
    watch(
      () => props[prop],
      () => {
        if (props[prop] !== void 0) {
          node.props[prop] = props[prop];
        }
      }
    );
  }
  watchEffect(() => {
    node.props.__root = __root.value;
  });
  const attributeWatchers = /* @__PURE__ */ new Set();
  const possibleProps = nodeProps(context.attrs);
  watchEffect(() => {
    watchAttributes(only(possibleProps, pseudoPropNames.value));
  });
  function watchAttributes(attrProps) {
    attributeWatchers.forEach((stop) => {
      stop();
      attributeWatchers.delete(stop);
    });
    for (const prop in attrProps) {
      const camelName = camel(prop);
      attributeWatchers.add(
        watch(
          () => context.attrs[prop],
          () => {
            node.props[camelName] = context.attrs[prop];
          }
        )
      );
    }
  }
  watchEffect(() => {
    const attrs = except(nodeProps(context.attrs), pseudoPropNames.value);
    if ("multiple" in attrs)
      attrs.multiple = undefine(attrs.multiple);
    if (typeof attrs.onBlur === "function") {
      attrs.onBlur = oncePerTick(attrs.onBlur);
    }
    node.props.attrs = Object.assign({}, node.props.attrs || {}, attrs);
  });
  watchEffect(() => {
    const messages3 = (props.errors ?? []).map(
      (error3) => /* @__PURE__ */ createMessage({
        key: slugify(error3),
        type: "error",
        value: error3,
        meta: { source: "prop" }
      })
    );
    node.store.apply(
      messages3,
      (message3) => message3.type === "error" && message3.meta.source === "prop"
    );
  });
  if (node.type !== "input") {
    const sourceKey = `${node.name}-prop`;
    watchEffect(() => {
      const inputErrors = props.inputErrors ?? {};
      const keys = Object.keys(inputErrors);
      if (!keys.length)
        node.clearErrors(true, sourceKey);
      const messages3 = keys.reduce((messages4, key) => {
        let value2 = inputErrors[key];
        if (typeof value2 === "string")
          value2 = [value2];
        if (Array.isArray(value2)) {
          messages4[key] = value2.map(
            (error3) => /* @__PURE__ */ createMessage({
              key: error3,
              type: "error",
              value: error3,
              meta: { source: sourceKey }
            })
          );
        }
        return messages4;
      }, {});
      node.store.apply(
        messages3,
        (message3) => message3.type === "error" && message3.meta.source === sourceKey
      );
    });
  }
  watchEffect(() => Object.assign(node.config, props.config));
  if (node.type !== "input") {
    provide(parentSymbol, node);
  }
  let clonedValueBeforeVmodel = void 0;
  node.on("modelUpdated", () => {
    context.emit("inputRaw", node.context?.value, node);
    if (isMounted) {
      context.emit("input", node.context?.value, node);
    }
    if (isVModeled && node.context) {
      clonedValueBeforeVmodel = cloneAny(node.value);
      context.emit("update:modelValue", shallowClone(node.value));
    }
  });
  if (isVModeled) {
    watch(
      toRef(props, "modelValue"),
      (value2) => {
        if (!eq(clonedValueBeforeVmodel, value2)) {
          node.input(value2, false);
        }
      },
      { deep: true }
    );
    if (node.value !== value) {
      node.emit("modelUpdated");
    }
  }
  onBeforeUnmount(() => node.destroy());
  return node;
}
var totalCreated = 1;
function isComponent2(obj) {
  return typeof obj === "function" && obj.length === 2 || typeof obj === "object" && !Array.isArray(obj) && !("$el" in obj) && !("$cmp" in obj) && !("if" in obj);
}
function createInput(schemaOrComponent, definitionOptions = {}, sectionsSchema = {}) {
  const definition3 = {
    type: "input",
    ...definitionOptions
  };
  let schema;
  if (isComponent2(schemaOrComponent)) {
    const cmpName = `SchemaComponent${totalCreated++}`;
    schema = createSection("input", () => ({
      $cmp: cmpName,
      props: {
        context: "$node.context"
      }
    }));
    definition3.library = { [cmpName]: markRaw(schemaOrComponent) };
  } else if (typeof schemaOrComponent === "function") {
    schema = schemaOrComponent;
  } else {
    schema = createSection("input", () => cloneAny(schemaOrComponent));
  }
  definition3.schema = useSchema(schema || "Schema undefined", sectionsSchema);
  if (!definition3.schemaMemoKey) {
    definition3.schemaMemoKey = `${Math.random()}`;
  }
  return definition3;
}

// packages/vue/src/composables/defineFormKitConfig.ts
function defineFormKitConfig(config) {
  return () => typeof config === "function" ? config() : config;
}
var inputList = {};
var schemas = {};
var classes = {
  container: `
    formkit-kitchen-sink 
    p-8
  `,
  tabs: `
    formkit-tabs 
    mt-4 
    mr-[min(350px,25vw)]
  `,
  tab: `
    formkit-kitchen-sink-tab
    inline-block
    mb-4
    -mr-px
    cursor-pointer
    px-4
    py-2
    border
    border-neutral-200
    text-neutral-800
    data-[active]:bg-neutral-800
    data-[active]:border-neutral-800
    data-[active]:text-neutral-50
    hover:bg-neutral-100
    hover:text-neutral-900
    dark:border-neutral-700
    dark:text-neutral-50
    dark:data-[active]:bg-neutral-100
    dark:data-[active]:border-neutral-100
    dark:data-[active]:text-neutral-800
    dark:hover:bg-neutral-800
    dark:hover:text-neutral-50
  `,
  filterContainer: `
    formkit-filter-container
    grid
    grid-cols-[repeat(auto-fit,300px)]
    mr-[min(350px,25vw)]
    -mt-4
    mb-8
    px-4
    pt-8
    pb-4
    border
    relative
    -translate-y-px
    max-w-[1000px]
    border-neutral-200
    dark:border-neutral-700
  `,
  filterGroup: `
    formkit-filter-group
    mr-8
    mb-8
    [&_legend]:text-lg
    [&_ul]:columns-2
    [&_ul>li:first-child]:[column-span:all]
    [&_ul>li:first-child]:mt-2
    [&_ul>li:first-child]:mb-2
    [&_ul>li:first-child]:pb-2
    [&_ul>li:first-child]:border-b
    [&_ul>li:first-child]:border-neutral-200
    dark:[&_ul>li:first-child]:border-neutral-700
  `,
  formContainer: `
    formkit-form-container
    w-full
    bg-white
    rounded
    border
    border-neutral-100
    shadow-lg
    max-w-[800px]
    p-[min(5vw,5rem)]
    dark:bg-neutral-900
    dark:border-neutral-800
    dark:shadow-3xl
    [&_form>h1]:text-2xl
    [&_form>h1]:mb-4
    [&_form>h1]:font-bold
    [&_form>h1+p]:text-base
    [&_form>h1+p]:mb-4
    [&_form>h1+p]:-mt-2
    [&_form_.double]:flex
    [&_form_.double>*]:w-1/2
    [&_form_.double>*:first-child]:mr-2
    [&_form_.triple]:flex
    [&_form_.triple>*]:w-1/3
    [&_form_.triple>*:first-child]:mr-2
    [&_form_.triple>*:last-child]:ml-2
  `,
  inputs: `formkit-inputs`,
  specimen: `
    formkit-specimen 
    flex 
    flex-col 
    p-2 
    max-w-[75vw]
  `,
  inputSection: `
    group/section
    formkit-input-section 
    mr-[min(325px,25vw)]
  `,
  specimenGroup: `
    formkit-specimen-group
    grid
    mb-16
    grid-cols-[repeat(auto-fit,400px)]
    group-data-[type="transferlist"]/section:grid-cols-[repeat(auto-fit,650px)]
    group-data-[type="multi-step"]/section:grid-cols-[repeat(auto-fit,550px)]
  `,
  inputType: `
    formkit-input-type
    block
    font-bold
    text-neutral-900
    border-b
    border-neutral-100
    text-3xl
    mb-8
    pb-2
    capitalize
    dark:border-neutral-800 
    dark:text-neutral-50
  `
};
async function fetchInputList() {
  const response = await fetch(
    "https://raw.githubusercontent.com/formkit/input-schemas/master/index.json"
  );
  const json = await response.json();
  return json;
}
async function fetchInputSchema(input) {
  try {
    const response = await fetch(
      `https://raw.githubusercontent.com/formkit/input-schemas/master/schemas/${input}.json`
    );
    const json = await response.json();
    return json;
  } catch (error3) {
    console.error(error3);
  }
}
var FormKitKitchenSink = /* @__PURE__ */ defineComponent({
  name: "FormKitKitchenSink",
  props: {
    schemas: {
      type: Array,
      required: false
    },
    pro: {
      type: Boolean,
      default: true
    },
    addons: {
      type: Boolean,
      default: true
    },
    forms: {
      type: Boolean,
      default: true
    },
    navigation: {
      type: Boolean,
      default: true
    }
  },
  async setup(props) {
    onMounted(() => {
      const filterNode = getNode("filter-checkboxes");
      data.filters = computed(() => {
        if (!filterNode?.context)
          return [];
        const filters = filterNode.context.value;
        const filterValues = [];
        Object.keys(filters).forEach((key) => {
          filterValues.push(...filters[key]);
        });
        return filterValues;
      });
    });
    inputList = Object.keys(inputList).length ? inputList : await fetchInputList();
    const promises = [];
    const activeTab = ref("");
    const inputCheckboxes = computed(() => {
      const inputGroups = {
        core: { label: "Inputs", name: "core", inputs: inputList.core }
      };
      if (props.pro) {
        inputGroups.pro = {
          label: "Pro Inputs",
          name: "pro",
          inputs: inputList.pro
        };
      }
      if (props.addons) {
        inputGroups.addons = {
          label: "Add-ons",
          name: "addons",
          inputs: inputList.addons
        };
      }
      return inputGroups;
    });
    if (!props.schemas) {
      const coreInputPromises = inputList.core.map(async (schema) => {
        const response = await fetchInputSchema(schema);
        schemas[schema] = response;
      });
      promises.push(...coreInputPromises);
      if (props.forms) {
        const formsPromises = inputList.forms.map(async (schema) => {
          const schemaName = `form/${schema}`;
          const response = await fetchInputSchema(schemaName);
          schemas[schemaName] = response;
        });
        promises.push(...formsPromises);
      }
      if (props.pro) {
        const proInputPromises = inputList.pro.map(async (schema) => {
          const response = await fetchInputSchema(schema);
          schemas[schema] = response;
        });
        promises.push(...proInputPromises);
      }
      if (props.addons) {
        const addonPromises = inputList.addons.map(async (schema) => {
          const response = await fetchInputSchema(schema);
          schemas[schema] = response;
        });
        promises.push(...addonPromises);
      }
    } else {
      const schemaPromises = props.schemas.map(async (schema) => {
        const response = await fetchInputSchema(`${schema}`);
        schemas[`${schema}`] = response;
      });
      promises.push(...schemaPromises);
    }
    const selectAll = (node) => {
      let previousValue = [];
      let skip = false;
      if (node.props.type !== "checkbox")
        return;
      node.on("created", () => {
        const currentValue = node.value;
        if (Array.isArray(currentValue) && currentValue.length === 1 && currentValue[0] === "all") {
          node.input(
            node.props.options.map((option) => {
              if (typeof option !== "string")
                return option.value;
              return option;
            })
          );
        }
        previousValue = Array.isArray(node.value) ? node.value : [];
      });
      node.on("commit", ({ payload }) => {
        if (skip) {
          skip = false;
          return;
        }
        if (!Array.isArray(payload))
          return;
        const previousValueHadAll = previousValue.includes("all");
        const currentValueHasAll = payload.includes("all");
        if (!previousValueHadAll && currentValueHasAll) {
          const computedOptions = node.props.options.map(
            (option) => {
              if (typeof option !== "string")
                return option.value;
              return option;
            }
          );
          node.input(computedOptions);
          previousValue = computedOptions;
          return;
        }
        if (previousValueHadAll && !currentValueHasAll) {
          node.input([]);
          previousValue = [];
          return;
        }
        const valueMinusAll = payload.filter((value) => value !== "all");
        if (valueMinusAll.length < node.props.options.length - 1 && currentValueHasAll) {
          node.input(valueMinusAll);
          previousValue = valueMinusAll;
          skip = true;
          return;
        }
        if (valueMinusAll.length === node.props.options.length - 1 && !currentValueHasAll) {
          const computedOptions = node.props.options.map(
            (option) => {
              if (typeof option !== "string")
                return option.value;
              return option;
            }
          );
          node.input(computedOptions);
          previousValue = Array.isArray(node.value) ? node.value : [];
          return;
        }
      });
    };
    const data = reactive({
      twClasses: classes,
      basicOptions: Array.from({ length: 15 }, (_, i) => `Option ${i + 1}`),
      asyncLoader: async () => {
        return await new Promise(() => {
        });
      },
      paginatedLoader: async ({
        page,
        hasNextPage
      }) => {
        const base = (page - 1) * 10;
        hasNextPage();
        return Array.from({ length: 10 }, (_, i) => `Option ${base + i + 1}`);
      },
      formSubmitHandler: async (data2) => {
        await new Promise((resolve) => setTimeout(resolve, 1e3));
        alert("Form submitted (fake) — check console for data object");
        console.log("Form data:", data2);
      },
      includes: (array, value) => {
        if (!Array.isArray(array))
          return false;
        return array.includes(value);
      },
      checkboxPlugins: [selectAll],
      filters: []
    });
    await Promise.all(promises);
    const inputKeys = Object.keys(schemas);
    const formNames = inputKeys.map((key) => {
      if (key.startsWith("form/")) {
        switch (key) {
          case "form/tshirt":
            return {
              id: key,
              name: "Order Form"
            };
          default:
            const name = key.replace("form/", "");
            return {
              id: key,
              name: name.charAt(0).toUpperCase() + name.slice(1) + " Form"
            };
        }
      }
      return {
        id: key,
        name: ""
      };
    });
    const filteredFormNames = formNames.filter((form) => form.name !== "");
    const forms = inputKeys.filter((schema) => {
      return schema.startsWith("form/");
    });
    const inputs = inputKeys.filter(
      (schema) => !schema.startsWith("form/")
    );
    const tabs = [];
    if (inputs.length) {
      tabs.push({
        id: "kitchen-sink",
        name: "Kitchen Sink"
      });
    }
    if (forms.length) {
      tabs.push(...filteredFormNames.sort((a, b) => a.name > b.name ? 1 : -1));
    }
    if (tabs.length) {
      activeTab.value = tabs[0].id;
    }
    const kitchenSinkRenders = computed(() => {
      inputs.sort();
      const schemaDefinitions = inputs.reduce(
        (schemaDefinitions2, inputName) => {
          const schemaDefinition = schemas[inputName];
          schemaDefinitions2.push({
            $el: "div",
            if: '$includes($filters, "' + inputName + '")',
            attrs: {
              key: inputName,
              class: "$twClasses.inputSection",
              "data-type": inputName
            },
            children: [
              {
                $el: "h2",
                attrs: {
                  class: "$twClasses.inputType"
                },
                children: inputName
              },
              {
                $el: "div",
                attrs: {
                  class: "$twClasses.specimenGroup"
                },
                children: [
                  ...(Array.isArray(schemaDefinition) ? schemaDefinition : [schemaDefinition]).map((specimen) => {
                    return {
                      $el: "div",
                      attrs: {
                        class: "$twClasses.specimen"
                      },
                      children: [specimen]
                    };
                  })
                ]
              }
            ]
          });
          return schemaDefinitions2;
        },
        []
      );
      return h(
        KeepAlive,
        {},
        {
          default: () => {
            return activeTab.value === "kitchen-sink" ? h(FormKitSchema, { schema: schemaDefinitions, data }) : null;
          }
        }
      );
    });
    const formRenders = computed(() => {
      return filteredFormNames.map((form) => {
        const schemaDefinition = schemas[form.id];
        return h(
          "div",
          {
            key: form.id
          },
          activeTab.value === form.id ? [
            h(
              "div",
              {
                class: classes.formContainer
              },
              [
                h(FormKitSchema, {
                  schema: schemaDefinition[0],
                  data
                })
              ]
            )
          ] : ""
        );
      }).filter((form) => form.children);
    });
    const tabBar = computed(() => {
      return h(
        "div",
        {
          key: "tab-bar",
          class: classes.tabs
        },
        tabs.map((tab) => {
          return h(
            "span",
            {
              class: classes.tab,
              key: tab.id,
              "data-tab": tab.id,
              "data-active": activeTab.value === tab.id || void 0,
              onClick: () => {
                activeTab.value = tab.id;
              }
            },
            tab.name
          );
        })
      );
    });
    const filterCheckboxes = computed(() => {
      const createCheckboxSchema = (inputGroup) => {
        return {
          $el: "div",
          attrs: {
            class: "$twClasses.filterGroup"
          },
          children: [
            {
              $formkit: "checkbox",
              name: inputGroup.name,
              label: inputGroup.label,
              plugins: "$checkboxPlugins",
              value: ["all"],
              options: [
                {
                  label: "All",
                  value: "all"
                },
                ...Array.isArray(inputGroup.inputs) ? inputGroup.inputs : []
              ]
            }
          ]
        };
      };
      const filterSchema = h(FormKitSchema, {
        key: "filter-checkboxes",
        data,
        schema: {
          $formkit: "group",
          id: "filter-checkboxes",
          children: [
            {
              $el: "div",
              attrs: {
                class: "$twClasses.filterContainer"
              },
              children: Object.keys(inputCheckboxes.value).map((key) => {
                const inputGroup = inputCheckboxes.value[key];
                return createCheckboxSchema(inputGroup);
              })
            }
          ]
        }
      });
      return h(
        KeepAlive,
        {},
        {
          default: () => {
            if (!(tabs.find((tab) => tab.id === "kitchen-sink") && activeTab.value === "kitchen-sink")) {
              return null;
            }
            return filterSchema;
          }
        }
      );
    });
    return () => {
      return h(
        "div",
        {
          class: classes.container
        },
        [
          tabs.length > 1 ? tabBar.value : void 0,
          filterCheckboxes.value,
          ...formRenders.value,
          kitchenSinkRenders.value
        ]
      );
    };
  }
});
var messages = createSection("messages", () => ({
  $el: "ul",
  if: "$fns.length($messages)"
}));
var message = createSection("message", () => ({
  $el: "li",
  for: ["message", "$messages"],
  attrs: {
    key: "$message.key",
    id: `$id + '-' + $message.key`,
    "data-message-type": "$message.type"
  }
}));
var definition = messages(message("$message.value"));
var FormKitMessages = /* @__PURE__ */ defineComponent({
  props: {
    node: {
      type: Object,
      required: false
    },
    sectionsSchema: {
      type: Object,
      default: {}
    },
    defaultPosition: {
      type: [String, Boolean],
      default: false
    },
    library: {
      type: Object,
      default: () => ({})
    }
  },
  setup(props, context) {
    const node = computed(() => {
      return props.node || inject(parentSymbol, void 0);
    });
    watch(
      node,
      () => {
        if (node.value?.context && !undefine(props.defaultPosition)) {
          node.value.context.defaultMessagePlacement = false;
        }
      },
      { immediate: true }
    );
    const schema = definition(props.sectionsSchema || {});
    const data = computed(() => {
      return {
        messages: node.value?.context?.messages || {},
        fns: node.value?.context?.fns || {},
        classes: node.value?.context?.classes || {}
      };
    });
    return () => node.value?.context ? h(
      FormKitSchema_default,
      { schema, data: data.value, library: props.library },
      { ...context.slots }
    ) : null;
  }
});
function useConfig(config) {
  const options = Object.assign(
    {
      alias: "FormKit",
      schemaAlias: "FormKitSchema"
    },
    typeof config === "function" ? config() : config
  );
  const rootConfig = createConfig(options.config || {});
  options.config = { rootConfig };
  provide(optionsSymbol, options);
  provide(configSymbol, rootConfig);
  if (typeof window !== "undefined") {
    globalThis.__FORMKIT_CONFIGS__ = (globalThis.__FORMKIT_CONFIGS__ || []).concat([rootConfig]);
  }
}
var FormKitProvider = /* @__PURE__ */ defineComponent(
  function FormKitProvider2(props, { slots, attrs }) {
    const options = {};
    if (props.config) {
      useConfig(props.config);
    }
    return () => slots.default ? slots.default(options).map((vnode) => {
      return h(vnode, {
        ...attrs,
        ...vnode.props
      });
    }) : null;
  },
  { props: ["config"], name: "FormKitProvider", inheritAttrs: false }
);
var FormKitConfigLoader = /* @__PURE__ */ defineComponent(
  async function FormKitConfigLoader2(props, context) {
    let config = {};
    if (props.configFile) {
      const configFile = await import(
        /*@__formkit.config.ts__*/
        /* @vite-ignore */
        /* webpackIgnore: true */
        props.configFile
      );
      config = "default" in configFile ? configFile.default : configFile;
    }
    if (typeof config === "function") {
      config = config();
    }
    const useDefaultConfig = props.defaultConfig ?? true;
    if (useDefaultConfig) {
      const { defaultConfig: defaultConfig2 } = await Promise.resolve().then(() => (init_defaultConfig(), defaultConfig_exports));
      config = /* @__PURE__ */ defaultConfig2(config);
    }
    return () => h(FormKitProvider, { ...context.attrs, config }, context.slots);
  },
  {
    props: ["defaultConfig", "configFile"],
    inheritAttrs: false
  }
);
var FormKitLazyProvider = /* @__PURE__ */ defineComponent(
  function FormKitLazyProvider2(props, context) {
    const config = inject(optionsSymbol, null);
    const passthru = (vnode) => {
      return h(vnode, {
        ...context.attrs,
        ...vnode.props
      });
    };
    if (config) {
      return () => context.slots?.default ? context.slots.default().map(passthru) : null;
    }
    const instance = getCurrentInstance();
    if (instance.suspense) {
      return () => h(FormKitConfigLoader, props, {
        default: () => context.slots?.default ? context.slots.default().map(passthru) : null
      });
    }
    return () => h(Suspense, null, {
      ...context.slots,
      default: () => h(FormKitConfigLoader, { ...context.attrs, ...props }, context.slots)
    });
  },
  {
    props: ["defaultConfig", "configFile"],
    inheritAttrs: false
  }
);
function useFormKitContext(addressOrEffect, optionalEffect) {
  const address = typeof addressOrEffect === "string" ? addressOrEffect : void 0;
  const effect = typeof addressOrEffect === "function" ? addressOrEffect : optionalEffect;
  const context = ref();
  const parentNode = inject(parentSymbol, null);
  if (parentNode) {
    if (address) {
      context.value = parentNode.at(address)?.context;
      const root = parentNode.at("$root");
      if (root) {
        const receipt = root.on("child.deep", () => {
          const targetNode = parentNode.at(address);
          if (targetNode && targetNode.context !== context.value) {
            context.value = targetNode.context;
            if (effect)
              effect(context.value);
          }
        });
        onUnmounted(() => {
          root.off(receipt);
        });
      }
    } else {
      context.value = parentNode?.context;
    }
  }
  if (context.value && effect)
    effect(context.value);
  return context;
}
function useFormKitContextById(id, effect) {
  const context = ref();
  const targetNode = getNode(id);
  if (targetNode)
    context.value = targetNode.context;
  if (!targetNode) {
    const receipt = watchRegistry(id, ({ payload: node }) => {
      if (node) {
        context.value = node.context;
        stopWatch(receipt);
        if (effect)
          effect(context.value);
      }
    });
  }
  if (context.value && effect)
    effect(context.value);
  return context;
}
function useFormKitNodeById(id, effect) {
  const nodeRef = ref();
  const targetNode = getNode(id);
  if (targetNode)
    nodeRef.value = targetNode;
  if (!targetNode) {
    const receipt = watchRegistry(id, ({ payload: node }) => {
      if (node) {
        nodeRef.value = node;
        stopWatch(receipt);
        if (effect)
          effect(node);
      }
    });
  }
  if (nodeRef.value && effect)
    effect(nodeRef.value);
  return nodeRef;
}
var summary = createSection("summary", () => ({
  $el: "div",
  attrs: {
    "aria-live": "polite"
  }
}));
var summaryInner = createSection("summaryInner", () => ({
  $el: "div",
  if: "$summaries.length && $showSummaries"
}));
var messages2 = createSection("messages", () => ({
  $el: "ul",
  if: "$summaries.length && $showSummaries"
}));
var message2 = createSection("message", () => ({
  $el: "li",
  for: ["summary", "$summaries"],
  attrs: {
    key: "$summary.key",
    "data-message-type": "$summary.type"
  }
}));
var summaryHeader = createSection("summaryHeader", () => ({
  $el: "h2",
  attrs: {
    id: "$id"
  }
}));
var messageLink = createSection("messageLink", () => ({
  $el: "a",
  attrs: {
    id: "$summary.key",
    href: '$: "#" + $summary.id',
    onClick: "$jumpLink"
  }
}));
var definition2 = summary(
  summaryInner(
    summaryHeader("$summaryHeader"),
    messages2(message2(messageLink("$summary.message")))
  )
);
var FormKitSummary = /* @__PURE__ */ defineComponent({
  props: {
    node: {
      type: Object,
      required: false
    },
    forceShow: {
      type: Boolean,
      default: false
    },
    sectionsSchema: {
      type: Object,
      default: {}
    }
  },
  emits: {
    /* eslint-disable-next-line @typescript-eslint/no-unused-vars */
    show: (_summaries) => true
  },
  setup(props, context) {
    const id = `summary-${token()}`;
    const node = computed(() => {
      return props.node || inject(parentSymbol, void 0);
    });
    if (!node)
      throw new Error(
        "FormKitSummary must have a FormKit parent or use the node prop."
      );
    const summaryContexts = ref([]);
    const showSummaries = ref(false);
    const summaries = computed(() => {
      const summarizedMessages = [];
      summaryContexts.value.forEach((context2) => {
        for (const idx in context2.messages) {
          const message3 = context2.messages[idx];
          if (typeof message3.value !== "string")
            continue;
          summarizedMessages.push({
            message: message3.value,
            id: context2.id,
            key: `${context2.id}-${message3.key}`,
            type: message3.type
          });
        }
      });
      return summarizedMessages;
    });
    const addContexts = () => {
      summaryContexts.value = [];
      node.value?.walk(
        (child) => child.context && summaryContexts.value.push(child.context)
      );
    };
    node.value?.on("submit-raw", async () => {
      addContexts();
      if (summaries.value.length === 0)
        return;
      context.emit("show", summaries.value);
      showSummaries.value = true;
      await nextTick();
      if (typeof window !== "undefined") {
        document.getElementById(id)?.scrollIntoView({ behavior: "smooth" });
        if (summaries.value[0]) {
          document.getElementById(summaries.value[0].key)?.focus();
        }
      }
    });
    node.value?.on("child", addContexts);
    function jumpLink(e) {
      if (e.target instanceof HTMLAnchorElement) {
        e.preventDefault();
        const id2 = e.target.getAttribute("href")?.substring(1);
        if (id2) {
          document.getElementById(id2)?.scrollIntoView({ behavior: "smooth" });
          document.getElementById(id2)?.focus();
        }
      }
    }
    localize("summaryHeader", "There were errors in your form.")(node.value);
    const schema = definition2(props.sectionsSchema || {});
    const data = computed(() => {
      return {
        id,
        fns: node.value?.context?.fns || {},
        classes: node.value?.context?.classes || {},
        summaries: summaries.value,
        showSummaries: props.forceShow || showSummaries.value,
        summaryHeader: node.value?.context?.ui?.summaryHeader?.value || "",
        jumpLink
      };
    });
    return () => node.value?.context ? h(FormKitSchema_default, { schema, data: data.value }, { ...context.slots }) : null;
  }
});

// packages/vue/src/index.ts
init_defaultConfig();
init_bindings();
var FormKitIcon = /* @__PURE__ */ defineComponent({
  name: "FormKitIcon",
  props: {
    icon: {
      type: String,
      default: ""
    },
    iconLoader: {
      type: Function,
      default: null
    },
    iconLoaderUrl: {
      type: Function,
      default: null
    }
  },
  setup(props) {
    const icon = ref(void 0);
    const config = inject(optionsSymbol, {});
    const parent = inject(parentSymbol, null);
    let iconHandler = void 0;
    function loadIcon() {
      if (!iconHandler || typeof iconHandler !== "function")
        return;
      const iconOrPromise = iconHandler(props.icon);
      if (iconOrPromise instanceof Promise) {
        iconOrPromise.then((iconValue) => {
          icon.value = iconValue;
        });
      } else {
        icon.value = iconOrPromise;
      }
    }
    if (props.iconLoader && typeof props.iconLoader === "function") {
      iconHandler = createIconHandler(props.iconLoader);
    } else if (parent && parent.props?.iconLoader) {
      iconHandler = createIconHandler(parent.props.iconLoader);
    } else if (props.iconLoaderUrl && typeof props.iconLoaderUrl === "function") {
      iconHandler = createIconHandler(iconHandler, props.iconLoaderUrl);
    } else {
      const iconPlugin = config?.plugins?.find((plugin2) => {
        return typeof plugin2.iconHandler === "function";
      });
      if (iconPlugin) {
        iconHandler = iconPlugin.iconHandler;
      }
    }
    watch(
      () => props.icon,
      () => {
        loadIcon();
      },
      { immediate: true }
    );
    return () => {
      if (props.icon && icon.value) {
        return h("span", {
          class: "formkit-icon",
          innerHTML: icon.value
        });
      }
      return null;
    };
  }
});
function resetCount() {
  resetCounts();
  resetCount$1();
}

export { FormKit_default as FormKit, FormKitIcon, FormKitKitchenSink, FormKitLazyProvider, FormKitMessages, FormKitProvider, FormKitRoot, FormKitSchema, FormKitSummary, bindings_default as bindings, componentSymbol, configSymbol, createInput, defaultConfig, defineFormKitConfig, getCurrentSchemaNode, onSSRComplete, optionsSymbol, parentSymbol, plugin, resetCount, rootSymbol, ssrComplete, useConfig, useFormKitContext, useFormKitContextById, useFormKitNodeById, useInput };
//# sourceMappingURL=out.js.map
//# sourceMappingURL=index.mjs.map