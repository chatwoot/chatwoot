/*  */

/**
 * constants
 */

const numberFormatKeys = [
  'compactDisplay',
  'currency',
  'currencyDisplay',
  'currencySign',
  'localeMatcher',
  'notation',
  'numberingSystem',
  'signDisplay',
  'style',
  'unit',
  'unitDisplay',
  'useGrouping',
  'minimumIntegerDigits',
  'minimumFractionDigits',
  'maximumFractionDigits',
  'minimumSignificantDigits',
  'maximumSignificantDigits'
];

/**
 * utilities
 */

function warn (msg, err) {
  if (typeof console !== 'undefined') {
    console.warn('[vue-i18n] ' + msg);
    /* istanbul ignore if */
    if (err) {
      console.warn(err.stack);
    }
  }
}

function error (msg, err) {
  if (typeof console !== 'undefined') {
    console.error('[vue-i18n] ' + msg);
    /* istanbul ignore if */
    if (err) {
      console.error(err.stack);
    }
  }
}

const isArray = Array.isArray;

function isObject (obj) {
  return obj !== null && typeof obj === 'object'
}

function isBoolean (val) {
  return typeof val === 'boolean'
}

function isString (val) {
  return typeof val === 'string'
}

const toString = Object.prototype.toString;
const OBJECT_STRING = '[object Object]';
function isPlainObject (obj) {
  return toString.call(obj) === OBJECT_STRING
}

function isNull (val) {
  return val === null || val === undefined
}

function isFunction (val) {
  return typeof val === 'function'
}

function parseArgs (...args) {
  let locale = null;
  let params = null;
  if (args.length === 1) {
    if (isObject(args[0]) || isArray(args[0])) {
      params = args[0];
    } else if (typeof args[0] === 'string') {
      locale = args[0];
    }
  } else if (args.length === 2) {
    if (typeof args[0] === 'string') {
      locale = args[0];
    }
    /* istanbul ignore if */
    if (isObject(args[1]) || isArray(args[1])) {
      params = args[1];
    }
  }

  return { locale, params }
}

function looseClone (obj) {
  return JSON.parse(JSON.stringify(obj))
}

function remove (arr, item) {
  if (arr.delete(item)) {
    return arr
  }
}

function includes (arr, item) {
  return !!~arr.indexOf(item)
}

const hasOwnProperty = Object.prototype.hasOwnProperty;
function hasOwn (obj, key) {
  return hasOwnProperty.call(obj, key)
}

function merge (target) {
  const output = Object(target);
  for (let i = 1; i < arguments.length; i++) {
    const source = arguments[i];
    if (source !== undefined && source !== null) {
      let key;
      for (key in source) {
        if (hasOwn(source, key)) {
          if (isObject(source[key])) {
            output[key] = merge(output[key], source[key]);
          } else {
            output[key] = source[key];
          }
        }
      }
    }
  }
  return output
}

function looseEqual (a, b) {
  if (a === b) { return true }
  const isObjectA = isObject(a);
  const isObjectB = isObject(b);
  if (isObjectA && isObjectB) {
    try {
      const isArrayA = isArray(a);
      const isArrayB = isArray(b);
      if (isArrayA && isArrayB) {
        return a.length === b.length && a.every((e, i) => {
          return looseEqual(e, b[i])
        })
      } else if (!isArrayA && !isArrayB) {
        const keysA = Object.keys(a);
        const keysB = Object.keys(b);
        return keysA.length === keysB.length && keysA.every((key) => {
          return looseEqual(a[key], b[key])
        })
      } else {
        /* istanbul ignore next */
        return false
      }
    } catch (e) {
      /* istanbul ignore next */
      return false
    }
  } else if (!isObjectA && !isObjectB) {
    return String(a) === String(b)
  } else {
    return false
  }
}

/**
 * Sanitizes html special characters from input strings. For mitigating risk of XSS attacks.
 * @param rawText The raw input from the user that should be escaped.
 */
