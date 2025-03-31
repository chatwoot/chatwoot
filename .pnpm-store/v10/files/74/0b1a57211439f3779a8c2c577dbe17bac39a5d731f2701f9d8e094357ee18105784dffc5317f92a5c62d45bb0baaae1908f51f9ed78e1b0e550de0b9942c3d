(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory(require("vue"));
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else if(typeof exports === 'object')
		exports["vue3-color"] = factory(require("vue"));
	else
		root["vue3-color"] = factory(root["Vue"]);
})((typeof self !== 'undefined' ? self : this), function(__WEBPACK_EXTERNAL_MODULE__7203__) {
return /******/ (function() { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ 9662:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isCallable = __webpack_require__(614);
var tryToString = __webpack_require__(6330);

var TypeError = global.TypeError;

// `Assert: IsCallable(argument) is true`
module.exports = function (argument) {
  if (isCallable(argument)) return argument;
  throw TypeError(tryToString(argument) + ' is not a function');
};


/***/ }),

/***/ 6077:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isCallable = __webpack_require__(614);

var String = global.String;
var TypeError = global.TypeError;

module.exports = function (argument) {
  if (typeof argument == 'object' || isCallable(argument)) return argument;
  throw TypeError("Can't set " + String(argument) + ' as a prototype');
};


/***/ }),

/***/ 9670:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isObject = __webpack_require__(111);

var String = global.String;
var TypeError = global.TypeError;

// `Assert: Type(argument) is Object`
module.exports = function (argument) {
  if (isObject(argument)) return argument;
  throw TypeError(String(argument) + ' is not an object');
};


/***/ }),

/***/ 1318:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var toIndexedObject = __webpack_require__(5656);
var toAbsoluteIndex = __webpack_require__(1400);
var lengthOfArrayLike = __webpack_require__(6244);

// `Array.prototype.{ indexOf, includes }` methods implementation
var createMethod = function (IS_INCLUDES) {
  return function ($this, el, fromIndex) {
    var O = toIndexedObject($this);
    var length = lengthOfArrayLike(O);
    var index = toAbsoluteIndex(fromIndex, length);
    var value;
    // Array#includes uses SameValueZero equality algorithm
    // eslint-disable-next-line no-self-compare -- NaN check
    if (IS_INCLUDES && el != el) while (length > index) {
      value = O[index++];
      // eslint-disable-next-line no-self-compare -- NaN check
      if (value != value) return true;
    // Array#indexOf ignores holes, Array#includes - not
    } else for (;length > index; index++) {
      if ((IS_INCLUDES || index in O) && O[index] === el) return IS_INCLUDES || index || 0;
    } return !IS_INCLUDES && -1;
  };
};

module.exports = {
  // `Array.prototype.includes` method
  // https://tc39.es/ecma262/#sec-array.prototype.includes
  includes: createMethod(true),
  // `Array.prototype.indexOf` method
  // https://tc39.es/ecma262/#sec-array.prototype.indexof
  indexOf: createMethod(false)
};


/***/ }),

/***/ 4326:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);

var toString = uncurryThis({}.toString);
var stringSlice = uncurryThis(''.slice);

module.exports = function (it) {
  return stringSlice(toString(it), 8, -1);
};


/***/ }),

/***/ 648:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var TO_STRING_TAG_SUPPORT = __webpack_require__(1694);
var isCallable = __webpack_require__(614);
var classofRaw = __webpack_require__(4326);
var wellKnownSymbol = __webpack_require__(5112);

var TO_STRING_TAG = wellKnownSymbol('toStringTag');
var Object = global.Object;

// ES3 wrong here
var CORRECT_ARGUMENTS = classofRaw(function () { return arguments; }()) == 'Arguments';

// fallback for IE11 Script Access Denied error
var tryGet = function (it, key) {
  try {
    return it[key];
  } catch (error) { /* empty */ }
};

// getting tag from ES6+ `Object.prototype.toString`
module.exports = TO_STRING_TAG_SUPPORT ? classofRaw : function (it) {
  var O, tag, result;
  return it === undefined ? 'Undefined' : it === null ? 'Null'
    // @@toStringTag case
    : typeof (tag = tryGet(O = Object(it), TO_STRING_TAG)) == 'string' ? tag
    // builtinTag case
    : CORRECT_ARGUMENTS ? classofRaw(O)
    // ES3 arguments fallback
    : (result = classofRaw(O)) == 'Object' && isCallable(O.callee) ? 'Arguments' : result;
};


/***/ }),

/***/ 7741:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);

var replace = uncurryThis(''.replace);

var TEST = (function (arg) { return String(Error(arg).stack); })('zxcasd');
var V8_OR_CHAKRA_STACK_ENTRY = /\n\s*at [^:]*:[^\n]*/;
var IS_V8_OR_CHAKRA_STACK = V8_OR_CHAKRA_STACK_ENTRY.test(TEST);

module.exports = function (stack, dropEntries) {
  if (IS_V8_OR_CHAKRA_STACK && typeof stack == 'string') {
    while (dropEntries--) stack = replace(stack, V8_OR_CHAKRA_STACK_ENTRY, '');
  } return stack;
};


/***/ }),

/***/ 9920:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var hasOwn = __webpack_require__(2597);
var ownKeys = __webpack_require__(3887);
var getOwnPropertyDescriptorModule = __webpack_require__(1236);
var definePropertyModule = __webpack_require__(3070);

module.exports = function (target, source, exceptions) {
  var keys = ownKeys(source);
  var defineProperty = definePropertyModule.f;
  var getOwnPropertyDescriptor = getOwnPropertyDescriptorModule.f;
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i];
    if (!hasOwn(target, key) && !(exceptions && hasOwn(exceptions, key))) {
      defineProperty(target, key, getOwnPropertyDescriptor(source, key));
    }
  }
};


/***/ }),

/***/ 8880:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var DESCRIPTORS = __webpack_require__(9781);
var definePropertyModule = __webpack_require__(3070);
var createPropertyDescriptor = __webpack_require__(9114);

module.exports = DESCRIPTORS ? function (object, key, value) {
  return definePropertyModule.f(object, key, createPropertyDescriptor(1, value));
} : function (object, key, value) {
  object[key] = value;
  return object;
};


/***/ }),

/***/ 9114:
/***/ (function(module) {

module.exports = function (bitmap, value) {
  return {
    enumerable: !(bitmap & 1),
    configurable: !(bitmap & 2),
    writable: !(bitmap & 4),
    value: value
  };
};


/***/ }),

/***/ 9781:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var fails = __webpack_require__(7293);

// Detect IE8's incomplete defineProperty implementation
module.exports = !fails(function () {
  // eslint-disable-next-line es/no-object-defineproperty -- required for testing
  return Object.defineProperty({}, 1, { get: function () { return 7; } })[1] != 7;
});


/***/ }),

/***/ 317:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isObject = __webpack_require__(111);

var document = global.document;
// typeof document.createElement is 'object' in old IE
var EXISTS = isObject(document) && isObject(document.createElement);

module.exports = function (it) {
  return EXISTS ? document.createElement(it) : {};
};


/***/ }),

/***/ 8113:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var getBuiltIn = __webpack_require__(5005);

module.exports = getBuiltIn('navigator', 'userAgent') || '';


/***/ }),

/***/ 7392:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var userAgent = __webpack_require__(8113);

var process = global.process;
var Deno = global.Deno;
var versions = process && process.versions || Deno && Deno.version;
var v8 = versions && versions.v8;
var match, version;

if (v8) {
  match = v8.split('.');
  // in old Chrome, versions of V8 isn't V8 = Chrome / 10
  // but their correct versions are not interesting for us
  version = match[0] > 0 && match[0] < 4 ? 1 : +(match[0] + match[1]);
}

// BrowserFS NodeJS `process` polyfill incorrectly set `.v8` to `0.0`
// so check `userAgent` even if `.v8` exists, but 0
if (!version && userAgent) {
  match = userAgent.match(/Edge\/(\d+)/);
  if (!match || match[1] >= 74) {
    match = userAgent.match(/Chrome\/(\d+)/);
    if (match) version = +match[1];
  }
}

module.exports = version;


/***/ }),

/***/ 748:
/***/ (function(module) {

// IE8- don't enum bug keys
module.exports = [
  'constructor',
  'hasOwnProperty',
  'isPrototypeOf',
  'propertyIsEnumerable',
  'toLocaleString',
  'toString',
  'valueOf'
];


/***/ }),

/***/ 2914:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var fails = __webpack_require__(7293);
var createPropertyDescriptor = __webpack_require__(9114);

module.exports = !fails(function () {
  var error = Error('a');
  if (!('stack' in error)) return true;
  // eslint-disable-next-line es/no-object-defineproperty -- safe
  Object.defineProperty(error, 'stack', createPropertyDescriptor(1, 7));
  return error.stack !== 7;
});


/***/ }),

/***/ 2109:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var getOwnPropertyDescriptor = (__webpack_require__(1236).f);
var createNonEnumerableProperty = __webpack_require__(8880);
var redefine = __webpack_require__(1320);
var setGlobal = __webpack_require__(3505);
var copyConstructorProperties = __webpack_require__(9920);
var isForced = __webpack_require__(4705);

/*
  options.target      - name of the target object
  options.global      - target is the global object
  options.stat        - export as static methods of target
  options.proto       - export as prototype methods of target
  options.real        - real prototype method for the `pure` version
  options.forced      - export even if the native feature is available
  options.bind        - bind methods to the target, required for the `pure` version
  options.wrap        - wrap constructors to preventing global pollution, required for the `pure` version
  options.unsafe      - use the simple assignment of property instead of delete + defineProperty
  options.sham        - add a flag to not completely full polyfills
  options.enumerable  - export as enumerable property
  options.noTargetGet - prevent calling a getter on target
  options.name        - the .name of the function if it does not match the key
*/
module.exports = function (options, source) {
  var TARGET = options.target;
  var GLOBAL = options.global;
  var STATIC = options.stat;
  var FORCED, target, key, targetProperty, sourceProperty, descriptor;
  if (GLOBAL) {
    target = global;
  } else if (STATIC) {
    target = global[TARGET] || setGlobal(TARGET, {});
  } else {
    target = (global[TARGET] || {}).prototype;
  }
  if (target) for (key in source) {
    sourceProperty = source[key];
    if (options.noTargetGet) {
      descriptor = getOwnPropertyDescriptor(target, key);
      targetProperty = descriptor && descriptor.value;
    } else targetProperty = target[key];
    FORCED = isForced(GLOBAL ? key : TARGET + (STATIC ? '.' : '#') + key, options.forced);
    // contained in target
    if (!FORCED && targetProperty !== undefined) {
      if (typeof sourceProperty == typeof targetProperty) continue;
      copyConstructorProperties(sourceProperty, targetProperty);
    }
    // add a flag to not completely full polyfills
    if (options.sham || (targetProperty && targetProperty.sham)) {
      createNonEnumerableProperty(sourceProperty, 'sham', true);
    }
    // extend global
    redefine(target, key, sourceProperty, options);
  }
};


/***/ }),

/***/ 7293:
/***/ (function(module) {

module.exports = function (exec) {
  try {
    return !!exec();
  } catch (error) {
    return true;
  }
};


/***/ }),

/***/ 2104:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var NATIVE_BIND = __webpack_require__(4374);

var FunctionPrototype = Function.prototype;
var apply = FunctionPrototype.apply;
var call = FunctionPrototype.call;

// eslint-disable-next-line es/no-reflect -- safe
module.exports = typeof Reflect == 'object' && Reflect.apply || (NATIVE_BIND ? call.bind(apply) : function () {
  return call.apply(apply, arguments);
});


/***/ }),

/***/ 4374:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var fails = __webpack_require__(7293);

module.exports = !fails(function () {
  var test = (function () { /* empty */ }).bind();
  // eslint-disable-next-line no-prototype-builtins -- safe
  return typeof test != 'function' || test.hasOwnProperty('prototype');
});


/***/ }),

/***/ 6916:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var NATIVE_BIND = __webpack_require__(4374);

var call = Function.prototype.call;

module.exports = NATIVE_BIND ? call.bind(call) : function () {
  return call.apply(call, arguments);
};


/***/ }),

/***/ 6530:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var DESCRIPTORS = __webpack_require__(9781);
var hasOwn = __webpack_require__(2597);

var FunctionPrototype = Function.prototype;
// eslint-disable-next-line es/no-object-getownpropertydescriptor -- safe
var getDescriptor = DESCRIPTORS && Object.getOwnPropertyDescriptor;

var EXISTS = hasOwn(FunctionPrototype, 'name');
// additional protection from minified / mangled / dropped function names
var PROPER = EXISTS && (function something() { /* empty */ }).name === 'something';
var CONFIGURABLE = EXISTS && (!DESCRIPTORS || (DESCRIPTORS && getDescriptor(FunctionPrototype, 'name').configurable));

module.exports = {
  EXISTS: EXISTS,
  PROPER: PROPER,
  CONFIGURABLE: CONFIGURABLE
};


/***/ }),

/***/ 1702:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var NATIVE_BIND = __webpack_require__(4374);

var FunctionPrototype = Function.prototype;
var bind = FunctionPrototype.bind;
var call = FunctionPrototype.call;
var uncurryThis = NATIVE_BIND && bind.bind(call, call);

module.exports = NATIVE_BIND ? function (fn) {
  return fn && uncurryThis(fn);
} : function (fn) {
  return fn && function () {
    return call.apply(fn, arguments);
  };
};


/***/ }),

/***/ 5005:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isCallable = __webpack_require__(614);

var aFunction = function (argument) {
  return isCallable(argument) ? argument : undefined;
};

module.exports = function (namespace, method) {
  return arguments.length < 2 ? aFunction(global[namespace]) : global[namespace] && global[namespace][method];
};


/***/ }),

/***/ 8173:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var aCallable = __webpack_require__(9662);

// `GetMethod` abstract operation
// https://tc39.es/ecma262/#sec-getmethod
module.exports = function (V, P) {
  var func = V[P];
  return func == null ? undefined : aCallable(func);
};


/***/ }),

/***/ 7854:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var check = function (it) {
  return it && it.Math == Math && it;
};

// https://github.com/zloirock/core-js/issues/86#issuecomment-115759028
module.exports =
  // eslint-disable-next-line es/no-global-this -- safe
  check(typeof globalThis == 'object' && globalThis) ||
  check(typeof window == 'object' && window) ||
  // eslint-disable-next-line no-restricted-globals -- safe
  check(typeof self == 'object' && self) ||
  check(typeof __webpack_require__.g == 'object' && __webpack_require__.g) ||
  // eslint-disable-next-line no-new-func -- fallback
  (function () { return this; })() || Function('return this')();


/***/ }),

/***/ 2597:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);
var toObject = __webpack_require__(7908);

var hasOwnProperty = uncurryThis({}.hasOwnProperty);

// `HasOwnProperty` abstract operation
// https://tc39.es/ecma262/#sec-hasownproperty
module.exports = Object.hasOwn || function hasOwn(it, key) {
  return hasOwnProperty(toObject(it), key);
};


/***/ }),

/***/ 3501:
/***/ (function(module) {

module.exports = {};


/***/ }),

/***/ 4664:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var DESCRIPTORS = __webpack_require__(9781);
var fails = __webpack_require__(7293);
var createElement = __webpack_require__(317);

// Thanks to IE8 for its funny defineProperty
module.exports = !DESCRIPTORS && !fails(function () {
  // eslint-disable-next-line es/no-object-defineproperty -- required for testing
  return Object.defineProperty(createElement('div'), 'a', {
    get: function () { return 7; }
  }).a != 7;
});


/***/ }),

/***/ 8361:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var uncurryThis = __webpack_require__(1702);
var fails = __webpack_require__(7293);
var classof = __webpack_require__(4326);

var Object = global.Object;
var split = uncurryThis(''.split);

// fallback for non-array-like ES3 and non-enumerable old V8 strings
module.exports = fails(function () {
  // throws an error in rhino, see https://github.com/mozilla/rhino/issues/346
  // eslint-disable-next-line no-prototype-builtins -- safe
  return !Object('z').propertyIsEnumerable(0);
}) ? function (it) {
  return classof(it) == 'String' ? split(it, '') : Object(it);
} : Object;


/***/ }),

/***/ 9587:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var isCallable = __webpack_require__(614);
var isObject = __webpack_require__(111);
var setPrototypeOf = __webpack_require__(7674);

// makes subclassing work correct for wrapped built-ins
module.exports = function ($this, dummy, Wrapper) {
  var NewTarget, NewTargetPrototype;
  if (
    // it can work only with native `setPrototypeOf`
    setPrototypeOf &&
    // we haven't completely correct pre-ES6 way for getting `new.target`, so use this
    isCallable(NewTarget = dummy.constructor) &&
    NewTarget !== Wrapper &&
    isObject(NewTargetPrototype = NewTarget.prototype) &&
    NewTargetPrototype !== Wrapper.prototype
  ) setPrototypeOf($this, NewTargetPrototype);
  return $this;
};


/***/ }),

/***/ 2788:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);
var isCallable = __webpack_require__(614);
var store = __webpack_require__(5465);

var functionToString = uncurryThis(Function.toString);

// this helper broken in `core-js@3.4.1-3.4.4`, so we can't use `shared` helper
if (!isCallable(store.inspectSource)) {
  store.inspectSource = function (it) {
    return functionToString(it);
  };
}

module.exports = store.inspectSource;


/***/ }),

/***/ 8340:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var isObject = __webpack_require__(111);
var createNonEnumerableProperty = __webpack_require__(8880);

// `InstallErrorCause` abstract operation
// https://tc39.es/proposal-error-cause/#sec-errorobjects-install-error-cause
module.exports = function (O, options) {
  if (isObject(options) && 'cause' in options) {
    createNonEnumerableProperty(O, 'cause', options.cause);
  }
};


/***/ }),

/***/ 9909:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var NATIVE_WEAK_MAP = __webpack_require__(8536);
var global = __webpack_require__(7854);
var uncurryThis = __webpack_require__(1702);
var isObject = __webpack_require__(111);
var createNonEnumerableProperty = __webpack_require__(8880);
var hasOwn = __webpack_require__(2597);
var shared = __webpack_require__(5465);
var sharedKey = __webpack_require__(6200);
var hiddenKeys = __webpack_require__(3501);

var OBJECT_ALREADY_INITIALIZED = 'Object already initialized';
var TypeError = global.TypeError;
var WeakMap = global.WeakMap;
var set, get, has;

var enforce = function (it) {
  return has(it) ? get(it) : set(it, {});
};

var getterFor = function (TYPE) {
  return function (it) {
    var state;
    if (!isObject(it) || (state = get(it)).type !== TYPE) {
      throw TypeError('Incompatible receiver, ' + TYPE + ' required');
    } return state;
  };
};

if (NATIVE_WEAK_MAP || shared.state) {
  var store = shared.state || (shared.state = new WeakMap());
  var wmget = uncurryThis(store.get);
  var wmhas = uncurryThis(store.has);
  var wmset = uncurryThis(store.set);
  set = function (it, metadata) {
    if (wmhas(store, it)) throw new TypeError(OBJECT_ALREADY_INITIALIZED);
    metadata.facade = it;
    wmset(store, it, metadata);
    return metadata;
  };
  get = function (it) {
    return wmget(store, it) || {};
  };
  has = function (it) {
    return wmhas(store, it);
  };
} else {
  var STATE = sharedKey('state');
  hiddenKeys[STATE] = true;
  set = function (it, metadata) {
    if (hasOwn(it, STATE)) throw new TypeError(OBJECT_ALREADY_INITIALIZED);
    metadata.facade = it;
    createNonEnumerableProperty(it, STATE, metadata);
    return metadata;
  };
  get = function (it) {
    return hasOwn(it, STATE) ? it[STATE] : {};
  };
  has = function (it) {
    return hasOwn(it, STATE);
  };
}

module.exports = {
  set: set,
  get: get,
  has: has,
  enforce: enforce,
  getterFor: getterFor
};


/***/ }),

/***/ 614:
/***/ (function(module) {

// `IsCallable` abstract operation
// https://tc39.es/ecma262/#sec-iscallable
module.exports = function (argument) {
  return typeof argument == 'function';
};


/***/ }),

/***/ 4705:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var fails = __webpack_require__(7293);
var isCallable = __webpack_require__(614);

var replacement = /#|\.prototype\./;

var isForced = function (feature, detection) {
  var value = data[normalize(feature)];
  return value == POLYFILL ? true
    : value == NATIVE ? false
    : isCallable(detection) ? fails(detection)
    : !!detection;
};

var normalize = isForced.normalize = function (string) {
  return String(string).replace(replacement, '.').toLowerCase();
};

var data = isForced.data = {};
var NATIVE = isForced.NATIVE = 'N';
var POLYFILL = isForced.POLYFILL = 'P';

module.exports = isForced;


/***/ }),

/***/ 111:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var isCallable = __webpack_require__(614);

module.exports = function (it) {
  return typeof it == 'object' ? it !== null : isCallable(it);
};


/***/ }),

/***/ 1913:
/***/ (function(module) {

module.exports = false;


/***/ }),

/***/ 2190:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var getBuiltIn = __webpack_require__(5005);
var isCallable = __webpack_require__(614);
var isPrototypeOf = __webpack_require__(7976);
var USE_SYMBOL_AS_UID = __webpack_require__(3307);

var Object = global.Object;

module.exports = USE_SYMBOL_AS_UID ? function (it) {
  return typeof it == 'symbol';
} : function (it) {
  var $Symbol = getBuiltIn('Symbol');
  return isCallable($Symbol) && isPrototypeOf($Symbol.prototype, Object(it));
};


/***/ }),

/***/ 6244:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var toLength = __webpack_require__(7466);

// `LengthOfArrayLike` abstract operation
// https://tc39.es/ecma262/#sec-lengthofarraylike
module.exports = function (obj) {
  return toLength(obj.length);
};


/***/ }),

/***/ 133:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/* eslint-disable es/no-symbol -- required for testing */
var V8_VERSION = __webpack_require__(7392);
var fails = __webpack_require__(7293);

// eslint-disable-next-line es/no-object-getownpropertysymbols -- required for testing
module.exports = !!Object.getOwnPropertySymbols && !fails(function () {
  var symbol = Symbol();
  // Chrome 38 Symbol has incorrect toString conversion
  // `get-own-property-symbols` polyfill symbols converted to object are not Symbol instances
  return !String(symbol) || !(Object(symbol) instanceof Symbol) ||
    // Chrome 38-40 symbols are not inherited from DOM collections prototypes to instances
    !Symbol.sham && V8_VERSION && V8_VERSION < 41;
});


/***/ }),

/***/ 8536:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isCallable = __webpack_require__(614);
var inspectSource = __webpack_require__(2788);

var WeakMap = global.WeakMap;

module.exports = isCallable(WeakMap) && /native code/.test(inspectSource(WeakMap));


/***/ }),

/***/ 6277:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var toString = __webpack_require__(1340);

module.exports = function (argument, $default) {
  return argument === undefined ? arguments.length < 2 ? '' : $default : toString(argument);
};


/***/ }),

/***/ 3070:
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

var global = __webpack_require__(7854);
var DESCRIPTORS = __webpack_require__(9781);
var IE8_DOM_DEFINE = __webpack_require__(4664);
var V8_PROTOTYPE_DEFINE_BUG = __webpack_require__(3353);
var anObject = __webpack_require__(9670);
var toPropertyKey = __webpack_require__(4948);

var TypeError = global.TypeError;
// eslint-disable-next-line es/no-object-defineproperty -- safe
var $defineProperty = Object.defineProperty;
// eslint-disable-next-line es/no-object-getownpropertydescriptor -- safe
var $getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
var ENUMERABLE = 'enumerable';
var CONFIGURABLE = 'configurable';
var WRITABLE = 'writable';

// `Object.defineProperty` method
// https://tc39.es/ecma262/#sec-object.defineproperty
exports.f = DESCRIPTORS ? V8_PROTOTYPE_DEFINE_BUG ? function defineProperty(O, P, Attributes) {
  anObject(O);
  P = toPropertyKey(P);
  anObject(Attributes);
  if (typeof O === 'function' && P === 'prototype' && 'value' in Attributes && WRITABLE in Attributes && !Attributes[WRITABLE]) {
    var current = $getOwnPropertyDescriptor(O, P);
    if (current && current[WRITABLE]) {
      O[P] = Attributes.value;
      Attributes = {
        configurable: CONFIGURABLE in Attributes ? Attributes[CONFIGURABLE] : current[CONFIGURABLE],
        enumerable: ENUMERABLE in Attributes ? Attributes[ENUMERABLE] : current[ENUMERABLE],
        writable: false
      };
    }
  } return $defineProperty(O, P, Attributes);
} : $defineProperty : function defineProperty(O, P, Attributes) {
  anObject(O);
  P = toPropertyKey(P);
  anObject(Attributes);
  if (IE8_DOM_DEFINE) try {
    return $defineProperty(O, P, Attributes);
  } catch (error) { /* empty */ }
  if ('get' in Attributes || 'set' in Attributes) throw TypeError('Accessors not supported');
  if ('value' in Attributes) O[P] = Attributes.value;
  return O;
};


/***/ }),

/***/ 1236:
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

var DESCRIPTORS = __webpack_require__(9781);
var call = __webpack_require__(6916);
var propertyIsEnumerableModule = __webpack_require__(5296);
var createPropertyDescriptor = __webpack_require__(9114);
var toIndexedObject = __webpack_require__(5656);
var toPropertyKey = __webpack_require__(4948);
var hasOwn = __webpack_require__(2597);
var IE8_DOM_DEFINE = __webpack_require__(4664);

// eslint-disable-next-line es/no-object-getownpropertydescriptor -- safe
var $getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;

// `Object.getOwnPropertyDescriptor` method
// https://tc39.es/ecma262/#sec-object.getownpropertydescriptor
exports.f = DESCRIPTORS ? $getOwnPropertyDescriptor : function getOwnPropertyDescriptor(O, P) {
  O = toIndexedObject(O);
  P = toPropertyKey(P);
  if (IE8_DOM_DEFINE) try {
    return $getOwnPropertyDescriptor(O, P);
  } catch (error) { /* empty */ }
  if (hasOwn(O, P)) return createPropertyDescriptor(!call(propertyIsEnumerableModule.f, O, P), O[P]);
};


/***/ }),

/***/ 8006:
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {

var internalObjectKeys = __webpack_require__(6324);
var enumBugKeys = __webpack_require__(748);

var hiddenKeys = enumBugKeys.concat('length', 'prototype');

// `Object.getOwnPropertyNames` method
// https://tc39.es/ecma262/#sec-object.getownpropertynames
// eslint-disable-next-line es/no-object-getownpropertynames -- safe
exports.f = Object.getOwnPropertyNames || function getOwnPropertyNames(O) {
  return internalObjectKeys(O, hiddenKeys);
};


/***/ }),

/***/ 5181:
/***/ (function(__unused_webpack_module, exports) {

// eslint-disable-next-line es/no-object-getownpropertysymbols -- safe
exports.f = Object.getOwnPropertySymbols;


/***/ }),

/***/ 7976:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);

module.exports = uncurryThis({}.isPrototypeOf);


/***/ }),

/***/ 6324:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);
var hasOwn = __webpack_require__(2597);
var toIndexedObject = __webpack_require__(5656);
var indexOf = (__webpack_require__(1318).indexOf);
var hiddenKeys = __webpack_require__(3501);

var push = uncurryThis([].push);

