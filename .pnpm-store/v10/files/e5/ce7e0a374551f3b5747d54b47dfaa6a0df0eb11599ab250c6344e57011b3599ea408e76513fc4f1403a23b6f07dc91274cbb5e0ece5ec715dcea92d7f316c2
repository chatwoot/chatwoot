'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var isToday = _interopDefault(require('date-fns/isToday'));
var isYesterday = _interopDefault(require('date-fns/isYesterday'));

/**
 * Creates a debounced version of a function that delays invoking the provided function
 * until after a specified wait time has elapsed since the last time it was invoked.
 *
 * @param {Function} func - The function to debounce. Will receive any arguments passed to the debounced function.
 * @param {number} wait - The number of milliseconds to delay execution after the last call.
 * @param {boolean} [immediate] - If true, the function will execute immediately on the first call,
 *                               then start the debounce behavior for subsequent calls.
 * @param {number} [maxWait] - The maximum time the function can be delayed before it's forcibly executed.
 *                            If specified, the function will be called after this many milliseconds
 *                            have passed since its last execution, regardless of the debounce wait time.
 *
 * @returns {Function} A debounced version of the original function that has the following behavior:
 *   - Delays execution until `wait` milliseconds have passed since the last call
 *   - If `immediate` is true, executes on the leading edge of the first call
 *   - If `maxWait` is provided, ensures the function is called at least once every `maxWait` milliseconds
 *   - Preserves the `this` context and arguments of the most recent call
 *   - Cancels pending executions when called again within the wait period
 *
 * @example
 * // Basic debounce
 * const debouncedSearch = debounce(searchAPI, 300);
 *
 * // With immediate execution
 * const debouncedSave = debounce(saveData, 1000, true);
 *
 * // With maximum wait time
 * const debouncedUpdate = debounce(updateUI, 200, false, 1000);
 */
var debounce = function debounce(func, wait, immediate, maxWait) {
  var timeout = null;
  var lastInvokeTime = 0;
  return function () {
    var _this = this;
    for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }
    var time = Date.now();
    var isFirstCall = lastInvokeTime === 0;
    // Check if this is the first call and immediate execution is requested
    if (isFirstCall && immediate) {
      lastInvokeTime = time;
      func.apply(this, args);
      return;
    }
    // Clear any existing timeout
    if (timeout !== null) {
      clearTimeout(timeout);
      timeout = null;
    }
    // Calculate if maxWait threshold has been reached
    var timeSinceLastInvoke = time - lastInvokeTime;
    var shouldInvokeNow = maxWait !== undefined && timeSinceLastInvoke >= maxWait;
    if (shouldInvokeNow) {
      lastInvokeTime = time;
      func.apply(this, args);
      return;
    }
    // Set a new timeout
    timeout = setTimeout(function () {
      lastInvokeTime = Date.now();
      timeout = null;
      func.apply(_this, args);
    }, wait);
  };
};

function asyncGeneratorStep(n, t, e, r, o, a, c) {
  try {
    var i = n[a](c),
      u = i.value;
  } catch (n) {
    return void e(n);
  }
  i.done ? t(u) : Promise.resolve(u).then(r, o);
}
function _asyncToGenerator(n) {
  return function () {
    var t = this,
      e = arguments;
    return new Promise(function (r, o) {
      var a = n.apply(t, e);
      function _next(n) {
        asyncGeneratorStep(a, r, o, _next, _throw, "next", n);
      }
      function _throw(n) {
        asyncGeneratorStep(a, r, o, _next, _throw, "throw", n);
      }
      _next(void 0);
    });
  };
}
function _extends() {
  return _extends = Object.assign ? Object.assign.bind() : function (n) {
    for (var e = 1; e < arguments.length; e++) {
      var t = arguments[e];
      for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]);
    }
    return n;
  }, _extends.apply(null, arguments);
}
function _regeneratorRuntime() {
  _regeneratorRuntime = function () {
    return e;
  };
  var t,
    e = {},
    r = Object.prototype,
    n = r.hasOwnProperty,
    o = Object.defineProperty || function (t, e, r) {
      t[e] = r.value;
    },
    i = "function" == typeof Symbol ? Symbol : {},
    a = i.iterator || "@@iterator",
    c = i.asyncIterator || "@@asyncIterator",
    u = i.toStringTag || "@@toStringTag";
  function define(t, e, r) {
    return Object.defineProperty(t, e, {
      value: r,
      enumerable: !0,
      configurable: !0,
      writable: !0
    }), t[e];
  }
  try {
    define({}, "");
  } catch (t) {
    define = function (t, e, r) {
      return t[e] = r;
    };
  }
  function wrap(t, e, r, n) {
    var i = e && e.prototype instanceof Generator ? e : Generator,
      a = Object.create(i.prototype),
      c = new Context(n || []);
    return o(a, "_invoke", {
      value: makeInvokeMethod(t, r, c)
    }), a;
  }
  function tryCatch(t, e, r) {
    try {
      return {
        type: "normal",
        arg: t.call(e, r)
      };
    } catch (t) {
      return {
        type: "throw",
        arg: t
      };
    }
  }
  e.wrap = wrap;
  var h = "suspendedStart",
    l = "suspendedYield",
    f = "executing",
    s = "completed",
    y = {};
  function Generator() {}
  function GeneratorFunction() {}
  function GeneratorFunctionPrototype() {}
  var p = {};
  define(p, a, function () {
    return this;
  });
  var d = Object.getPrototypeOf,
    v = d && d(d(values([])));
  v && v !== r && n.call(v, a) && (p = v);
  var g = GeneratorFunctionPrototype.prototype = Generator.prototype = Object.create(p);
  function defineIteratorMethods(t) {
    ["next", "throw", "return"].forEach(function (e) {
      define(t, e, function (t) {
        return this._invoke(e, t);
      });
    });
  }
  function AsyncIterator(t, e) {
    function invoke(r, o, i, a) {
      var c = tryCatch(t[r], t, o);
      if ("throw" !== c.type) {
        var u = c.arg,
          h = u.value;
        return h && "object" == typeof h && n.call(h, "__await") ? e.resolve(h.__await).then(function (t) {
          invoke("next", t, i, a);
        }, function (t) {
          invoke("throw", t, i, a);
        }) : e.resolve(h).then(function (t) {
          u.value = t, i(u);
        }, function (t) {
          return invoke("throw", t, i, a);
        });
      }
      a(c.arg);
    }
    var r;
    o(this, "_invoke", {
      value: function (t, n) {
        function callInvokeWithMethodAndArg() {
          return new e(function (e, r) {
            invoke(t, n, e, r);
          });
        }
        return r = r ? r.then(callInvokeWithMethodAndArg, callInvokeWithMethodAndArg) : callInvokeWithMethodAndArg();
      }
    });
  }
  function makeInvokeMethod(e, r, n) {
    var o = h;
    return function (i, a) {
      if (o === f) throw Error("Generator is already running");
      if (o === s) {
        if ("throw" === i) throw a;
        return {
          value: t,
          done: !0
        };
      }
      for (n.method = i, n.arg = a;;) {
        var c = n.delegate;
        if (c) {
          var u = maybeInvokeDelegate(c, n);
          if (u) {
            if (u === y) continue;
            return u;
          }
        }
        if ("next" === n.method) n.sent = n._sent = n.arg;else if ("throw" === n.method) {
          if (o === h) throw o = s, n.arg;
          n.dispatchException(n.arg);
        } else "return" === n.method && n.abrupt("return", n.arg);
        o = f;
        var p = tryCatch(e, r, n);
        if ("normal" === p.type) {
          if (o = n.done ? s : l, p.arg === y) continue;
          return {
            value: p.arg,
            done: n.done
          };
        }
        "throw" === p.type && (o = s, n.method = "throw", n.arg = p.arg);
      }
    };
  }
  function maybeInvokeDelegate(e, r) {
    var n = r.method,
      o = e.iterator[n];
    if (o === t) return r.delegate = null, "throw" === n && e.iterator.return && (r.method = "return", r.arg = t, maybeInvokeDelegate(e, r), "throw" === r.method) || "return" !== n && (r.method = "throw", r.arg = new TypeError("The iterator does not provide a '" + n + "' method")), y;
    var i = tryCatch(o, e.iterator, r.arg);
    if ("throw" === i.type) return r.method = "throw", r.arg = i.arg, r.delegate = null, y;
    var a = i.arg;
    return a ? a.done ? (r[e.resultName] = a.value, r.next = e.nextLoc, "return" !== r.method && (r.method = "next", r.arg = t), r.delegate = null, y) : a : (r.method = "throw", r.arg = new TypeError("iterator result is not an object"), r.delegate = null, y);
  }
  function pushTryEntry(t) {
    var e = {
      tryLoc: t[0]
    };
    1 in t && (e.catchLoc = t[1]), 2 in t && (e.finallyLoc = t[2], e.afterLoc = t[3]), this.tryEntries.push(e);
  }
  function resetTryEntry(t) {
    var e = t.completion || {};
    e.type = "normal", delete e.arg, t.completion = e;
  }
  function Context(t) {
    this.tryEntries = [{
      tryLoc: "root"
    }], t.forEach(pushTryEntry, this), this.reset(!0);
  }
  function values(e) {
    if (e || "" === e) {
      var r = e[a];
      if (r) return r.call(e);
      if ("function" == typeof e.next) return e;
      if (!isNaN(e.length)) {
        var o = -1,
          i = function next() {
            for (; ++o < e.length;) if (n.call(e, o)) return next.value = e[o], next.done = !1, next;
            return next.value = t, next.done = !0, next;
          };
        return i.next = i;
      }
    }
    throw new TypeError(typeof e + " is not iterable");
  }
  return GeneratorFunction.prototype = GeneratorFunctionPrototype, o(g, "constructor", {
    value: GeneratorFunctionPrototype,
    configurable: !0
  }), o(GeneratorFunctionPrototype, "constructor", {
    value: GeneratorFunction,
    configurable: !0
  }), GeneratorFunction.displayName = define(GeneratorFunctionPrototype, u, "GeneratorFunction"), e.isGeneratorFunction = function (t) {
    var e = "function" == typeof t && t.constructor;
    return !!e && (e === GeneratorFunction || "GeneratorFunction" === (e.displayName || e.name));
  }, e.mark = function (t) {
    return Object.setPrototypeOf ? Object.setPrototypeOf(t, GeneratorFunctionPrototype) : (t.__proto__ = GeneratorFunctionPrototype, define(t, u, "GeneratorFunction")), t.prototype = Object.create(g), t;
  }, e.awrap = function (t) {
    return {
      __await: t
    };
  }, defineIteratorMethods(AsyncIterator.prototype), define(AsyncIterator.prototype, c, function () {
    return this;
  }), e.AsyncIterator = AsyncIterator, e.async = function (t, r, n, o, i) {
    void 0 === i && (i = Promise);
    var a = new AsyncIterator(wrap(t, r, n, o), i);
    return e.isGeneratorFunction(r) ? a : a.next().then(function (t) {
      return t.done ? t.value : a.next();
    });
  }, defineIteratorMethods(g), define(g, u, "Generator"), define(g, a, function () {
    return this;
  }), define(g, "toString", function () {
    return "[object Generator]";
  }), e.keys = function (t) {
    var e = Object(t),
      r = [];
    for (var n in e) r.push(n);
    return r.reverse(), function next() {
      for (; r.length;) {
        var t = r.pop();
        if (t in e) return next.value = t, next.done = !1, next;
      }
      return next.done = !0, next;
    };
  }, e.values = values, Context.prototype = {
    constructor: Context,
    reset: function (e) {
      if (this.prev = 0, this.next = 0, this.sent = this._sent = t, this.done = !1, this.delegate = null, this.method = "next", this.arg = t, this.tryEntries.forEach(resetTryEntry), !e) for (var r in this) "t" === r.charAt(0) && n.call(this, r) && !isNaN(+r.slice(1)) && (this[r] = t);
    },
    stop: function () {
      this.done = !0;
      var t = this.tryEntries[0].completion;
      if ("throw" === t.type) throw t.arg;
      return this.rval;
    },
    dispatchException: function (e) {
      if (this.done) throw e;
      var r = this;
      function handle(n, o) {
        return a.type = "throw", a.arg = e, r.next = n, o && (r.method = "next", r.arg = t), !!o;
      }
      for (var o = this.tryEntries.length - 1; o >= 0; --o) {
        var i = this.tryEntries[o],
          a = i.completion;
        if ("root" === i.tryLoc) return handle("end");
        if (i.tryLoc <= this.prev) {
          var c = n.call(i, "catchLoc"),
            u = n.call(i, "finallyLoc");
          if (c && u) {
            if (this.prev < i.catchLoc) return handle(i.catchLoc, !0);
            if (this.prev < i.finallyLoc) return handle(i.finallyLoc);
          } else if (c) {
            if (this.prev < i.catchLoc) return handle(i.catchLoc, !0);
          } else {
            if (!u) throw Error("try statement without catch or finally");
            if (this.prev < i.finallyLoc) return handle(i.finallyLoc);
          }
        }
      }
    },
    abrupt: function (t, e) {
      for (var r = this.tryEntries.length - 1; r >= 0; --r) {
        var o = this.tryEntries[r];
        if (o.tryLoc <= this.prev && n.call(o, "finallyLoc") && this.prev < o.finallyLoc) {
          var i = o;
          break;
        }
      }
      i && ("break" === t || "continue" === t) && i.tryLoc <= e && e <= i.finallyLoc && (i = null);
      var a = i ? i.completion : {};
      return a.type = t, a.arg = e, i ? (this.method = "next", this.next = i.finallyLoc, y) : this.complete(a);
    },
    complete: function (t, e) {
      if ("throw" === t.type) throw t.arg;
      return "break" === t.type || "continue" === t.type ? this.next = t.arg : "return" === t.type ? (this.rval = this.arg = t.arg, this.method = "return", this.next = "end") : "normal" === t.type && e && (this.next = e), y;
    },
    finish: function (t) {
      for (var e = this.tryEntries.length - 1; e >= 0; --e) {
        var r = this.tryEntries[e];
        if (r.finallyLoc === t) return this.complete(r.completion, r.afterLoc), resetTryEntry(r), y;
      }
    },
    catch: function (t) {
      for (var e = this.tryEntries.length - 1; e >= 0; --e) {
        var r = this.tryEntries[e];
        if (r.tryLoc === t) {
          var n = r.completion;
          if ("throw" === n.type) {
            var o = n.arg;
            resetTryEntry(r);
          }
          return o;
        }
      }
      throw Error("illegal catch attempt");
    },
    delegateYield: function (e, r, n) {
      return this.delegate = {
        iterator: values(e),
        resultName: r,
        nextLoc: n
      }, "next" === this.method && (this.arg = t), y;
    }
  }, e;
}