function escapeHtml(rawText) {
  return rawText
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

/**
 * Escapes html tags and special symbols from all provided params which were returned from parseArgs().params.
 * This method performs an in-place operation on the params object.
 *
 * @param {any} params Parameters as provided from `parseArgs().params`.
 *                     May be either an array of strings or a string->any map.
 *
 * @returns The manipulated `params` object.
 */
function escapeParams(params) {
  if(params != null) {
    Object.keys(params).forEach(key => {
      if(typeof(params[key]) == 'string') {
        params[key] = escapeHtml(params[key]);
      }
    });
  }
  return params
}

/*  */

function extend (Vue) {
  if (!Vue.prototype.hasOwnProperty('$i18n')) {
    // $FlowFixMe
    Object.defineProperty(Vue.prototype, '$i18n', {
      get () { return this._i18n }
    });
  }

  Vue.prototype.$t = function (key, ...values) {
    const i18n = this.$i18n;
    return i18n._t(key, i18n.locale, i18n._getMessages(), this, ...values)
  };

  Vue.prototype.$tc = function (key, choice, ...values) {
    const i18n = this.$i18n;
    return i18n._tc(key, i18n.locale, i18n._getMessages(), this, choice, ...values)
  };

  Vue.prototype.$te = function (key, locale) {
    const i18n = this.$i18n;
    return i18n._te(key, i18n.locale, i18n._getMessages(), locale)
  };

  Vue.prototype.$d = function (value, ...args) {
    return this.$i18n.d(value, ...args)
  };

  Vue.prototype.$n = function (value, ...args) {
    return this.$i18n.n(value, ...args)
  };
}

/*  */

var mixin = {
  beforeCreate () {
    const options = this.$options;
    options.i18n = options.i18n || (options.__i18n ? {} : null);

    if (options.i18n) {
      if (options.i18n instanceof VueI18n) {
        // init locale messages via custom blocks
        if (options.__i18n) {
          try {
            let localeMessages = options.i18n && options.i18n.messages ? options.i18n.messages : {};
            options.__i18n.forEach(resource => {
              localeMessages = merge(localeMessages, JSON.parse(resource));
            });
            Object.keys(localeMessages).forEach((locale) => {
              options.i18n.mergeLocaleMessage(locale, localeMessages[locale]);
            });
          } catch (e) {
            {
              error(`Cannot parse locale messages via custom blocks.`, e);
            }
          }
        }
        this._i18n = options.i18n;
        this._i18nWatcher = this._i18n.watchI18nData();
      } else if (isPlainObject(options.i18n)) {
        const rootI18n = this.$root && this.$root.$i18n && this.$root.$i18n instanceof VueI18n
          ? this.$root.$i18n
          : null;
        // component local i18n
        if (rootI18n) {
          options.i18n.root = this.$root;
          options.i18n.formatter = rootI18n.formatter;
          options.i18n.fallbackLocale = rootI18n.fallbackLocale;
          options.i18n.formatFallbackMessages = rootI18n.formatFallbackMessages;
          options.i18n.silentTranslationWarn = rootI18n.silentTranslationWarn;
          options.i18n.silentFallbackWarn = rootI18n.silentFallbackWarn;
          options.i18n.pluralizationRules = rootI18n.pluralizationRules;
          options.i18n.preserveDirectiveContent = rootI18n.preserveDirectiveContent;
          this.$root.$once('hook:beforeDestroy', () => {
            options.i18n.root = null;
            options.i18n.formatter = null;
            options.i18n.fallbackLocale = null;
            options.i18n.formatFallbackMessages = null;
            options.i18n.silentTranslationWarn = null;
            options.i18n.silentFallbackWarn = null;
            options.i18n.pluralizationRules = null;
            options.i18n.preserveDirectiveContent = null;
          });
        }

        // init locale messages via custom blocks
        if (options.__i18n) {
          try {
            let localeMessages = options.i18n && options.i18n.messages ? options.i18n.messages : {};
            options.__i18n.forEach(resource => {
              localeMessages = merge(localeMessages, JSON.parse(resource));
            });
            options.i18n.messages = localeMessages;
          } catch (e) {
            {
              warn(`Cannot parse locale messages via custom blocks.`, e);
            }
          }
        }

        const { sharedMessages } = options.i18n;
        if (sharedMessages && isPlainObject(sharedMessages)) {
          options.i18n.messages = merge(options.i18n.messages, sharedMessages);
        }

        this._i18n = new VueI18n(options.i18n);
        this._i18nWatcher = this._i18n.watchI18nData();

        if (options.i18n.sync === undefined || !!options.i18n.sync) {
          this._localeWatcher = this.$i18n.watchLocale();
        }

        if (rootI18n) {
          rootI18n.onComponentInstanceCreated(this._i18n);
        }
      } else {
        {
          warn(`Cannot be interpreted 'i18n' option.`);
        }
      }
    } else if (this.$root && this.$root.$i18n && this.$root.$i18n instanceof VueI18n) {
      // root i18n
      this._i18n = this.$root.$i18n;
    } else if (options.parent && options.parent.$i18n && options.parent.$i18n instanceof VueI18n) {
      // parent i18n
      this._i18n = options.parent.$i18n;
    }
  },

  beforeMount () {
    const options = this.$options;
    options.i18n = options.i18n || (options.__i18n ? {} : null);

    if (options.i18n) {
      if (options.i18n instanceof VueI18n) {
        // init locale messages via custom blocks
        this._i18n.subscribeDataChanging(this);
        this._subscribing = true;
      } else if (isPlainObject(options.i18n)) {
        this._i18n.subscribeDataChanging(this);
        this._subscribing = true;
      } else {
        {
          warn(`Cannot be interpreted 'i18n' option.`);
        }
      }
    } else if (this.$root && this.$root.$i18n && this.$root.$i18n instanceof VueI18n) {
      this._i18n.subscribeDataChanging(this);
      this._subscribing = true;
    } else if (options.parent && options.parent.$i18n && options.parent.$i18n instanceof VueI18n) {
      this._i18n.subscribeDataChanging(this);
      this._subscribing = true;
    }
  },

  mounted () {
    if (this !== this.$root && this.$options.__INTLIFY_META__ && this.$el) {
      this.$el.setAttribute('data-intlify', this.$options.__INTLIFY_META__);
    }
  },

  beforeDestroy () {
    if (!this._i18n) { return }

    const self = this;
    this.$nextTick(() => {
      if (self._subscribing) {
        self._i18n.unsubscribeDataChanging(self);
        delete self._subscribing;
      }

      if (self._i18nWatcher) {
        self._i18nWatcher();
        self._i18n.destroyVM();
        delete self._i18nWatcher;
      }

      if (self._localeWatcher) {
        self._localeWatcher();
        delete self._localeWatcher;
      }
    });
  }
};

/*  */

var interpolationComponent = {
  name: 'i18n',
  functional: true,
  props: {
    tag: {
      type: [String, Boolean, Object],
      default: 'span'
    },
    path: {
      type: String,
      required: true
    },
    locale: {
      type: String
    },
    places: {
      type: [Array, Object]
    }
  },
  render (h, { data, parent, props, slots }) {
    const { $i18n } = parent;
    if (!$i18n) {
      {
        warn('Cannot find VueI18n instance!');
      }
      return
    }

    const { path, locale, places } = props;
    const params = slots();
    const children = $i18n.i(
      path,
      locale,
      onlyHasDefaultPlace(params) || places
        ? useLegacyPlaces(params.default, places)
        : params
    );

    const tag = (!!props.tag && props.tag !== true) || props.tag === false ? props.tag : 'span';
    return tag ? h(tag, data, children) : children
  }
};

function onlyHasDefaultPlace (params) {
  let prop;
  for (prop in params) {
    if (prop !== 'default') { return false }
  }
  return Boolean(prop)
}

function useLegacyPlaces (children, places) {
  const params = places ? createParamsFromPlaces(places) : {};

  if (!children) { return params }

  // Filter empty text nodes
  children = children.filter(child => {
    return child.tag || child.text.trim() !== ''
  });

  const everyPlace = children.every(vnodeHasPlaceAttribute);
  if (everyPlace) {
    warn('`place` attribute is deprecated in next major version. Please switch to Vue slots.');
  }

  return children.reduce(
    everyPlace ? assignChildPlace : assignChildIndex,
    params
  )
}

function createParamsFromPlaces (places) {
  {
    warn('`places` prop is deprecated in next major version. Please switch to Vue slots.');
  }

  return Array.isArray(places)
    ? places.reduce(assignChildIndex, {})
    : Object.assign({}, places)
}

function assignChildPlace (params, child) {
  if (child.data && child.data.attrs && child.data.attrs.place) {
    params[child.data.attrs.place] = child;
  }
  return params
}

function assignChildIndex (params, child, index) {
  params[index] = child;
  return params
}

function vnodeHasPlaceAttribute (vnode) {
  return Boolean(vnode.data && vnode.data.attrs && vnode.data.attrs.place)
}

/*  */

var numberComponent = {
  name: 'i18n-n',
  functional: true,
  props: {
    tag: {
      type: [String, Boolean, Object],
      default: 'span'
    },
    value: {
      type: Number,
      required: true
    },
    format: {
      type: [String, Object]
    },
    locale: {
      type: String
    }
  },
  render (h, { props, parent, data }) {
    const i18n = parent.$i18n;

    if (!i18n) {
      {
        warn('Cannot find VueI18n instance!');
      }
      return null
    }

    let key = null;
    let options = null;

    if (isString(props.format)) {
      key = props.format;
    } else if (isObject(props.format)) {
      if (props.format.key) {
        key = props.format.key;
      }

      // Filter out number format options only
      options = Object.keys(props.format).reduce((acc, prop) => {
        if (includes(numberFormatKeys, prop)) {
          return Object.assign({}, acc, { [prop]: props.format[prop] })
        }
        return acc
      }, null);
    }

    const locale = props.locale || i18n.locale;
    const parts = i18n._ntp(props.value, locale, key, options);

    const values = parts.map((part, index) => {
      const slot = data.scopedSlots && data.scopedSlots[part.type];
      return slot ? slot({ [part.type]: part.value, index, parts }) : part.value
    });

    const tag = (!!props.tag && props.tag !== true) || props.tag === false ? props.tag : 'span';
    return tag
      ? h(tag, {
        attrs: data.attrs,
        'class': data['class'],
        staticClass: data.staticClass
      }, values)
      : values
  }
};

/*  */

function bind (el, binding, vnode) {
  if (!assert(el, vnode)) { return }

  t(el, binding, vnode);
}

function update (el, binding, vnode, oldVNode) {
  if (!assert(el, vnode)) { return }

  const i18n = vnode.context.$i18n;
  if (localeEqual(el, vnode) &&
    (looseEqual(binding.value, binding.oldValue) &&
     looseEqual(el._localeMessage, i18n.getLocaleMessage(i18n.locale)))) { return }

  t(el, binding, vnode);
}

function unbind (el, binding, vnode, oldVNode) {
  const vm = vnode.context;
  if (!vm) {
    warn('Vue instance does not exists in VNode context');
    return
  }

  const i18n = vnode.context.$i18n || {};
  if (!binding.modifiers.preserve && !i18n.preserveDirectiveContent) {
    el.textContent = '';
  }
  el._vt = undefined;
  delete el['_vt'];
  el._locale = undefined;
  delete el['_locale'];
  el._localeMessage = undefined;
  delete el['_localeMessage'];
}

function assert (el, vnode) {
  const vm = vnode.context;
  if (!vm) {
    warn('Vue instance does not exists in VNode context');
    return false
  }

  if (!vm.$i18n) {
    warn('VueI18n instance does not exists in Vue instance');
    return false
  }

  return true
}

function localeEqual (el, vnode) {
  const vm = vnode.context;
  return el._locale === vm.$i18n.locale
}

function t (el, binding, vnode) {
  const value = binding.value;

  const { path, locale, args, choice } = parseValue(value);
  if (!path && !locale && !args) {
    warn('value type not supported');
    return
  }

  if (!path) {
    warn('`path` is required in v-t directive');
    return
  }

  const vm = vnode.context;
  if (choice != null) {
    el._vt = el.textContent = vm.$i18n.tc(path, choice, ...makeParams(locale, args));
  } else {
    el._vt = el.textContent = vm.$i18n.t(path, ...makeParams(locale, args));
  }
  el._locale = vm.$i18n.locale;
  el._localeMessage = vm.$i18n.getLocaleMessage(vm.$i18n.locale);
}

function parseValue (value) {
  let path;
  let locale;
  let args;
  let choice;

  if (isString(value)) {
    path = value;
  } else if (isPlainObject(value)) {
    path = value.path;
    locale = value.locale;
    args = value.args;
    choice = value.choice;
  }

  return { path, locale, args, choice }
}

function makeParams (locale, args) {
  const params = [];

  locale && params.push(locale);
  if (args && (Array.isArray(args) || isPlainObject(args))) {
    params.push(args);
  }

  return params
}

let Vue;

function install (_Vue) {
  /* istanbul ignore if */
  if (install.installed && _Vue === Vue) {
    warn('already installed.');
    return
  }
  install.installed = true;

  Vue = _Vue;

  const version = (Vue.version && Number(Vue.version.split('.')[0])) || -1;
  /* istanbul ignore if */
  if (version < 2) {
    warn(`vue-i18n (${install.version}) need to use Vue 2.0 or later (Vue: ${Vue.version}).`);
    return
  }

  extend(Vue);
  Vue.mixin(mixin);
  Vue.directive('t', { bind, update, unbind });
  Vue.component(interpolationComponent.name, interpolationComponent);
  Vue.component(numberComponent.name, numberComponent);

  // use simple mergeStrategies to prevent i18n instance lose '__proto__'
  const strats = Vue.config.optionMergeStrategies;
  strats.i18n = function (parentVal, childVal) {
    return childVal === undefined
      ? parentVal
      : childVal
  };
}

/*  */

class BaseFormatter {
  

  constructor () {
    this._caches = Object.create(null);
  }

  interpolate (message, values) {
    if (!values) {
      return [message]
    }
    let tokens = this._caches[message];
    if (!tokens) {
      tokens = parse(message);
      this._caches[message] = tokens;
    }
    return compile(tokens, values)
  }
}



const RE_TOKEN_LIST_VALUE = /^(?:\d)+/;
const RE_TOKEN_NAMED_VALUE = /^(?:\w)+/;

function parse (format) {
  const tokens = [];
  let position = 0;

  let text = '';
  while (position < format.length) {
    let char = format[position++];
    if (char === '{') {
      if (text) {
        tokens.push({ type: 'text', value: text });
      }

      text = '';
      let sub = '';
      char = format[position++];
      while (char !== undefined && char !== '}') {
        sub += char;
        char = format[position++];
      }
      const isClosed = char === '}';

      const type = RE_TOKEN_LIST_VALUE.test(sub)
        ? 'list'
        : isClosed && RE_TOKEN_NAMED_VALUE.test(sub)
          ? 'named'
          : 'unknown';
      tokens.push({ value: sub, type });
    } else if (char === '%') {
      // when found rails i18n syntax, skip text capture
      if (format[(position)] !== '{') {
        text += char;
      }
    } else {
      text += char;
    }
  }

  text && tokens.push({ type: 'text', value: text });

  return tokens
}

function compile (tokens, values) {
  const compiled = [];
  let index = 0;

  const mode = Array.isArray(values)
    ? 'list'
    : isObject(values)
      ? 'named'
      : 'unknown';
  if (mode === 'unknown') { return compiled }

  while (index < tokens.length) {
    const token = tokens[index];
    switch (token.type) {
      case 'text':
        compiled.push(token.value);
        break
      case 'list':
        compiled.push(values[parseInt(token.value, 10)]);
        break
      case 'named':
        if (mode === 'named') {
          compiled.push((values)[token.value]);
        } else {
          {
            warn(`Type of token '${token.type}' and format of value '${mode}' don't match!`);
          }
        }
        break
      case 'unknown':
        {
          warn(`Detect 'unknown' type of token!`);
        }
        break
    }
    index++;
  }

  return compiled
}

/*  */

/**
 *  Path parser
 *  - Inspired:
 *    Vue.js Path parser
 */

// actions
const APPEND = 0;
const PUSH = 1;
const INC_SUB_PATH_DEPTH = 2;
const PUSH_SUB_PATH = 3;

// states
const BEFORE_PATH = 0;
const IN_PATH = 1;
const BEFORE_IDENT = 2;
const IN_IDENT = 3;
const IN_SUB_PATH = 4;
const IN_SINGLE_QUOTE = 5;
const IN_DOUBLE_QUOTE = 6;
const AFTER_PATH = 7;
const ERROR = 8;

const pathStateMachine = [];

pathStateMachine[BEFORE_PATH] = {
  'ws': [BEFORE_PATH],
  'ident': [IN_IDENT, APPEND],
  '[': [IN_SUB_PATH],
  'eof': [AFTER_PATH]
};

pathStateMachine[IN_PATH] = {
  'ws': [IN_PATH],
  '.': [BEFORE_IDENT],
  '[': [IN_SUB_PATH],
  'eof': [AFTER_PATH]
};

pathStateMachine[BEFORE_IDENT] = {
  'ws': [BEFORE_IDENT],
  'ident': [IN_IDENT, APPEND],
  '0': [IN_IDENT, APPEND],
  'number': [IN_IDENT, APPEND]
};

pathStateMachine[IN_IDENT] = {
  'ident': [IN_IDENT, APPEND],
  '0': [IN_IDENT, APPEND],
  'number': [IN_IDENT, APPEND],
  'ws': [IN_PATH, PUSH],
  '.': [BEFORE_IDENT, PUSH],
  '[': [IN_SUB_PATH, PUSH],
  'eof': [AFTER_PATH, PUSH]
};

pathStateMachine[IN_SUB_PATH] = {
  "'": [IN_SINGLE_QUOTE, APPEND],
  '"': [IN_DOUBLE_QUOTE, APPEND],
  '[': [IN_SUB_PATH, INC_SUB_PATH_DEPTH],
  ']': [IN_PATH, PUSH_SUB_PATH],
  'eof': ERROR,
  'else': [IN_SUB_PATH, APPEND]
};

pathStateMachine[IN_SINGLE_QUOTE] = {
  "'": [IN_SUB_PATH, APPEND],
  'eof': ERROR,
  'else': [IN_SINGLE_QUOTE, APPEND]
};

pathStateMachine[IN_DOUBLE_QUOTE] = {
  '"': [IN_SUB_PATH, APPEND],
  'eof': ERROR,
  'else': [IN_DOUBLE_QUOTE, APPEND]
};

/**
 * Check if an expression is a literal value.
 */

const literalValueRE = /^\s?(?:true|false|-?[\d.]+|'[^']*'|"[^"]*")\s?$/;
function isLiteral (exp) {
  return literalValueRE.test(exp)
}

/**
 * Strip quotes from a string
 */

function stripQuotes (str) {
  const a = str.charCodeAt(0);
  const b = str.charCodeAt(str.length - 1);
  return a === b && (a === 0x22 || a === 0x27)
    ? str.slice(1, -1)
    : str
}

/**
 * Determine the type of a character in a keypath.
 */

function getPathCharType (ch) {
  if (ch === undefined || ch === null) { return 'eof' }

  const code = ch.charCodeAt(0);

  switch (code) {
    case 0x5B: // [
    case 0x5D: // ]
    case 0x2E: // .
    case 0x22: // "
    case 0x27: // '
      return ch

    case 0x5F: // _
    case 0x24: // $
    case 0x2D: // -
      return 'ident'

    case 0x09: // Tab
    case 0x0A: // Newline
    case 0x0D: // Return
    case 0xA0:  // No-break space
    case 0xFEFF:  // Byte Order Mark
    case 0x2028:  // Line Separator
    case 0x2029:  // Paragraph Separator
      return 'ws'
  }

  return 'ident'
}

/**
 * Format a subPath, return its plain form if it is
 * a literal string or number. Otherwise prepend the
 * dynamic indicator (*).
 */

function formatSubPath (path) {
  const trimmed = path.trim();
  // invalid leading 0
  if (path.charAt(0) === '0' && isNaN(path)) { return false }

  return isLiteral(trimmed) ? stripQuotes(trimmed) : '*' + trimmed
}

/**
 * Parse a string path into an array of segments
 */

function parse$1 (path) {
  const keys = [];
  let index = -1;
  let mode = BEFORE_PATH;
  let subPathDepth = 0;
  let c;
  let key;
  let newChar;
  let type;
  let transition;
  let action;
  let typeMap;
  const actions = [];

  actions[PUSH] = function () {
    if (key !== undefined) {
      keys.push(key);
      key = undefined;
    }
  };

  actions[APPEND] = function () {
    if (key === undefined) {
      key = newChar;
    } else {
      key += newChar;
    }
  };

  actions[INC_SUB_PATH_DEPTH] = function () {
    actions[APPEND]();
    subPathDepth++;
  };

  actions[PUSH_SUB_PATH] = function () {
    if (subPathDepth > 0) {
      subPathDepth--;
      mode = IN_SUB_PATH;
      actions[APPEND]();
    } else {
      subPathDepth = 0;
      if (key === undefined) { return false }
      key = formatSubPath(key);
      if (key === false) {
        return false
      } else {
        actions[PUSH]();
      }
    }
  };

  function maybeUnescapeQuote () {
    const nextChar = path[index + 1];
    if ((mode === IN_SINGLE_QUOTE && nextChar === "'") ||
      (mode === IN_DOUBLE_QUOTE && nextChar === '"')) {
      index++;
      newChar = '\\' + nextChar;
      actions[APPEND]();
      return true
    }
  }

  while (mode !== null) {
    index++;
    c = path[index];

    if (c === '\\' && maybeUnescapeQuote()) {
      continue
    }

    type = getPathCharType(c);
    typeMap = pathStateMachine[mode];
    transition = typeMap[type] || typeMap['else'] || ERROR;

    if (transition === ERROR) {
      return // parse error
    }

    mode = transition[0];
    action = actions[transition[1]];
    if (action) {
      newChar = transition[2];
      newChar = newChar === undefined
        ? c
        : newChar;
      if (action() === false) {
        return
      }
    }

    if (mode === AFTER_PATH) {
      return keys
    }
  }
}





class I18nPath {
  

  constructor () {
    this._cache = Object.create(null);
  }

  /**
   * External parse that check for a cache hit first
   */
  parsePath (path) {
    let hit = this._cache[path];
    if (!hit) {
      hit = parse$1(path);
      if (hit) {
        this._cache[path] = hit;
      }
    }
    return hit || []
  }

  /**
   * Get path value from path string
   */
  getPathValue (obj, path) {
    if (!isObject(obj)) { return null }

    const paths = this.parsePath(path);
    if (paths.length === 0) {
      return null
    } else {
      const length = paths.length;
      let last = obj;
      let i = 0;
      while (i < length) {
        const value = last[paths[i]];
        if (value === undefined || value === null) {
          return null
        }
        last = value;
        i++;
      }

      return last
    }
  }
}

/*  */



const htmlTagMatcher = /<\/?[\w\s="/.':;#-\/]+>/;
const linkKeyMatcher = /(?:@(?:\.[a-z]+)?:(?:[\w\-_|.]+|\([\w\-_|.]+\)))/g;
const linkKeyPrefixMatcher = /^@(?:\.([a-z]+))?:/;
const bracketsMatcher = /[()]/g;
const defaultModifiers = {
  'upper': str => str.toLocaleUpperCase(),
  'lower': str => str.toLocaleLowerCase(),
  'capitalize': str => `${str.charAt(0).toLocaleUpperCase()}${str.substr(1)}`
};

const defaultFormatter = new BaseFormatter();

class VueI18n {
  
  
  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  constructor (options = {}) {
    // Auto install if it is not done yet and `window` has `Vue`.
    // To allow users to avoid auto-installation in some cases,
    // this code should be placed here. See #290
    /* istanbul ignore if */
    if (!Vue && typeof window !== 'undefined' && window.Vue) {
      install(window.Vue);
    }

    const locale = options.locale || 'en-US';
    const fallbackLocale = options.fallbackLocale === false
      ? false
      : options.fallbackLocale || 'en-US';
    const messages = options.messages || {};
    const dateTimeFormats = options.dateTimeFormats || {};
    const numberFormats = options.numberFormats || {};

    this._vm = null;
    this._formatter = options.formatter || defaultFormatter;
    this._modifiers = options.modifiers || {};
    this._missing = options.missing || null;
    this._root = options.root || null;
    this._sync = options.sync === undefined ? true : !!options.sync;
    this._fallbackRoot = options.fallbackRoot === undefined
      ? true
      : !!options.fallbackRoot;
    this._formatFallbackMessages = options.formatFallbackMessages === undefined
      ? false
      : !!options.formatFallbackMessages;
    this._silentTranslationWarn = options.silentTranslationWarn === undefined
      ? false
      : options.silentTranslationWarn;
    this._silentFallbackWarn = options.silentFallbackWarn === undefined
      ? false
      : !!options.silentFallbackWarn;
    this._dateTimeFormatters = {};
    this._numberFormatters = {};
    this._path = new I18nPath();
    this._dataListeners = new Set();
    this._componentInstanceCreatedListener = options.componentInstanceCreatedListener || null;
    this._preserveDirectiveContent = options.preserveDirectiveContent === undefined
      ? false
      : !!options.preserveDirectiveContent;
    this.pluralizationRules = options.pluralizationRules || {};
    this._warnHtmlInMessage = options.warnHtmlInMessage || 'off';
    this._postTranslation = options.postTranslation || null;
    this._escapeParameterHtml = options.escapeParameterHtml || false;

    /**
     * @param choice {number} a choice index given by the input to $tc: `$tc('path.to.rule', choiceIndex)`
     * @param choicesLength {number} an overall amount of available choices
     * @returns a final choice index
    */
    this.getChoiceIndex = (choice, choicesLength) => {
      const thisPrototype = Object.getPrototypeOf(this);
      if (thisPrototype && thisPrototype.getChoiceIndex) {
        const prototypeGetChoiceIndex = (thisPrototype.getChoiceIndex);
        return (prototypeGetChoiceIndex).call(this, choice, choicesLength)
      }

      // Default (old) getChoiceIndex implementation - english-compatible
      const defaultImpl = (_choice, _choicesLength) => {
        _choice = Math.abs(_choice);

        if (_choicesLength === 2) {
          return _choice
            ? _choice > 1
              ? 1
              : 0
            : 1
        }

        return _choice ? Math.min(_choice, 2) : 0
      };

      if (this.locale in this.pluralizationRules) {
        return this.pluralizationRules[this.locale].apply(this, [choice, choicesLength])
      } else {
        return defaultImpl(choice, choicesLength)
      }
    };


    this._exist = (message, key) => {
      if (!message || !key) { return false }
      if (!isNull(this._path.getPathValue(message, key))) { return true }
      // fallback for flat key
      if (message[key]) { return true }
      return false
    };

    if (this._warnHtmlInMessage === 'warn' || this._warnHtmlInMessage === 'error') {
      Object.keys(messages).forEach(locale => {
        this._checkLocaleMessage(locale, this._warnHtmlInMessage, messages[locale]);
      });
    }

    this._initVM({
      locale,
      fallbackLocale,
      messages,
      dateTimeFormats,
      numberFormats
    });
  }

  _checkLocaleMessage (locale, level, message) {
    const paths = [];

    const fn = (level, locale, message, paths) => {
      if (isPlainObject(message)) {
        Object.keys(message).forEach(key => {
          const val = message[key];
          if (isPlainObject(val)) {
            paths.push(key);
            paths.push('.');
            fn(level, locale, val, paths);
            paths.pop();
            paths.pop();
          } else {
            paths.push(key);
            fn(level, locale, val, paths);
            paths.pop();
          }
        });
      } else if (isArray(message)) {
        message.forEach((item, index) => {
          if (isPlainObject(item)) {
            paths.push(`[${index}]`);
            paths.push('.');
            fn(level, locale, item, paths);
            paths.pop();
            paths.pop();
          } else {
            paths.push(`[${index}]`);
            fn(level, locale, item, paths);
            paths.pop();
          }
        });
      } else if (isString(message)) {
        const ret = htmlTagMatcher.test(message);
        if (ret) {
          const msg = `Detected HTML in message '${message}' of keypath '${paths.join('')}' at '${locale}'. Consider component interpolation with '<i18n>' to avoid XSS. See https://bit.ly/2ZqJzkp`;
          if (level === 'warn') {
            warn(msg);
          } else if (level === 'error') {
            error(msg);
          }
        }
      }
    };

    fn(level, locale, message, paths);
  }

  _initVM (data) {
    const silent = Vue.config.silent;
    Vue.config.silent = true;
    this._vm = new Vue({ data });
    Vue.config.silent = silent;
  }

  destroyVM () {
    this._vm.$destroy();
  }

  subscribeDataChanging (vm) {
    this._dataListeners.add(vm);
  }

  unsubscribeDataChanging (vm) {
    remove(this._dataListeners, vm);
  }

  watchI18nData () {
    const self = this;
    return this._vm.$watch('$data', () => {
      self._dataListeners.forEach(e => {
        Vue.nextTick(() => {
          e && e.$forceUpdate();
        });
      });
    }, { deep: true })
  }

  watchLocale () {
    /* istanbul ignore if */
    if (!this._sync || !this._root) { return null }
    const target = this._vm;
    return this._root.$i18n.vm.$watch('locale', (val) => {
      target.$set(target, 'locale', val);
      target.$forceUpdate();
    }, { immediate: true })
  }

  onComponentInstanceCreated (newI18n) {
    if (this._componentInstanceCreatedListener) {
      this._componentInstanceCreatedListener(newI18n, this);
    }
  }

  get vm () { return this._vm }

  get messages () { return looseClone(this._getMessages()) }
  get dateTimeFormats () { return looseClone(this._getDateTimeFormats()) }
  get numberFormats () { return looseClone(this._getNumberFormats()) }
  get availableLocales () { return Object.keys(this.messages).sort() }

  get locale () { return this._vm.locale }
  set locale (locale) {
    this._vm.$set(this._vm, 'locale', locale);
  }

  get fallbackLocale () { return this._vm.fallbackLocale }
  set fallbackLocale (locale) {
    this._localeChainCache = {};
    this._vm.$set(this._vm, 'fallbackLocale', locale);
  }

  get formatFallbackMessages () { return this._formatFallbackMessages }
  set formatFallbackMessages (fallback) { this._formatFallbackMessages = fallback; }

  get missing () { return this._missing }
  set missing (handler) { this._missing = handler; }

  get formatter () { return this._formatter }
  set formatter (formatter) { this._formatter = formatter; }

  get silentTranslationWarn () { return this._silentTranslationWarn }
  set silentTranslationWarn (silent) { this._silentTranslationWarn = silent; }

  get silentFallbackWarn () { return this._silentFallbackWarn }
  set silentFallbackWarn (silent) { this._silentFallbackWarn = silent; }

  get preserveDirectiveContent () { return this._preserveDirectiveContent }
  set preserveDirectiveContent (preserve) { this._preserveDirectiveContent = preserve; }

  get warnHtmlInMessage () { return this._warnHtmlInMessage }
  set warnHtmlInMessage (level) {
    const orgLevel = this._warnHtmlInMessage;
    this._warnHtmlInMessage = level;
    if (orgLevel !== level && (level === 'warn' || level === 'error')) {
      const messages = this._getMessages();
      Object.keys(messages).forEach(locale => {
        this._checkLocaleMessage(locale, this._warnHtmlInMessage, messages[locale]);
      });
    }
  }

  get postTranslation () { return this._postTranslation }
  set postTranslation (handler) { this._postTranslation = handler; }

  _getMessages () { return this._vm.messages }
  _getDateTimeFormats () { return this._vm.dateTimeFormats }
  _getNumberFormats () { return this._vm.numberFormats }

  _warnDefault (locale, key, result, vm, values, interpolateMode) {
    if (!isNull(result)) { return result }
    if (this._missing) {
      const missingRet = this._missing.apply(null, [locale, key, vm, values]);
      if (isString(missingRet)) {
        return missingRet
      }
    } else {
      if (!this._isSilentTranslationWarn(key)) {
        warn(
          `Cannot translate the value of keypath '${key}'. ` +
          'Use the value of keypath as default.'
        );
      }
    }

    if (this._formatFallbackMessages) {
      const parsedArgs = parseArgs(...values);
      return this._render(key, interpolateMode, parsedArgs.params, key)
    } else {
      return key
    }
  }

  _isFallbackRoot (val) {
    return !val && !isNull(this._root) && this._fallbackRoot
  }

  _isSilentFallbackWarn (key) {
    return this._silentFallbackWarn instanceof RegExp
      ? this._silentFallbackWarn.test(key)
      : this._silentFallbackWarn
  }

  _isSilentFallback (locale, key) {
    return this._isSilentFallbackWarn(key) && (this._isFallbackRoot() || locale !== this.fallbackLocale)
  }

  _isSilentTranslationWarn (key) {
    return this._silentTranslationWarn instanceof RegExp
      ? this._silentTranslationWarn.test(key)
      : this._silentTranslationWarn
  }

  _interpolate (
    locale,
    message,
    key,
    host,
    interpolateMode,
    values,
    visitedLinkStack
  ) {
    if (!message) { return null }

    const pathRet = this._path.getPathValue(message, key);
    if (isArray(pathRet) || isPlainObject(pathRet)) { return pathRet }

    let ret;
    if (isNull(pathRet)) {
      /* istanbul ignore else */
      if (isPlainObject(message)) {
        ret = message[key];
        if (!(isString(ret) || isFunction(ret))) {
          if (!this._isSilentTranslationWarn(key) && !this._isSilentFallback(locale, key)) {
            warn(`Value of key '${key}' is not a string or function !`);
          }
          return null
        }
      } else {
        return null
      }
    } else {
      /* istanbul ignore else */
      if (isString(pathRet) || isFunction(pathRet)) {
        ret = pathRet;
      } else {
        if (!this._isSilentTranslationWarn(key) && !this._isSilentFallback(locale, key)) {
          warn(`Value of key '${key}' is not a string or function!`);
        }
        return null
      }
    }

    // Check for the existence of links within the translated string
    if (isString(ret) && (ret.indexOf('@:') >= 0 || ret.indexOf('@.') >= 0)) {
      ret = this._link(locale, message, ret, host, 'raw', values, visitedLinkStack);
    }

    return this._render(ret, interpolateMode, values, key)
  }

  _link (
    locale,
    message,
    str,
    host,
    interpolateMode,
    values,
    visitedLinkStack
  ) {
    let ret = str;

    // Match all the links within the local
    // We are going to replace each of
    // them with its translation
    const matches = ret.match(linkKeyMatcher);
    for (let idx in matches) {
      // ie compatible: filter custom array
      // prototype method
      if (!matches.hasOwnProperty(idx)) {
        continue
      }
      const link = matches[idx];
      const linkKeyPrefixMatches = link.match(linkKeyPrefixMatcher);
      const [linkPrefix, formatterName] = linkKeyPrefixMatches;

      // Remove the leading @:, @.case: and the brackets
      const linkPlaceholder = link.replace(linkPrefix, '').replace(bracketsMatcher, '');

      if (includes(visitedLinkStack, linkPlaceholder)) {
        {
          warn(`Circular reference found. "${link}" is already visited in the chain of ${visitedLinkStack.reverse().join(' <- ')}`);
        }
        return ret
      }
      visitedLinkStack.push(linkPlaceholder);

      // Translate the link
      let translated = this._interpolate(
        locale, message, linkPlaceholder, host,
        interpolateMode === 'raw' ? 'string' : interpolateMode,
        interpolateMode === 'raw' ? undefined : values,
        visitedLinkStack
      );

      if (this._isFallbackRoot(translated)) {
        if (!this._isSilentTranslationWarn(linkPlaceholder)) {
          warn(`Fall back to translate the link placeholder '${linkPlaceholder}' with root locale.`);
        }
        /* istanbul ignore if */
        if (!this._root) { throw Error('unexpected error') }
        const root = this._root.$i18n;
        translated = root._translate(
          root._getMessages(), root.locale, root.fallbackLocale,
          linkPlaceholder, host, interpolateMode, values
        );
      }
      translated = this._warnDefault(
        locale, linkPlaceholder, translated, host,
        isArray(values) ? values : [values],
        interpolateMode
      );

      if (this._modifiers.hasOwnProperty(formatterName)) {
        translated = this._modifiers[formatterName](translated);
      } else if (defaultModifiers.hasOwnProperty(formatterName)) {
        translated = defaultModifiers[formatterName](translated);
      }

      visitedLinkStack.pop();

      // Replace the link with the translated
      ret = !translated ? ret : ret.replace(link, translated);
    }

    return ret
  }

  _createMessageContext (values) {
    const _list = isArray(values) ? values : [];
    const _named = isObject(values) ? values : {};
    const list = (index) => _list[index];
    const named = (key) => _named[key];
    return {
      list,
      named
    }
  }

  _render (message, interpolateMode, values, path) {
    if (isFunction(message)) {
      return message(this._createMessageContext(values))
    }

    let ret = this._formatter.interpolate(message, values, path);

    // If the custom formatter refuses to work - apply the default one
    if (!ret) {
      ret = defaultFormatter.interpolate(message, values, path);
    }

    // if interpolateMode is **not** 'string' ('row'),
    // return the compiled data (e.g. ['foo', VNode, 'bar']) with formatter
    return interpolateMode === 'string' && !isString(ret) ? ret.join('') : ret
  }

  _appendItemToChain (chain, item, blocks) {
    let follow = false;
    if (!includes(chain, item)) {
      follow = true;
      if (item) {
        follow = item[item.length - 1] !== '!';
        item = item.replace(/!/g, '');
        chain.push(item);
        if (blocks && blocks[item]) {
          follow = blocks[item];
        }
      }
    }
    return follow
  }

  _appendLocaleToChain (chain, locale, blocks) {
    let follow;
    const tokens = locale.split('-');
    do {
      const item = tokens.join('-');
      follow = this._appendItemToChain(chain, item, blocks);
      tokens.splice(-1, 1);
    } while (tokens.length && (follow === true))
    return follow
  }

  _appendBlockToChain (chain, block, blocks) {
    let follow = true;
    for (let i = 0; (i < block.length) && (isBoolean(follow)); i++) {
      const locale = block[i];
      if (isString(locale)) {
        follow = this._appendLocaleToChain(chain, locale, blocks);
      }
    }
    return follow
  }

  _getLocaleChain (start, fallbackLocale) {
    if (start === '') { return [] }

    if (!this._localeChainCache) {
      this._localeChainCache = {};
    }

    let chain = this._localeChainCache[start];
    if (!chain) {
      if (!fallbackLocale) {
        fallbackLocale = this.fallbackLocale;
      }
      chain = [];

      // first block defined by start
      let block = [start];

      // while any intervening block found
      while (isArray(block)) {
        block = this._appendBlockToChain(
          chain,
          block,
          fallbackLocale
        );
      }

      // last block defined by default
      let defaults;
      if (isArray(fallbackLocale)) {
        defaults = fallbackLocale;
      } else if (isObject(fallbackLocale)) {
        /* $FlowFixMe */
        if (fallbackLocale['default']) {
          defaults = fallbackLocale['default'];
        } else {
          defaults = null;
        }
      } else {
        defaults = fallbackLocale;
      }

      // convert defaults to array
      if (isString(defaults)) {
        block = [defaults];
      } else {
        block = defaults;
      }
      if (block) {
        this._appendBlockToChain(
          chain,
          block,
          null
        );
      }
      this._localeChainCache[start] = chain;
    }
    return chain
  }

  _translate (
    messages,
    locale,
    fallback,
    key,
    host,
    interpolateMode,
    args
  ) {
    const chain = this._getLocaleChain(locale, fallback);
    let res;
    for (let i = 0; i < chain.length; i++) {
      const step = chain[i];
      res =
        this._interpolate(step, messages[step], key, host, interpolateMode, args, [key]);
      if (!isNull(res)) {
        if (step !== locale && "development" !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
          warn(("Fall back to translate the keypath '" + key + "' with '" + step + "' locale."));
        }
        return res
      }
    }
    return null
  }

  _t (key, _locale, messages, host, ...values) {
    if (!key) { return '' }

    const parsedArgs = parseArgs(...values);
    if(this._escapeParameterHtml) {
      parsedArgs.params = escapeParams(parsedArgs.params);
    }

    const locale = parsedArgs.locale || _locale;

    let ret = this._translate(
      messages, locale, this.fallbackLocale, key,
      host, 'string', parsedArgs.params
    );
    if (this._isFallbackRoot(ret)) {
      if (!this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
        warn(`Fall back to translate the keypath '${key}' with root locale.`);
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$t(key, ...values)
    } else {
      ret = this._warnDefault(locale, key, ret, host, values, 'string');
      if (this._postTranslation && ret !== null && ret !== undefined) {
        ret = this._postTranslation(ret, key);
      }
      return ret
    }
  }

  t (key, ...values) {
    return this._t(key, this.locale, this._getMessages(), null, ...values)
  }

  _i (key, locale, messages, host, values) {
    const ret =
      this._translate(messages, locale, this.fallbackLocale, key, host, 'raw', values);
    if (this._isFallbackRoot(ret)) {
      if (!this._isSilentTranslationWarn(key)) {
        warn(`Fall back to interpolate the keypath '${key}' with root locale.`);
      }
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n.i(key, locale, values)
    } else {
      return this._warnDefault(locale, key, ret, host, [values], 'raw')
    }
  }

  i (key, locale, values) {
    /* istanbul ignore if */
    if (!key) { return '' }

    if (!isString(locale)) {
      locale = this.locale;
    }

    return this._i(key, locale, this._getMessages(), null, values)
  }

  _tc (
    key,
    _locale,
    messages,
    host,
    choice,
    ...values
  ) {
    if (!key) { return '' }
    if (choice === undefined) {
      choice = 1;
    }

    const predefined = { 'count': choice, 'n': choice };
    const parsedArgs = parseArgs(...values);
    parsedArgs.params = Object.assign(predefined, parsedArgs.params);
    values = parsedArgs.locale === null ? [parsedArgs.params] : [parsedArgs.locale, parsedArgs.params];
    return this.fetchChoice(this._t(key, _locale, messages, host, ...values), choice)
  }

  fetchChoice (message, choice) {
    /* istanbul ignore if */
    if (!message || !isString(message)) { return null }
    const choices = message.split('|');

    choice = this.getChoiceIndex(choice, choices.length);
    if (!choices[choice]) { return message }
    return choices[choice].trim()
  }

  tc (key, choice, ...values) {
    return this._tc(key, this.locale, this._getMessages(), null, choice, ...values)
  }

  _te (key, locale, messages, ...args) {
    const _locale = parseArgs(...args).locale || locale;
    return this._exist(messages[_locale], key)
  }

  te (key, locale) {
    return this._te(key, this.locale, this._getMessages(), locale)
  }

  getLocaleMessage (locale) {
    return looseClone(this._vm.messages[locale] || {})
  }

  setLocaleMessage (locale, message) {
    if (this._warnHtmlInMessage === 'warn' || this._warnHtmlInMessage === 'error') {
      this._checkLocaleMessage(locale, this._warnHtmlInMessage, message);
    }
    this._vm.$set(this._vm.messages, locale, message);
  }

  mergeLocaleMessage (locale, message) {
    if (this._warnHtmlInMessage === 'warn' || this._warnHtmlInMessage === 'error') {
      this._checkLocaleMessage(locale, this._warnHtmlInMessage, message);
    }
    this._vm.$set(this._vm.messages, locale, merge(
      typeof this._vm.messages[locale] !== 'undefined' && Object.keys(this._vm.messages[locale]).length
        ? this._vm.messages[locale]
        : {},
      message
    ));
  }

  getDateTimeFormat (locale) {
    return looseClone(this._vm.dateTimeFormats[locale] || {})
  }

  setDateTimeFormat (locale, format) {
    this._vm.$set(this._vm.dateTimeFormats, locale, format);
    this._clearDateTimeFormat(locale, format);
  }

  mergeDateTimeFormat (locale, format) {
    this._vm.$set(this._vm.dateTimeFormats, locale, merge(this._vm.dateTimeFormats[locale] || {}, format));
    this._clearDateTimeFormat(locale, format);
  }

  _clearDateTimeFormat (locale, format) {
    for (let key in format) {
      const id = `${locale}__${key}`;

      if (!this._dateTimeFormatters.hasOwnProperty(id)) {
        continue
      }

      delete this._dateTimeFormatters[id];
    }
  }

  _localizeDateTime (
    value,
    locale,
    fallback,
    dateTimeFormats,
    key
  ) {
    let _locale = locale;
    let formats = dateTimeFormats[_locale];

    const chain = this._getLocaleChain(locale, fallback);
    for (let i = 0; i < chain.length; i++) {
      const current = _locale;
      const step = chain[i];
      formats = dateTimeFormats[step];
      _locale = step;
      // fallback locale
      if (isNull(formats) || isNull(formats[key])) {
        if (step !== locale && "development" !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
          warn(`Fall back to '${step}' datetime formats from '${current}' datetime formats.`);
        }
      } else {
        break
      }
    }

    if (isNull(formats) || isNull(formats[key])) {
      return null
    } else {
      const format = formats[key];
      const id = `${_locale}__${key}`;
      let formatter = this._dateTimeFormatters[id];
      if (!formatter) {
        formatter = this._dateTimeFormatters[id] = new Intl.DateTimeFormat(_locale, format);
      }
      return formatter.format(value)
    }
  }

  _d (value, locale, key) {
    /* istanbul ignore if */
    if (!VueI18n.availabilities.dateTimeFormat) {
      warn('Cannot format a Date value due to not supported Intl.DateTimeFormat.');
      return ''
    }

    if (!key) {
      return new Intl.DateTimeFormat(locale).format(value)
    }

    const ret =
      this._localizeDateTime(value, locale, this.fallbackLocale, this._getDateTimeFormats(), key);
    if (this._isFallbackRoot(ret)) {
      if (!this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
        warn(`Fall back to datetime localization of root: key '${key}'.`);
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n.d(value, key, locale)
    } else {
      return ret || ''
    }
  }

  d (value, ...args) {
    let locale = this.locale;
    let key = null;

    if (args.length === 1) {
      if (isString(args[0])) {
        key = args[0];
      } else if (isObject(args[0])) {
        if (args[0].locale) {
          locale = args[0].locale;
        }
        if (args[0].key) {
          key = args[0].key;
        }
      }
    } else if (args.length === 2) {
      if (isString(args[0])) {
        key = args[0];
      }
      if (isString(args[1])) {
        locale = args[1];
      }
    }

    return this._d(value, locale, key)
  }

  getNumberFormat (locale) {
    return looseClone(this._vm.numberFormats[locale] || {})
  }

  setNumberFormat (locale, format) {
    this._vm.$set(this._vm.numberFormats, locale, format);
    this._clearNumberFormat(locale, format);
  }

  mergeNumberFormat (locale, format) {
    this._vm.$set(this._vm.numberFormats, locale, merge(this._vm.numberFormats[locale] || {}, format));
    this._clearNumberFormat(locale, format);
  }

  _clearNumberFormat (locale, format) {
    for (let key in format) {
      const id = `${locale}__${key}`;

      if (!this._numberFormatters.hasOwnProperty(id)) {
        continue
      }

      delete this._numberFormatters[id];
    }
  }

  _getNumberFormatter (
    value,
    locale,
    fallback,
    numberFormats,
    key,
    options
  ) {
    let _locale = locale;
    let formats = numberFormats[_locale];

    const chain = this._getLocaleChain(locale, fallback);
    for (let i = 0; i < chain.length; i++) {
      const current = _locale;
      const step = chain[i];
      formats = numberFormats[step];
      _locale = step;
      // fallback locale
      if (isNull(formats) || isNull(formats[key])) {
        if (step !== locale && "development" !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
          warn(`Fall back to '${step}' number formats from '${current}' number formats.`);
        }
      } else {
        break
      }
    }

    if (isNull(formats) || isNull(formats[key])) {
      return null
    } else {
      const format = formats[key];

      let formatter;
      if (options) {
        // If options specified - create one time number formatter
        formatter = new Intl.NumberFormat(_locale, Object.assign({}, format, options));
      } else {
        const id = `${_locale}__${key}`;
        formatter = this._numberFormatters[id];
        if (!formatter) {
          formatter = this._numberFormatters[id] = new Intl.NumberFormat(_locale, format);
        }
      }
      return formatter
    }
  }

  _n (value, locale, key, options) {
    /* istanbul ignore if */
    if (!VueI18n.availabilities.numberFormat) {
      {
        warn('Cannot format a Number value due to not supported Intl.NumberFormat.');
      }
      return ''
    }

    if (!key) {
      const nf = !options ? new Intl.NumberFormat(locale) : new Intl.NumberFormat(locale, options);
      return nf.format(value)
    }

    const formatter = this._getNumberFormatter(value, locale, this.fallbackLocale, this._getNumberFormats(), key, options);
    const ret = formatter && formatter.format(value);
    if (this._isFallbackRoot(ret)) {
      if (!this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
        warn(`Fall back to number localization of root: key '${key}'.`);
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n.n(value, Object.assign({}, { key, locale }, options))
    } else {
      return ret || ''
    }
  }

  n (value, ...args) {
    let locale = this.locale;
    let key = null;
    let options = null;

    if (args.length === 1) {
      if (isString(args[0])) {
        key = args[0];
      } else if (isObject(args[0])) {
        if (args[0].locale) {
          locale = args[0].locale;
        }
        if (args[0].key) {
          key = args[0].key;
        }

        // Filter out number format options only
        options = Object.keys(args[0]).reduce((acc, key) => {
          if (includes(numberFormatKeys, key)) {
            return Object.assign({}, acc, { [key]: args[0][key] })
          }
          return acc
        }, null);
      }
    } else if (args.length === 2) {
      if (isString(args[0])) {
        key = args[0];
      }
      if (isString(args[1])) {
        locale = args[1];
      }
    }

    return this._n(value, locale, key, options)
  }

  _ntp (value, locale, key, options) {
    /* istanbul ignore if */
    if (!VueI18n.availabilities.numberFormat) {
      {
        warn('Cannot format to parts a Number value due to not supported Intl.NumberFormat.');
      }
      return []
    }

    if (!key) {
      const nf = !options ? new Intl.NumberFormat(locale) : new Intl.NumberFormat(locale, options);
      return nf.formatToParts(value)
    }

    const formatter = this._getNumberFormatter(value, locale, this.fallbackLocale, this._getNumberFormats(), key, options);
    const ret = formatter && formatter.formatToParts(value);
    if (this._isFallbackRoot(ret)) {
      if (!this._isSilentTranslationWarn(key)) {
        warn(`Fall back to format number to parts of root: key '${key}' .`);
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n._ntp(value, locale, key, options)
    } else {
      return ret || []
    }
  }
}

let availabilities;
// $FlowFixMe
Object.defineProperty(VueI18n, 'availabilities', {
  get () {
    if (!availabilities) {
      const intlDefined = typeof Intl !== 'undefined';
      availabilities = {
        dateTimeFormat: intlDefined && typeof Intl.DateTimeFormat !== 'undefined',
        numberFormat: intlDefined && typeof Intl.NumberFormat !== 'undefined'
      };
    }

    return availabilities
  }
});

VueI18n.install = install;
VueI18n.version = '8.24.3';

export default VueI18n;