module.exports = function (object, names) {
  var O = toIndexedObject(object);
  var i = 0;
  var result = [];
  var key;
  for (key in O) !hasOwn(hiddenKeys, key) && hasOwn(O, key) && push(result, key);
  // Don't enum bug & hidden keys
  while (names.length > i) if (hasOwn(O, key = names[i++])) {
    ~indexOf(result, key) || push(result, key);
  }
  return result;
};


/***/ }),

/***/ 5296:
/***/ (function(__unused_webpack_module, exports) {

"use strict";

var $propertyIsEnumerable = {}.propertyIsEnumerable;
// eslint-disable-next-line es/no-object-getownpropertydescriptor -- safe
var getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;

// Nashorn ~ JDK8 bug
var NASHORN_BUG = getOwnPropertyDescriptor && !$propertyIsEnumerable.call({ 1: 2 }, 1);

// `Object.prototype.propertyIsEnumerable` method implementation
// https://tc39.es/ecma262/#sec-object.prototype.propertyisenumerable
exports.f = NASHORN_BUG ? function propertyIsEnumerable(V) {
  var descriptor = getOwnPropertyDescriptor(this, V);
  return !!descriptor && descriptor.enumerable;
} : $propertyIsEnumerable;


/***/ }),

/***/ 7674:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/* eslint-disable no-proto -- safe */
var uncurryThis = __webpack_require__(1702);
var anObject = __webpack_require__(9670);
var aPossiblePrototype = __webpack_require__(6077);

// `Object.setPrototypeOf` method
// https://tc39.es/ecma262/#sec-object.setprototypeof
// Works with __proto__ only. Old v8 can't work with null proto objects.
// eslint-disable-next-line es/no-object-setprototypeof -- safe
module.exports = Object.setPrototypeOf || ('__proto__' in {} ? function () {
  var CORRECT_SETTER = false;
  var test = {};
  var setter;
  try {
    // eslint-disable-next-line es/no-object-getownpropertydescriptor -- safe
    setter = uncurryThis(Object.getOwnPropertyDescriptor(Object.prototype, '__proto__').set);
    setter(test, []);
    CORRECT_SETTER = test instanceof Array;
  } catch (error) { /* empty */ }
  return function setPrototypeOf(O, proto) {
    anObject(O);
    aPossiblePrototype(proto);
    if (CORRECT_SETTER) setter(O, proto);
    else O.__proto__ = proto;
    return O;
  };
}() : undefined);


/***/ }),

/***/ 2140:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var call = __webpack_require__(6916);
var isCallable = __webpack_require__(614);
var isObject = __webpack_require__(111);

var TypeError = global.TypeError;

// `OrdinaryToPrimitive` abstract operation
// https://tc39.es/ecma262/#sec-ordinarytoprimitive
module.exports = function (input, pref) {
  var fn, val;
  if (pref === 'string' && isCallable(fn = input.toString) && !isObject(val = call(fn, input))) return val;
  if (isCallable(fn = input.valueOf) && !isObject(val = call(fn, input))) return val;
  if (pref !== 'string' && isCallable(fn = input.toString) && !isObject(val = call(fn, input))) return val;
  throw TypeError("Can't convert object to primitive value");
};


/***/ }),

/***/ 3887:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var getBuiltIn = __webpack_require__(5005);
var uncurryThis = __webpack_require__(1702);
var getOwnPropertyNamesModule = __webpack_require__(8006);
var getOwnPropertySymbolsModule = __webpack_require__(5181);
var anObject = __webpack_require__(9670);

var concat = uncurryThis([].concat);

// all object keys, includes non-enumerable and symbols
module.exports = getBuiltIn('Reflect', 'ownKeys') || function ownKeys(it) {
  var keys = getOwnPropertyNamesModule.f(anObject(it));
  var getOwnPropertySymbols = getOwnPropertySymbolsModule.f;
  return getOwnPropertySymbols ? concat(keys, getOwnPropertySymbols(it)) : keys;
};


/***/ }),

/***/ 1320:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var isCallable = __webpack_require__(614);
var hasOwn = __webpack_require__(2597);
var createNonEnumerableProperty = __webpack_require__(8880);
var setGlobal = __webpack_require__(3505);
var inspectSource = __webpack_require__(2788);
var InternalStateModule = __webpack_require__(9909);
var CONFIGURABLE_FUNCTION_NAME = (__webpack_require__(6530).CONFIGURABLE);

var getInternalState = InternalStateModule.get;
var enforceInternalState = InternalStateModule.enforce;
var TEMPLATE = String(String).split('String');

(module.exports = function (O, key, value, options) {
  var unsafe = options ? !!options.unsafe : false;
  var simple = options ? !!options.enumerable : false;
  var noTargetGet = options ? !!options.noTargetGet : false;
  var name = options && options.name !== undefined ? options.name : key;
  var state;
  if (isCallable(value)) {
    if (String(name).slice(0, 7) === 'Symbol(') {
      name = '[' + String(name).replace(/^Symbol\(([^)]*)\)/, '$1') + ']';
    }
    if (!hasOwn(value, 'name') || (CONFIGURABLE_FUNCTION_NAME && value.name !== name)) {
      createNonEnumerableProperty(value, 'name', name);
    }
    state = enforceInternalState(value);
    if (!state.source) {
      state.source = TEMPLATE.join(typeof name == 'string' ? name : '');
    }
  }
  if (O === global) {
    if (simple) O[key] = value;
    else setGlobal(key, value);
    return;
  } else if (!unsafe) {
    delete O[key];
  } else if (!noTargetGet && O[key]) {
    simple = true;
  }
  if (simple) O[key] = value;
  else createNonEnumerableProperty(O, key, value);
// add fake Function#toString for correct work wrapped methods / constructors with methods like LoDash isNative
})(Function.prototype, 'toString', function toString() {
  return isCallable(this) && getInternalState(this).source || inspectSource(this);
});


/***/ }),

/***/ 4488:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);

var TypeError = global.TypeError;

// `RequireObjectCoercible` abstract operation
// https://tc39.es/ecma262/#sec-requireobjectcoercible
module.exports = function (it) {
  if (it == undefined) throw TypeError("Can't call method on " + it);
  return it;
};


/***/ }),

/***/ 3505:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);

// eslint-disable-next-line es/no-object-defineproperty -- safe
var defineProperty = Object.defineProperty;

module.exports = function (key, value) {
  try {
    defineProperty(global, key, { value: value, configurable: true, writable: true });
  } catch (error) {
    global[key] = value;
  } return value;
};


/***/ }),

/***/ 6200:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var shared = __webpack_require__(2309);
var uid = __webpack_require__(9711);

var keys = shared('keys');

module.exports = function (key) {
  return keys[key] || (keys[key] = uid(key));
};


/***/ }),

/***/ 5465:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var setGlobal = __webpack_require__(3505);

var SHARED = '__core-js_shared__';
var store = global[SHARED] || setGlobal(SHARED, {});

module.exports = store;


/***/ }),

/***/ 2309:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var IS_PURE = __webpack_require__(1913);
var store = __webpack_require__(5465);

(module.exports = function (key, value) {
  return store[key] || (store[key] = value !== undefined ? value : {});
})('versions', []).push({
  version: '3.21.1',
  mode: IS_PURE ? 'pure' : 'global',
  copyright: '© 2014-2022 Denis Pushkarev (zloirock.ru)',
  license: 'https://github.com/zloirock/core-js/blob/v3.21.1/LICENSE',
  source: 'https://github.com/zloirock/core-js'
});


/***/ }),

/***/ 1400:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var toIntegerOrInfinity = __webpack_require__(9303);

var max = Math.max;
var min = Math.min;

// Helper for a popular repeating case of the spec:
// Let integer be ? ToInteger(index).
// If integer < 0, let result be max((length + integer), 0); else let result be min(integer, length).
module.exports = function (index, length) {
  var integer = toIntegerOrInfinity(index);
  return integer < 0 ? max(integer + length, 0) : min(integer, length);
};


/***/ }),

/***/ 5656:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// toObject with fallback for non-array-like ES3 strings
var IndexedObject = __webpack_require__(8361);
var requireObjectCoercible = __webpack_require__(4488);

module.exports = function (it) {
  return IndexedObject(requireObjectCoercible(it));
};


/***/ }),

/***/ 9303:
/***/ (function(module) {

var ceil = Math.ceil;
var floor = Math.floor;

// `ToIntegerOrInfinity` abstract operation
// https://tc39.es/ecma262/#sec-tointegerorinfinity
module.exports = function (argument) {
  var number = +argument;
  // eslint-disable-next-line no-self-compare -- safe
  return number !== number || number === 0 ? 0 : (number > 0 ? floor : ceil)(number);
};


/***/ }),

/***/ 7466:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var toIntegerOrInfinity = __webpack_require__(9303);

var min = Math.min;

// `ToLength` abstract operation
// https://tc39.es/ecma262/#sec-tolength
module.exports = function (argument) {
  return argument > 0 ? min(toIntegerOrInfinity(argument), 0x1FFFFFFFFFFFFF) : 0; // 2 ** 53 - 1 == 9007199254740991
};


/***/ }),

/***/ 7908:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var requireObjectCoercible = __webpack_require__(4488);

var Object = global.Object;

// `ToObject` abstract operation
// https://tc39.es/ecma262/#sec-toobject
module.exports = function (argument) {
  return Object(requireObjectCoercible(argument));
};


/***/ }),

/***/ 7593:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var call = __webpack_require__(6916);
var isObject = __webpack_require__(111);
var isSymbol = __webpack_require__(2190);
var getMethod = __webpack_require__(8173);
var ordinaryToPrimitive = __webpack_require__(2140);
var wellKnownSymbol = __webpack_require__(5112);

var TypeError = global.TypeError;
var TO_PRIMITIVE = wellKnownSymbol('toPrimitive');

// `ToPrimitive` abstract operation
// https://tc39.es/ecma262/#sec-toprimitive
module.exports = function (input, pref) {
  if (!isObject(input) || isSymbol(input)) return input;
  var exoticToPrim = getMethod(input, TO_PRIMITIVE);
  var result;
  if (exoticToPrim) {
    if (pref === undefined) pref = 'default';
    result = call(exoticToPrim, input, pref);
    if (!isObject(result) || isSymbol(result)) return result;
    throw TypeError("Can't convert object to primitive value");
  }
  if (pref === undefined) pref = 'number';
  return ordinaryToPrimitive(input, pref);
};


/***/ }),

/***/ 4948:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var toPrimitive = __webpack_require__(7593);
var isSymbol = __webpack_require__(2190);

// `ToPropertyKey` abstract operation
// https://tc39.es/ecma262/#sec-topropertykey
module.exports = function (argument) {
  var key = toPrimitive(argument, 'string');
  return isSymbol(key) ? key : key + '';
};


/***/ }),

/***/ 1694:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var wellKnownSymbol = __webpack_require__(5112);

var TO_STRING_TAG = wellKnownSymbol('toStringTag');
var test = {};

test[TO_STRING_TAG] = 'z';

module.exports = String(test) === '[object z]';


/***/ }),

/***/ 1340:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var classof = __webpack_require__(648);

var String = global.String;

module.exports = function (argument) {
  if (classof(argument) === 'Symbol') throw TypeError('Cannot convert a Symbol value to a string');
  return String(argument);
};


/***/ }),

/***/ 6330:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);

var String = global.String;

module.exports = function (argument) {
  try {
    return String(argument);
  } catch (error) {
    return 'Object';
  }
};


/***/ }),

/***/ 9711:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var uncurryThis = __webpack_require__(1702);

var id = 0;
var postfix = Math.random();
var toString = uncurryThis(1.0.toString);

module.exports = function (key) {
  return 'Symbol(' + (key === undefined ? '' : key) + ')_' + toString(++id + postfix, 36);
};


/***/ }),

/***/ 3307:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/* eslint-disable es/no-symbol -- required for testing */
var NATIVE_SYMBOL = __webpack_require__(133);

module.exports = NATIVE_SYMBOL
  && !Symbol.sham
  && typeof Symbol.iterator == 'symbol';


/***/ }),

/***/ 3353:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var DESCRIPTORS = __webpack_require__(9781);
var fails = __webpack_require__(7293);

// V8 ~ Chrome 36-
// https://bugs.chromium.org/p/v8/issues/detail?id=3334
module.exports = DESCRIPTORS && fails(function () {
  // eslint-disable-next-line es/no-object-defineproperty -- required for testing
  return Object.defineProperty(function () { /* empty */ }, 'prototype', {
    value: 42,
    writable: false
  }).prototype != 42;
});


/***/ }),

/***/ 5112:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var global = __webpack_require__(7854);
var shared = __webpack_require__(2309);
var hasOwn = __webpack_require__(2597);
var uid = __webpack_require__(9711);
var NATIVE_SYMBOL = __webpack_require__(133);
var USE_SYMBOL_AS_UID = __webpack_require__(3307);

var WellKnownSymbolsStore = shared('wks');
var Symbol = global.Symbol;
var symbolFor = Symbol && Symbol['for'];
var createWellKnownSymbol = USE_SYMBOL_AS_UID ? Symbol : Symbol && Symbol.withoutSetter || uid;

module.exports = function (name) {
  if (!hasOwn(WellKnownSymbolsStore, name) || !(NATIVE_SYMBOL || typeof WellKnownSymbolsStore[name] == 'string')) {
    var description = 'Symbol.' + name;
    if (NATIVE_SYMBOL && hasOwn(Symbol, name)) {
      WellKnownSymbolsStore[name] = Symbol[name];
    } else if (USE_SYMBOL_AS_UID && symbolFor) {
      WellKnownSymbolsStore[name] = symbolFor(description);
    } else {
      WellKnownSymbolsStore[name] = createWellKnownSymbol(description);
    }
  } return WellKnownSymbolsStore[name];
};


/***/ }),

/***/ 9191:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

"use strict";

var getBuiltIn = __webpack_require__(5005);
var hasOwn = __webpack_require__(2597);
var createNonEnumerableProperty = __webpack_require__(8880);
var isPrototypeOf = __webpack_require__(7976);
var setPrototypeOf = __webpack_require__(7674);
var copyConstructorProperties = __webpack_require__(9920);
var inheritIfRequired = __webpack_require__(9587);
var normalizeStringArgument = __webpack_require__(6277);
var installErrorCause = __webpack_require__(8340);
var clearErrorStack = __webpack_require__(7741);
var ERROR_STACK_INSTALLABLE = __webpack_require__(2914);
var IS_PURE = __webpack_require__(1913);

module.exports = function (FULL_NAME, wrapper, FORCED, IS_AGGREGATE_ERROR) {
  var OPTIONS_POSITION = IS_AGGREGATE_ERROR ? 2 : 1;
  var path = FULL_NAME.split('.');
  var ERROR_NAME = path[path.length - 1];
  var OriginalError = getBuiltIn.apply(null, path);

  if (!OriginalError) return;

  var OriginalErrorPrototype = OriginalError.prototype;

  // V8 9.3- bug https://bugs.chromium.org/p/v8/issues/detail?id=12006
  if (!IS_PURE && hasOwn(OriginalErrorPrototype, 'cause')) delete OriginalErrorPrototype.cause;

  if (!FORCED) return OriginalError;

  var BaseError = getBuiltIn('Error');

  var WrappedError = wrapper(function (a, b) {
    var message = normalizeStringArgument(IS_AGGREGATE_ERROR ? b : a, undefined);
    var result = IS_AGGREGATE_ERROR ? new OriginalError(a) : new OriginalError();
    if (message !== undefined) createNonEnumerableProperty(result, 'message', message);
    if (ERROR_STACK_INSTALLABLE) createNonEnumerableProperty(result, 'stack', clearErrorStack(result.stack, 2));
    if (this && isPrototypeOf(OriginalErrorPrototype, this)) inheritIfRequired(result, this, WrappedError);
    if (arguments.length > OPTIONS_POSITION) installErrorCause(result, arguments[OPTIONS_POSITION]);
    return result;
  });

  WrappedError.prototype = OriginalErrorPrototype;

  if (ERROR_NAME !== 'Error') {
    if (setPrototypeOf) setPrototypeOf(WrappedError, BaseError);
    else copyConstructorProperties(WrappedError, BaseError, { name: true });
  }

  copyConstructorProperties(WrappedError, OriginalError);

  if (!IS_PURE) try {
    // Safari 13- bug: WebAssembly errors does not have a proper `.name`
    if (OriginalErrorPrototype.name !== ERROR_NAME) {
      createNonEnumerableProperty(OriginalErrorPrototype, 'name', ERROR_NAME);
    }
    OriginalErrorPrototype.constructor = WrappedError;
  } catch (error) { /* empty */ }

  return WrappedError;
};


/***/ }),

/***/ 1703:
/***/ (function(__unused_webpack_module, __unused_webpack_exports, __webpack_require__) {

/* eslint-disable no-unused-vars -- required for functions `.length` */
var $ = __webpack_require__(2109);
var global = __webpack_require__(7854);
var apply = __webpack_require__(2104);
var wrapErrorConstructorWithCause = __webpack_require__(9191);

var WEB_ASSEMBLY = 'WebAssembly';
var WebAssembly = global[WEB_ASSEMBLY];

var FORCED = Error('e', { cause: 7 }).cause !== 7;

var exportGlobalErrorCauseWrapper = function (ERROR_NAME, wrapper) {
  var O = {};
  O[ERROR_NAME] = wrapErrorConstructorWithCause(ERROR_NAME, wrapper, FORCED);
  $({ global: true, forced: FORCED }, O);
};

var exportWebAssemblyErrorCauseWrapper = function (ERROR_NAME, wrapper) {
  if (WebAssembly && WebAssembly[ERROR_NAME]) {
    var O = {};
    O[ERROR_NAME] = wrapErrorConstructorWithCause(WEB_ASSEMBLY + '.' + ERROR_NAME, wrapper, FORCED);
    $({ target: WEB_ASSEMBLY, stat: true, forced: FORCED }, O);
  }
};

// https://github.com/tc39/proposal-error-cause
exportGlobalErrorCauseWrapper('Error', function (init) {
  return function Error(message) { return apply(init, this, arguments); };
});
exportGlobalErrorCauseWrapper('EvalError', function (init) {
  return function EvalError(message) { return apply(init, this, arguments); };
});
exportGlobalErrorCauseWrapper('RangeError', function (init) {
  return function RangeError(message) { return apply(init, this, arguments); };
});
exportGlobalErrorCauseWrapper('ReferenceError', function (init) {
  return function ReferenceError(message) { return apply(init, this, arguments); };
});
exportGlobalErrorCauseWrapper('SyntaxError', function (init) {
  return function SyntaxError(message) { return apply(init, this, arguments); };
});
exportGlobalErrorCauseWrapper('TypeError', function (init) {
  return function TypeError(message) { return apply(init, this, arguments); };
});
exportGlobalErrorCauseWrapper('URIError', function (init) {
  return function URIError(message) { return apply(init, this, arguments); };
});
exportWebAssemblyErrorCauseWrapper('CompileError', function (init) {
  return function CompileError(message) { return apply(init, this, arguments); };
});
exportWebAssemblyErrorCauseWrapper('LinkError', function (init) {
  return function LinkError(message) { return apply(init, this, arguments); };
});
exportWebAssemblyErrorCauseWrapper('RuntimeError', function (init) {
  return function RuntimeError(message) { return apply(init, this, arguments); };
});


/***/ }),