/**
 * @name Get contrasting text color
 * @description Get contrasting text color from a text color
 * @param bgColor  Background color of text.
 * @returns contrasting text color
 */
var getContrastingTextColor = function getContrastingTextColor(bgColor) {
  var color = bgColor.replace('#', '');
  var r = parseInt(color.slice(0, 2), 16);
  var g = parseInt(color.slice(2, 4), 16);
  var b = parseInt(color.slice(4, 6), 16);
  // http://stackoverflow.com/a/3943023/112731
  return r * 0.299 + g * 0.587 + b * 0.114 > 186 ? '#000000' : '#FFFFFF';
};
/**
 * @name Get formatted date
 * @description Get date in today, yesterday or any other date format
 * @param date  date
 * @param todayText  Today text
 * @param yesterdayText  Yesterday text
 * @returns formatted date
 */
var formatDate = function formatDate(_ref) {
  var date = _ref.date,
    todayText = _ref.todayText,
    yesterdayText = _ref.yesterdayText;
  var dateValue = new Date(date);
  if (isToday(dateValue)) return todayText;
  if (isYesterday(dateValue)) return yesterdayText;
  return date;
};
/**
 * @name formatTime
 * @description Format time to Hour, Minute and Second
 * @param timeInSeconds  number
 * @returns formatted time
 */
var formatTime = function formatTime(timeInSeconds) {
  var formattedTime = '';
  if (timeInSeconds >= 60 && timeInSeconds < 3600) {
    var minutes = Math.floor(timeInSeconds / 60);
    formattedTime = minutes + " Min";
    var seconds = minutes === 60 ? 0 : Math.floor(timeInSeconds % 60);
    return formattedTime + ("" + (seconds > 0 ? ' ' + seconds + ' Sec' : ''));
  }
  if (timeInSeconds >= 3600 && timeInSeconds < 86400) {
    var hours = Math.floor(timeInSeconds / 3600);
    formattedTime = hours + " Hr";
    var _minutes = timeInSeconds % 3600 < 60 || hours === 24 ? 0 : Math.floor(timeInSeconds % 3600 / 60);
    return formattedTime + ("" + (_minutes > 0 ? ' ' + _minutes + ' Min' : ''));
  }
  if (timeInSeconds >= 86400) {
    var days = Math.floor(timeInSeconds / 86400);
    formattedTime = days + " Day";
    var _hours = timeInSeconds % 86400 < 3600 || days >= 364 ? 0 : Math.floor(timeInSeconds % 86400 / 3600);
    return formattedTime + ("" + (_hours > 0 ? ' ' + _hours + ' Hr' : ''));
  }
  return Math.floor(timeInSeconds) + " Sec";
};
/**
 * @name trimContent
 * @description Trim a string to max length
 * @param content String to trim
 * @param maxLength Length of the string to trim, default 1024
 * @param ellipsis Boolean to add dots at the end of the string, default false
 * @returns trimmed string
 */
var trimContent = function trimContent(content, maxLength, ellipsis) {
  if (content === void 0) {
    content = '';
  }
  if (maxLength === void 0) {
    maxLength = 1024;
  }
  if (ellipsis === void 0) {
    ellipsis = false;
  }
  var trimmedContent = content;
  if (content.length > maxLength) {
    trimmedContent = content.substring(0, maxLength);
  }
  if (ellipsis) {
    trimmedContent = trimmedContent + '...';
  }
  return trimmedContent;
};
/**
 * @name convertSecondsToTimeUnit
 * @description Convert seconds to time unit
 * @param seconds  number
 * @param unitNames  object
 * @returns time and unit
 * @example
 * convertToUnit(60, { minute: 'm', hour: 'h', day: 'd' }); // { time: 1, unit: 'm' }
 * convertToUnit(60, { minute: 'Minutes', hour: 'Hours', day: 'Days' }); // { time: 1, unit: 'Minutes' }
 */
var convertSecondsToTimeUnit = function convertSecondsToTimeUnit(seconds, unitNames) {
  if (seconds === null || seconds === 0) return {
    time: '',
    unit: ''
  };
  if (seconds < 3600) return {
    time: Number((seconds / 60).toFixed(1)),
    unit: unitNames.minute
  };
  if (seconds < 86400) return {
    time: Number((seconds / 3600).toFixed(1)),
    unit: unitNames.hour
  };
  return {
    time: Number((seconds / 86400).toFixed(1)),
    unit: unitNames.day
  };
};
/**
 * @name fileNameWithEllipsis
 * @description Truncates a filename while preserving the extension
 * @param {Object} file - File object containing filename or name property
 * @param {number} [maxLength=26] - Maximum length of the filename (excluding extension)
 * @param {string} [ellipsis='…'] - Character to use for truncation
 * @returns {string} Truncated filename with extension
 * @example
 * fileNameWithEllipsis({ filename: 'very-long-filename.pdf' }, 10) // 'very-long-f….pdf'
 * fileNameWithEllipsis({ name: 'short.txt' }, 10) // 'short.txt'
 */
var fileNameWithEllipsis = function fileNameWithEllipsis(file, maxLength, ellipsis) {
  var _ref2, _file$filename;
  if (maxLength === void 0) {
    maxLength = 26;
  }
  if (ellipsis === void 0) {
    ellipsis = '…';
  }
  var fullName = (_ref2 = (_file$filename = file == null ? void 0 : file.filename) != null ? _file$filename : file == null ? void 0 : file.name) != null ? _ref2 : 'Untitled';
  var dotIndex = fullName.lastIndexOf('.');
  if (dotIndex === -1) return fullName;
  var _ref3 = [fullName.slice(0, dotIndex), fullName.slice(dotIndex)],
    name = _ref3[0],
    extension = _ref3[1];
  if (name.length <= maxLength) return fullName;
  return "" + name.slice(0, maxLength) + ellipsis + extension;
};
/**
 * @name splitName
 * @description Splits a full name into firstName and lastName
 * @param {string} name - Full name of the user
 * @returns {Object} Object with firstName and lastName
 * @example
 * splitName('Mary Jane Smith') // { firstName: 'Mary Jane', lastName: 'Smith' }
 * splitName('Alice') // { firstName: 'Alice', lastName: '' }
 * splitName('John Doe') // { firstName: 'John', lastName: 'Doe' }
 * splitName('') // { firstName: '', lastName: '' }
 */