/***/ 5959:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-chrome{background:#fff;border-radius:2px;box-shadow:0 0 2px rgba(0,0,0,.3),0 4px 8px rgba(0,0,0,.3);box-sizing:initial;width:225px;font-family:Menlo;background-color:#fff}.vc-chrome-controls{display:flex}.vc-chrome-color-wrap{position:relative;width:36px}.vc-chrome-active-color{position:relative;width:30px;height:30px;border-radius:15px;overflow:hidden;z-index:1}.vc-chrome-color-wrap .vc-checkerboard{width:30px;height:30px;border-radius:15px;background-size:auto}.vc-chrome-sliders{flex:1}.vc-chrome-fields-wrap{display:flex;padding-top:16px}.vc-chrome-fields{display:flex;margin-left:-6px;flex:1}.vc-chrome-field{padding-left:6px;width:100%}.vc-chrome-toggle-btn{width:32px;text-align:right;position:relative}.vc-chrome-toggle-icon{margin-right:-4px;margin-top:12px;cursor:pointer;position:relative;z-index:2}.vc-chrome-toggle-icon-highlight{position:absolute;width:24px;height:28px;background:#eee;border-radius:4px;top:10px;left:12px}.vc-chrome-hue-wrap{margin-bottom:8px}.vc-chrome-alpha-wrap,.vc-chrome-hue-wrap{position:relative;height:10px}.vc-chrome-alpha-wrap .vc-alpha-gradient,.vc-chrome-hue-wrap .vc-hue{border-radius:2px}.vc-chrome-alpha-wrap .vc-alpha-picker,.vc-chrome-hue-wrap .vc-hue-picker{width:12px;height:12px;border-radius:6px;transform:translate(-6px,-2px);background-color:#f8f8f8;box-shadow:0 1px 4px 0 rgba(0,0,0,.37)}.vc-chrome-body{padding:16px 16px 12px;background-color:#fff}.vc-chrome-saturation-wrap{width:100%;padding-bottom:55%;position:relative;border-radius:2px 2px 0 0;overflow:hidden}.vc-chrome-saturation-wrap .vc-saturation-circle{width:12px;height:12px}.vc-chrome-fields .vc-input__input{font-size:11px;color:#333;width:100%;border-radius:2px;border:none;box-shadow:inset 0 0 0 1px #dadada;height:21px;text-align:center}.vc-chrome-fields .vc-input__label{text-transform:uppercase;font-size:11px;line-height:11px;color:#969696;text-align:center;display:block;margin-top:12px}.vc-chrome__disable-alpha .vc-chrome-active-color{width:18px;height:18px}.vc-chrome__disable-alpha .vc-chrome-color-wrap{width:30px}.vc-chrome__disable-alpha .vc-chrome-hue-wrap{margin-top:4px;margin-bottom:4px}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 4368:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-compact{padding-top:5px;padding-left:5px;width:245px;border-radius:2px;box-sizing:border-box;box-shadow:0 2px 10px rgba(0,0,0,.12),0 2px 5px rgba(0,0,0,.16);background-color:#fff}.vc-compact-colors{overflow:hidden;padding:0;margin:0}.vc-compact-color-item{list-style:none;width:15px;height:15px;float:left;margin-right:5px;margin-bottom:5px;position:relative;cursor:pointer}.vc-compact-color-item--white{box-shadow:inset 0 0 0 1px #ddd}.vc-compact-color-item--white .vc-compact-dot{background:#000}.vc-compact-dot{position:absolute;top:5px;right:5px;bottom:5px;left:5px;border-radius:50%;opacity:1;background:#fff}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 3075:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-grayscale{width:125px;border-radius:2px;box-shadow:0 2px 15px rgba(0,0,0,.12),0 2px 10px rgba(0,0,0,.16);background-color:#fff}.vc-grayscale-colors{border-radius:2px;overflow:hidden;padding:0;margin:0}.vc-grayscale-color-item{list-style:none;width:25px;height:25px;float:left;position:relative;cursor:pointer}.vc-grayscale-color-item--white .vc-grayscale-dot{background:#000}.vc-grayscale-dot{position:absolute;top:50%;left:50%;width:6px;height:6px;margin:-3px 0 0 -2px;border-radius:50%;opacity:1;background:#fff}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 8061:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-material{width:98px;height:98px;padding:16px;font-family:Roboto;position:relative;border-radius:2px;box-shadow:0 2px 10px rgba(0,0,0,.12),0 2px 5px rgba(0,0,0,.16);background-color:#fff}.vc-material .vc-input__input{width:100%;margin-top:12px;font-size:15px;color:#333;height:30px}.vc-material .vc-input__label{position:absolute;top:0;left:0;font-size:11px;color:#999;text-transform:capitalize}.vc-material-hex{border-bottom-width:2px;border-bottom-style:solid}.vc-material-split{display:flex;margin-right:-10px;padding-top:11px}.vc-material-third{flex:1;padding-right:10px}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 5175:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-photoshop{background:#dcdcdc;border-radius:4px;box-shadow:0 0 0 1px rgba(0,0,0,.25),0 8px 16px rgba(0,0,0,.15);box-sizing:initial;width:513px;font-family:Roboto}.vc-photoshop__disable-fields{width:390px}.vc-ps-head{background-image:linear-gradient(-180deg,#f0f0f0,#d4d4d4);border-bottom:1px solid #b1b1b1;box-shadow:inset 0 1px 0 0 hsla(0,0%,100%,.2),inset 0 -1px 0 0 rgba(0,0,0,.02);height:23px;line-height:24px;border-radius:4px 4px 0 0;font-size:13px;color:#4d4d4d;text-align:center}.vc-ps-body{padding:15px;display:flex}.vc-ps-saturation-wrap{width:256px;height:256px;position:relative;border:2px solid #b3b3b3;border-bottom:2px solid #f0f0f0;overflow:hidden}.vc-ps-saturation-wrap .vc-saturation-circle{width:12px;height:12px}.vc-ps-hue-wrap{height:256px;width:19px;margin-left:10px;border:2px solid #b3b3b3;border-bottom:2px solid #f0f0f0}.vc-ps-hue-pointer,.vc-ps-hue-wrap{position:relative}.vc-ps-hue-pointer--left,.vc-ps-hue-pointer--right{position:absolute;width:0;height:0;border-style:solid;border-width:5px 0 5px 8px;border-color:transparent transparent transparent #555}.vc-ps-hue-pointer--left:after,.vc-ps-hue-pointer--right:after{content:\"\";width:0;height:0;border-style:solid;border-width:4px 0 4px 6px;border-color:transparent transparent transparent #fff;position:absolute;top:1px;left:1px;transform:translate(-8px,-5px)}.vc-ps-hue-pointer--left{transform:translate(-13px,-4px)}.vc-ps-hue-pointer--right{transform:translate(20px,-4px) rotate(180deg)}.vc-ps-controls{width:180px;margin-left:10px;display:flex}.vc-ps-controls__disable-fields{width:auto}.vc-ps-actions{margin-left:20px;flex:1}.vc-ps-ac-btn{cursor:pointer;background-image:linear-gradient(-180deg,#fff,#e6e6e6);border:1px solid #878787;border-radius:2px;height:20px;box-shadow:0 1px 0 0 #eaeaea;font-size:14px;color:#000;line-height:20px;text-align:center;margin-bottom:10px}.vc-ps-previews{width:60px}.vc-ps-previews__swatches{border:1px solid #b3b3b3;border-bottom:1px solid #f0f0f0;margin-bottom:2px;margin-top:1px}.vc-ps-previews__pr-color{height:34px;box-shadow:inset 1px 0 0 #000,inset -1px 0 0 #000,inset 0 1px 0 #000}.vc-ps-previews__label{font-size:14px;color:#000;text-align:center}.vc-ps-fields{padding-top:5px;padding-bottom:9px;width:80px;position:relative}.vc-ps-fields .vc-input__input{margin-left:40%;width:40%;height:18px;border:1px solid #888;box-shadow:inset 0 1px 1px rgba(0,0,0,.1),0 1px 0 0 #ececec;margin-bottom:5px;font-size:13px;padding-left:3px;margin-right:10px}.vc-ps-fields .vc-input__desc,.vc-ps-fields .vc-input__label{top:0;text-transform:uppercase;font-size:13px;height:18px;line-height:22px;position:absolute}.vc-ps-fields .vc-input__label{left:0;width:34px}.vc-ps-fields .vc-input__desc{right:0;width:0}.vc-ps-fields__divider{height:5px}.vc-ps-fields__hex .vc-input__input{margin-left:20%;width:80%;height:18px;border:1px solid #888;box-shadow:inset 0 1px 1px rgba(0,0,0,.1),0 1px 0 0 #ececec;margin-bottom:6px;font-size:13px;padding-left:3px}.vc-ps-fields__hex .vc-input__label{position:absolute;top:0;left:0;width:14px;text-transform:uppercase;font-size:13px;height:18px;line-height:22px}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 9610:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-sketch{position:relative;width:200px;padding:10px 10px 0;box-sizing:initial;background:#fff;border-radius:4px;box-shadow:0 0 0 1px rgba(0,0,0,.15),0 8px 16px rgba(0,0,0,.15)}.vc-sketch-saturation-wrap{width:100%;padding-bottom:75%;position:relative;overflow:hidden}.vc-sketch-controls{display:flex}.vc-sketch-sliders{padding:4px 0;flex:1}.vc-sketch-sliders .vc-alpha-gradient,.vc-sketch-sliders .vc-hue{border-radius:2px}.vc-sketch-alpha-wrap,.vc-sketch-hue-wrap{position:relative;height:10px}.vc-sketch-alpha-wrap{margin-top:4px;overflow:hidden}.vc-sketch-color-wrap{width:24px;height:24px;position:relative;margin-top:4px;margin-left:4px;border-radius:3px}.vc-sketch-active-color{position:absolute;top:0;left:0;right:0;bottom:0;border-radius:2px;box-shadow:inset 0 0 0 1px rgba(0,0,0,.15),inset 0 0 4px rgba(0,0,0,.25);z-index:2}.vc-sketch-color-wrap .vc-checkerboard{background-size:auto}.vc-sketch-field{display:flex;padding-top:4px}.vc-sketch-field .vc-input__input{width:90%;padding:4px 0 3px 10%;border:none;box-shadow:inset 0 0 0 1px #ccc;font-size:10px}.vc-sketch-field .vc-input__label{display:block;text-align:center;font-size:11px;color:#222;padding-top:3px;padding-bottom:4px;text-transform:capitalize}.vc-sketch-field--single{flex:1;padding-left:6px}.vc-sketch-field--double{flex:2}.vc-sketch-presets{margin-right:-10px;margin-left:-10px;padding-left:10px;padding-top:10px;border-top:1px solid #eee}.vc-sketch-presets-color{overflow:hidden;position:relative;display:inline-block;margin:0 10px 10px 0;vertical-align:top;cursor:pointer;width:16px;height:16px}.vc-sketch-presets-color,.vc-sketch-presets-color .vc-checkerboard{border-radius:3px;box-shadow:inset 0 0 0 1px rgba(0,0,0,.15)}.vc-sketch__disable-alpha .vc-sketch-color-wrap{height:10px}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 6774:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-slider{position:relative;width:410px}.vc-slider-hue-warp{height:12px;position:relative}.vc-slider-hue-warp .vc-hue-picker{width:14px;height:14px;border-radius:6px;transform:translate(-7px,-2px);background-color:#f8f8f8;box-shadow:0 1px 4px 0 rgba(0,0,0,.37)}.vc-slider-swatches{display:flex;margin-top:20px}.vc-slider-swatch{margin-right:1px;flex:1;width:20%}.vc-slider-swatch:first-child{margin-right:1px}.vc-slider-swatch:first-child .vc-slider-swatch-picker{border-radius:2px 0 0 2px}.vc-slider-swatch:last-child{margin-right:0}.vc-slider-swatch:last-child .vc-slider-swatch-picker{border-radius:0 2px 2px 0}.vc-slider-swatch-picker{cursor:pointer;height:12px}.vc-slider-swatch:nth-child(n) .vc-slider-swatch-picker.vc-slider-swatch-picker--active{transform:scaleY(1.8);border-radius:3.6px/2px}.vc-slider-swatch-picker--white{box-shadow:inset 0 0 0 1px #ddd}.vc-slider-swatch-picker--active.vc-slider-swatch-picker--white{box-shadow:inset 0 0 0 .6px #ddd}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 1570:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-swatches{width:320px;height:240px;overflow-y:scroll;background-color:#fff;box-shadow:0 2px 10px rgba(0,0,0,.12),0 2px 5px rgba(0,0,0,.16)}.vc-swatches-box{padding:16px 0 6px 16px;overflow:hidden}.vc-swatches-color-group{padding-bottom:10px;width:40px;float:left;margin-right:10px}.vc-swatches-color-it{box-sizing:border-box;width:40px;height:24px;cursor:pointer;background:#880e4f;margin-bottom:1px;overflow:hidden;border-radius:2px 2px 0 0}.vc-swatches-color--white{border:1px solid #ddd}.vc-swatches-pick{fill:#fff;margin-left:8px;display:block}.vc-swatches-color--white .vc-swatches-pick{fill:#333}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 9276:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-twitter{background:#fff;border:0 solid rgba(0,0,0,.25);box-shadow:0 1px 4px rgba(0,0,0,.25);border-radius:4px;position:relative}.vc-twitter-triangle{border-color:transparent transparent #fff transparent}.vc-twitter-triangle,.vc-twitter-triangle-shadow{width:0;height:0;border-style:solid;border-width:0 9px 10px 9px;position:absolute}.vc-twitter-triangle-shadow{border-color:transparent transparent rgba(0,0,0,.1) transparent}.vc-twitter-body{padding:15px 9px 9px 15px}.vc-twitter .vc-editable-input{position:relative}.vc-twitter .vc-editable-input input{width:100px;font-size:14px;color:#666;border:0;outline:none;height:28px;box-shadow:inset 0 0 0 1px #f0f0f0;box-sizing:content-box;border-radius:0 4px 4px 0;float:left;padding:1px;padding-left:8px}.vc-twitter .vc-editable-input span{display:none}.vc-twitter-hash{background:#f0f0f0;height:30px;width:30px;border-radius:4px 0 0 4px;float:left;color:#98a1a4;display:flex;align-items:center;justify-content:center}.vc-twitter-swatch{width:30px;height:30px;float:left;border-radius:4px;margin:0 6px 6px 0;cursor:pointer;position:relative;outline:none}.vc-twitter-clear{clear:both}.vc-twitter-hide-triangle .vc-twitter-triangle,.vc-twitter-hide-triangle .vc-twitter-triangle-shadow{display:none}.vc-twitter-top-left-triangle .vc-twitter-triangle{top:-10px;left:12px}.vc-twitter-top-left-triangle .vc-twitter-triangle-shadow{top:-11px;left:12px}.vc-twitter-top-right-triangle .vc-twitter-triangle{top:-10px;right:12px}.vc-twitter-top-right-triangle .vc-twitter-triangle-shadow{top:-11px;right:12px}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 9424:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-alpha,.vc-alpha-checkboard-wrap{position:absolute;top:0;right:0;bottom:0;left:0}.vc-alpha-checkboard-wrap{overflow:hidden}.vc-alpha-gradient{position:absolute;top:0;right:0;bottom:0;left:0}.vc-alpha-container{cursor:pointer;position:relative;z-index:2;height:100%;margin:0 3px}.vc-alpha-pointer{z-index:2;position:absolute}.vc-alpha-picker{cursor:pointer;width:4px;border-radius:1px;height:8px;box-shadow:0 0 2px rgba(0,0,0,.6);background:#fff;margin-top:1px;transform:translateX(-2px)}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 5916:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-checkerboard{position:absolute;top:0;right:0;bottom:0;left:0;background-size:contain}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 420:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-editable-input{position:relative}.vc-input__input{padding:0;border:0;outline:none}.vc-input__label{text-transform:capitalize}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 9178:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-hue{position:absolute;top:0;right:0;bottom:0;left:0;border-radius:2px}.vc-hue--horizontal{background:linear-gradient(90deg,red 0,#ff0 17%,#0f0 33%,#0ff 50%,#00f 67%,#f0f 83%,red)}.vc-hue--vertical{background:linear-gradient(0deg,red 0,#ff0 17%,#0f0 33%,#0ff 50%,#00f 67%,#f0f 83%,red)}.vc-hue-container{cursor:pointer;margin:0 2px;position:relative;height:100%}.vc-hue-pointer{z-index:2;position:absolute}.vc-hue-picker{cursor:pointer;margin-top:1px;width:4px;border-radius:1px;height:8px;box-shadow:0 0 2px rgba(0,0,0,.6);background:#fff;transform:translateX(-2px)}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 8651:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(8081);
/* harmony import */ var _node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0__);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(3645);
/* harmony import */ var _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(_node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1__);
// Imports


var ___CSS_LOADER_EXPORT___ = _node_modules_css_loader_dist_runtime_api_js__WEBPACK_IMPORTED_MODULE_1___default()((_node_modules_css_loader_dist_runtime_noSourceMaps_js__WEBPACK_IMPORTED_MODULE_0___default()));
// Module
___CSS_LOADER_EXPORT___.push([module.id, ".vc-saturation,.vc-saturation--black,.vc-saturation--white{cursor:pointer;position:absolute;top:0;left:0;right:0;bottom:0}.vc-saturation--white{background:linear-gradient(90deg,#fff,hsla(0,0%,100%,0))}.vc-saturation--black{background:linear-gradient(0deg,#000,transparent)}.vc-saturation-pointer{cursor:pointer;position:absolute}.vc-saturation-circle{cursor:head;width:4px;height:4px;box-shadow:0 0 0 1.5px #fff,inset 0 0 1px 1px rgba(0,0,0,.3),0 0 1px 2px rgba(0,0,0,.4);border-radius:50%;transform:translate(-2px,-2px)}", ""]);
// Exports
/* harmony default export */ __webpack_exports__["default"] = (___CSS_LOADER_EXPORT___);


/***/ }),

/***/ 3645:
/***/ (function(module) {

"use strict";


/*
  MIT License http://www.opensource.org/licenses/mit-license.php
  Author Tobias Koppers @sokra
*/
module.exports = function (cssWithMappingToString) {
  var list = []; // return the list of modules as css string

  list.toString = function toString() {
    return this.map(function (item) {
      var content = "";
      var needLayer = typeof item[5] !== "undefined";

      if (item[4]) {
        content += "@supports (".concat(item[4], ") {");
      }

      if (item[2]) {
        content += "@media ".concat(item[2], " {");
      }

      if (needLayer) {
        content += "@layer".concat(item[5].length > 0 ? " ".concat(item[5]) : "", " {");
      }

      content += cssWithMappingToString(item);

      if (needLayer) {
        content += "}";
      }

      if (item[2]) {
        content += "}";
      }

      if (item[4]) {
        content += "}";
      }

      return content;
    }).join("");
  }; // import a list of modules into the list


  list.i = function i(modules, media, dedupe, supports, layer) {
    if (typeof modules === "string") {
      modules = [[null, modules, undefined]];
    }

    var alreadyImportedModules = {};

    if (dedupe) {
      for (var k = 0; k < this.length; k++) {
        var id = this[k][0];

        if (id != null) {
          alreadyImportedModules[id] = true;
        }
      }
    }

    for (var _k = 0; _k < modules.length; _k++) {
      var item = [].concat(modules[_k]);

      if (dedupe && alreadyImportedModules[item[0]]) {
        continue;
      }

      if (typeof layer !== "undefined") {
        if (typeof item[5] === "undefined") {
          item[5] = layer;
        } else {
          item[1] = "@layer".concat(item[5].length > 0 ? " ".concat(item[5]) : "", " {").concat(item[1], "}");
          item[5] = layer;
        }
      }

      if (media) {
        if (!item[2]) {
          item[2] = media;
        } else {
          item[1] = "@media ".concat(item[2], " {").concat(item[1], "}");
          item[2] = media;
        }
      }

      if (supports) {
        if (!item[4]) {
          item[4] = "".concat(supports);
        } else {
          item[1] = "@supports (".concat(item[4], ") {").concat(item[1], "}");
          item[4] = supports;
        }
      }

      list.push(item);
    }
  };

  return list;
};

/***/ }),

/***/ 8081:
/***/ (function(module) {

"use strict";


module.exports = function (i) {
  return i[1];
};

/***/ }),

/***/ 3770:
/***/ (function(module) {

module.exports = clamp;

function clamp(value, min, max) {
  return min < max ? value < min ? min : value > max ? max : value : value < max ? max : value > min ? min : value;
}

/***/ }),

/***/ 6620:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var root = __webpack_require__(8503);
/** Built-in value references. */


var Symbol = root.Symbol;
module.exports = Symbol;

/***/ }),

/***/ 9411:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var Symbol = __webpack_require__(6620),
    getRawTag = __webpack_require__(4737),
    objectToString = __webpack_require__(2492);
/** `Object#toString` result references. */


var nullTag = '[object Null]',
    undefinedTag = '[object Undefined]';
/** Built-in value references. */

var symToStringTag = Symbol ? Symbol.toStringTag : undefined;
/**
 * The base implementation of `getTag` without fallbacks for buggy environments.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the `toStringTag`.
 */

function baseGetTag(value) {
  if (value == null) {
    return value === undefined ? undefinedTag : nullTag;
  }

  return symToStringTag && symToStringTag in Object(value) ? getRawTag(value) : objectToString(value);
}

module.exports = baseGetTag;

/***/ }),

/***/ 5349:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var trimmedEndIndex = __webpack_require__(7384);
/** Used to match leading whitespace. */


var reTrimStart = /^\s+/;
/**
 * The base implementation of `_.trim`.
 *
 * @private
 * @param {string} string The string to trim.
 * @returns {string} Returns the trimmed string.
 */

function baseTrim(string) {
  return string ? string.slice(0, trimmedEndIndex(string) + 1).replace(reTrimStart, '') : string;
}

module.exports = baseTrim;

/***/ }),

/***/ 6419:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

/** Detect free variable `global` from Node.js. */
var freeGlobal = typeof __webpack_require__.g == 'object' && __webpack_require__.g && __webpack_require__.g.Object === Object && __webpack_require__.g;
module.exports = freeGlobal;

/***/ }),

/***/ 4737:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var Symbol = __webpack_require__(6620);
/** Used for built-in method references. */


var objectProto = Object.prototype;
/** Used to check objects for own properties. */

var hasOwnProperty = objectProto.hasOwnProperty;
/**
 * Used to resolve the
 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
 * of values.
 */

var nativeObjectToString = objectProto.toString;
/** Built-in value references. */

var symToStringTag = Symbol ? Symbol.toStringTag : undefined;
/**
 * A specialized version of `baseGetTag` which ignores `Symbol.toStringTag` values.
 *
 * @private
 * @param {*} value The value to query.
 * @returns {string} Returns the raw `toStringTag`.
 */

function getRawTag(value) {
  var isOwn = hasOwnProperty.call(value, symToStringTag),
      tag = value[symToStringTag];

  try {
    value[symToStringTag] = undefined;
    var unmasked = true;
  } catch (e) {}

  var result = nativeObjectToString.call(value);

  if (unmasked) {
    if (isOwn) {
      value[symToStringTag] = tag;
    } else {
      delete value[symToStringTag];
    }
  }

  return result;
}

module.exports = getRawTag;

/***/ }),

/***/ 2492:
/***/ (function(module) {

/** Used for built-in method references. */
var objectProto = Object.prototype;
/**
 * Used to resolve the
 * [`toStringTag`](http://ecma-international.org/ecma-262/7.0/#sec-object.prototype.tostring)
 * of values.
 */

var nativeObjectToString = objectProto.toString;
/**
 * Converts `value` to a string using `Object.prototype.toString`.
 *
 * @private
 * @param {*} value The value to convert.
 * @returns {string} Returns the converted string.
 */

function objectToString(value) {
  return nativeObjectToString.call(value);
}

module.exports = objectToString;

/***/ }),

/***/ 8503:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var freeGlobal = __webpack_require__(6419);
/** Detect free variable `self`. */


var freeSelf = typeof self == 'object' && self && self.Object === Object && self;
/** Used as a reference to the global object. */

var root = freeGlobal || freeSelf || Function('return this')();
module.exports = root;

/***/ }),

/***/ 7384:
/***/ (function(module) {

/** Used to match a single whitespace character. */
var reWhitespace = /\s/;
/**
 * Used by `_.trim` and `_.trimEnd` to get the index of the last non-whitespace
 * character of `string`.
 *
 * @private
 * @param {string} string The string to inspect.
 * @returns {number} Returns the index of the last non-whitespace character.
 */

function trimmedEndIndex(string) {
  var index = string.length;

  while (index-- && reWhitespace.test(string.charAt(index))) {}

  return index;
}

module.exports = trimmedEndIndex;

/***/ }),

/***/ 2764:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

__webpack_require__(1703);

var isObject = __webpack_require__(2661),
    now = __webpack_require__(9238),
    toNumber = __webpack_require__(692);
/** Error message constants. */


var FUNC_ERROR_TEXT = 'Expected a function';
/* Built-in method references for those with the same name as other `lodash` methods. */

var nativeMax = Math.max,
    nativeMin = Math.min;
/**
 * Creates a debounced function that delays invoking `func` until after `wait`
 * milliseconds have elapsed since the last time the debounced function was
 * invoked. The debounced function comes with a `cancel` method to cancel
 * delayed `func` invocations and a `flush` method to immediately invoke them.
 * Provide `options` to indicate whether `func` should be invoked on the
 * leading and/or trailing edge of the `wait` timeout. The `func` is invoked
 * with the last arguments provided to the debounced function. Subsequent
 * calls to the debounced function return the result of the last `func`
 * invocation.
 *
 * **Note:** If `leading` and `trailing` options are `true`, `func` is
 * invoked on the trailing edge of the timeout only if the debounced function
 * is invoked more than once during the `wait` timeout.
 *
 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
 *
 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
 * for details over the differences between `_.debounce` and `_.throttle`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to debounce.
 * @param {number} [wait=0] The number of milliseconds to delay.
 * @param {Object} [options={}] The options object.
 * @param {boolean} [options.leading=false]
 *  Specify invoking on the leading edge of the timeout.
 * @param {number} [options.maxWait]
 *  The maximum time `func` is allowed to be delayed before it's invoked.
 * @param {boolean} [options.trailing=true]
 *  Specify invoking on the trailing edge of the timeout.
 * @returns {Function} Returns the new debounced function.
 * @example
 *
 * // Avoid costly calculations while the window size is in flux.
 * jQuery(window).on('resize', _.debounce(calculateLayout, 150));
 *
 * // Invoke `sendMail` when clicked, debouncing subsequent calls.
 * jQuery(element).on('click', _.debounce(sendMail, 300, {
 *   'leading': true,
 *   'trailing': false
 * }));
 *
 * // Ensure `batchLog` is invoked once after 1 second of debounced calls.
 * var debounced = _.debounce(batchLog, 250, { 'maxWait': 1000 });
 * var source = new EventSource('/stream');
 * jQuery(source).on('message', debounced);
 *
 * // Cancel the trailing debounced invocation.
 * jQuery(window).on('popstate', debounced.cancel);
 */

function debounce(func, wait, options) {
  var lastArgs,
      lastThis,
      maxWait,
      result,
      timerId,
      lastCallTime,
      lastInvokeTime = 0,
      leading = false,
      maxing = false,
      trailing = true;

  if (typeof func != 'function') {
    throw new TypeError(FUNC_ERROR_TEXT);
  }

  wait = toNumber(wait) || 0;

  if (isObject(options)) {
    leading = !!options.leading;
    maxing = 'maxWait' in options;
    maxWait = maxing ? nativeMax(toNumber(options.maxWait) || 0, wait) : maxWait;
    trailing = 'trailing' in options ? !!options.trailing : trailing;
  }

  function invokeFunc(time) {
    var args = lastArgs,
        thisArg = lastThis;
    lastArgs = lastThis = undefined;
    lastInvokeTime = time;
    result = func.apply(thisArg, args);
    return result;
  }

  function leadingEdge(time) {
    // Reset any `maxWait` timer.
    lastInvokeTime = time; // Start the timer for the trailing edge.

    timerId = setTimeout(timerExpired, wait); // Invoke the leading edge.

    return leading ? invokeFunc(time) : result;
  }

  function remainingWait(time) {
    var timeSinceLastCall = time - lastCallTime,
        timeSinceLastInvoke = time - lastInvokeTime,
        timeWaiting = wait - timeSinceLastCall;
    return maxing ? nativeMin(timeWaiting, maxWait - timeSinceLastInvoke) : timeWaiting;
  }

  function shouldInvoke(time) {
    var timeSinceLastCall = time - lastCallTime,
        timeSinceLastInvoke = time - lastInvokeTime; // Either this is the first call, activity has stopped and we're at the
    // trailing edge, the system time has gone backwards and we're treating
    // it as the trailing edge, or we've hit the `maxWait` limit.

    return lastCallTime === undefined || timeSinceLastCall >= wait || timeSinceLastCall < 0 || maxing && timeSinceLastInvoke >= maxWait;
  }

  function timerExpired() {
    var time = now();

    if (shouldInvoke(time)) {
      return trailingEdge(time);
    } // Restart the timer.


    timerId = setTimeout(timerExpired, remainingWait(time));
  }

  function trailingEdge(time) {
    timerId = undefined; // Only invoke if we have `lastArgs` which means `func` has been
    // debounced at least once.

    if (trailing && lastArgs) {
      return invokeFunc(time);
    }

    lastArgs = lastThis = undefined;
    return result;
  }

  function cancel() {
    if (timerId !== undefined) {
      clearTimeout(timerId);
    }

    lastInvokeTime = 0;
    lastArgs = lastCallTime = lastThis = timerId = undefined;
  }

  function flush() {
    return timerId === undefined ? result : trailingEdge(now());
  }

  function debounced() {
    var time = now(),
        isInvoking = shouldInvoke(time);
    lastArgs = arguments;
    lastThis = this;
    lastCallTime = time;

    if (isInvoking) {
      if (timerId === undefined) {
        return leadingEdge(lastCallTime);
      }

      if (maxing) {
        // Handle invocations in a tight loop.
        clearTimeout(timerId);
        timerId = setTimeout(timerExpired, wait);
        return invokeFunc(lastCallTime);
      }
    }

    if (timerId === undefined) {
      timerId = setTimeout(timerExpired, wait);
    }

    return result;
  }

  debounced.cancel = cancel;
  debounced.flush = flush;
  return debounced;
}

module.exports = debounce;

/***/ }),

/***/ 2661:
/***/ (function(module) {

/**
 * Checks if `value` is the
 * [language type](http://www.ecma-international.org/ecma-262/7.0/#sec-ecmascript-language-types)
 * of `Object`. (e.g. arrays, functions, objects, regexes, `new Number(0)`, and `new String('')`)
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is an object, else `false`.
 * @example
 *
 * _.isObject({});
 * // => true
 *
 * _.isObject([1, 2, 3]);
 * // => true
 *
 * _.isObject(_.noop);
 * // => true
 *
 * _.isObject(null);
 * // => false
 */
function isObject(value) {
  var type = typeof value;
  return value != null && (type == 'object' || type == 'function');
}

module.exports = isObject;

/***/ }),

/***/ 6408:
/***/ (function(module) {

/**
 * Checks if `value` is object-like. A value is object-like if it's not `null`
 * and has a `typeof` result of "object".
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is object-like, else `false`.
 * @example
 *
 * _.isObjectLike({});
 * // => true
 *
 * _.isObjectLike([1, 2, 3]);
 * // => true
 *
 * _.isObjectLike(_.noop);
 * // => false
 *
 * _.isObjectLike(null);
 * // => false
 */
function isObjectLike(value) {
  return value != null && typeof value == 'object';
}

module.exports = isObjectLike;

/***/ }),

/***/ 9322:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var baseGetTag = __webpack_require__(9411),
    isObjectLike = __webpack_require__(6408);
/** `Object#toString` result references. */


var symbolTag = '[object Symbol]';
/**
 * Checks if `value` is classified as a `Symbol` primitive or object.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to check.
 * @returns {boolean} Returns `true` if `value` is a symbol, else `false`.
 * @example
 *
 * _.isSymbol(Symbol.iterator);
 * // => true
 *
 * _.isSymbol('abc');
 * // => false
 */

function isSymbol(value) {
  return typeof value == 'symbol' || isObjectLike(value) && baseGetTag(value) == symbolTag;
}

module.exports = isSymbol;

/***/ }),

/***/ 9238:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var root = __webpack_require__(8503);
/**
 * Gets the timestamp of the number of milliseconds that have elapsed since
 * the Unix epoch (1 January 1970 00:00:00 UTC).
 *
 * @static
 * @memberOf _
 * @since 2.4.0
 * @category Date
 * @returns {number} Returns the timestamp.
 * @example
 *
 * _.defer(function(stamp) {
 *   console.log(_.now() - stamp);
 * }, _.now());
 * // => Logs the number of milliseconds it took for the deferred invocation.
 */


var now = function () {
  return root.Date.now();
};

module.exports = now;

/***/ }),

/***/ 1788:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

__webpack_require__(1703);

var debounce = __webpack_require__(2764),
    isObject = __webpack_require__(2661);
/** Error message constants. */


var FUNC_ERROR_TEXT = 'Expected a function';
/**
 * Creates a throttled function that only invokes `func` at most once per
 * every `wait` milliseconds. The throttled function comes with a `cancel`
 * method to cancel delayed `func` invocations and a `flush` method to
 * immediately invoke them. Provide `options` to indicate whether `func`
 * should be invoked on the leading and/or trailing edge of the `wait`
 * timeout. The `func` is invoked with the last arguments provided to the
 * throttled function. Subsequent calls to the throttled function return the
 * result of the last `func` invocation.
 *
 * **Note:** If `leading` and `trailing` options are `true`, `func` is
 * invoked on the trailing edge of the timeout only if the throttled function
 * is invoked more than once during the `wait` timeout.
 *
 * If `wait` is `0` and `leading` is `false`, `func` invocation is deferred
 * until to the next tick, similar to `setTimeout` with a timeout of `0`.
 *
 * See [David Corbacho's article](https://css-tricks.com/debouncing-throttling-explained-examples/)
 * for details over the differences between `_.throttle` and `_.debounce`.
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Function
 * @param {Function} func The function to throttle.
 * @param {number} [wait=0] The number of milliseconds to throttle invocations to.
 * @param {Object} [options={}] The options object.
 * @param {boolean} [options.leading=true]
 *  Specify invoking on the leading edge of the timeout.
 * @param {boolean} [options.trailing=true]
 *  Specify invoking on the trailing edge of the timeout.
 * @returns {Function} Returns the new throttled function.
 * @example
 *
 * // Avoid excessively updating the position while scrolling.
 * jQuery(window).on('scroll', _.throttle(updatePosition, 100));
 *
 * // Invoke `renewToken` when the click event is fired, but not more than once every 5 minutes.
 * var throttled = _.throttle(renewToken, 300000, { 'trailing': false });
 * jQuery(element).on('click', throttled);
 *
 * // Cancel the trailing throttled invocation.
 * jQuery(window).on('popstate', throttled.cancel);
 */

function throttle(func, wait, options) {
  var leading = true,
      trailing = true;

  if (typeof func != 'function') {
    throw new TypeError(FUNC_ERROR_TEXT);
  }

  if (isObject(options)) {
    leading = 'leading' in options ? !!options.leading : leading;
    trailing = 'trailing' in options ? !!options.trailing : trailing;
  }

  return debounce(func, wait, {
    'leading': leading,
    'maxWait': wait,
    'trailing': trailing
  });
}

module.exports = throttle;

/***/ }),

/***/ 692:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

var baseTrim = __webpack_require__(5349),
    isObject = __webpack_require__(2661),
    isSymbol = __webpack_require__(9322);
/** Used as references for various `Number` constants. */


var NAN = 0 / 0;
/** Used to detect bad signed hexadecimal string values. */

var reIsBadHex = /^[-+]0x[0-9a-f]+$/i;
/** Used to detect binary string values. */

var reIsBinary = /^0b[01]+$/i;
/** Used to detect octal string values. */

var reIsOctal = /^0o[0-7]+$/i;
/** Built-in method references without a dependency on `root`. */

var freeParseInt = parseInt;
/**
 * Converts `value` to a number.
 *
 * @static
 * @memberOf _
 * @since 4.0.0
 * @category Lang
 * @param {*} value The value to process.
 * @returns {number} Returns the number.
 * @example
 *
 * _.toNumber(3.2);
 * // => 3.2
 *
 * _.toNumber(Number.MIN_VALUE);
 * // => 5e-324
 *
 * _.toNumber(Infinity);
 * // => Infinity
 *
 * _.toNumber('3.2');
 * // => 3.2
 */

function toNumber(value) {
  if (typeof value == 'number') {
    return value;
  }

  if (isSymbol(value)) {
    return NAN;
  }

  if (isObject(value)) {
    var other = typeof value.valueOf == 'function' ? value.valueOf() : value;
    value = isObject(other) ? other + '' : other;
  }

  if (typeof value != 'string') {
    return value === 0 ? value : +value;
  }

  value = baseTrim(value);
  var isBinary = reIsBinary.test(value);
  return isBinary || reIsOctal.test(value) ? freeParseInt(value.slice(2), isBinary ? 2 : 8) : reIsBadHex.test(value) ? NAN : +value;
}

module.exports = toNumber;

/***/ }),

/***/ 9339:
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_RESULT__;// TinyColor v1.4.2
// https://github.com/bgrins/TinyColor
// Brian Grinstead, MIT License
(function (Math) {
  var trimLeft = /^\s+/,
      trimRight = /\s+$/,
      tinyCounter = 0,
      mathRound = Math.round,
      mathMin = Math.min,
      mathMax = Math.max,
      mathRandom = Math.random;

  function tinycolor(color, opts) {
    color = color ? color : '';
    opts = opts || {}; // If input is already a tinycolor, return itself

    if (color instanceof tinycolor) {
      return color;
    } // If we are called as a function, call using new instead


    if (!(this instanceof tinycolor)) {
      return new tinycolor(color, opts);
    }

    var rgb = inputToRGB(color);
    this._originalInput = color, this._r = rgb.r, this._g = rgb.g, this._b = rgb.b, this._a = rgb.a, this._roundA = mathRound(100 * this._a) / 100, this._format = opts.format || rgb.format;
    this._gradientType = opts.gradientType; // Don't let the range of [0,255] come back in [0,1].
    // Potentially lose a little bit of precision here, but will fix issues where
    // .5 gets interpreted as half of the total, instead of half of 1
    // If it was supposed to be 128, this was already taken care of by `inputToRgb`

    if (this._r < 1) {
      this._r = mathRound(this._r);
    }

    if (this._g < 1) {
      this._g = mathRound(this._g);
    }

    if (this._b < 1) {
      this._b = mathRound(this._b);
    }

    this._ok = rgb.ok;
    this._tc_id = tinyCounter++;
  }

  tinycolor.prototype = {
    isDark: function () {
      return this.getBrightness() < 128;
    },
    isLight: function () {
      return !this.isDark();
    },
    isValid: function () {
      return this._ok;
    },
    getOriginalInput: function () {
      return this._originalInput;
    },
    getFormat: function () {
      return this._format;
    },
    getAlpha: function () {
      return this._a;
    },
    getBrightness: function () {
      //http://www.w3.org/TR/AERT#color-contrast
      var rgb = this.toRgb();
      return (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
    },
    getLuminance: function () {
      //http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
      var rgb = this.toRgb();
      var RsRGB, GsRGB, BsRGB, R, G, B;
      RsRGB = rgb.r / 255;
      GsRGB = rgb.g / 255;
      BsRGB = rgb.b / 255;

      if (RsRGB <= 0.03928) {
        R = RsRGB / 12.92;
      } else {
        R = Math.pow((RsRGB + 0.055) / 1.055, 2.4);
      }

      if (GsRGB <= 0.03928) {
        G = GsRGB / 12.92;
      } else {
        G = Math.pow((GsRGB + 0.055) / 1.055, 2.4);
      }

      if (BsRGB <= 0.03928) {
        B = BsRGB / 12.92;
      } else {
        B = Math.pow((BsRGB + 0.055) / 1.055, 2.4);
      }

      return 0.2126 * R + 0.7152 * G + 0.0722 * B;
    },
    setAlpha: function (value) {
      this._a = boundAlpha(value);
      this._roundA = mathRound(100 * this._a) / 100;
      return this;
    },
    toHsv: function () {
      var hsv = rgbToHsv(this._r, this._g, this._b);
      return {
        h: hsv.h * 360,
        s: hsv.s,
        v: hsv.v,
        a: this._a
      };
    },
    toHsvString: function () {
      var hsv = rgbToHsv(this._r, this._g, this._b);
      var h = mathRound(hsv.h * 360),
          s = mathRound(hsv.s * 100),
          v = mathRound(hsv.v * 100);
      return this._a == 1 ? "hsv(" + h + ", " + s + "%, " + v + "%)" : "hsva(" + h + ", " + s + "%, " + v + "%, " + this._roundA + ")";
    },
    toHsl: function () {
      var hsl = rgbToHsl(this._r, this._g, this._b);
      return {
        h: hsl.h * 360,
        s: hsl.s,
        l: hsl.l,
        a: this._a
      };
    },
    toHslString: function () {
      var hsl = rgbToHsl(this._r, this._g, this._b);
      var h = mathRound(hsl.h * 360),
          s = mathRound(hsl.s * 100),
          l = mathRound(hsl.l * 100);
      return this._a == 1 ? "hsl(" + h + ", " + s + "%, " + l + "%)" : "hsla(" + h + ", " + s + "%, " + l + "%, " + this._roundA + ")";
    },
    toHex: function (allow3Char) {
      return rgbToHex(this._r, this._g, this._b, allow3Char);
    },
    toHexString: function (allow3Char) {
      return '#' + this.toHex(allow3Char);
    },
    toHex8: function (allow4Char) {
      return rgbaToHex(this._r, this._g, this._b, this._a, allow4Char);
    },
    toHex8String: function (allow4Char) {
      return '#' + this.toHex8(allow4Char);
    },
    toRgb: function () {
      return {
        r: mathRound(this._r),
        g: mathRound(this._g),
        b: mathRound(this._b),
        a: this._a
      };
    },
    toRgbString: function () {
      return this._a == 1 ? "rgb(" + mathRound(this._r) + ", " + mathRound(this._g) + ", " + mathRound(this._b) + ")" : "rgba(" + mathRound(this._r) + ", " + mathRound(this._g) + ", " + mathRound(this._b) + ", " + this._roundA + ")";
    },
    toPercentageRgb: function () {
      return {
        r: mathRound(bound01(this._r, 255) * 100) + "%",
        g: mathRound(bound01(this._g, 255) * 100) + "%",
        b: mathRound(bound01(this._b, 255) * 100) + "%",
        a: this._a
      };
    },
    toPercentageRgbString: function () {
      return this._a == 1 ? "rgb(" + mathRound(bound01(this._r, 255) * 100) + "%, " + mathRound(bound01(this._g, 255) * 100) + "%, " + mathRound(bound01(this._b, 255) * 100) + "%)" : "rgba(" + mathRound(bound01(this._r, 255) * 100) + "%, " + mathRound(bound01(this._g, 255) * 100) + "%, " + mathRound(bound01(this._b, 255) * 100) + "%, " + this._roundA + ")";
    },
    toName: function () {
      if (this._a === 0) {
        return "transparent";
      }

      if (this._a < 1) {
        return false;
      }

      return hexNames[rgbToHex(this._r, this._g, this._b, true)] || false;
    },
    toFilter: function (secondColor) {
      var hex8String = '#' + rgbaToArgbHex(this._r, this._g, this._b, this._a);
      var secondHex8String = hex8String;
      var gradientType = this._gradientType ? "GradientType = 1, " : "";

      if (secondColor) {
        var s = tinycolor(secondColor);
        secondHex8String = '#' + rgbaToArgbHex(s._r, s._g, s._b, s._a);
      }

      return "progid:DXImageTransform.Microsoft.gradient(" + gradientType + "startColorstr=" + hex8String + ",endColorstr=" + secondHex8String + ")";
    },
    toString: function (format) {
      var formatSet = !!format;
      format = format || this._format;
      var formattedString = false;
      var hasAlpha = this._a < 1 && this._a >= 0;
      var needsAlphaFormat = !formatSet && hasAlpha && (format === "hex" || format === "hex6" || format === "hex3" || format === "hex4" || format === "hex8" || format === "name");

      if (needsAlphaFormat) {
        // Special case for "transparent", all other non-alpha formats
        // will return rgba when there is transparency.
        if (format === "name" && this._a === 0) {
          return this.toName();
        }

        return this.toRgbString();
      }

      if (format === "rgb") {
        formattedString = this.toRgbString();
      }

      if (format === "prgb") {
        formattedString = this.toPercentageRgbString();
      }

      if (format === "hex" || format === "hex6") {
        formattedString = this.toHexString();
      }

      if (format === "hex3") {
        formattedString = this.toHexString(true);
      }

      if (format === "hex4") {
        formattedString = this.toHex8String(true);
      }

      if (format === "hex8") {
        formattedString = this.toHex8String();
      }

      if (format === "name") {
        formattedString = this.toName();
      }

      if (format === "hsl") {
        formattedString = this.toHslString();
      }

      if (format === "hsv") {
        formattedString = this.toHsvString();
      }

      return formattedString || this.toHexString();
    },
    clone: function () {
      return tinycolor(this.toString());
    },
    _applyModification: function (fn, args) {
      var color = fn.apply(null, [this].concat([].slice.call(args)));
      this._r = color._r;
      this._g = color._g;
      this._b = color._b;
      this.setAlpha(color._a);
      return this;
    },
    lighten: function () {
      return this._applyModification(lighten, arguments);
    },
    brighten: function () {
      return this._applyModification(brighten, arguments);
    },
    darken: function () {
      return this._applyModification(darken, arguments);
    },
    desaturate: function () {
      return this._applyModification(desaturate, arguments);
    },
    saturate: function () {
      return this._applyModification(saturate, arguments);
    },
    greyscale: function () {
      return this._applyModification(greyscale, arguments);
    },
    spin: function () {
      return this._applyModification(spin, arguments);
    },
    _applyCombination: function (fn, args) {
      return fn.apply(null, [this].concat([].slice.call(args)));
    },
    analogous: function () {
      return this._applyCombination(analogous, arguments);
    },
    complement: function () {
      return this._applyCombination(complement, arguments);
    },
    monochromatic: function () {
      return this._applyCombination(monochromatic, arguments);
    },
    splitcomplement: function () {
      return this._applyCombination(splitcomplement, arguments);
    },
    triad: function () {
      return this._applyCombination(triad, arguments);
    },
    tetrad: function () {
      return this._applyCombination(tetrad, arguments);
    }
  }; // If input is an object, force 1 into "1.0" to handle ratios properly
  // String input requires "1.0" as input, so 1 will be treated as 1

  tinycolor.fromRatio = function (color, opts) {
    if (typeof color == "object") {
      var newColor = {};

      for (var i in color) {
        if (color.hasOwnProperty(i)) {
          if (i === "a") {
            newColor[i] = color[i];
          } else {
            newColor[i] = convertToPercentage(color[i]);
          }
        }
      }

      color = newColor;
    }

    return tinycolor(color, opts);
  }; // Given a string or object, convert that input to RGB
  // Possible string inputs:
  //
  //     "red"
  //     "#f00" or "f00"
  //     "#ff0000" or "ff0000"
  //     "#ff000000" or "ff000000"
  //     "rgb 255 0 0" or "rgb (255, 0, 0)"
  //     "rgb 1.0 0 0" or "rgb (1, 0, 0)"
  //     "rgba (255, 0, 0, 1)" or "rgba 255, 0, 0, 1"
  //     "rgba (1.0, 0, 0, 1)" or "rgba 1.0, 0, 0, 1"
  //     "hsl(0, 100%, 50%)" or "hsl 0 100% 50%"
  //     "hsla(0, 100%, 50%, 1)" or "hsla 0 100% 50%, 1"
  //     "hsv(0, 100%, 100%)" or "hsv 0 100% 100%"
  //


  function inputToRGB(color) {
    var rgb = {
      r: 0,
      g: 0,
      b: 0
    };
    var a = 1;
    var s = null;
    var v = null;
    var l = null;
    var ok = false;
    var format = false;

    if (typeof color == "string") {
      color = stringInputToObject(color);
    }

    if (typeof color == "object") {
      if (isValidCSSUnit(color.r) && isValidCSSUnit(color.g) && isValidCSSUnit(color.b)) {
        rgb = rgbToRgb(color.r, color.g, color.b);
        ok = true;
        format = String(color.r).substr(-1) === "%" ? "prgb" : "rgb";
      } else if (isValidCSSUnit(color.h) && isValidCSSUnit(color.s) && isValidCSSUnit(color.v)) {
        s = convertToPercentage(color.s);
        v = convertToPercentage(color.v);
        rgb = hsvToRgb(color.h, s, v);
        ok = true;
        format = "hsv";
      } else if (isValidCSSUnit(color.h) && isValidCSSUnit(color.s) && isValidCSSUnit(color.l)) {
        s = convertToPercentage(color.s);
        l = convertToPercentage(color.l);
        rgb = hslToRgb(color.h, s, l);
        ok = true;
        format = "hsl";
      }

      if (color.hasOwnProperty("a")) {
        a = color.a;
      }
    }

    a = boundAlpha(a);
    return {
      ok: ok,
      format: color.format || format,
      r: mathMin(255, mathMax(rgb.r, 0)),
      g: mathMin(255, mathMax(rgb.g, 0)),
      b: mathMin(255, mathMax(rgb.b, 0)),
      a: a
    };
  } // Conversion Functions
  // --------------------
  // `rgbToHsl`, `rgbToHsv`, `hslToRgb`, `hsvToRgb` modified from:
  // <http://mjijackson.com/2008/02/rgb-to-hsl-and-rgb-to-hsv-color-model-conversion-algorithms-in-javascript>
  // `rgbToRgb`
  // Handle bounds / percentage checking to conform to CSS color spec
  // <http://www.w3.org/TR/css3-color/>
  // *Assumes:* r, g, b in [0, 255] or [0, 1]
  // *Returns:* { r, g, b } in [0, 255]


  function rgbToRgb(r, g, b) {
    return {
      r: bound01(r, 255) * 255,
      g: bound01(g, 255) * 255,
      b: bound01(b, 255) * 255
    };
  } // `rgbToHsl`
  // Converts an RGB color value to HSL.
  // *Assumes:* r, g, and b are contained in [0, 255] or [0, 1]
  // *Returns:* { h, s, l } in [0,1]


  function rgbToHsl(r, g, b) {
    r = bound01(r, 255);
    g = bound01(g, 255);
    b = bound01(b, 255);
    var max = mathMax(r, g, b),
        min = mathMin(r, g, b);
    var h,
        s,
        l = (max + min) / 2;

    if (max == min) {
      h = s = 0; // achromatic
    } else {
      var d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

      switch (max) {
        case r:
          h = (g - b) / d + (g < b ? 6 : 0);
          break;

        case g:
          h = (b - r) / d + 2;
          break;

        case b:
          h = (r - g) / d + 4;
          break;
      }

      h /= 6;
    }

    return {
      h: h,
      s: s,
      l: l
    };
  } // `hslToRgb`
  // Converts an HSL color value to RGB.
  // *Assumes:* h is contained in [0, 1] or [0, 360] and s and l are contained [0, 1] or [0, 100]
  // *Returns:* { r, g, b } in the set [0, 255]


  function hslToRgb(h, s, l) {
    var r, g, b;
    h = bound01(h, 360);
    s = bound01(s, 100);
    l = bound01(l, 100);

    function hue2rgb(p, q, t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }

    if (s === 0) {
      r = g = b = l; // achromatic
    } else {
      var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      var p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return {
      r: r * 255,
      g: g * 255,
      b: b * 255
    };
  } // `rgbToHsv`
  // Converts an RGB color value to HSV
  // *Assumes:* r, g, and b are contained in the set [0, 255] or [0, 1]
  // *Returns:* { h, s, v } in [0,1]


  function rgbToHsv(r, g, b) {
    r = bound01(r, 255);
    g = bound01(g, 255);
    b = bound01(b, 255);
    var max = mathMax(r, g, b),
        min = mathMin(r, g, b);
    var h,
        s,
        v = max;
    var d = max - min;
    s = max === 0 ? 0 : d / max;

    if (max == min) {
      h = 0; // achromatic
    } else {
      switch (max) {
        case r:
          h = (g - b) / d + (g < b ? 6 : 0);
          break;

        case g:
          h = (b - r) / d + 2;
          break;

        case b:
          h = (r - g) / d + 4;
          break;
      }

      h /= 6;
    }

    return {
      h: h,
      s: s,
      v: v
    };
  } // `hsvToRgb`
  // Converts an HSV color value to RGB.
  // *Assumes:* h is contained in [0, 1] or [0, 360] and s and v are contained in [0, 1] or [0, 100]
  // *Returns:* { r, g, b } in the set [0, 255]


  function hsvToRgb(h, s, v) {
    h = bound01(h, 360) * 6;
    s = bound01(s, 100);
    v = bound01(v, 100);
    var i = Math.floor(h),
        f = h - i,
        p = v * (1 - s),
        q = v * (1 - f * s),
        t = v * (1 - (1 - f) * s),
        mod = i % 6,
        r = [v, q, p, p, t, v][mod],
        g = [t, v, v, q, p, p][mod],
        b = [p, p, t, v, v, q][mod];
    return {
      r: r * 255,
      g: g * 255,
      b: b * 255
    };
  } // `rgbToHex`
  // Converts an RGB color to hex
  // Assumes r, g, and b are contained in the set [0, 255]
  // Returns a 3 or 6 character hex


  function rgbToHex(r, g, b, allow3Char) {
    var hex = [pad2(mathRound(r).toString(16)), pad2(mathRound(g).toString(16)), pad2(mathRound(b).toString(16))]; // Return a 3 character hex if possible

    if (allow3Char && hex[0].charAt(0) == hex[0].charAt(1) && hex[1].charAt(0) == hex[1].charAt(1) && hex[2].charAt(0) == hex[2].charAt(1)) {
      return hex[0].charAt(0) + hex[1].charAt(0) + hex[2].charAt(0);
    }

    return hex.join("");
  } // `rgbaToHex`
  // Converts an RGBA color plus alpha transparency to hex
  // Assumes r, g, b are contained in the set [0, 255] and
  // a in [0, 1]. Returns a 4 or 8 character rgba hex


  function rgbaToHex(r, g, b, a, allow4Char) {
    var hex = [pad2(mathRound(r).toString(16)), pad2(mathRound(g).toString(16)), pad2(mathRound(b).toString(16)), pad2(convertDecimalToHex(a))]; // Return a 4 character hex if possible

    if (allow4Char && hex[0].charAt(0) == hex[0].charAt(1) && hex[1].charAt(0) == hex[1].charAt(1) && hex[2].charAt(0) == hex[2].charAt(1) && hex[3].charAt(0) == hex[3].charAt(1)) {
      return hex[0].charAt(0) + hex[1].charAt(0) + hex[2].charAt(0) + hex[3].charAt(0);
    }

    return hex.join("");
  } // `rgbaToArgbHex`
  // Converts an RGBA color to an ARGB Hex8 string
  // Rarely used, but required for "toFilter()"


  function rgbaToArgbHex(r, g, b, a) {
    var hex = [pad2(convertDecimalToHex(a)), pad2(mathRound(r).toString(16)), pad2(mathRound(g).toString(16)), pad2(mathRound(b).toString(16))];
    return hex.join("");
  } // `equals`
  // Can be called with any tinycolor input


  tinycolor.equals = function (color1, color2) {
    if (!color1 || !color2) {
      return false;
    }

    return tinycolor(color1).toRgbString() == tinycolor(color2).toRgbString();
  };

  tinycolor.random = function () {
    return tinycolor.fromRatio({
      r: mathRandom(),
      g: mathRandom(),
      b: mathRandom()
    });
  }; // Modification Functions
  // ----------------------
  // Thanks to less.js for some of the basics here
  // <https://github.com/cloudhead/less.js/blob/master/lib/less/functions.js>


  function desaturate(color, amount) {
    amount = amount === 0 ? 0 : amount || 10;
    var hsl = tinycolor(color).toHsl();
    hsl.s -= amount / 100;
    hsl.s = clamp01(hsl.s);
    return tinycolor(hsl);
  }

  function saturate(color, amount) {
    amount = amount === 0 ? 0 : amount || 10;
    var hsl = tinycolor(color).toHsl();
    hsl.s += amount / 100;
    hsl.s = clamp01(hsl.s);
    return tinycolor(hsl);
  }

  function greyscale(color) {
    return tinycolor(color).desaturate(100);
  }

  function lighten(color, amount) {
    amount = amount === 0 ? 0 : amount || 10;
    var hsl = tinycolor(color).toHsl();
    hsl.l += amount / 100;
    hsl.l = clamp01(hsl.l);
    return tinycolor(hsl);
  }

  function brighten(color, amount) {
    amount = amount === 0 ? 0 : amount || 10;
    var rgb = tinycolor(color).toRgb();
    rgb.r = mathMax(0, mathMin(255, rgb.r - mathRound(255 * -(amount / 100))));
    rgb.g = mathMax(0, mathMin(255, rgb.g - mathRound(255 * -(amount / 100))));
    rgb.b = mathMax(0, mathMin(255, rgb.b - mathRound(255 * -(amount / 100))));
    return tinycolor(rgb);
  }

  function darken(color, amount) {
    amount = amount === 0 ? 0 : amount || 10;
    var hsl = tinycolor(color).toHsl();
    hsl.l -= amount / 100;
    hsl.l = clamp01(hsl.l);
    return tinycolor(hsl);
  } // Spin takes a positive or negative amount within [-360, 360] indicating the change of hue.
  // Values outside of this range will be wrapped into this range.


  function spin(color, amount) {
    var hsl = tinycolor(color).toHsl();
    var hue = (hsl.h + amount) % 360;
    hsl.h = hue < 0 ? 360 + hue : hue;
    return tinycolor(hsl);
  } // Combination Functions
  // ---------------------
  // Thanks to jQuery xColor for some of the ideas behind these
  // <https://github.com/infusion/jQuery-xcolor/blob/master/jquery.xcolor.js>


  function complement(color) {
    var hsl = tinycolor(color).toHsl();
    hsl.h = (hsl.h + 180) % 360;
    return tinycolor(hsl);
  }

  function triad(color) {
    var hsl = tinycolor(color).toHsl();
    var h = hsl.h;
    return [tinycolor(color), tinycolor({
      h: (h + 120) % 360,
      s: hsl.s,
      l: hsl.l
    }), tinycolor({
      h: (h + 240) % 360,
      s: hsl.s,
      l: hsl.l
    })];
  }

  function tetrad(color) {
    var hsl = tinycolor(color).toHsl();
    var h = hsl.h;
    return [tinycolor(color), tinycolor({
      h: (h + 90) % 360,
      s: hsl.s,
      l: hsl.l
    }), tinycolor({
      h: (h + 180) % 360,
      s: hsl.s,
      l: hsl.l
    }), tinycolor({
      h: (h + 270) % 360,
      s: hsl.s,
      l: hsl.l
    })];
  }

  function splitcomplement(color) {
    var hsl = tinycolor(color).toHsl();
    var h = hsl.h;
    return [tinycolor(color), tinycolor({
      h: (h + 72) % 360,
      s: hsl.s,
      l: hsl.l
    }), tinycolor({
      h: (h + 216) % 360,
      s: hsl.s,
      l: hsl.l
    })];
  }

  function analogous(color, results, slices) {
    results = results || 6;
    slices = slices || 30;
    var hsl = tinycolor(color).toHsl();
    var part = 360 / slices;
    var ret = [tinycolor(color)];

    for (hsl.h = (hsl.h - (part * results >> 1) + 720) % 360; --results;) {
      hsl.h = (hsl.h + part) % 360;
      ret.push(tinycolor(hsl));
    }

    return ret;
  }

  function monochromatic(color, results) {
    results = results || 6;
    var hsv = tinycolor(color).toHsv();
    var h = hsv.h,
        s = hsv.s,
        v = hsv.v;
    var ret = [];
    var modification = 1 / results;

    while (results--) {
      ret.push(tinycolor({
        h: h,
        s: s,
        v: v
      }));
      v = (v + modification) % 1;
    }

    return ret;
  } // Utility Functions
  // ---------------------


  tinycolor.mix = function (color1, color2, amount) {
    amount = amount === 0 ? 0 : amount || 50;
    var rgb1 = tinycolor(color1).toRgb();
    var rgb2 = tinycolor(color2).toRgb();
    var p = amount / 100;
    var rgba = {
      r: (rgb2.r - rgb1.r) * p + rgb1.r,
      g: (rgb2.g - rgb1.g) * p + rgb1.g,
      b: (rgb2.b - rgb1.b) * p + rgb1.b,
      a: (rgb2.a - rgb1.a) * p + rgb1.a
    };
    return tinycolor(rgba);
  }; // Readability Functions
  // ---------------------
  // <http://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef (WCAG Version 2)
  // `contrast`
  // Analyze the 2 colors and returns the color contrast defined by (WCAG Version 2)


  tinycolor.readability = function (color1, color2) {
    var c1 = tinycolor(color1);
    var c2 = tinycolor(color2);
    return (Math.max(c1.getLuminance(), c2.getLuminance()) + 0.05) / (Math.min(c1.getLuminance(), c2.getLuminance()) + 0.05);
  }; // `isReadable`
  // Ensure that foreground and background color combinations meet WCAG2 guidelines.
  // The third argument is an optional Object.
  //      the 'level' property states 'AA' or 'AAA' - if missing or invalid, it defaults to 'AA';
  //      the 'size' property states 'large' or 'small' - if missing or invalid, it defaults to 'small'.
  // If the entire object is absent, isReadable defaults to {level:"AA",size:"small"}.
  // *Example*
  //    tinycolor.isReadable("#000", "#111") => false
  //    tinycolor.isReadable("#000", "#111",{level:"AA",size:"large"}) => false


  tinycolor.isReadable = function (color1, color2, wcag2) {
    var readability = tinycolor.readability(color1, color2);
    var wcag2Parms, out;
    out = false;
    wcag2Parms = validateWCAG2Parms(wcag2);

    switch (wcag2Parms.level + wcag2Parms.size) {
      case "AAsmall":
      case "AAAlarge":
        out = readability >= 4.5;
        break;

      case "AAlarge":
        out = readability >= 3;
        break;

      case "AAAsmall":
        out = readability >= 7;
        break;
    }

    return out;
  }; // `mostReadable`
  // Given a base color and a list of possible foreground or background
  // colors for that base, returns the most readable color.
  // Optionally returns Black or White if the most readable color is unreadable.
  // *Example*
  //    tinycolor.mostReadable(tinycolor.mostReadable("#123", ["#124", "#125"],{includeFallbackColors:false}).toHexString(); // "#112255"
  //    tinycolor.mostReadable(tinycolor.mostReadable("#123", ["#124", "#125"],{includeFallbackColors:true}).toHexString();  // "#ffffff"
  //    tinycolor.mostReadable("#a8015a", ["#faf3f3"],{includeFallbackColors:true,level:"AAA",size:"large"}).toHexString(); // "#faf3f3"
  //    tinycolor.mostReadable("#a8015a", ["#faf3f3"],{includeFallbackColors:true,level:"AAA",size:"small"}).toHexString(); // "#ffffff"


  tinycolor.mostReadable = function (baseColor, colorList, args) {
    var bestColor = null;
    var bestScore = 0;
    var readability;
    var includeFallbackColors, level, size;
    args = args || {};
    includeFallbackColors = args.includeFallbackColors;
    level = args.level;
    size = args.size;

    for (var i = 0; i < colorList.length; i++) {
      readability = tinycolor.readability(baseColor, colorList[i]);

      if (readability > bestScore) {
        bestScore = readability;
        bestColor = tinycolor(colorList[i]);
      }
    }

    if (tinycolor.isReadable(baseColor, bestColor, {
      "level": level,
      "size": size
    }) || !includeFallbackColors) {
      return bestColor;
    } else {
      args.includeFallbackColors = false;
      return tinycolor.mostReadable(baseColor, ["#fff", "#000"], args);
    }
  }; // Big List of Colors
  // ------------------
  // <http://www.w3.org/TR/css3-color/#svg-color>


  var names = tinycolor.names = {
    aliceblue: "f0f8ff",
    antiquewhite: "faebd7",
    aqua: "0ff",
    aquamarine: "7fffd4",
    azure: "f0ffff",
    beige: "f5f5dc",
    bisque: "ffe4c4",
    black: "000",
    blanchedalmond: "ffebcd",
    blue: "00f",
    blueviolet: "8a2be2",
    brown: "a52a2a",
    burlywood: "deb887",
    burntsienna: "ea7e5d",
    cadetblue: "5f9ea0",
    chartreuse: "7fff00",
    chocolate: "d2691e",
    coral: "ff7f50",
    cornflowerblue: "6495ed",
    cornsilk: "fff8dc",
    crimson: "dc143c",
    cyan: "0ff",
    darkblue: "00008b",
    darkcyan: "008b8b",
    darkgoldenrod: "b8860b",
    darkgray: "a9a9a9",
    darkgreen: "006400",
    darkgrey: "a9a9a9",
    darkkhaki: "bdb76b",
    darkmagenta: "8b008b",
    darkolivegreen: "556b2f",
    darkorange: "ff8c00",
    darkorchid: "9932cc",
    darkred: "8b0000",
    darksalmon: "e9967a",
    darkseagreen: "8fbc8f",
    darkslateblue: "483d8b",
    darkslategray: "2f4f4f",
    darkslategrey: "2f4f4f",
    darkturquoise: "00ced1",
    darkviolet: "9400d3",
    deeppink: "ff1493",
    deepskyblue: "00bfff",
    dimgray: "696969",
    dimgrey: "696969",
    dodgerblue: "1e90ff",
    firebrick: "b22222",
    floralwhite: "fffaf0",
    forestgreen: "228b22",
    fuchsia: "f0f",
    gainsboro: "dcdcdc",
    ghostwhite: "f8f8ff",
    gold: "ffd700",
    goldenrod: "daa520",
    gray: "808080",
    green: "008000",
    greenyellow: "adff2f",
    grey: "808080",
    honeydew: "f0fff0",
    hotpink: "ff69b4",
    indianred: "cd5c5c",
    indigo: "4b0082",
    ivory: "fffff0",
    khaki: "f0e68c",
    lavender: "e6e6fa",
    lavenderblush: "fff0f5",
    lawngreen: "7cfc00",
    lemonchiffon: "fffacd",
    lightblue: "add8e6",
    lightcoral: "f08080",
    lightcyan: "e0ffff",
    lightgoldenrodyellow: "fafad2",
    lightgray: "d3d3d3",
    lightgreen: "90ee90",
    lightgrey: "d3d3d3",
    lightpink: "ffb6c1",
    lightsalmon: "ffa07a",
    lightseagreen: "20b2aa",
    lightskyblue: "87cefa",
    lightslategray: "789",
    lightslategrey: "789",
    lightsteelblue: "b0c4de",
    lightyellow: "ffffe0",
    lime: "0f0",
    limegreen: "32cd32",
    linen: "faf0e6",
    magenta: "f0f",
    maroon: "800000",
    mediumaquamarine: "66cdaa",
    mediumblue: "0000cd",
    mediumorchid: "ba55d3",
    mediumpurple: "9370db",
    mediumseagreen: "3cb371",
    mediumslateblue: "7b68ee",
    mediumspringgreen: "00fa9a",
    mediumturquoise: "48d1cc",
    mediumvioletred: "c71585",
    midnightblue: "191970",
    mintcream: "f5fffa",
    mistyrose: "ffe4e1",
    moccasin: "ffe4b5",
    navajowhite: "ffdead",
    navy: "000080",
    oldlace: "fdf5e6",
    olive: "808000",
    olivedrab: "6b8e23",
    orange: "ffa500",
    orangered: "ff4500",
    orchid: "da70d6",
    palegoldenrod: "eee8aa",
    palegreen: "98fb98",
    paleturquoise: "afeeee",
    palevioletred: "db7093",
    papayawhip: "ffefd5",
    peachpuff: "ffdab9",
    peru: "cd853f",
    pink: "ffc0cb",
    plum: "dda0dd",
    powderblue: "b0e0e6",
    purple: "800080",
    rebeccapurple: "663399",
    red: "f00",
    rosybrown: "bc8f8f",
    royalblue: "4169e1",
    saddlebrown: "8b4513",
    salmon: "fa8072",
    sandybrown: "f4a460",
    seagreen: "2e8b57",
    seashell: "fff5ee",
    sienna: "a0522d",
    silver: "c0c0c0",
    skyblue: "87ceeb",
    slateblue: "6a5acd",
    slategray: "708090",
    slategrey: "708090",
    snow: "fffafa",
    springgreen: "00ff7f",
    steelblue: "4682b4",
    tan: "d2b48c",
    teal: "008080",
    thistle: "d8bfd8",
    tomato: "ff6347",
    turquoise: "40e0d0",
    violet: "ee82ee",
    wheat: "f5deb3",
    white: "fff",
    whitesmoke: "f5f5f5",
    yellow: "ff0",
    yellowgreen: "9acd32"
  }; // Make it easy to access colors via `hexNames[hex]`

  var hexNames = tinycolor.hexNames = flip(names); // Utilities
  // ---------
  // `{ 'name1': 'val1' }` becomes `{ 'val1': 'name1' }`

  function flip(o) {
    var flipped = {};

    for (var i in o) {
      if (o.hasOwnProperty(i)) {
        flipped[o[i]] = i;
      }
    }

    return flipped;
  } // Return a valid alpha value [0,1] with all invalid values being set to 1


  function boundAlpha(a) {
    a = parseFloat(a);

    if (isNaN(a) || a < 0 || a > 1) {
      a = 1;
    }

    return a;
  } // Take input from [0, n] and return it as [0, 1]


  function bound01(n, max) {
    if (isOnePointZero(n)) {
      n = "100%";
    }

    var processPercent = isPercentage(n);
    n = mathMin(max, mathMax(0, parseFloat(n))); // Automatically convert percentage into number

    if (processPercent) {
      n = parseInt(n * max, 10) / 100;
    } // Handle floating point rounding errors


    if (Math.abs(n - max) < 0.000001) {
      return 1;
    } // Convert into [0, 1] range if it isn't already


    return n % max / parseFloat(max);
  } // Force a number between 0 and 1


  function clamp01(val) {
    return mathMin(1, mathMax(0, val));
  } // Parse a base-16 hex value into a base-10 integer


  function parseIntFromHex(val) {
    return parseInt(val, 16);
  } // Need to handle 1.0 as 100%, since once it is a number, there is no difference between it and 1
  // <http://stackoverflow.com/questions/7422072/javascript-how-to-detect-number-as-a-decimal-including-1-0>


  function isOnePointZero(n) {
    return typeof n == "string" && n.indexOf('.') != -1 && parseFloat(n) === 1;
  } // Check to see if string passed in is a percentage


  function isPercentage(n) {
    return typeof n === "string" && n.indexOf('%') != -1;
  } // Force a hex value to have 2 characters


  function pad2(c) {
    return c.length == 1 ? '0' + c : '' + c;
  } // Replace a decimal with it's percentage value


  function convertToPercentage(n) {
    if (n <= 1) {
      n = n * 100 + "%";
    }

    return n;
  } // Converts a decimal to a hex value


  function convertDecimalToHex(d) {
    return Math.round(parseFloat(d) * 255).toString(16);
  } // Converts a hex value to a decimal


  function convertHexToDecimal(h) {
    return parseIntFromHex(h) / 255;
  }

  var matchers = function () {
    // <http://www.w3.org/TR/css3-values/#integers>
    var CSS_INTEGER = "[-\\+]?\\d+%?"; // <http://www.w3.org/TR/css3-values/#number-value>

    var CSS_NUMBER = "[-\\+]?\\d*\\.\\d+%?"; // Allow positive/negative integer/number.  Don't capture the either/or, just the entire outcome.

    var CSS_UNIT = "(?:" + CSS_NUMBER + ")|(?:" + CSS_INTEGER + ")"; // Actual matching.
    // Parentheses and commas are optional, but not required.
    // Whitespace can take the place of commas or opening paren

    var PERMISSIVE_MATCH3 = "[\\s|\\(]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")\\s*\\)?";
    var PERMISSIVE_MATCH4 = "[\\s|\\(]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")[,|\\s]+(" + CSS_UNIT + ")\\s*\\)?";
    return {
      CSS_UNIT: new RegExp(CSS_UNIT),
      rgb: new RegExp("rgb" + PERMISSIVE_MATCH3),
      rgba: new RegExp("rgba" + PERMISSIVE_MATCH4),
      hsl: new RegExp("hsl" + PERMISSIVE_MATCH3),
      hsla: new RegExp("hsla" + PERMISSIVE_MATCH4),
      hsv: new RegExp("hsv" + PERMISSIVE_MATCH3),
      hsva: new RegExp("hsva" + PERMISSIVE_MATCH4),
      hex3: /^#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})$/,
      hex6: /^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/,
      hex4: /^#?([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})([0-9a-fA-F]{1})$/,
      hex8: /^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/
    };
  }(); // `isValidCSSUnit`
  // Take in a single string / number and check to see if it looks like a CSS unit
  // (see `matchers` above for definition).


  function isValidCSSUnit(color) {
    return !!matchers.CSS_UNIT.exec(color);
  } // `stringInputToObject`
  // Permissive string parsing.  Take in a number of formats, and output an object
  // based on detected format.  Returns `{ r, g, b }` or `{ h, s, l }` or `{ h, s, v}`


  function stringInputToObject(color) {
    color = color.replace(trimLeft, '').replace(trimRight, '').toLowerCase();
    var named = false;

    if (names[color]) {
      color = names[color];
      named = true;
    } else if (color == 'transparent') {
      return {
        r: 0,
        g: 0,
        b: 0,
        a: 0,
        format: "name"
      };
    } // Try to match string input using regular expressions.
    // Keep most of the number bounding out of this function - don't worry about [0,1] or [0,100] or [0,360]
    // Just return an object and let the conversion functions handle that.
    // This way the result will be the same whether the tinycolor is initialized with string or object.


    var match;

    if (match = matchers.rgb.exec(color)) {
      return {
        r: match[1],
        g: match[2],
        b: match[3]
      };
    }

    if (match = matchers.rgba.exec(color)) {
      return {
        r: match[1],
        g: match[2],
        b: match[3],
        a: match[4]
      };
    }

    if (match = matchers.hsl.exec(color)) {
      return {
        h: match[1],
        s: match[2],
        l: match[3]
      };
    }

    if (match = matchers.hsla.exec(color)) {
      return {
        h: match[1],
        s: match[2],
        l: match[3],
        a: match[4]
      };
    }

    if (match = matchers.hsv.exec(color)) {
      return {
        h: match[1],
        s: match[2],
        v: match[3]
      };
    }

    if (match = matchers.hsva.exec(color)) {
      return {
        h: match[1],
        s: match[2],
        v: match[3],
        a: match[4]
      };
    }

    if (match = matchers.hex8.exec(color)) {
      return {
        r: parseIntFromHex(match[1]),
        g: parseIntFromHex(match[2]),
        b: parseIntFromHex(match[3]),
        a: convertHexToDecimal(match[4]),
        format: named ? "name" : "hex8"
      };
    }

    if (match = matchers.hex6.exec(color)) {
      return {
        r: parseIntFromHex(match[1]),
        g: parseIntFromHex(match[2]),
        b: parseIntFromHex(match[3]),
        format: named ? "name" : "hex"
      };
    }

    if (match = matchers.hex4.exec(color)) {
      return {
        r: parseIntFromHex(match[1] + '' + match[1]),
        g: parseIntFromHex(match[2] + '' + match[2]),
        b: parseIntFromHex(match[3] + '' + match[3]),
        a: convertHexToDecimal(match[4] + '' + match[4]),
        format: named ? "name" : "hex8"
      };
    }

    if (match = matchers.hex3.exec(color)) {
      return {
        r: parseIntFromHex(match[1] + '' + match[1]),
        g: parseIntFromHex(match[2] + '' + match[2]),
        b: parseIntFromHex(match[3] + '' + match[3]),
        format: named ? "name" : "hex"
      };
    }

    return false;
  }

  function validateWCAG2Parms(parms) {
    // return valid WCAG2 parms for isReadable.
    // If input parms are invalid, return {"level":"AA", "size":"small"}
    var level, size;
    parms = parms || {
      "level": "AA",
      "size": "small"
    };
    level = (parms.level || "AA").toUpperCase();
    size = (parms.size || "small").toLowerCase();

    if (level !== "AA" && level !== "AAA") {
      level = "AA";
    }

    if (size !== "small" && size !== "large") {
      size = "small";
    }

    return {
      "level": level,
      "size": size
    };
  } // Node: Export function


  if ( true && module.exports) {
    module.exports = tinycolor;
  } // AMD/requirejs: Define the module
  else if (true) {
    !(__WEBPACK_AMD_DEFINE_RESULT__ = (function () {
      return tinycolor;
    }).call(exports, __webpack_require__, exports, module),
		__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
  } // Browser: Expose to window
  else {}
})(Math);