var splitName = function splitName(fullName) {
  var trimmedName = fullName.trim();
  if (!trimmedName) {
    return {
      firstName: '',
      lastName: ''
    };
  }
  // Split the name by spaces
  var nameParts = trimmedName.split(/\s+/);
  // If only one word, treat it as firstName
  if (nameParts.length === 1) {
    return {
      firstName: nameParts[0],
      lastName: ''
    };
  }
  // Last element is lastName, everything else is firstName
  var lastName = nameParts.pop() || '';
  var firstName = nameParts.join(' ');
  return {
    firstName: firstName,
    lastName: lastName
  };
};
/**
 * Downloads a file from a URL with proper file type handling
 * @name downloadFile
 * @description Downloads file from URL with proper type handling and cleanup
 * @param {Object} options Download configuration options
 * @param {string} options.url File URL to download
 * @param {string} options.type File type identifier
 * @param {string} [options.extension] Optional file extension
 * @returns {Promise<boolean>} Returns true if download successful, false otherwise
 */
var downloadFile = /*#__PURE__*/function () {
  var _ref5 = /*#__PURE__*/_asyncToGenerator(/*#__PURE__*/_regeneratorRuntime().mark(function _callee(_ref4) {
    var url, type, _ref4$extension, extension, _filenameMatch$, response, blobData, contentType, fileExtension, dispositionHeader, filenameMatch, filename, blobUrl, link;
    return _regeneratorRuntime().wrap(function _callee$(_context) {
      while (1) switch (_context.prev = _context.next) {
        case 0:
          url = _ref4.url, type = _ref4.type, _ref4$extension = _ref4.extension, extension = _ref4$extension === void 0 ? null : _ref4$extension;
          if (!(!url || !type)) {
            _context.next = 3;
            break;
          }
          throw new Error('Invalid download parameters');
        case 3:
          _context.prev = 3;
          _context.next = 6;
          return fetch(url, {
            cache: 'no-store'
          });
        case 6:
          response = _context.sent;
          if (response.ok) {
            _context.next = 9;
            break;
          }
          throw new Error("Download failed: " + response.status);
        case 9:
          _context.next = 11;
          return response.blob();
        case 11:
          blobData = _context.sent;
          contentType = response.headers.get('content-type');
          fileExtension = extension || (contentType ? contentType.split('/')[1] : type);
          dispositionHeader = response.headers.get('content-disposition');
          filenameMatch = dispositionHeader == null ? void 0 : dispositionHeader.match(/filename="(.*?)"/);
          filename = (_filenameMatch$ = filenameMatch == null ? void 0 : filenameMatch[1]) != null ? _filenameMatch$ : "attachment_" + Date.now() + "." + fileExtension;
          blobUrl = URL.createObjectURL(blobData);
          link = Object.assign(document.createElement('a'), {
            href: blobUrl,
            download: filename,
            style: 'display: none'
          });
          document.body.append(link);
          link.click();
          link.remove();
          URL.revokeObjectURL(blobUrl);
          _context.next = 28;
          break;
        case 25:
          _context.prev = 25;
          _context.t0 = _context["catch"](3);
          throw _context.t0 instanceof Error ? _context.t0 : new Error('Download failed');
        case 28:
        case "end":
          return _context.stop();
      }
    }, _callee, null, [[3, 25]]);
  }));
  return function downloadFile(_x) {
    return _ref5.apply(this, arguments);
  };
}();
/**
 * Extracts file information from a URL or file path.
 *
 * @param {string} url - The URL or file path to process
 * @returns {FileInfo} Object containing file information
 *
 * @example
 * getFileInfo('https://example.com/path/Document%20Name.PDF')
 * returns {
 *   name: 'Document Name.PDF',
 *   type: 'pdf',
 *   base: 'Document Name'
 * }
 *
 * getFileInfo('invalid/url')
 * returns {
 *   name: 'Unknown File',
 *   type: '',
 *   base: 'Unknown File'
 * }
 */