/***/ }),

/***/ 1620:
/***/ (function(__unused_webpack_module, exports) {

"use strict";
var __webpack_unused_export__;


__webpack_unused_export__ = ({
  value: true
}); // runtime helper for setting properties on components
// in a tree-shakable way

exports.Z = (sfc, props) => {
  const target = sfc.__vccOpts || sfc;

  for (const [key, val] of props) {
    target[key] = val;
  }

  return target;
};

/***/ }),

/***/ 883:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(5959);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("a4c83a98", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 8890:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(4368);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("1a787bdc", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 6322:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(3075);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("1862f674", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 426:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(8061);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("c034ceec", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 1029:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(5175);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("299e98aa", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 9108:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(9610);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("b24f45be", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 180:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(6774);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("7c51b67e", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 8421:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(1570);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("9f85176e", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 9806:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(9276);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("50578974", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 5033:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(9424);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("5868d5c4", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 1285:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(5916);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("43ca537e", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 7590:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(420);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("d2a17fb8", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 6893:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(9178);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("edf56fc6", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 7344:
/***/ (function(module, __unused_webpack_exports, __webpack_require__) {

// style-loader: Adds some css to the DOM by adding a <style> tag

// load the styles
var content = __webpack_require__(8651);
if(content.__esModule) content = content.default;
if(typeof content === 'string') content = [[module.id, content, '']];
if(content.locals) module.exports = content.locals;
// add the styles to the DOM
var add = (__webpack_require__(208)/* ["default"] */ .Z)
var update = add("6f79cd00", content, true, {"sourceMap":false,"shadowMode":false});

/***/ }),

/***/ 208:
/***/ (function(__unused_webpack_module, __webpack_exports__, __webpack_require__) {

"use strict";

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "Z": function() { return /* binding */ addStylesClient; }
});

;// CONCATENATED MODULE: ./node_modules/vue-style-loader/lib/listToStyles.js
/**
 * Translates the list format produced by css-loader into something
 * easier to manipulate.
 */
function listToStyles(parentId, list) {
  var styles = [];
  var newStyles = {};

  for (var i = 0; i < list.length; i++) {
    var item = list[i];
    var id = item[0];
    var css = item[1];
    var media = item[2];
    var sourceMap = item[3];
    var part = {
      id: parentId + ':' + i,
      css: css,
      media: media,
      sourceMap: sourceMap
    };

    if (!newStyles[id]) {
      styles.push(newStyles[id] = {
        id: id,
        parts: [part]
      });
    } else {
      newStyles[id].parts.push(part);
    }
  }

  return styles;
}
;// CONCATENATED MODULE: ./node_modules/vue-style-loader/lib/addStylesClient.js
/*
  MIT License http://www.opensource.org/licenses/mit-license.php
  Author Tobias Koppers @sokra
  Modified by Evan You @yyx990803
*/



var hasDocument = typeof document !== 'undefined'

if (typeof DEBUG !== 'undefined' && DEBUG) {
  if (!hasDocument) {
    throw new Error(
    'vue-style-loader cannot be used in a non-browser environment. ' +
    "Use { target: 'node' } in your Webpack config to indicate a server-rendering environment."
  ) }
}

/*
type StyleObject = {
  id: number;
  parts: Array<StyleObjectPart>
}

type StyleObjectPart = {
  css: string;
  media: string;
  sourceMap: ?string
}
*/

var stylesInDom = {/*
  [id: number]: {
    id: number,
    refs: number,
    parts: Array<(obj?: StyleObjectPart) => void>
  }
*/}

var head = hasDocument && (document.head || document.getElementsByTagName('head')[0])
var singletonElement = null
var singletonCounter = 0
var isProduction = false
var noop = function () {}
var options = null
var ssrIdKey = 'data-vue-ssr-id'

// Force single-tag solution on IE6-9, which has a hard limit on the # of <style>
// tags it will allow on a page
var isOldIE = typeof navigator !== 'undefined' && /msie [6-9]\b/.test(navigator.userAgent.toLowerCase())

function addStylesClient (parentId, list, _isProduction, _options) {
  isProduction = _isProduction

  options = _options || {}

  var styles = listToStyles(parentId, list)
  addStylesToDom(styles)

  return function update (newList) {
    var mayRemove = []
    for (var i = 0; i < styles.length; i++) {
      var item = styles[i]
      var domStyle = stylesInDom[item.id]
      domStyle.refs--
      mayRemove.push(domStyle)
    }
    if (newList) {
      styles = listToStyles(parentId, newList)
      addStylesToDom(styles)
    } else {
      styles = []
    }
    for (var i = 0; i < mayRemove.length; i++) {
      var domStyle = mayRemove[i]
      if (domStyle.refs === 0) {
        for (var j = 0; j < domStyle.parts.length; j++) {
          domStyle.parts[j]()
        }
        delete stylesInDom[domStyle.id]
      }
    }
  }
}

function addStylesToDom (styles /* Array<StyleObject> */) {
  for (var i = 0; i < styles.length; i++) {
    var item = styles[i]
    var domStyle = stylesInDom[item.id]
    if (domStyle) {
      domStyle.refs++
      for (var j = 0; j < domStyle.parts.length; j++) {
        domStyle.parts[j](item.parts[j])
      }
      for (; j < item.parts.length; j++) {
        domStyle.parts.push(addStyle(item.parts[j]))
      }
      if (domStyle.parts.length > item.parts.length) {
        domStyle.parts.length = item.parts.length
      }
    } else {
      var parts = []
      for (var j = 0; j < item.parts.length; j++) {
        parts.push(addStyle(item.parts[j]))
      }
      stylesInDom[item.id] = { id: item.id, refs: 1, parts: parts }
    }
  }
}

function createStyleElement () {
  var styleElement = document.createElement('style')
  styleElement.type = 'text/css'
  head.appendChild(styleElement)
  return styleElement
}

function addStyle (obj /* StyleObjectPart */) {
  var update, remove
  var styleElement = document.querySelector('style[' + ssrIdKey + '~="' + obj.id + '"]')

  if (styleElement) {
    if (isProduction) {
      // has SSR styles and in production mode.
      // simply do nothing.
      return noop
    } else {
      // has SSR styles but in dev mode.
      // for some reason Chrome can't handle source map in server-rendered
      // style tags - source maps in <style> only works if the style tag is
      // created and inserted dynamically. So we remove the server rendered
      // styles and inject new ones.
      styleElement.parentNode.removeChild(styleElement)
    }
  }

  if (isOldIE) {
    // use singleton mode for IE9.
    var styleIndex = singletonCounter++
    styleElement = singletonElement || (singletonElement = createStyleElement())
    update = applyToSingletonTag.bind(null, styleElement, styleIndex, false)
    remove = applyToSingletonTag.bind(null, styleElement, styleIndex, true)
  } else {
    // use multi-style-tag mode in all other cases
    styleElement = createStyleElement()
    update = applyToTag.bind(null, styleElement)
    remove = function () {
      styleElement.parentNode.removeChild(styleElement)
    }
  }

  update(obj)

  return function updateStyle (newObj /* StyleObjectPart */) {
    if (newObj) {
      if (newObj.css === obj.css &&
          newObj.media === obj.media &&
          newObj.sourceMap === obj.sourceMap) {
        return
      }
      update(obj = newObj)
    } else {
      remove()
    }
  }
}

var replaceText = (function () {
  var textStore = []

  return function (index, replacement) {
    textStore[index] = replacement
    return textStore.filter(Boolean).join('\n')
  }
})()

function applyToSingletonTag (styleElement, index, remove, obj) {
  var css = remove ? '' : obj.css

  if (styleElement.styleSheet) {
    styleElement.styleSheet.cssText = replaceText(index, css)
  } else {
    var cssNode = document.createTextNode(css)
    var childNodes = styleElement.childNodes
    if (childNodes[index]) styleElement.removeChild(childNodes[index])
    if (childNodes.length) {
      styleElement.insertBefore(cssNode, childNodes[index])
    } else {
      styleElement.appendChild(cssNode)
    }
  }
}

function applyToTag (styleElement, obj) {
  var css = obj.css
  var media = obj.media
  var sourceMap = obj.sourceMap

  if (media) {
    styleElement.setAttribute('media', media)
  }
  if (options.ssrId) {
    styleElement.setAttribute(ssrIdKey, obj.id)
  }

  if (sourceMap) {
    // https://developer.chrome.com/devtools/docs/javascript-debugging
    // this makes source maps inside style tags work properly in Chrome
    css += '\n/*# sourceURL=' + sourceMap.sources[0] + ' */'
    // http://stackoverflow.com/a/26603875
    css += '\n/*# sourceMappingURL=data:application/json;base64,' + btoa(unescape(encodeURIComponent(JSON.stringify(sourceMap)))) + ' */'
  }

  if (styleElement.styleSheet) {
    styleElement.styleSheet.cssText = css
  } else {
    while (styleElement.firstChild) {
      styleElement.removeChild(styleElement.firstChild)
    }
    styleElement.appendChild(document.createTextNode(css))
  }
}


/***/ }),

/***/ 7203:
/***/ (function(module) {

"use strict";
module.exports = __WEBPACK_EXTERNAL_MODULE__7203__;

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			id: moduleId,
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/compat get default export */
/******/ 	!function() {
/******/ 		// getDefaultExport function for compatibility with non-harmony modules
/******/ 		__webpack_require__.n = function(module) {
/******/ 			var getter = module && module.__esModule ?
/******/ 				function() { return module['default']; } :
/******/ 				function() { return module; };
/******/ 			__webpack_require__.d(getter, { a: getter });
/******/ 			return getter;
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/define property getters */
/******/ 	!function() {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = function(exports, definition) {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/global */
/******/ 	!function() {
/******/ 		__webpack_require__.g = (function() {
/******/ 			if (typeof globalThis === 'object') return globalThis;
/******/ 			try {
/******/ 				return this || new Function('return this')();
/******/ 			} catch (e) {
/******/ 				if (typeof window === 'object') return window;
/******/ 			}
/******/ 		})();
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	!function() {
/******/ 		__webpack_require__.o = function(obj, prop) { return Object.prototype.hasOwnProperty.call(obj, prop); }
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	!function() {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = function(exports) {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	}();
/******/ 	
/******/ 	/* webpack/runtime/publicPath */
/******/ 	!function() {
/******/ 		__webpack_require__.p = "";
/******/ 	}();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be in strict mode.
!function() {
"use strict";
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

// EXPORTS
__webpack_require__.d(__webpack_exports__, {
  "Alpha": function() { return /* reexport */ Alpha; },
  "Checkboard": function() { return /* reexport */ Checkboard; },
  "Chrome": function() { return /* reexport */ Chrome; },
  "ColorMixin": function() { return /* reexport */ color; },
  "Compact": function() { return /* reexport */ Compact; },
  "EditableInput": function() { return /* reexport */ EditableInput; },
  "Grayscale": function() { return /* reexport */ Grayscale; },
  "Hue": function() { return /* reexport */ Hue; },
  "Material": function() { return /* reexport */ Material; },
  "Photoshop": function() { return /* reexport */ Photoshop; },
  "Saturation": function() { return /* reexport */ Saturation; },
  "Sketch": function() { return /* reexport */ Sketch; },
  "Slider": function() { return /* reexport */ Slider; },
  "Swatches": function() { return /* reexport */ Swatches; },
  "Twitter": function() { return /* reexport */ Twitter; },
  "default": function() { return /* binding */ entry_lib; },
  "version": function() { return /* reexport */ version; }
});

;// CONCATENATED MODULE: ./node_modules/@vue/cli-service/lib/commands/build/setPublicPath.js
/* eslint-disable no-var */
// This file is imported into lib/wc client bundles.

if (typeof window !== 'undefined') {
  var currentScript = window.document.currentScript
  if (false) { var getCurrentScript; }

  var src = currentScript && currentScript.src.match(/(.+\/)[^/]+\.js(\?.*)?$/)
  if (src) {
    __webpack_require__.p = src[1] // eslint-disable-line
  }
}

// Indicate to webpack that this file can be concatenated
/* harmony default export */ var setPublicPath = (null);

;// CONCATENATED MODULE: ./package.json
var package_namespaceObject = {"i8":"3.0.6"};
// EXTERNAL MODULE: external {"commonjs":"vue","commonjs2":"vue","root":"Vue"}
var external_commonjs_vue_commonjs2_vue_root_Vue_ = __webpack_require__(7203);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Compact.vue?vue&type=template&id=1fcf22b8

const _hoisted_1 = {
  role: "application",
  "aria-label": "Compact color picker",
  class: "vc-compact"
};
const _hoisted_2 = {
  class: "vc-compact-colors",
  role: "listbox"
};
const _hoisted_3 = ["aria-label", "aria-selected", "onClick"];
const _hoisted_4 = {
  class: "vc-compact-dot"
};
function render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", _hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("ul", _hoisted_2, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)(_ctx.paletteUpperCase($props.palette), c => {
    return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("li", {
      role: "option",
      "aria-label": 'color:' + c,
      "aria-selected": c === $options.pick,
      class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(["vc-compact-color-item", {
        'vc-compact-color-item--white': c === '#FFFFFF'
      }]),
      key: c,
      style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
        background: c
      }),
      onClick: $event => $options.handlerClick(c)
    }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_4, null, 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, c === $options.pick]])], 14, _hoisted_3);
  }), 128))])]);
}
;// CONCATENATED MODULE: ./src/components/Compact.vue?vue&type=template&id=1fcf22b8

// EXTERNAL MODULE: ./node_modules/tinycolor2/tinycolor.js
var tinycolor = __webpack_require__(9339);
var tinycolor_default = /*#__PURE__*/__webpack_require__.n(tinycolor);
;// CONCATENATED MODULE: ./src/mixin/color.js


function _colorChange(data = {}, oldHue = 0) {
  const alpha = data && data.a;
  let color; // hsl is better than hex between conversions

  if (data && data.hsl) {
    color = tinycolor_default()(data.hsl);
  } else if (data && data.hex && data.hex.length > 0) {
    color = tinycolor_default()(data.hex);
  } else if (data && data.hsv) {
    color = tinycolor_default()(data.hsv);
  } else if (data && data.rgba) {
    color = tinycolor_default()(data.rgba);
  } else if (data && data.rgb) {
    color = tinycolor_default()(data.rgb);
  } else {
    color = tinycolor_default()(data);
  }

  if (color && (color._a === undefined || color._a === null)) {
    color.setAlpha(alpha || 1);
  }

  const hsl = color.toHsl();
  const hsv = color.toHsv();

  if (hsl.s === 0) {
    hsv.h = hsl.h = data.h || data.hsl && data.hsl.h || oldHue || 0;
  }
  /* --- comment this block to fix #109, may cause #25 again --- */
  // when the hsv.v is less than 0.0164 (base on test)
  // because of possible loss of precision
  // the result of hue and saturation would be miscalculated
  // if (hsv.v < 0.0164) {
  //   hsv.h = data.h || (data.hsv && data.hsv.h) || 0
  //   hsv.s = data.s || (data.hsv && data.hsv.s) || 0
  // }
  // if (hsl.l < 0.01) {
  //   hsl.h = data.h || (data.hsl && data.hsl.h) || 0
  //   hsl.s = data.s || (data.hsl && data.hsl.s) || 0
  // }

  /* ------ */


  return {
    hsl: hsl,
    hex: color.toHexString().toUpperCase(),
    hex8: color.toHex8String().toUpperCase(),
    rgba: color.toRgb(),
    hsv: hsv,
    oldHue: data.h || oldHue || hsl.h,
    source: data.source,
    a: data.a || color.getAlpha()
  };
}

/* harmony default export */ var color = ({
  props: ['modelValue'],

  data() {
    return {
      val: _colorChange(this.modelValue)
    };
  },

  computed: {
    colors: {
      get() {
        return this.val;
      },

      set(newVal) {
        this.val = newVal;
        this.$emit('update:modelValue', newVal);
      }

    }
  },
  watch: {
    modelValue(newVal) {
      this.val = _colorChange(newVal);
    }

  },
  methods: {
    colorChange(data, oldHue) {
      this.oldHue = this.colors.hsl.h;
      this.colors = _colorChange(data, oldHue || this.oldHue);
    },

    isValidHex(hex) {
      return tinycolor_default()(hex).isValid();
    },

    simpleCheckForValidColor(data) {
      const keysToCheck = ['r', 'g', 'b', 'a', 'h', 's', 'l', 'v'];
      let checked = 0;
      let passed = 0;

      for (let i = 0; i < keysToCheck.length; i++) {
        const letter = keysToCheck[i];

        if (data[letter]) {
          checked++;

          if (!isNaN(data[letter])) {
            passed++;
          }
        }
      }

      if (checked === passed) {
        return data;
      }
    },

    paletteUpperCase(palette) {
      return palette.map(c => c.toUpperCase());
    },

    isTransparent(color) {
      return tinycolor_default()(color).getAlpha() === 0;
    }

  }
});
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Compact.vue?vue&type=script&lang=js
 // import editableInput from './common/EditableInput.vue'

const defaultColors = ['#4D4D4D', '#999999', '#FFFFFF', '#F44E3B', '#FE9200', '#FCDC00', '#DBDF00', '#A4DD00', '#68CCCA', '#73D8FF', '#AEA1FF', '#FDA1FF', '#333333', '#808080', '#CCCCCC', '#D33115', '#E27300', '#FCC400', '#B0BC00', '#68BC00', '#16A5A5', '#009CE0', '#7B64FF', '#FA28FF', '#000000', '#666666', '#B3B3B3', '#9F0500', '#C45100', '#FB9E00', '#808900', '#194D33', '#0C797D', '#0062B1', '#653294', '#AB149E'];
/* harmony default export */ var Compactvue_type_script_lang_js = ({
  name: 'Compact',
  mixins: [color],
  props: {
    palette: {
      type: Array,

      default() {
        return defaultColors;
      }

    }
  },
  components: {// 'ed-in': editableInput
  },
  computed: {
    pick() {
      return this.colors.hex.toUpperCase();
    }

  },
  methods: {
    handlerClick(c) {
      this.colorChange({
        hex: c,
        source: 'hex'
      });
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Compact.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Compact.vue?vue&type=style&index=0&id=1fcf22b8&lang=css
var Compactvue_type_style_index_0_id_1fcf22b8_lang_css = __webpack_require__(8890);
;// CONCATENATED MODULE: ./src/components/Compact.vue?vue&type=style&index=0&id=1fcf22b8&lang=css

// EXTERNAL MODULE: ./node_modules/vue-loader/dist/exportHelper.js
var exportHelper = __webpack_require__(1620);
;// CONCATENATED MODULE: ./src/components/Compact.vue




;


const __exports__ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Compactvue_type_script_lang_js, [['render',render]])

/* harmony default export */ var Compact = (__exports__);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Grayscale.vue?vue&type=template&id=5742c0cf

const Grayscalevue_type_template_id_5742c0cf_hoisted_1 = {
  role: "application",
  "aria-label": "Grayscale color picker",
  class: "vc-grayscale"
};
const Grayscalevue_type_template_id_5742c0cf_hoisted_2 = {
  class: "vc-grayscale-colors",
  role: "listbox"
};
const Grayscalevue_type_template_id_5742c0cf_hoisted_3 = ["aria-label", "aria-selected", "onClick"];
const Grayscalevue_type_template_id_5742c0cf_hoisted_4 = {
  class: "vc-grayscale-dot"
};
function Grayscalevue_type_template_id_5742c0cf_render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Grayscalevue_type_template_id_5742c0cf_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("ul", Grayscalevue_type_template_id_5742c0cf_hoisted_2, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)(_ctx.paletteUpperCase($props.palette), c => {
    return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("li", {
      role: "option",
      "aria-label": 'Color:' + c,
      "aria-selected": c === $options.pick,
      key: c,
      class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(["vc-grayscale-color-item", {
        'vc-grayscale-color-item--white': c == '#FFFFFF'
      }]),
      style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
        background: c
      }),
      onClick: $event => $options.handlerClick(c)
    }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Grayscalevue_type_template_id_5742c0cf_hoisted_4, null, 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, c === $options.pick]])], 14, Grayscalevue_type_template_id_5742c0cf_hoisted_3);
  }), 128))])]);
}
;// CONCATENATED MODULE: ./src/components/Grayscale.vue?vue&type=template&id=5742c0cf

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Grayscale.vue?vue&type=script&lang=js