var getFileInfo = function getFileInfo(url) {
  var defaultInfo = {
    name: 'Unknown File',
    type: '',
    base: 'Unknown File'
  };
  if (!url || typeof url !== 'string') {
    return defaultInfo;
  }
  try {
    // Handle both URL and file path cases
    var cleanUrl = url.split(/[?#]/)[0] // Remove query params and hash
    .replace(/\\/g, '/'); // Normalize path separators
    var encodedFilename = cleanUrl.split('/').pop();
    if (!encodedFilename) {
      return defaultInfo;
    }
    var fileName = decodeURIComponent(encodedFilename);
    // Handle hidden files (starting with dot)
    if (fileName.startsWith('.') && !fileName.includes('.', 1)) {
      return {
        name: fileName,
        type: '',
        base: fileName
      };
    }
    // last index is where the file extension starts
    // This will handle cases where the file name has multiple dots
    var lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex === -1 || lastDotIndex === 0) {
      return {
        name: fileName,
        type: '',
        base: fileName
      };
    }
    var base = fileName.slice(0, lastDotIndex);
    var type = fileName.slice(lastDotIndex + 1).toLowerCase();
    return {
      name: fileName,
      type: type,
      base: base
    };
  } catch (error) {
    console.error('Error processing file info:', error);
    return defaultInfo;
  }
};
/**
 * Formats a number with K/M/B/T suffixes using Intl.NumberFormat
 * @param {number | string | null | undefined} num - The number to format
 * @returns {string} Formatted string (e.g., "1.2K", "2.3M", "999")
 * @example
 * formatNumber(1234)     // "1.2K"
 * formatNumber(1000000)  // "1M"
 * formatNumber(999)      // "999"
 * formatNumber(12344)    // "12.3K"
 */
var formatNumber = function formatNumber(num) {
  var n = Number(num) || 0;
  return new Intl.NumberFormat('en', {
    notation: 'compact',
    maximumFractionDigits: 1
  }).format(n);
};

/**
 * URL related helper functions
 */
/**
 * Converts various input formats to URL objects.
 * Handles URL objects, domain strings, relative paths, and full URLs.
 * @param {string|URL} input - Input to convert to URL object
 * @returns {URL|null} URL object or null if input is invalid
 */
var toURL = function toURL(input) {
  if (!input) return null;
  if (input instanceof URL) return input;
  if (typeof input === 'string' && !input.includes('://') && !input.startsWith('/')) {
    return new URL("https://" + input);
  }
  if (typeof input === 'string' && input.startsWith('/')) {
    return new URL(input, window.location.origin);
  }
  return new URL(input);
};
/**
 * Determines if two URLs belong to the same host by comparing their normalized URL objects.
 * Handles various input formats including URL objects, domain strings, relative paths, and full URLs.
 * Returns false if either URL cannot be parsed or normalized.
 * @param {string|URL} url1 - First URL to compare
 * @param {string|URL} url2 - Second URL to compare
 * @returns {boolean} True if both URLs have the same host, false otherwise
 */
var isSameHost = function isSameHost(url1, url2) {
  try {
    var urlObj1 = toURL(url1);
    var urlObj2 = toURL(url2);
    if (!urlObj1 || !urlObj2) return false;
    return urlObj1.hostname === urlObj2.hostname;
  } catch (error) {
    return false;
  }
};
/**
 * Check if a string is a valid domain name.
 * An empty string is allowed and considered valid.
 *
 * @param domain Domain to validate.
 * @returns Whether the domain matches the rules.
 */
var isValidDomain = function isValidDomain(domain) {
  if (domain === '') return true;
  var domainRegex = /^(?!-)(?!(?:[\0-\t\x0B\f\x0E-\u2027\u202A-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])*--)(?:[\x2D0-9A-Za-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0560-\u0588\u05D0-\u05EA\u05EF-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u0860-\u086A\u0870-\u0887\u0889-\u088E\u08A0-\u08C9\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u09FC\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C5D\u0C60\u0C61\u0C80\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D04-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D54-\u0D56\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E86-\u0E8A\u0E8C-\u0EA3\u0EA5\u0EA7-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u1711\u171F-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1878\u1880-\u1884\u1887-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4C\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1C80-\u1C8A\u1C90-\u1CBA\u1CBD-\u1CBF\u1CE9-\u1CEC\u1CEE-\u1CF3\u1CF5\u1CF6\u1CFA\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2183\u2184\u2C00-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005\u3006\u3031-\u3035\u303B\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312F\u3131-\u318E\u31A0-\u31BF\u31F0-\u31FF\u3400-\u4DBF\u4E00-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6E5\uA717-\uA71F\uA722-\uA788\uA78B-\uA7CD\uA7D0\uA7D1\uA7D3\uA7D5-\uA7DC\uA7F2-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA8FE\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB69\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF2D-\uDF40\uDF42-\uDF49\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF]|\uD801[\uDC00-\uDC9D\uDCB0-\uDCD3\uDCD8-\uDCFB\uDD00-\uDD27\uDD30-\uDD63\uDD70-\uDD7A\uDD7C-\uDD8A\uDD8C-\uDD92\uDD94\uDD95\uDD97-\uDDA1\uDDA3-\uDDB1\uDDB3-\uDDB9\uDDBB\uDDBC\uDDC0-\uDDF3\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67\uDF80-\uDF85\uDF87-\uDFB0\uDFB2-\uDFBA]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE35\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2\uDD00-\uDD23\uDD4A-\uDD65\uDD6F-\uDD85\uDE80-\uDEA9\uDEB0\uDEB1\uDEC2-\uDEC4\uDF00-\uDF1C\uDF27\uDF30-\uDF45\uDF70-\uDF81\uDFB0-\uDFC4\uDFE0-\uDFF6]|\uD804[\uDC03-\uDC37\uDC71\uDC72\uDC75\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD44\uDD47\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE3F\uDE40\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61\uDF80-\uDF89\uDF8B\uDF8E\uDF90-\uDFB5\uDFB7\uDFD1\uDFD3]|\uD805[\uDC00-\uDC34\uDC47-\uDC4A\uDC5F-\uDC61\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDEB8\uDF00-\uDF1A\uDF40-\uDF46]|\uD806[\uDC00-\uDC2B\uDCA0-\uDCDF\uDCFF-\uDD06\uDD09\uDD0C-\uDD13\uDD15\uDD16\uDD18-\uDD2F\uDD3F\uDD41\uDDA0-\uDDA7\uDDAA-\uDDD0\uDDE1\uDDE3\uDE00\uDE0B-\uDE32\uDE3A\uDE50\uDE5C-\uDE89\uDE9D\uDEB0-\uDEF8\uDFC0-\uDFE0]|\uD807[\uDC00-\uDC08\uDC0A-\uDC2E\uDC40\uDC72-\uDC8F\uDD00-\uDD06\uDD08\uDD09\uDD0B-\uDD30\uDD46\uDD60-\uDD65\uDD67\uDD68\uDD6A-\uDD89\uDD98\uDEE0-\uDEF2\uDF02\uDF04-\uDF10\uDF12-\uDF33\uDFB0]|\uD808[\uDC00-\uDF99]|\uD809[\uDC80-\uDD43]|\uD80B[\uDF90-\uDFF0]|[\uD80C\uD80E\uD80F\uD81C-\uD820\uD822\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883\uD885-\uD887][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2F\uDC41-\uDC46\uDC60-\uDFFF]|\uD810[\uDC00-\uDFFA]|\uD811[\uDC00-\uDE46]|\uD818[\uDD00-\uDD1D]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE70-\uDEBE\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDD40-\uDD6C\uDE40-\uDE7F\uDF00-\uDF4A\uDF50\uDF93-\uDF9F\uDFE0\uDFE1\uDFE3]|\uD821[\uDC00-\uDFF7]|\uD823[\uDC00-\uDCD5\uDCFF-\uDD08]|\uD82B[\uDFF0-\uDFF3\uDFF5-\uDFFB\uDFFD\uDFFE]|\uD82C[\uDC00-\uDD22\uDD32\uDD50-\uDD52\uDD55\uDD64-\uDD67\uDD70-\uDEFB]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD837[\uDF00-\uDF1E\uDF25-\uDF2A]|\uD838[\uDC30-\uDC6D\uDD00-\uDD2C\uDD37-\uDD3D\uDD4E\uDE90-\uDEAD\uDEC0-\uDEEB]|\uD839[\uDCD0-\uDCEB\uDDD0-\uDDED\uDDF0\uDFE0-\uDFE6\uDFE8-\uDFEB\uDFED\uDFEE\uDFF0-\uDFFE]|\uD83A[\uDC00-\uDCC4\uDD00-\uDD43\uDD4B]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF39\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0\uDFF0-\uDFFF]|\uD87B[\uDC00-\uDE5D]|\uD87E[\uDC00-\uDE1D]|\uD884[\uDC00-\uDF4A\uDF50-\uDFFF]|\uD888[\uDC00-\uDFAF]){1,63}(?<!-)(?:\.(?!-)(?!(?:[\0-\t\x0B\f\x0E-\u2027\u202A-\uD7FF\uE000-\uFFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])*--)(?:[\x2D0-9A-Za-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0560-\u0588\u05D0-\u05EA\u05EF-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u0860-\u086A\u0870-\u0887\u0889-\u088E\u08A0-\u08C9\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u09FC\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C5D\u0C60\u0C61\u0C80\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D04-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D54-\u0D56\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E86-\u0E8A\u0E8C-\u0EA3\u0EA5\u0EA7-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u1711\u171F-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1878\u1880-\u1884\u1887-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4C\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1C80-\u1C8A\u1C90-\u1CBA\u1CBD-\u1CBF\u1CE9-\u1CEC\u1CEE-\u1CF3\u1CF5\u1CF6\u1CFA\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2183\u2184\u2C00-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005\u3006\u3031-\u3035\u303B\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312F\u3131-\u318E\u31A0-\u31BF\u31F0-\u31FF\u3400-\u4DBF\u4E00-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6E5\uA717-\uA71F\uA722-\uA788\uA78B-\uA7CD\uA7D0\uA7D1\uA7D3\uA7D5-\uA7DC\uA7F2-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA8FE\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB69\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF2D-\uDF40\uDF42-\uDF49\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF]|\uD801[\uDC00-\uDC9D\uDCB0-\uDCD3\uDCD8-\uDCFB\uDD00-\uDD27\uDD30-\uDD63\uDD70-\uDD7A\uDD7C-\uDD8A\uDD8C-\uDD92\uDD94\uDD95\uDD97-\uDDA1\uDDA3-\uDDB1\uDDB3-\uDDB9\uDDBB\uDDBC\uDDC0-\uDDF3\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67\uDF80-\uDF85\uDF87-\uDFB0\uDFB2-\uDFBA]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE35\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2\uDD00-\uDD23\uDD4A-\uDD65\uDD6F-\uDD85\uDE80-\uDEA9\uDEB0\uDEB1\uDEC2-\uDEC4\uDF00-\uDF1C\uDF27\uDF30-\uDF45\uDF70-\uDF81\uDFB0-\uDFC4\uDFE0-\uDFF6]|\uD804[\uDC03-\uDC37\uDC71\uDC72\uDC75\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD44\uDD47\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE3F\uDE40\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61\uDF80-\uDF89\uDF8B\uDF8E\uDF90-\uDFB5\uDFB7\uDFD1\uDFD3]|\uD805[\uDC00-\uDC34\uDC47-\uDC4A\uDC5F-\uDC61\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDEB8\uDF00-\uDF1A\uDF40-\uDF46]|\uD806[\uDC00-\uDC2B\uDCA0-\uDCDF\uDCFF-\uDD06\uDD09\uDD0C-\uDD13\uDD15\uDD16\uDD18-\uDD2F\uDD3F\uDD41\uDDA0-\uDDA7\uDDAA-\uDDD0\uDDE1\uDDE3\uDE00\uDE0B-\uDE32\uDE3A\uDE50\uDE5C-\uDE89\uDE9D\uDEB0-\uDEF8\uDFC0-\uDFE0]|\uD807[\uDC00-\uDC08\uDC0A-\uDC2E\uDC40\uDC72-\uDC8F\uDD00-\uDD06\uDD08\uDD09\uDD0B-\uDD30\uDD46\uDD60-\uDD65\uDD67\uDD68\uDD6A-\uDD89\uDD98\uDEE0-\uDEF2\uDF02\uDF04-\uDF10\uDF12-\uDF33\uDFB0]|\uD808[\uDC00-\uDF99]|\uD809[\uDC80-\uDD43]|\uD80B[\uDF90-\uDFF0]|[\uD80C\uD80E\uD80F\uD81C-\uD820\uD822\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883\uD885-\uD887][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2F\uDC41-\uDC46\uDC60-\uDFFF]|\uD810[\uDC00-\uDFFA]|\uD811[\uDC00-\uDE46]|\uD818[\uDD00-\uDD1D]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE70-\uDEBE\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDD40-\uDD6C\uDE40-\uDE7F\uDF00-\uDF4A\uDF50\uDF93-\uDF9F\uDFE0\uDFE1\uDFE3]|\uD821[\uDC00-\uDFF7]|\uD823[\uDC00-\uDCD5\uDCFF-\uDD08]|\uD82B[\uDFF0-\uDFF3\uDFF5-\uDFFB\uDFFD\uDFFE]|\uD82C[\uDC00-\uDD22\uDD32\uDD50-\uDD52\uDD55\uDD64-\uDD67\uDD70-\uDEFB]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD837[\uDF00-\uDF1E\uDF25-\uDF2A]|\uD838[\uDC30-\uDC6D\uDD00-\uDD2C\uDD37-\uDD3D\uDD4E\uDE90-\uDEAD\uDEC0-\uDEEB]|\uD839[\uDCD0-\uDCEB\uDDD0-\uDDED\uDDF0\uDFE0-\uDFE6\uDFE8-\uDFEB\uDFED\uDFEE\uDFF0-\uDFFE]|\uD83A[\uDC00-\uDCC4\uDD00-\uDD43\uDD4B]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF39\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0\uDFF0-\uDFFF]|\uD87B[\uDC00-\uDE5D]|\uD87E[\uDC00-\uDE1D]|\uD884[\uDC00-\uDF4A\uDF50-\uDFFF]|\uD888[\uDC00-\uDFAF]){1,63}(?<!-))*\.(?:[A-Za-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0560-\u0588\u05D0-\u05EA\u05EF-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u0860-\u086A\u0870-\u0887\u0889-\u088E\u08A0-\u08C9\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u09FC\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C5D\u0C60\u0C61\u0C80\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D04-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D54-\u0D56\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E86-\u0E8A\u0E8C-\u0EA3\u0EA5\u0EA7-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u1711\u171F-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1878\u1880-\u1884\u1887-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4C\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1C80-\u1C8A\u1C90-\u1CBA\u1CBD-\u1CBF\u1CE9-\u1CEC\u1CEE-\u1CF3\u1CF5\u1CF6\u1CFA\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2183\u2184\u2C00-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005\u3006\u3031-\u3035\u303B\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312F\u3131-\u318E\u31A0-\u31BF\u31F0-\u31FF\u3400-\u4DBF\u4E00-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6E5\uA717-\uA71F\uA722-\uA788\uA78B-\uA7CD\uA7D0\uA7D1\uA7D3\uA7D5-\uA7DC\uA7F2-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA8FE\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB69\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF2D-\uDF40\uDF42-\uDF49\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF]|\uD801[\uDC00-\uDC9D\uDCB0-\uDCD3\uDCD8-\uDCFB\uDD00-\uDD27\uDD30-\uDD63\uDD70-\uDD7A\uDD7C-\uDD8A\uDD8C-\uDD92\uDD94\uDD95\uDD97-\uDDA1\uDDA3-\uDDB1\uDDB3-\uDDB9\uDDBB\uDDBC\uDDC0-\uDDF3\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67\uDF80-\uDF85\uDF87-\uDFB0\uDFB2-\uDFBA]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE35\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2\uDD00-\uDD23\uDD4A-\uDD65\uDD6F-\uDD85\uDE80-\uDEA9\uDEB0\uDEB1\uDEC2-\uDEC4\uDF00-\uDF1C\uDF27\uDF30-\uDF45\uDF70-\uDF81\uDFB0-\uDFC4\uDFE0-\uDFF6]|\uD804[\uDC03-\uDC37\uDC71\uDC72\uDC75\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD44\uDD47\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE3F\uDE40\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61\uDF80-\uDF89\uDF8B\uDF8E\uDF90-\uDFB5\uDFB7\uDFD1\uDFD3]|\uD805[\uDC00-\uDC34\uDC47-\uDC4A\uDC5F-\uDC61\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDEB8\uDF00-\uDF1A\uDF40-\uDF46]|\uD806[\uDC00-\uDC2B\uDCA0-\uDCDF\uDCFF-\uDD06\uDD09\uDD0C-\uDD13\uDD15\uDD16\uDD18-\uDD2F\uDD3F\uDD41\uDDA0-\uDDA7\uDDAA-\uDDD0\uDDE1\uDDE3\uDE00\uDE0B-\uDE32\uDE3A\uDE50\uDE5C-\uDE89\uDE9D\uDEB0-\uDEF8\uDFC0-\uDFE0]|\uD807[\uDC00-\uDC08\uDC0A-\uDC2E\uDC40\uDC72-\uDC8F\uDD00-\uDD06\uDD08\uDD09\uDD0B-\uDD30\uDD46\uDD60-\uDD65\uDD67\uDD68\uDD6A-\uDD89\uDD98\uDEE0-\uDEF2\uDF02\uDF04-\uDF10\uDF12-\uDF33\uDFB0]|\uD808[\uDC00-\uDF99]|\uD809[\uDC80-\uDD43]|\uD80B[\uDF90-\uDFF0]|[\uD80C\uD80E\uD80F\uD81C-\uD820\uD822\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883\uD885-\uD887][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2F\uDC41-\uDC46\uDC60-\uDFFF]|\uD810[\uDC00-\uDFFA]|\uD811[\uDC00-\uDE46]|\uD818[\uDD00-\uDD1D]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE70-\uDEBE\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDD40-\uDD6C\uDE40-\uDE7F\uDF00-\uDF4A\uDF50\uDF93-\uDF9F\uDFE0\uDFE1\uDFE3]|\uD821[\uDC00-\uDFF7]|\uD823[\uDC00-\uDCD5\uDCFF-\uDD08]|\uD82B[\uDFF0-\uDFF3\uDFF5-\uDFFB\uDFFD\uDFFE]|\uD82C[\uDC00-\uDD22\uDD32\uDD50-\uDD52\uDD55\uDD64-\uDD67\uDD70-\uDEFB]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD837[\uDF00-\uDF1E\uDF25-\uDF2A]|\uD838[\uDC30-\uDC6D\uDD00-\uDD2C\uDD37-\uDD3D\uDD4E\uDE90-\uDEAD\uDEC0-\uDEEB]|\uD839[\uDCD0-\uDCEB\uDDD0-\uDDED\uDDF0\uDFE0-\uDFE6\uDFE8-\uDFEB\uDFED\uDFEE\uDFF0-\uDFFE]|\uD83A[\uDC00-\uDCC4\uDD00-\uDD43\uDD4B]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF39\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0\uDFF0-\uDFFF]|\uD87B[\uDC00-\uDE5D]|\uD87E[\uDC00-\uDE1D]|\uD884[\uDC00-\uDF4A\uDF50-\uDFFF]|\uD888[\uDC00-\uDFAF]){2,63}$/;
  return domainRegex.test(domain) && domain.length <= 253;
};