const Grayscalevue_type_script_lang_js_defaultColors = ['#FFFFFF', '#F2F2F2', '#E6E6E6', '#D9D9D9', '#CCCCCC', '#BFBFBF', '#B3B3B3', '#A6A6A6', '#999999', '#8C8C8C', '#808080', '#737373', '#666666', '#595959', '#4D4D4D', '#404040', '#333333', '#262626', '#0D0D0D', '#000000'];
/* harmony default export */ var Grayscalevue_type_script_lang_js = ({
  name: 'Grayscale',
  mixins: [color],
  props: {
    palette: {
      type: Array,

      default() {
        return Grayscalevue_type_script_lang_js_defaultColors;
      }

    }
  },
  components: {},
  computed: {
    pick() {
      return this.colors.hex.toUpperCase();
    }

  },
  methods: {
    handlerClick(c) {
      this.colorChange({
        hex: c,
        source: 'hex'
      });
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Grayscale.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Grayscale.vue?vue&type=style&index=0&id=5742c0cf&lang=css
var Grayscalevue_type_style_index_0_id_5742c0cf_lang_css = __webpack_require__(6322);
;// CONCATENATED MODULE: ./src/components/Grayscale.vue?vue&type=style&index=0&id=5742c0cf&lang=css

;// CONCATENATED MODULE: ./src/components/Grayscale.vue




;


const Grayscale_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Grayscalevue_type_script_lang_js, [['render',Grayscalevue_type_template_id_5742c0cf_render]])

/* harmony default export */ var Grayscale = (Grayscale_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Material.vue?vue&type=template&id=6dd2ea40

const Materialvue_type_template_id_6dd2ea40_hoisted_1 = {
  role: "application",
  "aria-label": "Material color picker",
  class: "vc-material"
};
const Materialvue_type_template_id_6dd2ea40_hoisted_2 = {
  class: "vc-material-split"
};
const Materialvue_type_template_id_6dd2ea40_hoisted_3 = {
  class: "vc-material-third"
};
const Materialvue_type_template_id_6dd2ea40_hoisted_4 = {
  class: "vc-material-third"
};
const _hoisted_5 = {
  class: "vc-material-third"
};
function Materialvue_type_template_id_6dd2ea40_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_ed_in = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("ed-in");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Materialvue_type_template_id_6dd2ea40_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    class: "vc-material-hex",
    label: "hex",
    modelValue: _ctx.colors.hex,
    "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => _ctx.colors.hex = $event),
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      borderColor: _ctx.colors.hex
    }),
    onChange: $options.onChange
  }, null, 8, ["modelValue", "style", "onChange"]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Materialvue_type_template_id_6dd2ea40_hoisted_2, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Materialvue_type_template_id_6dd2ea40_hoisted_3, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "r",
    modelValue: _ctx.colors.rgba.r,
    "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => _ctx.colors.rgba.r = $event),
    onChange: $options.onChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Materialvue_type_template_id_6dd2ea40_hoisted_4, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "g",
    modelValue: _ctx.colors.rgba.g,
    "onUpdate:modelValue": _cache[2] || (_cache[2] = $event => _ctx.colors.rgba.g = $event),
    onChange: $options.onChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_5, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "b",
    modelValue: _ctx.colors.rgba.b,
    "onUpdate:modelValue": _cache[3] || (_cache[3] = $event => _ctx.colors.rgba.b = $event),
    onChange: $options.onChange
  }, null, 8, ["modelValue", "onChange"])])])]);
}
;// CONCATENATED MODULE: ./src/components/Material.vue?vue&type=template&id=6dd2ea40

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/EditableInput.vue?vue&type=template&id=56925d0b

const EditableInputvue_type_template_id_56925d0b_hoisted_1 = {
  class: "vc-editable-input"
};
const EditableInputvue_type_template_id_56925d0b_hoisted_2 = ["aria-labelledby"];
const EditableInputvue_type_template_id_56925d0b_hoisted_3 = ["for", "id"];
const EditableInputvue_type_template_id_56925d0b_hoisted_4 = {
  class: "vc-input__desc"
};
function EditableInputvue_type_template_id_56925d0b_render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", EditableInputvue_type_template_id_56925d0b_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("input", {
    "aria-labelledby": $options.labelId,
    class: "vc-input__input",
    "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => $options.val = $event),
    onKeydown: _cache[1] || (_cache[1] = (...args) => $options.handleKeyDown && $options.handleKeyDown(...args)),
    onInput: _cache[2] || (_cache[2] = (...args) => $options.update && $options.update(...args)),
    ref: "input"
  }, null, 40, EditableInputvue_type_template_id_56925d0b_hoisted_2), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vModelText, $options.val]]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("span", {
    for: $props.label,
    class: "vc-input__label",
    id: $options.labelId
  }, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($options.labelSpanText), 9, EditableInputvue_type_template_id_56925d0b_hoisted_3), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("span", EditableInputvue_type_template_id_56925d0b_hoisted_4, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.desc), 1)]);
}
;// CONCATENATED MODULE: ./src/components/common/EditableInput.vue?vue&type=template&id=56925d0b

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/EditableInput.vue?vue&type=script&lang=js
/* harmony default export */ var EditableInputvue_type_script_lang_js = ({
  name: 'editableInput',
  props: {
    label: String,
    labelText: String,
    desc: String,
    modelValue: [String, Number],
    max: Number,
    min: Number,
    arrowOffset: {
      type: Number,
      default: 1
    }
  },
  computed: {
    val: {
      get() {
        return this.modelValue;
      },

      set(v) {
        // TODO: min
        if (!(this.max === undefined) && +v > this.max) {
          this.$refs.input.value = this.max;
        } else {
          return v;
        }
      }

    },

    labelId() {
      return `input__label__${this.label}__${Math.random().toString().slice(2, 5)}`;
    },

    labelSpanText() {
      return this.labelText || this.label;
    }

  },
  methods: {
    update(e) {
      this.handleChange(e.target.value);
    },

    handleChange(newVal) {
      const data = {};
      data[this.label] = newVal;

      if (data.hex === undefined && data['#'] === undefined) {
        this.$emit('change', data);
      } else if (newVal.length > 5) {
        this.$emit('change', data);
      }
    },

    // **** unused
    // handleBlur (e) {
    //   console.log(e)
    // },
    handleKeyDown(e) {
      let val = this.val;
      const number = Number(val);

      if (number) {
        const amount = this.arrowOffset || 1; // Up

        if (e.keyCode === 38) {
          val = number + amount;
          this.handleChange(val);
          e.preventDefault();
        } // Down


        if (e.keyCode === 40) {
          val = number - amount;
          this.handleChange(val);
          e.preventDefault();
        }
      }
    } // **** unused
    // handleDrag (e) {
    //   console.log(e)
    // },
    // handleMouseDown (e) {
    //   console.log(e)
    // }


  }
});
;// CONCATENATED MODULE: ./src/components/common/EditableInput.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/EditableInput.vue?vue&type=style&index=0&id=56925d0b&lang=css
var EditableInputvue_type_style_index_0_id_56925d0b_lang_css = __webpack_require__(7590);
;// CONCATENATED MODULE: ./src/components/common/EditableInput.vue?vue&type=style&index=0&id=56925d0b&lang=css

;// CONCATENATED MODULE: ./src/components/common/EditableInput.vue




;


const EditableInput_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(EditableInputvue_type_script_lang_js, [['render',EditableInputvue_type_template_id_56925d0b_render]])

/* harmony default export */ var EditableInput = (EditableInput_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Material.vue?vue&type=script&lang=js


/* harmony default export */ var Materialvue_type_script_lang_js = ({
  name: 'Material',
  mixins: [color],
  components: {
    'ed-in': EditableInput
  },
  methods: {
    onChange(data) {
      if (!data) {
        return;
      }

      if (data.hex) {
        this.isValidHex(data.hex) && this.colorChange({
          hex: data.hex,
          source: 'hex'
        });
      } else if (data.r || data.g || data.b) {
        this.colorChange({
          r: data.r || this.colors.rgba.r,
          g: data.g || this.colors.rgba.g,
          b: data.b || this.colors.rgba.b,
          a: data.a || this.colors.rgba.a,
          source: 'rgba'
        });
      }
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Material.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Material.vue?vue&type=style&index=0&id=6dd2ea40&lang=css
var Materialvue_type_style_index_0_id_6dd2ea40_lang_css = __webpack_require__(426);
;// CONCATENATED MODULE: ./src/components/Material.vue?vue&type=style&index=0&id=6dd2ea40&lang=css

;// CONCATENATED MODULE: ./src/components/Material.vue




;


const Material_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Materialvue_type_script_lang_js, [['render',Materialvue_type_template_id_6dd2ea40_render]])

/* harmony default export */ var Material = (Material_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Slider.vue?vue&type=template&id=c87f38e0

const Slidervue_type_template_id_c87f38e0_hoisted_1 = {
  role: "application",
  "aria-label": "Slider color picker",
  class: "vc-slider"
};
const Slidervue_type_template_id_c87f38e0_hoisted_2 = {
  class: "vc-slider-hue-warp"
};
const Slidervue_type_template_id_c87f38e0_hoisted_3 = {
  class: "vc-slider-swatches",
  role: "group"
};
const Slidervue_type_template_id_c87f38e0_hoisted_4 = ["data-index", "aria-label", "onClick"];
function Slidervue_type_template_id_c87f38e0_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_hue = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("hue");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Slidervue_type_template_id_c87f38e0_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Slidervue_type_template_id_c87f38e0_hoisted_2, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_hue, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => _ctx.colors = $event),
    onChange: $options.hueChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Slidervue_type_template_id_c87f38e0_hoisted_3, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)($options.normalizedSwatches, (swatch, index) => {
    return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
      class: "vc-slider-swatch",
      key: index,
      "data-index": index,
      "aria-label": 'color:' + _ctx.colors.hex,
      role: "button",
      onClick: $event => $options.handleSwClick(index, swatch)
    }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
      class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(["vc-slider-swatch-picker", {
        'vc-slider-swatch-picker--active': $options.isActive(swatch, index),
        'vc-slider-swatch-picker--white': swatch.l === 1
      }]),
      style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
        background: 'hsl(' + _ctx.colors.hsl.h + ', ' + swatch.s * 100 + '%, ' + swatch.l * 100 + '%)'
      })
    }, null, 6)], 8, Slidervue_type_template_id_c87f38e0_hoisted_4);
  }), 128))])]);
}
;// CONCATENATED MODULE: ./src/components/Slider.vue?vue&type=template&id=c87f38e0

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Hue.vue?vue&type=template&id=d0fd3296

const Huevue_type_template_id_d0fd3296_hoisted_1 = ["aria-valuenow"];

const Huevue_type_template_id_d0fd3296_hoisted_2 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-hue-picker"
}, null, -1);

const Huevue_type_template_id_d0fd3296_hoisted_3 = [Huevue_type_template_id_d0fd3296_hoisted_2];
function Huevue_type_template_id_d0fd3296_render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(['vc-hue', $options.directionClass])
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-hue-container",
    role: "slider",
    "aria-valuenow": $options.colors.hsl.h,
    "aria-valuemin": "0",
    "aria-valuemax": "360",
    ref: "container",
    onMousedown: _cache[0] || (_cache[0] = (...args) => $options.handleMouseDown && $options.handleMouseDown(...args)),
    onTouchmove: _cache[1] || (_cache[1] = (...args) => $options.handleChange && $options.handleChange(...args)),
    onTouchstart: _cache[2] || (_cache[2] = (...args) => $options.handleChange && $options.handleChange(...args))
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-hue-pointer",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      top: $options.pointerTop,
      left: $options.pointerLeft
    }),
    role: "presentation"
  }, Huevue_type_template_id_d0fd3296_hoisted_3, 4)], 40, Huevue_type_template_id_d0fd3296_hoisted_1)], 2);
}
;// CONCATENATED MODULE: ./src/components/common/Hue.vue?vue&type=template&id=d0fd3296

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Hue.vue?vue&type=script&lang=js
/* harmony default export */ var Huevue_type_script_lang_js = ({
  name: 'Hue',
  props: {
    modelValue: Object,
    direction: {
      type: String,
      // [horizontal | vertical]
      default: 'horizontal'
    }
  },

  data() {
    return {
      oldHue: 0,
      pullDirection: ''
    };
  },

  computed: {
    colors() {
      const h = this.modelValue.hsl.h; // vue/no-side-effects-in-computed-properties

      /* eslint-disable */

      if (h !== 0 && h - this.oldHue > 0) this.pullDirection = 'right';
      if (h !== 0 && h - this.oldHue < 0) this.pullDirection = 'left';
      this.oldHue = h;
      /* eslint-enable */

      return this.modelValue;
    },

    directionClass() {
      return {
        'vc-hue--horizontal': this.direction === 'horizontal',
        'vc-hue--vertical': this.direction === 'vertical'
      };
    },

    pointerTop() {
      if (this.direction === 'vertical') {
        if (this.colors.hsl.h === 0 && this.pullDirection === 'right') return 0;
        return -(this.colors.hsl.h * 100 / 360) + 100 + '%';
      } else {
        return 0;
      }
    },

    pointerLeft() {
      if (this.direction === 'vertical') {
        return 0;
      } else {
        if (this.colors.hsl.h === 0 && this.pullDirection === 'right') return '100%';
        return this.colors.hsl.h * 100 / 360 + '%';
      }
    }

  },
  methods: {
    handleChange(e, skip) {
      !skip && e.preventDefault();
      const container = this.$refs.container;

      if (!container) {
        // for some edge cases, container may not exist. see #220
        return;
      }

      const containerWidth = container.clientWidth;
      const containerHeight = container.clientHeight;
      const xOffset = container.getBoundingClientRect().left + window.pageXOffset;
      const yOffset = container.getBoundingClientRect().top + window.pageYOffset;
      const pageX = e.pageX || (e.touches ? e.touches[0].pageX : 0);
      const pageY = e.pageY || (e.touches ? e.touches[0].pageY : 0);
      const left = pageX - xOffset;
      const top = pageY - yOffset;
      let h;
      let percent;

      if (this.direction === 'vertical') {
        if (top < 0) {
          h = 360;
        } else if (top > containerHeight) {
          h = 0;
        } else {
          percent = -(top * 100 / containerHeight) + 100;
          h = 360 * percent / 100;
        }

        if (this.colors.hsl.h !== h) {
          this.$emit('change', {
            h: h,
            s: this.colors.hsl.s,
            l: this.colors.hsl.l,
            a: this.colors.hsl.a,
            source: 'hsl'
          });
        }
      } else {
        if (left < 0) {
          h = 0;
        } else if (left > containerWidth) {
          h = 360;
        } else {
          percent = left * 100 / containerWidth;
          h = 360 * percent / 100;
        }

        if (this.colors.hsl.h !== h) {
          this.$emit('change', {
            h: h,
            s: this.colors.hsl.s,
            l: this.colors.hsl.l,
            a: this.colors.hsl.a,
            source: 'hsl'
          });
        }
      }
    },

    handleMouseDown(e) {
      this.handleChange(e, true);
      window.addEventListener('mousemove', this.handleChange);
      window.addEventListener('mouseup', this.handleMouseUp);
    },

    handleMouseUp(e) {
      this.unbindEventListeners();
    },

    unbindEventListeners() {
      window.removeEventListener('mousemove', this.handleChange);
      window.removeEventListener('mouseup', this.handleMouseUp);
    }

  }
});
;// CONCATENATED MODULE: ./src/components/common/Hue.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Hue.vue?vue&type=style&index=0&id=d0fd3296&lang=css
var Huevue_type_style_index_0_id_d0fd3296_lang_css = __webpack_require__(6893);
;// CONCATENATED MODULE: ./src/components/common/Hue.vue?vue&type=style&index=0&id=d0fd3296&lang=css

;// CONCATENATED MODULE: ./src/components/common/Hue.vue




;


const Hue_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Huevue_type_script_lang_js, [['render',Huevue_type_template_id_d0fd3296_render]])