var MessageType;
(function (MessageType) {
  MessageType[MessageType["INCOMING"] = 0] = "INCOMING";
  MessageType[MessageType["OUTGOING"] = 1] = "OUTGOING";
  MessageType[MessageType["ACTIVITY"] = 2] = "ACTIVITY";
  MessageType[MessageType["TEMPLATE"] = 3] = "TEMPLATE";
})(MessageType || (MessageType = {}));

function getRecipients(lastEmail, conversationContact, inboxEmail, forwardToEmail) {
  var _emailAttributes$from;
  var to = [];
  var cc = [];
  var bcc = [];
  // Reset emails if there's no lastEmail
  if (!lastEmail) {
    return {
      to: to,
      cc: cc,
      bcc: bcc
    };
  }
  // Extract values from lastEmail and current conversation context
  var messageType = lastEmail.message_type;
  var isIncoming = messageType === MessageType.INCOMING;
  var emailAttributes = {};
  if (isIncoming) {
    var contentAttributes = lastEmail.content_attributes;
    var email = contentAttributes.email;
    emailAttributes = {
      cc: (email == null ? void 0 : email.cc) || [],
      bcc: (email == null ? void 0 : email.bcc) || [],
      from: (email == null ? void 0 : email.from) || [],
      to: []
    };
  } else {
    var _contentAttributes = lastEmail.content_attributes;
    var _ref = _contentAttributes != null ? _contentAttributes : {},
      _ref$cc_emails = _ref.cc_emails,
      ccEmails = _ref$cc_emails === void 0 ? [] : _ref$cc_emails,
      _ref$bcc_emails = _ref.bcc_emails,
      bccEmails = _ref$bcc_emails === void 0 ? [] : _ref$bcc_emails,
      _ref$to_emails = _ref.to_emails,
      toEmails = _ref$to_emails === void 0 ? [] : _ref$to_emails;
    emailAttributes = {
      cc: ccEmails,
      bcc: bccEmails,
      to: toEmails,
      from: []
    };
  }
  var isLastEmailFromContact = false;
  // this will be false anyway if the last email was outgoing
  isLastEmailFromContact = isIncoming && ((_emailAttributes$from = emailAttributes.from) != null ? _emailAttributes$from : []).includes(conversationContact);
  if (isIncoming) {
    var _to, _emailAttributes$from2;
    // Reply to sender if incoming
    (_to = to).push.apply(_to, (_emailAttributes$from2 = emailAttributes.from) != null ? _emailAttributes$from2 : []);
  } else {
    var _to2, _emailAttributes$to;
    // Otherwise, reply to the last recipient (for outgoing message)
    // If there is no to_emails, reply to the conversation contact
    (_to2 = to).push.apply(_to2, (_emailAttributes$to = emailAttributes.to) != null ? _emailAttributes$to : [conversationContact]);
  }
  // Start building the cc list, including additional recipients
  // If the email had multiple recipients, include them in the cc list
  cc = emailAttributes.cc ? [].concat(emailAttributes.cc) : [];
  // Only include 'to' recipients in cc for incoming emails, not for outgoing
  if (Array.isArray(emailAttributes.to) && isIncoming) {
    var _cc;
    (_cc = cc).push.apply(_cc, emailAttributes.to);
  }
  // Add the conversation contact to cc if the last email wasn't sent by them
  // Ensure the message is an incoming one
  if (!isLastEmailFromContact && isIncoming) {
    cc.push(conversationContact);
  }
  // Process BCC: Remove conversation contact from bcc as it is already in cc
  bcc = (emailAttributes.bcc || []).filter(function (emailAddress) {
    return emailAddress !== conversationContact;
  });
  // Filter out undesired emails from cc:
  // - Remove conversation contact from cc if they sent the last email
  // - Remove inbox and forward-to email to prevent loops
  // - Remove emails matching the reply UUID pattern
  var replyUUIDPattern = /^reply\+([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/i;
  cc = cc.filter(function (email) {
    if (email === conversationContact && isLastEmailFromContact) {
      return false;
    }
    if (email === inboxEmail || email === forwardToEmail) {
      return false;
    }
    if (replyUUIDPattern.test(email)) {
      return false;
    }
    return true;
  });
  bcc = bcc.filter(function (email) {
    if (email === inboxEmail || email === forwardToEmail || replyUUIDPattern.test(email)) {
      return false;
    }
    return true;
  });
  // Deduplicate each recipient list by converting to a Set then back to an array
  to = Array.from(new Set(to));
  cc = Array.from(new Set(cc));
  bcc = Array.from(new Set(bcc));
  return {
    to: to,
    cc: cc,
    bcc: bcc
  };
}

/**
 * Function that parses a string boolean value and returns the corresponding boolean value
 * @param {string | number} candidate - The string boolean value to be parsed
 * @return {boolean} - The parsed boolean value
 */
function parseBoolean(candidate) {
  try {
    // lowercase the string, so TRUE becomes true
    var candidateString = String(candidate).toLowerCase();
    // wrap in boolean to ensure that the return value
    // is a boolean even if values like 0 or 1 are passed
    return Boolean(JSON.parse(candidateString));
  } catch (error) {
    return false;
  }
}
/**
 * Sanitizes text for safe HTML rendering by escaping potentially dangerous characters
 * while preserving valid HTML tags.
 *
 * This function performs the following transformations:
 * - Converts newline characters (\n) to HTML line breaks (<br>)
 * - Escapes stray '<' characters that are not part of valid HTML tags (e.g., "x < 5" → "x &lt; 5")
 * - Escapes stray '>' characters that are not part of valid HTML tags (e.g., "x > 5" → "x &gt; 5")
 * - Preserves valid HTML tags and their attributes (e.g., <div>, <span class="test">, </p>)
 *
 * LIMITATIONS: This regex-based approach has known limitations:
 * - Cannot properly handle '>' characters inside HTML attributes (e.g., <div title="x > 5"> may not work correctly)
 * - Complex nested quotes or edge cases may not be handled perfectly
 * - For more complex HTML sanitization needs, consider using a proper HTML parser
 *
 * @param {string | null | undefined} text - The text to sanitize. Can be null or undefined.
 * @returns {string} The sanitized text safe for HTML rendering, or the original value if null/undefined.
 *
 * @example
 * sanitizeTextForRender('Hello\nWorld') // 'Hello<br>World'
 * sanitizeTextForRender('if x < 5') // 'if x &lt; 5'
 * sanitizeTextForRender('<div>Hello</div>') // '<div>Hello</div>'
 * sanitizeTextForRender('Price < $100 <strong>Sale!</strong>') // 'Price &lt; $100 <strong>Sale!</strong>'
 */
function sanitizeTextForRender(text) {
  if (!text) return '';
  return text.replace(/\n/g, '<br>')
  // Escape < that doesn't start a valid HTML tag
  // Regex breakdown:
  // <          - matches '<'
  // (?!        - negative lookahead (not followed by)
  //   \/?      - optional forward slash for closing tags
  //   \w+      - one or more word characters (tag name)
  //   (?:      - non-capturing group for attributes
  //     \s+    - whitespace before attributes
  //     [^>]*  - any characters except '>' (attribute content)
  //   )?       - attributes are optional
  //   \/?>     - optional self-closing slash, then '>'
  // )          - end lookahead
  .replace(/<(?!\/?\w+(?:\s+[^>]*)?\/?>)/g, '&lt;')
  // Escape > that isn't part of an HTML tag
  // Regex breakdown:
  // (?<!       - negative lookbehind (not preceded by)
  //   <        - opening '<'
  //   \/?      - optional forward slash for closing tags
  //   \w+      - one or more word characters (tag name)
  //   (?:      - non-capturing group for attributes
  //     \s+    - whitespace before attributes
  //     [^>]*  - any characters except '>' (attribute content)
  //   )?       - attributes are optional
  //   \/?      - optional self-closing slash before >
  // )          - end lookbehind
  // >          - matches '>'
  .replace(/(?<!<\/?\w+(?:\s+[^>]*)?\/?)>/g, '&gt;');
}

/**
 * Sorts an array of numbers in ascending order.
 * @param {number[]} arr - The array of numbers to be sorted.
 * @returns {number[]} - The sorted array.
 */
function sortAsc(arr) {
  // .slice() is used to create a copy of the array so that the original array is not mutated
  return arr.slice().sort(function (a, b) {
    return a - b;
  });
}
/**
 * Calculates the quantile value of an array at a specified percentile.
 * @param {number[]} arr - The array of numbers to calculate the quantile value from.
 * @param {number} q - The percentile to calculate the quantile value for.
 * @returns {number} - The quantile value.
 */
function quantile(arr, q) {
  var sorted = sortAsc(arr); // Sort the array in ascending order
  return _quantileForSorted(sorted, q); // Calculate the quantile value
}
/**
 * Clamps a value between a minimum and maximum range.
 * @param {number} min - The minimum range.
 * @param {number} max - The maximum range.
 * @param {number} value - The value to be clamped.
 * @returns {number} - The clamped value.
 */
function clamp(min, max, value) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
/**
 * This method assumes the the array provided is already sorted in ascending order.
 * It's a helper method for the quantile method and should not be exported as is.
 *
 * @param {number[]} arr - The array of numbers to calculate the quantile value from.
 * @param {number} q - The percentile to calculate the quantile value for.
 * @returns {number} - The quantile value.
 */
function _quantileForSorted(sorted, q) {
  var clamped = clamp(0, 1, q); // Clamp the percentile between 0 and 1
  var pos = (sorted.length - 1) * clamped; // Calculate the index of the element at the specified percentile
  var base = Math.floor(pos); // Find the index of the closest element to the specified percentile
  var rest = pos - base; // Calculate the decimal value between the closest elements
  // Interpolate the quantile value between the closest elements
  // Most libraries don't to the interpolation, but I'm just having fun here
  // also see https://en.wikipedia.org/wiki/Quantile#Estimating_quantiles_from_a_sample
  if (sorted[base + 1] !== undefined) {
    // in case the position was a integer, the rest will be 0 and the interpolation will be skipped
    return sorted[base] + rest * (sorted[base + 1] - sorted[base]);
  }
  // Return the closest element if there is no interpolation possible
  return sorted[base];
}
/**
 * Calculates the quantile values for an array of intervals.
 * @param {number[]} data - The array of numbers to calculate the quantile values from.
 * @param {number[]} intervals - The array of intervals to calculate the quantile values for.
 * @returns {number[]} - The array of quantile values for the intervals.
 */
var getQuantileIntervals = function getQuantileIntervals(data, intervals) {
  // Sort the array in ascending order before looping through the intervals.
  // depending on the size of the array and the number of intervals, this can speed up the process by at least twice
  // for a random array of 100 numbers and 5 intervals, the speedup is 3x
  var sorted = sortAsc(data);
  return intervals.map(function (interval) {
    return _quantileForSorted(sorted, interval);
  });
};
/**
 * Calculates the relative position of a point from the center of an element
 *
 * @param {number} mouseX - The x-coordinate of the mouse pointer
 * @param {number} mouseY - The y-coordinate of the mouse pointer
 * @param {DOMRect} rect - The bounding client rectangle of the target element
 * @returns {{relativeX: number, relativeY: number}} Object containing x and y distances from center
 */
var calculateCenterOffset = function calculateCenterOffset(mouseX, mouseY, rect) {
  var centerX = rect.left + rect.width / 2;
  var centerY = rect.top + rect.height / 2;
  return {
    relativeX: mouseX - centerX,
    relativeY: mouseY - centerY
  };
};
/**
 * Applies a rotation matrix to coordinates
 * Used to adjust mouse coordinates based on the current rotation of the image
 * This function implements a standard 2D rotation matrix transformation:
 * [x']   [cos(θ) -sin(θ)] [x]
 * [y'] = [sin(θ)  cos(θ)] [y]
 *
 * @see {@link https://mathworld.wolfram.com/RotationMatrix.html} for mathematical derivation
 *
 * @param {number} relativeX - X-coordinate relative to center before rotation
 * @param {number} relativeY - Y-coordinate relative to center before rotation
 * @param {number} angle - Rotation angle in degrees
 * @returns {{rotatedX: number, rotatedY: number}} Coordinates after applying rotation matrix
 */
var applyRotationTransform = function applyRotationTransform(relativeX, relativeY, angle) {
  var radians = angle * Math.PI / 180;
  var cos = Math.cos(-radians);
  var sin = Math.sin(-radians);
  return {
    rotatedX: relativeX * cos - relativeY * sin,
    rotatedY: relativeX * sin + relativeY * cos
  };
};
/**
 * Converts absolute rotated coordinates to percentage values relative to image dimensions
 * Ensures values are clamped between 0-100% for valid CSS transform-origin properties
 *
 * @param {number} rotatedX - X-coordinate after rotation transformation
 * @param {number} rotatedY - Y-coordinate after rotation transformation
 * @param {number} width - Width of the target element
 * @param {number} height - Height of the target element
 * @returns {{x: number, y: number}} Normalized coordinates as percentages (0-100%)
 */
var normalizeToPercentage = function normalizeToPercentage(rotatedX, rotatedY, width, height) {
  // Convert to percentages (0-100%) relative to image dimensions
  // 50% represents the center point
  // The division by (width/2) maps the range [-width/2, width/2] to [-50%, 50%]
  // Adding 50% shifts this to [0%, 100%]
  return {
    x: Math.max(0, Math.min(100, 50 + rotatedX / (width / 2) * 50)),
    y: Math.max(0, Math.min(100, 50 + rotatedY / (height / 2) * 50))
  };
};

var MESSAGE_VARIABLES_REGEX = /{{(.*?)}}/g;
var skipCodeBlocks = function skipCodeBlocks(str) {
  return str.replace(/```(?:.|\n)+?```/g, '');
};
var capitalizeName = function capitalizeName(name) {
  if (!name) return ''; // Return empty string for null or undefined input
  return name.split(' ') // Split the name into words based on spaces
  .map(function (word) {
    if (!word) return ''; // Handle empty strings that might result from multiple spaces
    // Capitalize only the first character, leaving the rest unchanged
    // This correctly handles accented characters like 'í' in 'Aríel'
    return word.charAt(0).toUpperCase() + word.slice(1);
  }).join(' '); // Rejoin the words with spaces
};
var getFirstName = function getFirstName(_ref) {
  var user = _ref.user;
  var firstName = user != null && user.name ? user.name.split(' ').shift() : '';
  return capitalizeName(firstName);
};
var getLastName = function getLastName(_ref2) {
  var user = _ref2.user;
  if (user && user.name) {
    var lastName = user.name.split(' ').length > 1 ? user.name.split(' ').pop() : '';
    return capitalizeName(lastName);
  }
  return '';
};
var getMessageVariables = function getMessageVariables(_ref3) {
  var _assignee$email;
  var conversation = _ref3.conversation,
    contact = _ref3.contact,
    inbox = _ref3.inbox;
  var _conversation$meta = conversation.meta,
    assignee = _conversation$meta.assignee,
    sender = _conversation$meta.sender,
    id = conversation.id,
    _conversation$custom_ = conversation.custom_attributes,
    conversationCustomAttributes = _conversation$custom_ === void 0 ? {} : _conversation$custom_;
  var _ref4 = contact || {},
    contactCustomAttributes = _ref4.custom_attributes;
  var standardVariables = {
    'contact.name': capitalizeName((sender == null ? void 0 : sender.name) || ''),
    'contact.first_name': getFirstName({
      user: sender
    }),
    'contact.last_name': getLastName({
      user: sender
    }),
    'contact.email': sender == null ? void 0 : sender.email,
    'contact.phone': sender == null ? void 0 : sender.phone_number,
    'contact.id': sender == null ? void 0 : sender.id,
    'conversation.id': id,
    'inbox.id': inbox == null ? void 0 : inbox.id,
    'inbox.name': inbox == null ? void 0 : inbox.name,
    'agent.name': capitalizeName((assignee == null ? void 0 : assignee.name) || ''),
    'agent.first_name': getFirstName({
      user: assignee
    }),
    'agent.last_name': getLastName({
      user: assignee
    }),
    'agent.email': (_assignee$email = assignee == null ? void 0 : assignee.email) != null ? _assignee$email : ''
  };
  var conversationCustomAttributeVariables = Object.entries(conversationCustomAttributes != null ? conversationCustomAttributes : {}).reduce(function (acc, _ref5) {
    var key = _ref5[0],
      value = _ref5[1];
    acc["conversation.custom_attribute." + key] = value;
    return acc;
  }, {});
  var contactCustomAttributeVariables = Object.entries(contactCustomAttributes != null ? contactCustomAttributes : {}).reduce(function (acc, _ref6) {
    var key = _ref6[0],
      value = _ref6[1];
    acc["contact.custom_attribute." + key] = value;
    return acc;
  }, {});
  var variables = _extends({}, standardVariables, conversationCustomAttributeVariables, contactCustomAttributeVariables);
  return variables;
};
var replaceVariablesInMessage = function replaceVariablesInMessage(_ref7) {
  var message = _ref7.message,
    variables = _ref7.variables;
  // @ts-ignore
  return message == null ? void 0 : message.replace(MESSAGE_VARIABLES_REGEX, function (_, replace) {
    return variables[replace.trim()] ? variables[replace.trim().toLowerCase()] : '';
  });
};
var getUndefinedVariablesInMessage = function getUndefinedVariablesInMessage(_ref8) {
  var message = _ref8.message,
    variables = _ref8.variables;
  var messageWithOutCodeBlocks = skipCodeBlocks(message);
  var matches = messageWithOutCodeBlocks.match(MESSAGE_VARIABLES_REGEX);
  if (!matches) return [];
  return matches.map(function (match) {
    return match.replace('{{', '').replace('}}', '').trim();
  }).filter(function (variable) {
    return variables[variable] === undefined;
  });
};

/**
 * Creates a typing indicator utility.
 * @param onStartTyping Callback function to be called when typing starts
 * @param onStopTyping Callback function to be called when typing stops after delay
 * @param idleTime Delay for idle time in ms before considering typing stopped
 * @returns An object with start and stop methods for typing indicator
 */
var createTypingIndicator = function createTypingIndicator(onStartTyping, onStopTyping, idleTime) {
  var timer = null;
  var start = function start() {
    if (!timer) {
      onStartTyping();
    }
    reset();
  };
  var stop = function stop() {
    if (timer) {
      clearTimeout(timer);
      timer = null;
      onStopTyping();
    }
  };
  var reset = function reset() {
    if (timer) {
      clearTimeout(timer);
    }
    timer = setTimeout(function () {
      stop();
    }, idleTime);
  };
  return {
    start: start,
    stop: stop
  };
};

/**
 * Calculates the threshold for an SLA based on the current time and the provided threshold.
 * @param timeOffset - The time offset in seconds.
 * @param threshold - The threshold in seconds or null if not applicable.
 * @returns The calculated threshold in seconds or null if the threshold is null.
 */
var calculateThreshold = function calculateThreshold(timeOffset, threshold) {
  // Calculate the time left for the SLA to breach or the time since the SLA has missed
  if (threshold === null) return null;
  var currentTime = Math.floor(Date.now() / 1000);
  return timeOffset + threshold - currentTime;
};
/**
 * Finds the most urgent SLA status based on the threshold.
 * @param SLAStatuses - An array of SLAStatus objects.
 * @returns The most urgent SLAStatus object.
 */
var findMostUrgentSLAStatus = function findMostUrgentSLAStatus(SLAStatuses) {
  // Sort the SLAs based on the threshold and return the most urgent SLA
  SLAStatuses.sort(function (sla1, sla2) {
    return Math.abs(sla1.threshold) - Math.abs(sla2.threshold);
  });
  return SLAStatuses[0];
};
/**
 * Formats the SLA time in a human-readable format.
 * @param seconds - The time in seconds.
 * @returns A formatted string representing the time.
 */
var formatSLATime = function formatSLATime(seconds) {
  var units = {
    y: 31536000,
    mo: 2592000,
    d: 86400,
    h: 3600,
    m: 60
  };
  if (seconds < 60) {
    return '1m';
  }
  // we will only show two parts, two max granularity's, h-m, y-d, d-h, m, but no seconds
  var parts = [];
  Object.keys(units).forEach(function (unit) {
    var value = Math.floor(seconds / units[unit]);
    if (seconds < 60 && parts.length > 0) return;
    if (parts.length === 2) return;
    if (value > 0) {
      parts.push(value + unit);
      seconds -= value * units[unit];
    }
  });
  return parts.join(' ');
};
/**
 * Creates an SLA object based on the type, applied SLA, and chat details.
 * @param type - The type of SLA (FRT, NRT, RT).
 * @param appliedSla - The applied SLA details.
 * @param chat - The chat details.
 * @returns An object containing the SLA status or null if conditions are not met.
 */
var createSLAObject = function createSLAObject(type, appliedSla, chat) {
  var frtThreshold = appliedSla.sla_first_response_time_threshold,
    nrtThreshold = appliedSla.sla_next_response_time_threshold,
    rtThreshold = appliedSla.sla_resolution_time_threshold,
    createdAt = appliedSla.created_at;
  var firstReplyCreatedAt = chat.first_reply_created_at,
    waitingSince = chat.waiting_since,
    status = chat.status;
  var SLATypes = {
    FRT: {
      threshold: calculateThreshold(createdAt, frtThreshold),
      //   Check FRT only if threshold is not null and first reply hasn't been made
      condition: frtThreshold !== null && (!firstReplyCreatedAt || firstReplyCreatedAt === 0)
    },
    NRT: {
      threshold: calculateThreshold(waitingSince, nrtThreshold),
      // Check NRT only if threshold is not null, first reply has been made and we are waiting since
      condition: nrtThreshold !== null && !!firstReplyCreatedAt && !!waitingSince
    },
    RT: {
      threshold: calculateThreshold(createdAt, rtThreshold),
      // Check RT only if the conversation is open and threshold is not null
      condition: status === 'open' && rtThreshold !== null
    }
  };
  var SLAStatus = SLATypes[type];
  return SLAStatus ? _extends({}, SLAStatus, {
    type: type
  }) : null;
};
/**
 * Evaluates SLA conditions and returns an array of SLAStatus objects.
 * @param appliedSla - The applied SLA details.
 * @param chat - The chat details.
 * @returns An array of SLAStatus objects.
 */
var evaluateSLAConditions = function evaluateSLAConditions(appliedSla, chat) {
  // Filter out the SLA based on conditions and update the object with the breach status(icon, isSlaMissed)
  var SLATypes = ['FRT', 'NRT', 'RT'];
  return SLATypes.map(function (type) {
    return createSLAObject(type, appliedSla, chat);
  }).filter(function (SLAStatus) {
    return !!SLAStatus && SLAStatus.condition;
  }).map(function (SLAStatus) {
    return _extends({}, SLAStatus, {
      icon: SLAStatus.threshold <= 0 ? 'flame' : 'alarm',
      isSlaMissed: SLAStatus.threshold <= 0
    });
  });
};
/**
 * Evaluates the SLA status for a given chat and applied SLA.
 * @param {Object} params - The parameters object.
 * @param params.appliedSla - The applied SLA details.
 * @param params.chat - The chat details.
 * @returns An object containing the most urgent SLA status.
 */
var evaluateSLAStatus = function evaluateSLAStatus(_ref) {
  var appliedSla = _ref.appliedSla,
    chat = _ref.chat;
  if (!appliedSla || !chat) return {
    type: '',
    threshold: '',
    icon: '',
    isSlaMissed: false
  };
  // Filter out the SLA and create the object for each breach
  var SLAStatuses = evaluateSLAConditions(appliedSla, chat);
  // Return the most urgent SLA which is latest to breach or has missed
  var mostUrgent = findMostUrgentSLAStatus(SLAStatuses);
  return mostUrgent ? {
    type: mostUrgent == null ? void 0 : mostUrgent.type,
    threshold: formatSLATime(mostUrgent.threshold <= 0 ? -mostUrgent.threshold : mostUrgent.threshold),
    icon: mostUrgent.icon,
    isSlaMissed: mostUrgent.isSlaMissed
  } : {
    type: '',
    threshold: '',
    icon: '',
    isSlaMissed: false
  };
};

/**
 * Parses various date formats into a JavaScript Date object
 *
 * This function handles different date input formats commonly found in conversation data:
 * - 10-digit timestamps (Unix seconds) - automatically converted to milliseconds
 * - 13-digit timestamps (Unix milliseconds) - used directly
 * - String representations of timestamps
 * - ISO date strings (e.g., "2025-06-01T12:30:00Z")
 * - Simple date strings (e.g., "2025-06-01") - time defaults to 00:00:00
 * - Date strings with space-separated time (e.g., "2025-06-01 12:30:00")
 *
 * Note: This function follows JavaScript Date constructor behavior for date parsing.
 * Some invalid dates like "2025-02-30" auto-correct to valid dates (becomes "2025-03-02"),
 * while malformed strings like "2025-13-01" or "2025-06-01T25:00:00" return null.
 *
 * @example
 * coerceToDate('2025-06-01') // Returns Date object set to 2025-06-01 00:00:00
 * coerceToDate('2025-06-01T12:30:00Z') // Returns Date object with specified time
 * coerceToDate(1748834578) // Returns Date object (10-digit timestamp in seconds)
 * coerceToDate(1748834578000) // Returns Date object (13-digit timestamp in milliseconds)
 * coerceToDate('1748834578') // Returns Date object (string timestamp converted)
 * coerceToDate(null) // Returns null
 * coerceToDate('invalid-date') // Returns null
 */
var coerceToDate = function coerceToDate(dateInput) {
  if (dateInput == null) return null;
  var timestamp = typeof dateInput === 'number' ? dateInput : null;
  // Handle string inputs that represent numeric timestamps
  if (timestamp === null && typeof dateInput === 'string' && /^\d+$/.test(dateInput)) {
    timestamp = Number(dateInput);
  }
  // Process numeric timestamps
  if (timestamp !== null) {
    // Convert 10-digit timestamps (seconds) to milliseconds
    var timestampMs = timestamp.toString().length === 10 ? timestamp * 1000 : timestamp;
    return new Date(timestampMs);
  }
  // Process string date inputs
  if (typeof dateInput === 'string') {
    var dateObj = new Date(dateInput);
    // Return null for invalid dates
    if (Number.isNaN(dateObj.getTime())) return null;
    // If no time component is specified, set time to 00:00:00
    // this is because by default JS will set the time to midnight UTC for that date
    var hasTimeComponent = /T\d{2}:\d{2}(:\d{2})?/.test(dateInput) || /\d{2}:\d{2}/.test(dateInput);
    if (!hasTimeComponent) {
      dateObj.setHours(0, 0, 0, 0);
    }
    return dateObj;
  }
  return null;
};

var _CHANNEL_CONFIGS;
// ---------- Channels ----------
var INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  WHATSAPP: 'Channel::Whatsapp',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
  TELEGRAM: 'Channel::Telegram',
  LINE: 'Channel::Line',
  SMS: 'Channel::Sms',
  INSTAGRAM: 'Channel::Instagram',
  VOICE: 'Channel::Voice'
};
// ---------- Docs ----------
/**
 * LINE: https://developers.line.biz/en/reference/messaging-api/#image-message, https://developers.line.biz/en/reference/messaging-api/#video-message
 * INSTAGRAM: https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api#requirements
 * WHATSAPP CLOUD: https://developers.facebook.com/docs/whatsapp/cloud-api/reference/media#supported-media-types
 * TWILIO WHATSAPP: https://www.twilio.com/docs/whatsapp/guidance-whatsapp-media-messages
 * TWILIO SMS: https://www.twilio.com/docs/messaging/guides/accepted-mime-types
 */
// ---------- Central config ----------
/**
 * Upload rules configuration.
 *
 * Each node can define:
 * - mimeGroups: { prefix: [exts] }
 *   Example: { image: ["png","jpeg"] } → ["image/png","image/jpeg"]
 *   Special: ["*"] → allow all (e.g. "image/*").
 * - extensions: Raw file extensions (e.g. [".3gpp"]).
 * - max: Default maximum size in MB for this channel.
 * - maxByCategory: Override per category (image, video, audio, document).
 *
 * Resolution order:
 *  1. channel + medium (e.g. TWILIO.whatsapp)
 *  2. channel + "*" fallback
 *  3. global default
 */
var CHANNEL_CONFIGS = (_CHANNEL_CONFIGS = {
  "default": {
    mimeGroups: {
      image: ['*'],
      audio: ['*'],
      video: ['*'],
      text: ['csv', 'plain', 'rtf', 'xml'],
      application: ['json', 'pdf', 'xml', 'zip', 'x-7z-compressed', 'vnd.rar', 'x-tar', 'msword', 'vnd.ms-excel', 'vnd.ms-powerpoint', 'vnd.oasis.opendocument.text', 'vnd.openxmlformats-officedocument.presentationml.presentation', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'vnd.openxmlformats-officedocument.wordprocessingml.document']
    },
    extensions: ['.3gpp'],
    max: 40
  }
}, _CHANNEL_CONFIGS[INBOX_TYPES.WHATSAPP] = {
  '*': {
    mimeGroups: {
      audio: ['aac', 'amr', 'mp3', 'm4a', 'ogg'],
      image: ['jpeg', 'png'],
      video: ['3gp', 'mp4'],
      text: ['plain'],
      application: ['pdf', 'vnd.ms-excel', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'msword', 'vnd.openxmlformats-officedocument.wordprocessingml.document', 'vnd.ms-powerpoint', 'vnd.openxmlformats-officedocument.presentationml.presentation']
    },
    maxByCategory: {
      image: 5,
      video: 16,
      audio: 16,
      document: 100
    }
  }
}, _CHANNEL_CONFIGS[INBOX_TYPES.INSTAGRAM] = {
  '*': {
    mimeGroups: {
      audio: ['aac', 'm4a', 'wav', 'mp4'],
      image: ['png', 'jpeg', 'gif'],
      video: ['mp4', 'ogg', 'avi', 'mov', 'webm']
    },
    maxByCategory: {
      image: 16,
      video: 25,
      audio: 25
    }
  }
}, _CHANNEL_CONFIGS[INBOX_TYPES.FB] = {
  '*': {
    mimeGroups: {
      audio: ['aac', 'm4a', 'wav', 'mp4'],
      image: ['png', 'jpeg', 'gif'],
      video: ['mp4', 'ogg', 'avi', 'mov', 'webm'],
      text: ['plain'],
      application: ['pdf', 'vnd.ms-excel', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'msword', 'vnd.openxmlformats-officedocument.wordprocessingml.document', 'vnd.ms-powerpoint', 'vnd.openxmlformats-officedocument.presentationml.presentation']
    },
    maxByCategory: {
      image: 8,
      audio: 25,
      video: 25,
      document: 25
    }
  }
}, _CHANNEL_CONFIGS[INBOX_TYPES.LINE] = {
  '*': {
    mimeGroups: {
      image: ['png', 'jpeg'],
      video: ['mp4']
    },
    maxByCategory: {
      image: 10
    }
  }
}, _CHANNEL_CONFIGS[INBOX_TYPES.TWILIO] = {
  sms: {
    max: 5
  },
  whatsapp: {
    mimeGroups: {
      image: ['png', 'jpeg'],
      audio: ['mpeg', 'opus', 'ogg', 'amr'],
      video: ['mp4'],
      application: ['pdf']
    },
    max: 5
  }
}, _CHANNEL_CONFIGS);
// ---------- Helpers ----------
/**
 * @name DOC_HEADS
 * @description MIME type categories that should be considered "document"
 */
var DOC_HEADS = /*#__PURE__*/new Set(['application', 'text']);
/**
 * @name categoryFromMime
 * @description Gets a high-level category name from a MIME type.
 *
 * @param {string} mime - MIME type string (e.g. "image/png").
 * @returns {"image"|"video"|"audio"|"document"|undefined} Category name.
 */
var categoryFromMime = function categoryFromMime(mime) {
  var _mime$split$, _mime$split;
  var head = (_mime$split$ = mime == null || (_mime$split = mime.split('/')) == null ? void 0 : _mime$split[0]) != null ? _mime$split$ : '';
  return DOC_HEADS.has(head) ? 'document' : head;
};
/**
 * @name getNode
 * @description Finds the matching rule node for a channel and optional medium.
 *
 * @param {ChannelKey} [channelType] - One of INBOX_TYPES.
 * @param {string}      [medium]     - Optional sub-medium (e.g. "sms","whatsapp").
 * @returns {ChannelNodeConfig} Config node with rules.
 */
var getNode = function getNode(channelType, medium) {
  var _ref, _channelCfg;
  if (!channelType) return CHANNEL_CONFIGS["default"];
  var channelCfg = CHANNEL_CONFIGS[channelType];
  if (!channelCfg) return CHANNEL_CONFIGS["default"];
  return (_ref = (_channelCfg = channelCfg[medium != null ? medium : '*']) != null ? _channelCfg : channelCfg['*']) != null ? _ref : CHANNEL_CONFIGS["default"];
};
/**
 * @name expandMimeGroups
 * @description Expands MIME groups and extensions into a list of strings.
 *
 * Examples:
 *  { image: ["*"] }         → ["image/*"]
 *  { image: ["png"] }       → ["image/png"]
 *  { application: ["pdf"] } → ["application/pdf"]
 *  extensions: [".3gpp"]    → [".3gpp"]
 *
 * @param {Object} mimeGroups - Grouped MIME suffixes by prefix.
 * @param {string[]} extensions - Extra raw extensions.
 * @returns {string[]} Expanded list of MIME/extension strings.
 */
var expandMimeGroups = function expandMimeGroups(mimeGroups, extensions) {
  if (mimeGroups === void 0) {
    mimeGroups = {};
  }
  if (extensions === void 0) {
    extensions = [];
  }
  var mimes = Object.entries(mimeGroups).flatMap(function (_ref2) {
    var prefix = _ref2[0],
      exts = _ref2[1];
    return (exts != null ? exts : []).map(function (ext) {
      return ext === '*' ? prefix + "/*" : prefix + "/" + ext;
    });
  });
  return [].concat(mimes, extensions);
};
// ---------- Public API ----------
/**
 * @name getAllowedFileTypesByChannel
 * @description Builds the full "accept" string for <input type="file">,
 * based on channel + medium rules.
 *
 * @param {Object} params
 * @param {string} [params.channelType] - Channel type (from INBOX_TYPES).
 * @param {string} [params.medium] - Medium under the channel.
 * @returns {string} Comma-separated list of allowed MIME types/extensions.
 *
 * @example
 * getAllowedFileTypesByChannel({ channelType: INBOX_TYPES.WHATSAPP });
 * → "audio/aac, audio/amr, image/jpeg, image/png, video/3gp, ..."
 */
var getAllowedFileTypesByChannel = function getAllowedFileTypesByChannel(_temp) {
  var _ref3 = _temp === void 0 ? {} : _temp,
    channelType = _ref3.channelType,
    medium = _ref3.medium;
  var node = getNode(channelType, medium);
  var _ref4 = !node.mimeGroups && !node.extensions ? CHANNEL_CONFIGS["default"] : node,
    mimeGroups = _ref4.mimeGroups,
    extensions = _ref4.extensions;
  return expandMimeGroups(mimeGroups, extensions).join(', ');
};
/**
 * @name getMaxUploadSizeByChannel
 * @description Gets the maximum allowed file size (in MB) for a channel, medium, and MIME type.
 *
 * Priority:
 * - Category-specific size (image/video/audio/document).
 * - Channel/medium-level max.
 * - Global default max.
 *
 * @param {Object} params
 * @param {string} [params.channelType] - Channel type (from INBOX_TYPES).
 * @param {string} [params.medium] - Medium under the channel.
 * @param {string} [params.mime] - MIME type string (for category lookup).
 * @returns {number} Maximum file size in MB.
 *
 * @example
 * getMaxUploadSizeByChannel({ channelType: INBOX_TYPES.WHATSAPP, mime: "image/png" });
 * → 5
 */
var getMaxUploadSizeByChannel = function getMaxUploadSizeByChannel(_temp2) {
  var _node$maxByCategory, _ref6;
  var _ref5 = _temp2 === void 0 ? {} : _temp2,
    channelType = _ref5.channelType,
    medium = _ref5.medium,
    mime = _ref5.mime;
  var node = getNode(channelType, medium);
  var cat = categoryFromMime(mime);
  var catMax = cat ? (_node$maxByCategory = node.maxByCategory) == null ? void 0 : _node$maxByCategory[cat] : undefined;
  return (_ref6 = catMax != null ? catMax : node.max) != null ? _ref6 : CHANNEL_CONFIGS["default"].max;
};

exports.applyRotationTransform = applyRotationTransform;
exports.calculateCenterOffset = calculateCenterOffset;
exports.clamp = clamp;
exports.coerceToDate = coerceToDate;
exports.convertSecondsToTimeUnit = convertSecondsToTimeUnit;
exports.createTypingIndicator = createTypingIndicator;
exports.debounce = debounce;
exports.downloadFile = downloadFile;
exports.evaluateSLAStatus = evaluateSLAStatus;
exports.fileNameWithEllipsis = fileNameWithEllipsis;
exports.formatDate = formatDate;
exports.formatNumber = formatNumber;
exports.formatTime = formatTime;
exports.getAllowedFileTypesByChannel = getAllowedFileTypesByChannel;
exports.getContrastingTextColor = getContrastingTextColor;
exports.getFileInfo = getFileInfo;
exports.getMaxUploadSizeByChannel = getMaxUploadSizeByChannel;
exports.getMessageVariables = getMessageVariables;
exports.getQuantileIntervals = getQuantileIntervals;
exports.getRecipients = getRecipients;
exports.getUndefinedVariablesInMessage = getUndefinedVariablesInMessage;
exports.isSameHost = isSameHost;
exports.isValidDomain = isValidDomain;
exports.normalizeToPercentage = normalizeToPercentage;
exports.parseBoolean = parseBoolean;
exports.quantile = quantile;
exports.replaceVariablesInMessage = replaceVariablesInMessage;
exports.sanitizeTextForRender = sanitizeTextForRender;
exports.sortAsc = sortAsc;
exports.splitName = splitName;
exports.toURL = toURL;
exports.trimContent = trimContent;
//# sourceMappingURL=utils.cjs.development.js.map