/* harmony default export */ var Hue = (Hue_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Slider.vue?vue&type=script&lang=js


const DEFAULT_SATURATION = 0.5;
/* harmony default export */ var Slidervue_type_script_lang_js = ({
  name: 'Slider',
  mixins: [color],
  props: {
    swatches: {
      type: Array,

      default() {
        // also accepts: ['.80', '.65', '.50', '.35', '.20']
        return [{
          s: DEFAULT_SATURATION,
          l: 0.8
        }, {
          s: DEFAULT_SATURATION,
          l: 0.65
        }, {
          s: DEFAULT_SATURATION,
          l: 0.5
        }, {
          s: DEFAULT_SATURATION,
          l: 0.35
        }, {
          s: DEFAULT_SATURATION,
          l: 0.2
        }];
      }

    }
  },
  components: {
    hue: Hue
  },
  computed: {
    normalizedSwatches() {
      const swatches = this.swatches;
      return swatches.map(swatch => {
        // to be compatible with another data format ['.80', '.65', '.50', '.35', '.20']
        if (typeof swatch !== 'object') {
          return {
            s: DEFAULT_SATURATION,
            l: swatch
          };
        }

        return swatch;
      });
    }

  },
  methods: {
    isActive(swatch, index) {
      const hsl = this.colors.hsl;

      if (hsl.l === 1 && swatch.l === 1) {
        return true;
      }

      if (hsl.l === 0 && swatch.l === 0) {
        return true;
      }

      return Math.abs(hsl.l - swatch.l) < 0.01 && Math.abs(hsl.s - swatch.s) < 0.01;
    },

    hueChange(data) {
      this.colorChange(data);
    },

    handleSwClick(index, swatch) {
      this.colorChange({
        h: this.colors.hsl.h,
        s: swatch.s,
        l: swatch.l,
        source: 'hsl'
      });
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Slider.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Slider.vue?vue&type=style&index=0&id=c87f38e0&lang=css
var Slidervue_type_style_index_0_id_c87f38e0_lang_css = __webpack_require__(180);
;// CONCATENATED MODULE: ./src/components/Slider.vue?vue&type=style&index=0&id=c87f38e0&lang=css

;// CONCATENATED MODULE: ./src/components/Slider.vue




;


const Slider_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Slidervue_type_script_lang_js, [['render',Slidervue_type_template_id_c87f38e0_render]])

/* harmony default export */ var Slider = (Slider_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Swatches.vue?vue&type=template&id=3e9acefe

const Swatchesvue_type_template_id_3e9acefe_hoisted_1 = ["data-pick"];
const Swatchesvue_type_template_id_3e9acefe_hoisted_2 = {
  class: "vc-swatches-box",
  role: "listbox"
};
const Swatchesvue_type_template_id_3e9acefe_hoisted_3 = ["aria-label", "aria-selected", "data-color", "onClick"];
const Swatchesvue_type_template_id_3e9acefe_hoisted_4 = {
  class: "vc-swatches-pick"
};

const Swatchesvue_type_template_id_3e9acefe_hoisted_5 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("svg", {
  style: {
    "width": "24px",
    "height": "24px"
  },
  viewBox: "0 0 24 24"
}, [/*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("path", {
  d: "M21,7L9,19L3.5,13.5L4.91,12.09L9,16.17L19.59,5.59L21,7Z"
})], -1);

const _hoisted_6 = [Swatchesvue_type_template_id_3e9acefe_hoisted_5];
function Swatchesvue_type_template_id_3e9acefe_render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    role: "application",
    "aria-label": "Swatches color picker",
    class: "vc-swatches",
    "data-pick": $options.pick
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Swatchesvue_type_template_id_3e9acefe_hoisted_2, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)($props.palette, (group, $idx) => {
    return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
      class: "vc-swatches-color-group",
      key: $idx
    }, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)(group, c => {
      return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
        class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(['vc-swatches-color-it', {
          'vc-swatches-color--white': c === '#FFFFFF'
        }]),
        role: "option",
        "aria-label": 'Color:' + c,
        "aria-selected": $options.equal(c),
        key: c,
        "data-color": c,
        style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
          background: c
        }),
        onClick: $event => $options.handlerClick(c)
      }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Swatchesvue_type_template_id_3e9acefe_hoisted_4, _hoisted_6, 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, $options.equal(c)]])], 14, Swatchesvue_type_template_id_3e9acefe_hoisted_3);
    }), 128))]);
  }), 128))])], 8, Swatchesvue_type_template_id_3e9acefe_hoisted_1);
}
;// CONCATENATED MODULE: ./src/components/Swatches.vue?vue&type=template&id=3e9acefe

;// CONCATENATED MODULE: ./node_modules/material-colors/dist/colors.es2015.js
var red = {
  "50": "#ffebee",
  "100": "#ffcdd2",
  "200": "#ef9a9a",
  "300": "#e57373",
  "400": "#ef5350",
  "500": "#f44336",
  "600": "#e53935",
  "700": "#d32f2f",
  "800": "#c62828",
  "900": "#b71c1c",
  "a100": "#ff8a80",
  "a200": "#ff5252",
  "a400": "#ff1744",
  "a700": "#d50000"
};
var pink = {
  "50": "#fce4ec",
  "100": "#f8bbd0",
  "200": "#f48fb1",
  "300": "#f06292",
  "400": "#ec407a",
  "500": "#e91e63",
  "600": "#d81b60",
  "700": "#c2185b",
  "800": "#ad1457",
  "900": "#880e4f",
  "a100": "#ff80ab",
  "a200": "#ff4081",
  "a400": "#f50057",
  "a700": "#c51162"
};
var purple = {
  "50": "#f3e5f5",
  "100": "#e1bee7",
  "200": "#ce93d8",
  "300": "#ba68c8",
  "400": "#ab47bc",
  "500": "#9c27b0",
  "600": "#8e24aa",
  "700": "#7b1fa2",
  "800": "#6a1b9a",
  "900": "#4a148c",
  "a100": "#ea80fc",
  "a200": "#e040fb",
  "a400": "#d500f9",
  "a700": "#aa00ff"
};
var deepPurple = {
  "50": "#ede7f6",
  "100": "#d1c4e9",
  "200": "#b39ddb",
  "300": "#9575cd",
  "400": "#7e57c2",
  "500": "#673ab7",
  "600": "#5e35b1",
  "700": "#512da8",
  "800": "#4527a0",
  "900": "#311b92",
  "a100": "#b388ff",
  "a200": "#7c4dff",
  "a400": "#651fff",
  "a700": "#6200ea"
};
var indigo = {
  "50": "#e8eaf6",
  "100": "#c5cae9",
  "200": "#9fa8da",
  "300": "#7986cb",
  "400": "#5c6bc0",
  "500": "#3f51b5",
  "600": "#3949ab",
  "700": "#303f9f",
  "800": "#283593",
  "900": "#1a237e",
  "a100": "#8c9eff",
  "a200": "#536dfe",
  "a400": "#3d5afe",
  "a700": "#304ffe"
};
var blue = {
  "50": "#e3f2fd",
  "100": "#bbdefb",
  "200": "#90caf9",
  "300": "#64b5f6",
  "400": "#42a5f5",
  "500": "#2196f3",
  "600": "#1e88e5",
  "700": "#1976d2",
  "800": "#1565c0",
  "900": "#0d47a1",
  "a100": "#82b1ff",
  "a200": "#448aff",
  "a400": "#2979ff",
  "a700": "#2962ff"
};
var lightBlue = {
  "50": "#e1f5fe",
  "100": "#b3e5fc",
  "200": "#81d4fa",
  "300": "#4fc3f7",
  "400": "#29b6f6",
  "500": "#03a9f4",
  "600": "#039be5",
  "700": "#0288d1",
  "800": "#0277bd",
  "900": "#01579b",
  "a100": "#80d8ff",
  "a200": "#40c4ff",
  "a400": "#00b0ff",
  "a700": "#0091ea"
};
var cyan = {
  "50": "#e0f7fa",
  "100": "#b2ebf2",
  "200": "#80deea",
  "300": "#4dd0e1",
  "400": "#26c6da",
  "500": "#00bcd4",
  "600": "#00acc1",
  "700": "#0097a7",
  "800": "#00838f",
  "900": "#006064",
  "a100": "#84ffff",
  "a200": "#18ffff",
  "a400": "#00e5ff",
  "a700": "#00b8d4"
};
var teal = {
  "50": "#e0f2f1",
  "100": "#b2dfdb",
  "200": "#80cbc4",
  "300": "#4db6ac",
  "400": "#26a69a",
  "500": "#009688",
  "600": "#00897b",
  "700": "#00796b",
  "800": "#00695c",
  "900": "#004d40",
  "a100": "#a7ffeb",
  "a200": "#64ffda",
  "a400": "#1de9b6",
  "a700": "#00bfa5"
};
var green = {
  "50": "#e8f5e9",
  "100": "#c8e6c9",
  "200": "#a5d6a7",
  "300": "#81c784",
  "400": "#66bb6a",
  "500": "#4caf50",
  "600": "#43a047",
  "700": "#388e3c",
  "800": "#2e7d32",
  "900": "#1b5e20",
  "a100": "#b9f6ca",
  "a200": "#69f0ae",
  "a400": "#00e676",
  "a700": "#00c853"
};
var lightGreen = {
  "50": "#f1f8e9",
  "100": "#dcedc8",
  "200": "#c5e1a5",
  "300": "#aed581",
  "400": "#9ccc65",
  "500": "#8bc34a",
  "600": "#7cb342",
  "700": "#689f38",
  "800": "#558b2f",
  "900": "#33691e",
  "a100": "#ccff90",
  "a200": "#b2ff59",
  "a400": "#76ff03",
  "a700": "#64dd17"
};
var lime = {
  "50": "#f9fbe7",
  "100": "#f0f4c3",
  "200": "#e6ee9c",
  "300": "#dce775",
  "400": "#d4e157",
  "500": "#cddc39",
  "600": "#c0ca33",
  "700": "#afb42b",
  "800": "#9e9d24",
  "900": "#827717",
  "a100": "#f4ff81",
  "a200": "#eeff41",
  "a400": "#c6ff00",
  "a700": "#aeea00"
};
var yellow = {
  "50": "#fffde7",
  "100": "#fff9c4",
  "200": "#fff59d",
  "300": "#fff176",
  "400": "#ffee58",
  "500": "#ffeb3b",
  "600": "#fdd835",
  "700": "#fbc02d",
  "800": "#f9a825",
  "900": "#f57f17",
  "a100": "#ffff8d",
  "a200": "#ffff00",
  "a400": "#ffea00",
  "a700": "#ffd600"
};
var amber = {
  "50": "#fff8e1",
  "100": "#ffecb3",
  "200": "#ffe082",
  "300": "#ffd54f",
  "400": "#ffca28",
  "500": "#ffc107",
  "600": "#ffb300",
  "700": "#ffa000",
  "800": "#ff8f00",
  "900": "#ff6f00",
  "a100": "#ffe57f",
  "a200": "#ffd740",
  "a400": "#ffc400",
  "a700": "#ffab00"
};
var orange = {
  "50": "#fff3e0",
  "100": "#ffe0b2",
  "200": "#ffcc80",
  "300": "#ffb74d",
  "400": "#ffa726",
  "500": "#ff9800",
  "600": "#fb8c00",
  "700": "#f57c00",
  "800": "#ef6c00",
  "900": "#e65100",
  "a100": "#ffd180",
  "a200": "#ffab40",
  "a400": "#ff9100",
  "a700": "#ff6d00"
};
var deepOrange = {
  "50": "#fbe9e7",
  "100": "#ffccbc",
  "200": "#ffab91",
  "300": "#ff8a65",
  "400": "#ff7043",
  "500": "#ff5722",
  "600": "#f4511e",
  "700": "#e64a19",
  "800": "#d84315",
  "900": "#bf360c",
  "a100": "#ff9e80",
  "a200": "#ff6e40",
  "a400": "#ff3d00",
  "a700": "#dd2c00"
};
var brown = {
  "50": "#efebe9",
  "100": "#d7ccc8",
  "200": "#bcaaa4",
  "300": "#a1887f",
  "400": "#8d6e63",
  "500": "#795548",
  "600": "#6d4c41",
  "700": "#5d4037",
  "800": "#4e342e",
  "900": "#3e2723"
};
var grey = {
  "50": "#fafafa",
  "100": "#f5f5f5",
  "200": "#eeeeee",
  "300": "#e0e0e0",
  "400": "#bdbdbd",
  "500": "#9e9e9e",
  "600": "#757575",
  "700": "#616161",
  "800": "#424242",
  "900": "#212121"
};
var blueGrey = {
  "50": "#eceff1",
  "100": "#cfd8dc",
  "200": "#b0bec5",
  "300": "#90a4ae",
  "400": "#78909c",
  "500": "#607d8b",
  "600": "#546e7a",
  "700": "#455a64",
  "800": "#37474f",
  "900": "#263238"
};
var darkText = {
  "primary": "rgba(0, 0, 0, 0.87)",
  "secondary": "rgba(0, 0, 0, 0.54)",
  "disabled": "rgba(0, 0, 0, 0.38)",
  "dividers": "rgba(0, 0, 0, 0.12)"
};
var lightText = {
  "primary": "rgba(255, 255, 255, 1)",
  "secondary": "rgba(255, 255, 255, 0.7)",
  "disabled": "rgba(255, 255, 255, 0.5)",
  "dividers": "rgba(255, 255, 255, 0.12)"
};
var darkIcons = {
  "active": "rgba(0, 0, 0, 0.54)",
  "inactive": "rgba(0, 0, 0, 0.38)"
};
var lightIcons = {
  "active": "rgba(255, 255, 255, 1)",
  "inactive": "rgba(255, 255, 255, 0.5)"
};
var white = "#ffffff";
var black = "#000000";
/* harmony default export */ var colors_es2015 = ({
  red: red,
  pink: pink,
  purple: purple,
  deepPurple: deepPurple,
  indigo: indigo,
  blue: blue,
  lightBlue: lightBlue,
  cyan: cyan,
  teal: teal,
  green: green,
  lightGreen: lightGreen,
  lime: lime,
  yellow: yellow,
  amber: amber,
  orange: orange,
  deepOrange: deepOrange,
  brown: brown,
  grey: grey,
  blueGrey: blueGrey,
  darkText: darkText,
  lightText: lightText,
  darkIcons: darkIcons,
  lightIcons: lightIcons,
  white: white,
  black: black
});
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Swatches.vue?vue&type=script&lang=js


const colorMap = ['red', 'pink', 'purple', 'deepPurple', 'indigo', 'blue', 'lightBlue', 'cyan', 'teal', 'green', 'lightGreen', 'lime', 'yellow', 'amber', 'orange', 'deepOrange', 'brown', 'blueGrey', 'black'];
const colorLevel = ['900', '700', '500', '300', '100'];

const Swatchesvue_type_script_lang_js_defaultColors = (() => {
  const colors = [];
  colorMap.forEach(type => {
    let typeColor = [];

    if (type.toLowerCase() === 'black' || type.toLowerCase() === 'white') {
      typeColor = typeColor.concat(['#000000', '#FFFFFF']);
    } else {
      colorLevel.forEach(level => {
        const color = colors_es2015[type][level];
        typeColor.push(color.toUpperCase());
      });
    }

    colors.push(typeColor);
  });
  return colors;
})();

/* harmony default export */ var Swatchesvue_type_script_lang_js = ({
  name: 'Swatches',
  mixins: [color],
  props: {
    palette: {
      type: Array,

      default() {
        return Swatchesvue_type_script_lang_js_defaultColors;
      }

    }
  },
  computed: {
    pick() {
      return this.colors.hex;
    }

  },
  methods: {
    equal(color) {
      return color.toLowerCase() === this.colors.hex.toLowerCase();
    },

    handlerClick(c) {
      this.colorChange({
        hex: c,
        source: 'hex'
      });
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Swatches.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Swatches.vue?vue&type=style&index=0&id=3e9acefe&lang=css
var Swatchesvue_type_style_index_0_id_3e9acefe_lang_css = __webpack_require__(8421);
;// CONCATENATED MODULE: ./src/components/Swatches.vue?vue&type=style&index=0&id=3e9acefe&lang=css

;// CONCATENATED MODULE: ./src/components/Swatches.vue




;


const Swatches_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Swatchesvue_type_script_lang_js, [['render',Swatchesvue_type_template_id_3e9acefe_render]])

/* harmony default export */ var Swatches = (Swatches_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Photoshop.vue?vue&type=template&id=9851ac8a

const Photoshopvue_type_template_id_9851ac8a_hoisted_1 = {
  role: "heading",
  class: "vc-ps-head"
};
const Photoshopvue_type_template_id_9851ac8a_hoisted_2 = {
  class: "vc-ps-body"
};
const Photoshopvue_type_template_id_9851ac8a_hoisted_3 = {
  class: "vc-ps-saturation-wrap"
};
const Photoshopvue_type_template_id_9851ac8a_hoisted_4 = {
  class: "vc-ps-hue-wrap"
};

const Photoshopvue_type_template_id_9851ac8a_hoisted_5 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-ps-hue-pointer"
}, [/*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("i", {
  class: "vc-ps-hue-pointer--left"
}), /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("i", {
  class: "vc-ps-hue-pointer--right"
})], -1);

const Photoshopvue_type_template_id_9851ac8a_hoisted_6 = {
  class: "vc-ps-previews"
};
const _hoisted_7 = {
  class: "vc-ps-previews__label"
};
const _hoisted_8 = {
  class: "vc-ps-previews__swatches"
};
const _hoisted_9 = ["aria-label"];
const _hoisted_10 = ["aria-label"];
const _hoisted_11 = {
  class: "vc-ps-previews__label"
};
const _hoisted_12 = {
  key: 0,
  class: "vc-ps-actions"
};
const _hoisted_13 = ["aria-label"];
const _hoisted_14 = ["aria-label"];
const _hoisted_15 = {
  class: "vc-ps-fields"
};

const _hoisted_16 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-ps-fields__divider"
}, null, -1);

const _hoisted_17 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-ps-fields__divider"
}, null, -1);

function Photoshopvue_type_template_id_9851ac8a_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_saturation = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("saturation");

  const _component_hue = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("hue");

  const _component_ed_in = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("ed-in");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    role: "application",
    "aria-label": "PhotoShop color picker",
    class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(['vc-photoshop', $props.disableFields ? 'vc-photoshop__disable-fields' : ''])
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Photoshopvue_type_template_id_9851ac8a_hoisted_1, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.head), 1), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Photoshopvue_type_template_id_9851ac8a_hoisted_2, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Photoshopvue_type_template_id_9851ac8a_hoisted_3, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_saturation, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Photoshopvue_type_template_id_9851ac8a_hoisted_4, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_hue, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => _ctx.colors = $event),
    onChange: $options.childChange,
    direction: "vertical"
  }, {
    default: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.withCtx)(() => [Photoshopvue_type_template_id_9851ac8a_hoisted_5]),
    _: 1
  }, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(['vc-ps-controls', $props.disableFields ? 'vc-ps-controls__disable-fields' : ''])
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Photoshopvue_type_template_id_9851ac8a_hoisted_6, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_7, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.newLabel), 1), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_8, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-ps-previews__pr-color",
    "aria-label": `New color is ${_ctx.colors.hex}`,
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      background: _ctx.colors.hex
    })
  }, null, 12, _hoisted_9), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-ps-previews__pr-color",
    "aria-label": `Current color is ${$data.currentColor}`,
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      background: $data.currentColor
    }),
    onClick: _cache[2] || (_cache[2] = (...args) => $options.clickCurrentColor && $options.clickCurrentColor(...args))
  }, null, 12, _hoisted_10)]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_11, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.currentLabel), 1)]), !$props.disableFields ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", _hoisted_12, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-ps-ac-btn",
    role: "button",
    "aria-label": $props.acceptLabel,
    onClick: _cache[3] || (_cache[3] = (...args) => $options.handleAccept && $options.handleAccept(...args))
  }, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.acceptLabel), 9, _hoisted_13), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-ps-ac-btn",
    role: "button",
    "aria-label": $props.cancelLabel,
    onClick: _cache[4] || (_cache[4] = (...args) => $options.handleCancel && $options.handleCancel(...args))
  }, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.cancelLabel), 9, _hoisted_14), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_15, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "h",
    desc: "°",
    modelValue: $options.hsv.h,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "s",
    desc: "%",
    modelValue: $options.hsv.s,
    max: 100,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "v",
    desc: "%",
    modelValue: $options.hsv.v,
    max: 100,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), _hoisted_16, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "r",
    modelValue: _ctx.colors.rgba.r,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "g",
    modelValue: _ctx.colors.rgba.g,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "b",
    modelValue: _ctx.colors.rgba.b,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), _hoisted_17, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "#",
    class: "vc-ps-fields__hex",
    modelValue: $options.hex,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), $props.hasResetButton ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    key: 0,
    class: "vc-ps-ac-btn",
    "aria-label": "reset",
    onClick: _cache[5] || (_cache[5] = (...args) => $options.handleReset && $options.handleReset(...args))
  }, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.toDisplayString)($props.resetLabel), 1)) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)], 2)])], 2);
}
;// CONCATENATED MODULE: ./src/components/Photoshop.vue?vue&type=template&id=9851ac8a

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Saturation.vue?vue&type=template&id=659348d8


const Saturationvue_type_template_id_659348d8_hoisted_1 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-saturation--white"
}, null, -1);

const Saturationvue_type_template_id_659348d8_hoisted_2 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-saturation--black"
}, null, -1);

const Saturationvue_type_template_id_659348d8_hoisted_3 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-saturation-circle"
}, null, -1);

const Saturationvue_type_template_id_659348d8_hoisted_4 = [Saturationvue_type_template_id_659348d8_hoisted_3];
function Saturationvue_type_template_id_659348d8_render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    class: "vc-saturation",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      background: $options.bgColor
    }),
    ref: "container",
    onMousedown: _cache[0] || (_cache[0] = (...args) => $options.handleMouseDown && $options.handleMouseDown(...args)),
    onTouchmove: _cache[1] || (_cache[1] = (...args) => $options.handleChange && $options.handleChange(...args)),
    onTouchstart: _cache[2] || (_cache[2] = (...args) => $options.handleChange && $options.handleChange(...args))
  }, [Saturationvue_type_template_id_659348d8_hoisted_1, Saturationvue_type_template_id_659348d8_hoisted_2, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-saturation-pointer",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      top: $options.pointerTop,
      left: $options.pointerLeft
    })
  }, Saturationvue_type_template_id_659348d8_hoisted_4, 4)], 36);
}
;// CONCATENATED MODULE: ./src/components/common/Saturation.vue?vue&type=template&id=659348d8

// EXTERNAL MODULE: ./node_modules/clamp/index.js
var clamp = __webpack_require__(3770);
var clamp_default = /*#__PURE__*/__webpack_require__.n(clamp);
// EXTERNAL MODULE: ./node_modules/lodash/throttle.js
var throttle = __webpack_require__(1788);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Saturation.vue?vue&type=script&lang=js


/* harmony default export */ var Saturationvue_type_script_lang_js = ({
  name: 'Saturation',
  props: {
    modelValue: Object
  },
  computed: {
    colors() {
      return this.modelValue;
    },

    bgColor() {
      return `hsl(${this.colors.hsv.h}, 100%, 50%)`;
    },

    pointerTop() {
      return -(this.colors.hsv.v * 100) + 1 + 100 + '%';
    },

    pointerLeft() {
      return this.colors.hsv.s * 100 + '%';
    }

  },
  methods: {
    throttle: throttle((fn, data) => {
      fn(data);
    }, 20, {
      leading: true,
      trailing: false
    }),

    handleChange(e, skip) {
      !skip && e.preventDefault();
      const container = this.$refs.container;

      if (!container) {
        // for some edge cases, container may not exist. see #220
        return;
      }

      const containerWidth = container.clientWidth;
      const containerHeight = container.clientHeight;
      const xOffset = container.getBoundingClientRect().left + window.pageXOffset;
      const yOffset = container.getBoundingClientRect().top + window.pageYOffset;
      const pageX = e.pageX || (e.touches ? e.touches[0].pageX : 0);
      const pageY = e.pageY || (e.touches ? e.touches[0].pageY : 0);
      const left = clamp_default()(pageX - xOffset, 0, containerWidth);
      const top = clamp_default()(pageY - yOffset, 0, containerHeight);
      const saturation = left / containerWidth;
      const bright = clamp_default()(-(top / containerHeight) + 1, 0, 1);
      this.throttle(this.onChange, {
        h: this.colors.hsv.h,
        s: saturation,
        v: bright,
        a: this.colors.hsv.a,
        source: 'hsva'
      });
    },

    onChange(param) {
      this.$emit('change', param);
    },

    handleMouseDown(e) {
      // this.handleChange(e, true)
      window.addEventListener('mousemove', this.handleChange);
      window.addEventListener('mouseup', this.handleChange);
      window.addEventListener('mouseup', this.handleMouseUp);
    },

    handleMouseUp(e) {
      this.unbindEventListeners();
    },

    unbindEventListeners() {
      window.removeEventListener('mousemove', this.handleChange);
      window.removeEventListener('mouseup', this.handleChange);
      window.removeEventListener('mouseup', this.handleMouseUp);
    }

  }
});
;// CONCATENATED MODULE: ./src/components/common/Saturation.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Saturation.vue?vue&type=style&index=0&id=659348d8&lang=css
var Saturationvue_type_style_index_0_id_659348d8_lang_css = __webpack_require__(7344);
;// CONCATENATED MODULE: ./src/components/common/Saturation.vue?vue&type=style&index=0&id=659348d8&lang=css

;// CONCATENATED MODULE: ./src/components/common/Saturation.vue




;


const Saturation_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Saturationvue_type_script_lang_js, [['render',Saturationvue_type_template_id_659348d8_render]])

/* harmony default export */ var Saturation = (Saturation_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Photoshop.vue?vue&type=script&lang=js



 // import alpha from './common/Alpha.vue'

/* harmony default export */ var Photoshopvue_type_script_lang_js = ({
  name: 'Photoshop',
  mixins: [color],
  props: {
    head: {
      type: String,
      default: 'Color Picker'
    },
    disableFields: {
      type: Boolean,
      default: false
    },
    hasResetButton: {
      type: Boolean,
      default: false
    },
    acceptLabel: {
      type: String,
      default: 'OK'
    },
    cancelLabel: {
      type: String,
      default: 'Cancel'
    },
    resetLabel: {
      type: String,
      default: 'Reset'
    },
    newLabel: {
      type: String,
      default: 'new'
    },
    currentLabel: {
      type: String,
      default: 'current'
    }
  },
  components: {
    saturation: Saturation,
    hue: Hue,
    // alpha,
    'ed-in': EditableInput
  },

  data() {
    return {
      currentColor: '#FFF'
    };
  },

  computed: {
    hsv() {
      const hsv = this.colors.hsv;
      return {
        h: hsv.h.toFixed(),
        s: (hsv.s * 100).toFixed(),
        v: (hsv.v * 100).toFixed()
      };
    },

    hex() {
      const hex = this.colors.hex;
      return hex && hex.replace('#', '');
    }

  },

  created() {
    this.currentColor = this.colors.hex;
  },

  methods: {
    childChange(data) {
      this.colorChange(data);
    },

    inputChange(data) {
      if (!data) {
        return;
      }

      if (data['#']) {
        this.isValidHex(data['#']) && this.colorChange({
          hex: data['#'],
          source: 'hex'
        });
      } else if (data.r || data.g || data.b || data.a) {
        this.colorChange({
          r: data.r || this.colors.rgba.r,
          g: data.g || this.colors.rgba.g,
          b: data.b || this.colors.rgba.b,
          a: data.a || this.colors.rgba.a,
          source: 'rgba'
        });
      } else if (data.h || data.s || data.v) {
        this.colorChange({
          h: data.h || this.colors.hsv.h,
          s: data.s / 100 || this.colors.hsv.s,
          v: data.v / 100 || this.colors.hsv.v,
          source: 'hsv'
        });
      }
    },

    clickCurrentColor() {
      this.colorChange({
        hex: this.currentColor,
        source: 'hex'
      });
    },

    handleAccept() {
      this.$emit('ok');
    },

    handleCancel() {
      this.$emit('cancel');
    },

    handleReset() {
      this.$emit('reset');
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Photoshop.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Photoshop.vue?vue&type=style&index=0&id=9851ac8a&lang=css
var Photoshopvue_type_style_index_0_id_9851ac8a_lang_css = __webpack_require__(1029);
;// CONCATENATED MODULE: ./src/components/Photoshop.vue?vue&type=style&index=0&id=9851ac8a&lang=css

;// CONCATENATED MODULE: ./src/components/Photoshop.vue




;


const Photoshop_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Photoshopvue_type_script_lang_js, [['render',Photoshopvue_type_template_id_9851ac8a_render]])

/* harmony default export */ var Photoshop = (Photoshop_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Sketch.vue?vue&type=template&id=5a577154

const Sketchvue_type_template_id_5a577154_hoisted_1 = {
  class: "vc-sketch-saturation-wrap"
};
const Sketchvue_type_template_id_5a577154_hoisted_2 = {
  class: "vc-sketch-controls"
};
const Sketchvue_type_template_id_5a577154_hoisted_3 = {
  class: "vc-sketch-sliders"
};
const Sketchvue_type_template_id_5a577154_hoisted_4 = {
  class: "vc-sketch-hue-wrap"
};
const Sketchvue_type_template_id_5a577154_hoisted_5 = {
  key: 0,
  class: "vc-sketch-alpha-wrap"
};
const Sketchvue_type_template_id_5a577154_hoisted_6 = {
  class: "vc-sketch-color-wrap"
};
const Sketchvue_type_template_id_5a577154_hoisted_7 = ["aria-label"];
const Sketchvue_type_template_id_5a577154_hoisted_8 = {
  key: 0,
  class: "vc-sketch-field"
};
const Sketchvue_type_template_id_5a577154_hoisted_9 = {
  class: "vc-sketch-field--double"
};
const Sketchvue_type_template_id_5a577154_hoisted_10 = {
  class: "vc-sketch-field--single"
};
const Sketchvue_type_template_id_5a577154_hoisted_11 = {
  class: "vc-sketch-field--single"
};
const Sketchvue_type_template_id_5a577154_hoisted_12 = {
  class: "vc-sketch-field--single"
};
const Sketchvue_type_template_id_5a577154_hoisted_13 = {
  key: 0,
  class: "vc-sketch-field--single"
};
const Sketchvue_type_template_id_5a577154_hoisted_14 = {
  class: "vc-sketch-presets",
  role: "group",
  "aria-label": "A color preset, pick one to set as current color"
};
const Sketchvue_type_template_id_5a577154_hoisted_15 = ["aria-label", "onClick"];
const Sketchvue_type_template_id_5a577154_hoisted_16 = ["aria-label", "onClick"];
function Sketchvue_type_template_id_5a577154_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_saturation = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("saturation");

  const _component_hue = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("hue");

  const _component_alpha = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("alpha");

  const _component_checkboard = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("checkboard");

  const _component_ed_in = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("ed-in");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    role: "application",
    "aria-label": "Sketch color picker",
    class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(['vc-sketch', $props.disableAlpha ? 'vc-sketch__disable-alpha' : ''])
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_saturation, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_2, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_3, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_4, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_hue, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])]), !$props.disableAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Sketchvue_type_template_id_5a577154_hoisted_5, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_alpha, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[2] || (_cache[2] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_6, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    "aria-label": `Current color is ${$options.activeColor}`,
    class: "vc-sketch-active-color",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      background: $options.activeColor
    })
  }, null, 12, Sketchvue_type_template_id_5a577154_hoisted_7), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_checkboard)])]), !$props.disableFields ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Sketchvue_type_template_id_5a577154_hoisted_8, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_9, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "hex",
    modelValue: $options.hex,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_10, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "r",
    modelValue: _ctx.colors.rgba.r,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_11, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "g",
    modelValue: _ctx.colors.rgba.g,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_12, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "b",
    modelValue: _ctx.colors.rgba.b,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), !$props.disableAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Sketchvue_type_template_id_5a577154_hoisted_13, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "a",
    modelValue: _ctx.colors.a,
    "arrow-offset": 0.01,
    max: 1,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "arrow-offset", "onChange"])])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Sketchvue_type_template_id_5a577154_hoisted_14, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)($props.presetColors, c => {
    return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, [!_ctx.isTransparent(c) ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
      class: "vc-sketch-presets-color",
      "aria-label": 'Color:' + c,
      key: 'if-' + c,
      style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
        background: c
      }),
      onClick: $event => $options.handlePreset(c)
    }, null, 12, Sketchvue_type_template_id_5a577154_hoisted_15)) : ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
      key: 'else-' + c,
      "aria-label": 'Color:' + c,
      class: "vc-sketch-presets-color",
      onClick: $event => $options.handlePreset(c)
    }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_checkboard)], 8, Sketchvue_type_template_id_5a577154_hoisted_16))], 64);
  }), 256))])], 2);
}
;// CONCATENATED MODULE: ./src/components/Sketch.vue?vue&type=template&id=5a577154

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Alpha.vue?vue&type=template&id=7db0276a

const Alphavue_type_template_id_7db0276a_hoisted_1 = {
  class: "vc-alpha"
};
const Alphavue_type_template_id_7db0276a_hoisted_2 = {
  class: "vc-alpha-checkboard-wrap"
};

const Alphavue_type_template_id_7db0276a_hoisted_3 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-alpha-picker"
}, null, -1);

const Alphavue_type_template_id_7db0276a_hoisted_4 = [Alphavue_type_template_id_7db0276a_hoisted_3];
function Alphavue_type_template_id_7db0276a_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_checkboard = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("checkboard");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Alphavue_type_template_id_7db0276a_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Alphavue_type_template_id_7db0276a_hoisted_2, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_checkboard)]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-alpha-gradient",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      background: $options.gradientColor
    })
  }, null, 4), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-alpha-container",
    ref: "container",
    onMousedown: _cache[0] || (_cache[0] = (...args) => $options.handleMouseDown && $options.handleMouseDown(...args)),
    onTouchmove: _cache[1] || (_cache[1] = (...args) => $options.handleChange && $options.handleChange(...args)),
    onTouchstart: _cache[2] || (_cache[2] = (...args) => $options.handleChange && $options.handleChange(...args))
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-alpha-pointer",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      left: $options.colors.a * 100 + '%'
    })
  }, Alphavue_type_template_id_7db0276a_hoisted_4, 4)], 544)]);
}
;// CONCATENATED MODULE: ./src/components/common/Alpha.vue?vue&type=template&id=7db0276a

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Checkboard.vue?vue&type=template&id=1af7c312

function Checkboardvue_type_template_id_1af7c312_render(_ctx, _cache, $props, $setup, $data, $options) {
  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    class: "vc-checkerboard",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)($options.bgStyle)
  }, null, 4);
}
;// CONCATENATED MODULE: ./src/components/common/Checkboard.vue?vue&type=template&id=1af7c312

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Checkboard.vue?vue&type=script&lang=js
const _checkboardCache = {};
/* harmony default export */ var Checkboardvue_type_script_lang_js = ({
  name: 'Checkboard',
  props: {
    size: {
      type: [Number, String],
      default: 8
    },
    white: {
      type: String,
      default: '#fff'
    },
    grey: {
      type: String,
      default: '#e6e6e6'
    }
  },
  computed: {
    bgStyle() {
      return {
        'background-image': 'url(' + getCheckboard(this.white, this.grey, this.size) + ')'
      };
    }

  }
});
/**
 * get base 64 data by canvas
 *
 * @param {String} c1 hex color
 * @param {String} c2 hex color
 * @param {Number} size
 */

function renderCheckboard(c1, c2, size) {
  // Dont Render On Server
  if (typeof document === 'undefined') {
    return null;
  }

  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size * 2;
  const ctx = canvas.getContext('2d'); // If no context can be found, return early.

  if (!ctx) {
    return null;
  }

  ctx.fillStyle = c1;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = c2;
  ctx.fillRect(0, 0, size, size);
  ctx.translate(size, size);
  ctx.fillRect(0, 0, size, size);
  return canvas.toDataURL();
}
/**
 * get checkboard base data and cache
 *
 * @param {String} c1 hex color
 * @param {String} c2 hex color
 * @param {Number} size
 */


function getCheckboard(c1, c2, size) {
  const key = c1 + ',' + c2 + ',' + size;

  if (_checkboardCache[key]) {
    return _checkboardCache[key];
  } else {
    const checkboard = renderCheckboard(c1, c2, size);
    _checkboardCache[key] = checkboard;
    return checkboard;
  }
}
;// CONCATENATED MODULE: ./src/components/common/Checkboard.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Checkboard.vue?vue&type=style&index=0&id=1af7c312&lang=css
var Checkboardvue_type_style_index_0_id_1af7c312_lang_css = __webpack_require__(1285);
;// CONCATENATED MODULE: ./src/components/common/Checkboard.vue?vue&type=style&index=0&id=1af7c312&lang=css

;// CONCATENATED MODULE: ./src/components/common/Checkboard.vue




;


const Checkboard_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Checkboardvue_type_script_lang_js, [['render',Checkboardvue_type_template_id_1af7c312_render]])

/* harmony default export */ var Checkboard = (Checkboard_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Alpha.vue?vue&type=script&lang=js

/* harmony default export */ var Alphavue_type_script_lang_js = ({
  name: 'Alpha',
  props: {
    modelValue: Object,
    onChange: Function
  },
  components: {
    checkboard: Checkboard
  },
  computed: {
    colors() {
      return this.modelValue;
    },

    gradientColor() {
      const rgba = this.colors.rgba;
      const rgbStr = [rgba.r, rgba.g, rgba.b].join(',');
      return 'linear-gradient(to right, rgba(' + rgbStr + ', 0) 0%, rgba(' + rgbStr + ', 1) 100%)';
    }

  },
  methods: {
    handleChange(e, skip) {
      !skip && e.preventDefault();
      const container = this.$refs.container;

      if (!container) {
        // for some edge cases, container may not exist. see #220
        return;
      }

      const containerWidth = container.clientWidth;
      const xOffset = container.getBoundingClientRect().left + window.pageXOffset;
      const pageX = e.pageX || (e.touches ? e.touches[0].pageX : 0);
      const left = pageX - xOffset;
      let a;

      if (left < 0) {
        a = 0;
      } else if (left > containerWidth) {
        a = 1;
      } else {
        a = Math.round(left * 100 / containerWidth) / 100;
      }

      if (this.colors.a !== a) {
        this.$emit('change', {
          h: this.colors.hsl.h,
          s: this.colors.hsl.s,
          l: this.colors.hsl.l,
          a: a,
          source: 'rgba'
        });
      }
    },

    handleMouseDown(e) {
      this.handleChange(e, true);
      window.addEventListener('mousemove', this.handleChange);
      window.addEventListener('mouseup', this.handleMouseUp);
    },

    handleMouseUp() {
      this.unbindEventListeners();
    },

    unbindEventListeners() {
      window.removeEventListener('mousemove', this.handleChange);
      window.removeEventListener('mouseup', this.handleMouseUp);
    }

  }
});
;// CONCATENATED MODULE: ./src/components/common/Alpha.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/common/Alpha.vue?vue&type=style&index=0&id=7db0276a&lang=css
var Alphavue_type_style_index_0_id_7db0276a_lang_css = __webpack_require__(5033);
;// CONCATENATED MODULE: ./src/components/common/Alpha.vue?vue&type=style&index=0&id=7db0276a&lang=css

;// CONCATENATED MODULE: ./src/components/common/Alpha.vue




;


const Alpha_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Alphavue_type_script_lang_js, [['render',Alphavue_type_template_id_7db0276a_render]])

/* harmony default export */ var Alpha = (Alpha_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Sketch.vue?vue&type=script&lang=js






const presetColors = ['#D0021B', '#F5A623', '#F8E71C', '#8B572A', '#7ED321', '#417505', '#BD10E0', '#9013FE', '#4A90E2', '#50E3C2', '#B8E986', '#000000', '#4A4A4A', '#9B9B9B', '#FFFFFF', 'rgba(0,0,0,0)'];
/* harmony default export */ var Sketchvue_type_script_lang_js = ({
  name: 'Sketch',
  mixins: [color],
  components: {
    saturation: Saturation,
    hue: Hue,
    alpha: Alpha,
    'ed-in': EditableInput,
    checkboard: Checkboard
  },
  props: {
    presetColors: {
      type: Array,

      default() {
        return presetColors;
      }

    },
    disableAlpha: {
      type: Boolean,
      default: false
    },
    disableFields: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    hex() {
      let hex;

      if (this.colors.a < 1) {
        hex = this.colors.hex8;
      } else {
        hex = this.colors.hex;
      }

      return hex.replace('#', '');
    },

    activeColor() {
      const rgba = this.colors.rgba;
      return 'rgba(' + [rgba.r, rgba.g, rgba.b, rgba.a].join(',') + ')';
    }

  },
  methods: {
    handlePreset(c) {
      this.colorChange({
        hex: c,
        source: 'hex'
      });
    },

    childChange(data) {
      this.colorChange(data);
    },

    inputChange(data) {
      if (!data) {
        return;
      }

      if (data.hex) {
        this.isValidHex(data.hex) && this.colorChange({
          hex: data.hex,
          source: 'hex'
        });
      } else if (data.r || data.g || data.b || data.a) {
        this.colorChange({
          r: data.r || this.colors.rgba.r,
          g: data.g || this.colors.rgba.g,
          b: data.b || this.colors.rgba.b,
          a: data.a || this.colors.rgba.a,
          source: 'rgba'
        });
      }
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Sketch.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Sketch.vue?vue&type=style&index=0&id=5a577154&lang=css
var Sketchvue_type_style_index_0_id_5a577154_lang_css = __webpack_require__(9108);
;// CONCATENATED MODULE: ./src/components/Sketch.vue?vue&type=style&index=0&id=5a577154&lang=css

;// CONCATENATED MODULE: ./src/components/Sketch.vue




;


const Sketch_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Sketchvue_type_script_lang_js, [['render',Sketchvue_type_template_id_5a577154_render]])

/* harmony default export */ var Sketch = (Sketch_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Chrome.vue?vue&type=template&id=41feb5bc

const Chromevue_type_template_id_41feb5bc_hoisted_1 = {
  class: "vc-chrome-saturation-wrap"
};
const Chromevue_type_template_id_41feb5bc_hoisted_2 = {
  class: "vc-chrome-body"
};
const Chromevue_type_template_id_41feb5bc_hoisted_3 = {
  class: "vc-chrome-controls"
};
const Chromevue_type_template_id_41feb5bc_hoisted_4 = {
  class: "vc-chrome-color-wrap"
};
const Chromevue_type_template_id_41feb5bc_hoisted_5 = ["aria-label"];
const Chromevue_type_template_id_41feb5bc_hoisted_6 = {
  class: "vc-chrome-sliders"
};
const Chromevue_type_template_id_41feb5bc_hoisted_7 = {
  class: "vc-chrome-hue-wrap"
};
const Chromevue_type_template_id_41feb5bc_hoisted_8 = {
  key: 0,
  class: "vc-chrome-alpha-wrap"
};
const Chromevue_type_template_id_41feb5bc_hoisted_9 = {
  key: 0,
  class: "vc-chrome-fields-wrap"
};
const Chromevue_type_template_id_41feb5bc_hoisted_10 = {
  class: "vc-chrome-fields"
};
const Chromevue_type_template_id_41feb5bc_hoisted_11 = {
  class: "vc-chrome-field"
};
const Chromevue_type_template_id_41feb5bc_hoisted_12 = {
  class: "vc-chrome-fields"
};
const Chromevue_type_template_id_41feb5bc_hoisted_13 = {
  class: "vc-chrome-field"
};
const Chromevue_type_template_id_41feb5bc_hoisted_14 = {
  class: "vc-chrome-field"
};
const Chromevue_type_template_id_41feb5bc_hoisted_15 = {
  class: "vc-chrome-field"
};
const Chromevue_type_template_id_41feb5bc_hoisted_16 = {
  key: 0,
  class: "vc-chrome-field"
};
const Chromevue_type_template_id_41feb5bc_hoisted_17 = {
  class: "vc-chrome-fields"
};
const _hoisted_18 = {
  class: "vc-chrome-field"
};
const _hoisted_19 = {
  class: "vc-chrome-field"
};
const _hoisted_20 = {
  class: "vc-chrome-field"
};
const _hoisted_21 = {
  key: 0,
  class: "vc-chrome-field"
};
const _hoisted_22 = {
  class: "vc-chrome-toggle-icon"
};

const _hoisted_23 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("path", {
  fill: "#333",
  d: "M12,18.17L8.83,15L7.42,16.41L12,21L16.59,16.41L15.17,15M12,5.83L15.17,9L16.58,7.59L12,3L7.41,7.59L8.83,9L12,5.83Z"
}, null, -1);

const _hoisted_24 = [_hoisted_23];
const _hoisted_25 = {
  class: "vc-chrome-toggle-icon-highlight"
};
function Chromevue_type_template_id_41feb5bc_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_saturation = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("saturation");

  const _component_checkboard = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("checkboard");

  const _component_hue = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("hue");

  const _component_alpha = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("alpha");

  const _component_ed_in = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("ed-in");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    role: "application",
    "aria-label": "Chrome color picker",
    class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(['vc-chrome', $props.disableAlpha ? 'vc-chrome__disable-alpha' : ''])
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_1, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_saturation, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[0] || (_cache[0] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_2, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_3, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_4, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    "aria-label": `current color is ${_ctx.colors.hex}`,
    class: "vc-chrome-active-color",
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      background: $options.activeColor
    })
  }, null, 12, Chromevue_type_template_id_41feb5bc_hoisted_5), !$props.disableAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createBlock)(_component_checkboard, {
    key: 0
  })) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_6, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_7, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_hue, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[1] || (_cache[1] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])]), !$props.disableAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Chromevue_type_template_id_41feb5bc_hoisted_8, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_alpha, {
    modelValue: _ctx.colors,
    "onUpdate:modelValue": _cache[2] || (_cache[2] = $event => _ctx.colors = $event),
    onChange: $options.childChange
  }, null, 8, ["modelValue", "onChange"])])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)])]), !$props.disableFields ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Chromevue_type_template_id_41feb5bc_hoisted_9, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_10, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_11, [!$options.hasAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createBlock)(_component_ed_in, {
    key: 0,
    label: "hex",
    modelValue: _ctx.colors.hex,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true), $options.hasAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createBlock)(_component_ed_in, {
    key: 1,
    label: "hex",
    modelValue: _ctx.colors.hex8,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)])], 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, $data.fieldsIndex === 0]]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_12, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_13, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "r",
    modelValue: _ctx.colors.rgba.r,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_14, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "g",
    modelValue: _ctx.colors.rgba.g,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_15, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "b",
    modelValue: _ctx.colors.rgba.b,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), !$props.disableAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", Chromevue_type_template_id_41feb5bc_hoisted_16, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "a",
    modelValue: _ctx.colors.a,
    "arrow-offset": 0.01,
    max: 1,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "arrow-offset", "onChange"])])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)], 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, $data.fieldsIndex === 1]]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Chromevue_type_template_id_41feb5bc_hoisted_17, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_18, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "h",
    modelValue: $options.hsl.h,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_19, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "s",
    modelValue: $options.hsl.s,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_20, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "l",
    modelValue: $options.hsl.l,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"])]), !$props.disableAlpha ? ((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", _hoisted_21, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_ed_in, {
    label: "a",
    modelValue: _ctx.colors.a,
    "arrow-offset": 0.01,
    max: 1,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "arrow-offset", "onChange"])])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)], 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, $data.fieldsIndex === 2]]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
    class: "vc-chrome-toggle-btn",
    role: "button",
    "aria-label": "Change another color definition",
    onClick: _cache[6] || (_cache[6] = (...args) => $options.toggleViews && $options.toggleViews(...args))
  }, [(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_22, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("svg", {
    style: {
      "width": "24px",
      "height": "24px"
    },
    viewBox: "0 0 24 24",
    onMouseover: _cache[3] || (_cache[3] = (...args) => $options.showHighlight && $options.showHighlight(...args)),
    onMouseenter: _cache[4] || (_cache[4] = (...args) => $options.showHighlight && $options.showHighlight(...args)),
    onMouseout: _cache[5] || (_cache[5] = (...args) => $options.hideHighlight && $options.hideHighlight(...args))
  }, _hoisted_24, 32))]), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.withDirectives)((0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", _hoisted_25, null, 512), [[external_commonjs_vue_commonjs2_vue_root_Vue_.vShow, $data.highlight]])])])) : (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createCommentVNode)("", true)])], 2);
}
;// CONCATENATED MODULE: ./src/components/Chrome.vue?vue&type=template&id=41feb5bc

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Chrome.vue?vue&type=script&lang=js






/* harmony default export */ var Chromevue_type_script_lang_js = ({
  name: 'Chrome',
  mixins: [color],
  props: {
    disableAlpha: {
      type: Boolean,
      default: false
    },
    disableFields: {
      type: Boolean,
      default: false
    }
  },
  components: {
    saturation: Saturation,
    hue: Hue,
    alpha: Alpha,
    'ed-in': EditableInput,
    checkboard: Checkboard
  },

  data() {
    return {
      fieldsIndex: 0,
      highlight: false
    };
  },

  computed: {
    hsl() {
      const {
        h,
        s,
        l
      } = this.colors.hsl;
      return {
        h: h.toFixed(),
        s: `${(s * 100).toFixed()}%`,
        l: `${(l * 100).toFixed()}%`
      };
    },

    activeColor() {
      const rgba = this.colors.rgba;
      return 'rgba(' + [rgba.r, rgba.g, rgba.b, rgba.a].join(',') + ')';
    },

    hasAlpha() {
      return this.colors.a < 1;
    }

  },
  methods: {
    childChange(data) {
      this.colorChange(data);
    },

    inputChange(data) {
      if (!data) {
        return;
      }

      if (data.hex) {
        this.isValidHex(data.hex) && this.colorChange({
          hex: data.hex,
          source: 'hex'
        });
      } else if (data.r || data.g || data.b || data.a) {
        this.colorChange({
          r: data.r || this.colors.rgba.r,
          g: data.g || this.colors.rgba.g,
          b: data.b || this.colors.rgba.b,
          a: data.a || this.colors.rgba.a,
          source: 'rgba'
        });
      } else if (data.h || data.s || data.l) {
        const s = data.s ? data.s.replace('%', '') / 100 : this.colors.hsl.s;
        const l = data.l ? data.l.replace('%', '') / 100 : this.colors.hsl.l;
        this.colorChange({
          h: data.h || this.colors.hsl.h,
          s,
          l,
          source: 'hsl'
        });
      }
    },

    toggleViews() {
      if (this.fieldsIndex >= 2) {
        this.fieldsIndex = 0;
        return;
      }

      this.fieldsIndex++;
    },

    showHighlight() {
      this.highlight = true;
    },

    hideHighlight() {
      this.highlight = false;
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Chrome.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Chrome.vue?vue&type=style&index=0&id=41feb5bc&lang=css
var Chromevue_type_style_index_0_id_41feb5bc_lang_css = __webpack_require__(883);
;// CONCATENATED MODULE: ./src/components/Chrome.vue?vue&type=style&index=0&id=41feb5bc&lang=css

;// CONCATENATED MODULE: ./src/components/Chrome.vue




;


const Chrome_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Chromevue_type_script_lang_js, [['render',Chromevue_type_template_id_41feb5bc_render]])

/* harmony default export */ var Chrome = (Chrome_exports_);
;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/templateLoader.js??ruleSet[1].rules[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Twitter.vue?vue&type=template&id=3d2e139c


const Twittervue_type_template_id_3d2e139c_hoisted_1 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-twitter-triangle-shadow"
}, null, -1);

const Twittervue_type_template_id_3d2e139c_hoisted_2 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-twitter-triangle"
}, null, -1);

const Twittervue_type_template_id_3d2e139c_hoisted_3 = {
  class: "vc-twitter-body"
};
const Twittervue_type_template_id_3d2e139c_hoisted_4 = ["onClick"];

const Twittervue_type_template_id_3d2e139c_hoisted_5 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-twitter-hash"
}, "#", -1);

const Twittervue_type_template_id_3d2e139c_hoisted_6 = /*#__PURE__*/(0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", {
  class: "vc-twitter-clear"
}, null, -1);

function Twittervue_type_template_id_3d2e139c_render(_ctx, _cache, $props, $setup, $data, $options) {
  const _component_editable_input = (0,external_commonjs_vue_commonjs2_vue_root_Vue_.resolveComponent)("editable-input");

  return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("div", {
    class: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeClass)(["vc-twitter", {
      'vc-twitter-hide-triangle ': $props.triangle === 'hide',
      'vc-twitter-top-left-triangle ': $props.triangle === 'top-left',
      'vc-twitter-top-right-triangle ': $props.triangle === 'top-right'
    }]),
    style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
      width: typeof $props.width === 'number' ? `${$props.width}px` : $props.width
    })
  }, [Twittervue_type_template_id_3d2e139c_hoisted_1, Twittervue_type_template_id_3d2e139c_hoisted_2, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementVNode)("div", Twittervue_type_template_id_3d2e139c_hoisted_3, [((0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(true), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)(external_commonjs_vue_commonjs2_vue_root_Vue_.Fragment, null, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.renderList)($props.defaultColors, (color, index) => {
    return (0,external_commonjs_vue_commonjs2_vue_root_Vue_.openBlock)(), (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createElementBlock)("span", {
      class: "vc-twitter-swatch",
      style: (0,external_commonjs_vue_commonjs2_vue_root_Vue_.normalizeStyle)({
        background: color,
        boxShadow: `0 0 4px ${$options.equal(color) ? color : 'transparent'}`
      }),
      key: index,
      onClick: $event => $options.handlerClick(color)
    }, null, 12, Twittervue_type_template_id_3d2e139c_hoisted_4);
  }), 128)), Twittervue_type_template_id_3d2e139c_hoisted_5, (0,external_commonjs_vue_commonjs2_vue_root_Vue_.createVNode)(_component_editable_input, {
    label: "#",
    modelValue: $options.hex,
    onChange: $options.inputChange
  }, null, 8, ["modelValue", "onChange"]), Twittervue_type_template_id_3d2e139c_hoisted_6])], 6);
}
;// CONCATENATED MODULE: ./src/components/Twitter.vue?vue&type=template&id=3d2e139c

;// CONCATENATED MODULE: ./node_modules/thread-loader/dist/cjs.js!./node_modules/babel-loader/lib/index.js??clonedRuleSet-82.use[1]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Twitter.vue?vue&type=script&lang=js


const Twittervue_type_script_lang_js_defaultColors = ['#FF6900', '#FCB900', '#7BDCB5', '#00D084', '#8ED1FC', '#0693E3', '#ABB8C3', '#EB144C', '#F78DA7', '#9900EF'];
/* harmony default export */ var Twittervue_type_script_lang_js = ({
  name: 'Twitter',
  mixins: [color],
  components: {
    editableInput: EditableInput
  },
  props: {
    width: {
      type: [String, Number],
      default: 276
    },
    defaultColors: {
      type: Array,

      default() {
        return Twittervue_type_script_lang_js_defaultColors;
      }

    },
    triangle: {
      default: 'top-left',

      validator(value) {
        return ['hide', 'top-left', 'top-right'].includes(value);
      }

    }
  },
  computed: {
    hsv() {
      const hsv = this.colors.hsv;
      return {
        h: hsv.h.toFixed(),
        s: (hsv.s * 100).toFixed(),
        v: (hsv.v * 100).toFixed()
      };
    },

    hex() {
      const hex = this.colors.hex;
      return hex && hex.replace('#', '');
    }

  },
  methods: {
    equal(color) {
      return color.toLowerCase() === this.colors.hex.toLowerCase();
    },

    handlerClick(color) {
      this.colorChange({
        hex: color,
        source: 'hex'
      });
    },

    inputChange(data) {
      if (!data) {
        return;
      }

      if (data['#']) {
        this.isValidHex(data['#']) && this.colorChange({
          hex: data['#'],
          source: 'hex'
        });
      } else if (data.r || data.g || data.b || data.a) {
        this.colorChange({
          r: data.r || this.colors.rgba.r,
          g: data.g || this.colors.rgba.g,
          b: data.b || this.colors.rgba.b,
          a: data.a || this.colors.rgba.a,
          source: 'rgba'
        });
      } else if (data.h || data.s || data.v) {
        this.colorChange({
          h: data.h || this.colors.hsv.h,
          s: data.s / 100 || this.colors.hsv.s,
          v: data.v / 100 || this.colors.hsv.v,
          source: 'hsv'
        });
      }
    }

  }
});
;// CONCATENATED MODULE: ./src/components/Twitter.vue?vue&type=script&lang=js
 
// EXTERNAL MODULE: ./node_modules/vue-style-loader/index.js??clonedRuleSet-54.use[0]!./node_modules/css-loader/dist/cjs.js??clonedRuleSet-54.use[1]!./node_modules/vue-loader/dist/stylePostLoader.js!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[2]!./node_modules/postcss-loader/dist/cjs.js??clonedRuleSet-54.use[3]!./node_modules/vue-loader/dist/index.js??ruleSet[0].use[0]!./src/components/Twitter.vue?vue&type=style&index=0&id=3d2e139c&lang=css
var Twittervue_type_style_index_0_id_3d2e139c_lang_css = __webpack_require__(9806);
;// CONCATENATED MODULE: ./src/components/Twitter.vue?vue&type=style&index=0&id=3d2e139c&lang=css

;// CONCATENATED MODULE: ./src/components/Twitter.vue




;


const Twitter_exports_ = /*#__PURE__*/(0,exportHelper/* default */.Z)(Twittervue_type_script_lang_js, [['render',Twittervue_type_template_id_3d2e139c_render]])

/* harmony default export */ var Twitter = (Twitter_exports_);
;// CONCATENATED MODULE: ./src/build.js
















const version = package_namespaceObject.i8;
const VueColor = {
  version,
  Compact: Compact,
  Grayscale: Grayscale,
  Twitter: Twitter,
  Material: Material,
  Slider: Slider,
  Swatches: Swatches,
  Photoshop: Photoshop,
  Sketch: Sketch,
  Chrome: Chrome,
  Alpha: Alpha,
  Checkboard: Checkboard,
  EditableInput: EditableInput,
  Hue: Hue,
  Saturation: Saturation,
  ColorMixin: color
};

if (!(typeof process === 'object' && String(process) === '[object process]')) {
  window.VueColor = VueColor;
}

/* harmony default export */ var build = (VueColor);

;// CONCATENATED MODULE: ./node_modules/@vue/cli-service/lib/commands/build/entry-lib.js


/* harmony default export */ var entry_lib = (build);


}();
/******/ 	return __webpack_exports__;
/******/ })()
;
});
//# sourceMappingURL=vue3-color.umd.js.map