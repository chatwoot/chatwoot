var v = function(e, t) {
  return v = Object.setPrototypeOf || { __proto__: [] } instanceof Array && function(n, r) {
    n.__proto__ = r;
  } || function(n, r) {
    for (var i in r)
      Object.prototype.hasOwnProperty.call(r, i) && (n[i] = r[i]);
  }, v(e, t);
};
function S(e, t) {
  if (typeof t != "function" && t !== null)
    throw new TypeError("Class extends value " + String(t) + " is not a constructor or null");
  v(e, t);
  function n() {
    this.constructor = e;
  }
  e.prototype = t === null ? Object.create(t) : (n.prototype = t.prototype, new n());
}
var m = function() {
  return m = Object.assign || function(t) {
    for (var n, r = 1, i = arguments.length; r < i; r++) {
      n = arguments[r];
      for (var o in n)
        Object.prototype.hasOwnProperty.call(n, o) && (t[o] = n[o]);
    }
    return t;
  }, m.apply(this, arguments);
};
function E(e, t) {
  var n = {};
  for (var r in e)
    Object.prototype.hasOwnProperty.call(e, r) && t.indexOf(r) < 0 && (n[r] = e[r]);
  if (e != null && typeof Object.getOwnPropertySymbols == "function")
    for (var i = 0, r = Object.getOwnPropertySymbols(e); i < r.length; i++)
      t.indexOf(r[i]) < 0 && Object.prototype.propertyIsEnumerable.call(e, r[i]) && (n[r[i]] = e[r[i]]);
  return n;
}
function P(e, t, n, r) {
  var i = arguments.length, o = i < 3 ? t : r === null ? r = Object.getOwnPropertyDescriptor(t, n) : r, a;
  if (typeof Reflect == "object" && typeof Reflect.decorate == "function")
    o = Reflect.decorate(e, t, n, r);
  else
    for (var u = e.length - 1; u >= 0; u--)
      (a = e[u]) && (o = (i < 3 ? a(o) : i > 3 ? a(t, n, o) : a(t, n)) || o);
  return i > 3 && o && Object.defineProperty(t, n, o), o;
}
function T(e, t) {
  return function(n, r) {
    t(n, r, e);
  };
}
function W(e, t, n, r, i, o) {
  function a(b) {
    if (b !== void 0 && typeof b != "function")
      throw new TypeError("Function expected");
    return b;
  }
  for (var u = r.kind, y = u === "getter" ? "get" : u === "setter" ? "set" : "value", f = !t && e ? r.static ? e : e.prototype : null, c = t || (f ? Object.getOwnPropertyDescriptor(f, r.name) : {}), s, l = !1, p = n.length - 1; p >= 0; p--) {
    var h = {};
    for (var d in r)
      h[d] = d === "access" ? {} : r[d];
    for (var d in r.access)
      h.access[d] = r.access[d];
    h.addInitializer = function(b) {
      if (l)
        throw new TypeError("Cannot add initializers after decoration has completed");
      o.push(a(b || null));
    };
    var _ = (0, n[p])(u === "accessor" ? { get: c.get, set: c.set } : c[y], h);
    if (u === "accessor") {
      if (_ === void 0)
        continue;
      if (_ === null || typeof _ != "object")
        throw new TypeError("Object expected");
      (s = a(_.get)) && (c.get = s), (s = a(_.set)) && (c.set = s), (s = a(_.init)) && i.unshift(s);
    } else
      (s = a(_)) && (u === "field" ? i.unshift(s) : c[y] = s);
  }
  f && Object.defineProperty(f, r.name, c), l = !0;
}
function X(e, t, n) {
  for (var r = arguments.length > 2, i = 0; i < t.length; i++)
    n = r ? t[i].call(e, n) : t[i].call(e);
  return r ? n : void 0;
}
function Y(e) {
  return typeof e == "symbol" ? e : "".concat(e);
}
function Z(e, t, n) {
  return typeof t == "symbol" && (t = t.description ? "[".concat(t.description, "]") : ""), Object.defineProperty(e, "name", { configurable: !0, value: n ? "".concat(n, " ", t) : t });
}
function D(e, t) {
  if (typeof Reflect == "object" && typeof Reflect.metadata == "function")
    return Reflect.metadata(e, t);
}
function x(e, t, n, r) {
  function i(o) {
    return o instanceof n ? o : new n(function(a) {
      a(o);
    });
  }
  return new (n || (n = Promise))(function(o, a) {
    function u(c) {
      try {
        f(r.next(c));
      } catch (s) {
        a(s);
      }
    }
    function y(c) {
      try {
        f(r.throw(c));
      } catch (s) {
        a(s);
      }
    }
    function f(c) {
      c.done ? o(c.value) : i(c.value).then(u, y);
    }
    f((r = r.apply(e, t || [])).next());
  });
}
function R(e, t) {
  var n = { label: 0, sent: function() {
    if (o[0] & 1)
      throw o[1];
    return o[1];
  }, trys: [], ops: [] }, r, i, o, a;
  return a = { next: u(0), throw: u(1), return: u(2) }, typeof Symbol == "function" && (a[Symbol.iterator] = function() {
    return this;
  }), a;
  function u(f) {
    return function(c) {
      return y([f, c]);
    };
  }
  function y(f) {
    if (r)
      throw new TypeError("Generator is already executing.");
    for (; a && (a = 0, f[0] && (n = 0)), n; )
      try {
        if (r = 1, i && (o = f[0] & 2 ? i.return : f[0] ? i.throw || ((o = i.return) && o.call(i), 0) : i.next) && !(o = o.call(i, f[1])).done)
          return o;
        switch (i = 0, o && (f = [f[0] & 2, o.value]), f[0]) {
          case 0:
          case 1:
            o = f;
            break;
          case 4:
            return n.label++, { value: f[1], done: !1 };
          case 5:
            n.label++, i = f[1], f = [0];
            continue;
          case 7:
            f = n.ops.pop(), n.trys.pop();
            continue;
          default:
            if (o = n.trys, !(o = o.length > 0 && o[o.length - 1]) && (f[0] === 6 || f[0] === 2)) {
              n = 0;
              continue;
            }
            if (f[0] === 3 && (!o || f[1] > o[0] && f[1] < o[3])) {
              n.label = f[1];
              break;
            }
            if (f[0] === 6 && n.label < o[1]) {
              n.label = o[1], o = f;
              break;
            }
            if (o && n.label < o[2]) {
              n.label = o[2], n.ops.push(f);
              break;
            }
            o[2] && n.ops.pop(), n.trys.pop();
            continue;
        }
        f = t.call(e, n);
      } catch (c) {
        f = [6, c], i = 0;
      } finally {
        r = o = 0;
      }
    if (f[0] & 5)
      throw f[1];
    return { value: f[0] ? f[1] : void 0, done: !0 };
  }
}
var O = Object.create ? function(e, t, n, r) {
  r === void 0 && (r = n);
  var i = Object.getOwnPropertyDescriptor(t, n);
  (!i || ("get" in i ? !t.__esModule : i.writable || i.configurable)) && (i = { enumerable: !0, get: function() {
    return t[n];
  } }), Object.defineProperty(e, r, i);
} : function(e, t, n, r) {
  r === void 0 && (r = n), e[r] = t[n];
};
function A(e, t) {
  for (var n in e)
    n !== "default" && !Object.prototype.hasOwnProperty.call(t, n) && O(t, e, n);
}
function g(e) {
  var t = typeof Symbol == "function" && Symbol.iterator, n = t && e[t], r = 0;
  if (n)
    return n.call(e);
  if (e && typeof e.length == "number")
    return {
      next: function() {
        return e && r >= e.length && (e = void 0), { value: e && e[r++], done: !e };
      }
    };
  throw new TypeError(t ? "Object is not iterable." : "Symbol.iterator is not defined.");
}
function j(e, t) {
  var n = typeof Symbol == "function" && e[Symbol.iterator];
  if (!n)
    return e;
  var r = n.call(e), i, o = [], a;
  try {
    for (; (t === void 0 || t-- > 0) && !(i = r.next()).done; )
      o.push(i.value);
  } catch (u) {
    a = { error: u };
  } finally {
    try {
      i && !i.done && (n = r.return) && n.call(r);
    } finally {
      if (a)
        throw a.error;
    }
  }
  return o;
}
function C() {
  for (var e = [], t = 0; t < arguments.length; t++)
    e = e.concat(j(arguments[t]));
  return e;
}
function F() {
  for (var e = 0, t = 0, n = arguments.length; t < n; t++)
    e += arguments[t].length;
  for (var r = Array(e), i = 0, t = 0; t < n; t++)
    for (var o = arguments[t], a = 0, u = o.length; a < u; a++, i++)
      r[i] = o[a];
  return r;
}
function M(e, t, n) {
  if (n || arguments.length === 2)
    for (var r = 0, i = t.length, o; r < i; r++)
      (o || !(r in t)) && (o || (o = Array.prototype.slice.call(t, 0, r)), o[r] = t[r]);
  return e.concat(o || Array.prototype.slice.call(t));
}
function w(e) {
  return this instanceof w ? (this.v = e, this) : new w(e);
}
function G(e, t, n) {
  if (!Symbol.asyncIterator)
    throw new TypeError("Symbol.asyncIterator is not defined.");
  var r = n.apply(e, t || []), i, o = [];
  return i = {}, a("next"), a("throw"), a("return"), i[Symbol.asyncIterator] = function() {
    return this;
  }, i;
  function a(l) {
    r[l] && (i[l] = function(p) {
      return new Promise(function(h, d) {
        o.push([l, p, h, d]) > 1 || u(l, p);
      });
    });
  }
  function u(l, p) {
    try {
      y(r[l](p));
    } catch (h) {
      s(o[0][3], h);
    }
  }
  function y(l) {
    l.value instanceof w ? Promise.resolve(l.value.v).then(f, c) : s(o[0][2], l);
  }
  function f(l) {
    u("next", l);
  }
  function c(l) {
    u("throw", l);
  }
  function s(l, p) {
    l(p), o.shift(), o.length && u(o[0][0], o[0][1]);
  }
}
function I(e) {
  var t, n;
  return t = {}, r("next"), r("throw", function(i) {
    throw i;
  }), r("return"), t[Symbol.iterator] = function() {
    return this;
  }, t;
  function r(i, o) {
    t[i] = e[i] ? function(a) {
      return (n = !n) ? { value: w(e[i](a)), done: !1 } : o ? o(a) : a;
    } : o;
  }
}
function V(e) {
  if (!Symbol.asyncIterator)
    throw new TypeError("Symbol.asyncIterator is not defined.");
  var t = e[Symbol.asyncIterator], n;
  return t ? t.call(e) : (e = typeof g == "function" ? g(e) : e[Symbol.iterator](), n = {}, r("next"), r("throw"), r("return"), n[Symbol.asyncIterator] = function() {
    return this;
  }, n);
  function r(o) {
    n[o] = e[o] && function(a) {
      return new Promise(function(u, y) {
        a = e[o](a), i(u, y, a.done, a.value);
      });
    };
  }
  function i(o, a, u, y) {
    Promise.resolve(y).then(function(f) {
      o({ value: f, done: u });
    }, a);
  }
}
function q(e, t) {
  return Object.defineProperty ? Object.defineProperty(e, "raw", { value: t }) : e.raw = t, e;
}
var B = Object.create ? function(e, t) {
  Object.defineProperty(e, "default", { enumerable: !0, value: t });
} : function(e, t) {
  e.default = t;
};
function K(e) {
  if (e && e.__esModule)
    return e;
  var t = {};
  if (e != null)
    for (var n in e)
      n !== "default" && Object.prototype.hasOwnProperty.call(e, n) && O(t, e, n);
  return B(t, e), t;
}
function N(e) {
  return e && e.__esModule ? e : { default: e };
}
function z(e, t, n, r) {
  if (n === "a" && !r)
    throw new TypeError("Private accessor was defined without a getter");
  if (typeof t == "function" ? e !== t || !r : !t.has(e))
    throw new TypeError("Cannot read private member from an object whose class did not declare it");
  return n === "m" ? r : n === "a" ? r.call(e) : r ? r.value : t.get(e);
}
function H(e, t, n, r, i) {
  if (r === "m")
    throw new TypeError("Private method is not writable");
  if (r === "a" && !i)
    throw new TypeError("Private accessor was defined without a setter");
  if (typeof t == "function" ? e !== t || !i : !t.has(e))
    throw new TypeError("Cannot write private member to an object whose class did not declare it");
  return r === "a" ? i.call(e, n) : i ? i.value = n : t.set(e, n), n;
}
function J(e, t) {
  if (t === null || typeof t != "object" && typeof t != "function")
    throw new TypeError("Cannot use 'in' operator on non-object");
  return typeof e == "function" ? t === e : e.has(t);
}
function L(e, t, n) {
  if (t != null) {
    if (typeof t != "object" && typeof t != "function")
      throw new TypeError("Object expected.");
    var r;
    if (n) {
      if (!Symbol.asyncDispose)
        throw new TypeError("Symbol.asyncDispose is not defined.");
      r = t[Symbol.asyncDispose];
    }
    if (r === void 0) {
      if (!Symbol.dispose)
        throw new TypeError("Symbol.dispose is not defined.");
      r = t[Symbol.dispose];
    }
    if (typeof r != "function")
      throw new TypeError("Object not disposable.");
    e.stack.push({ value: t, dispose: r, async: n });
  } else
    n && e.stack.push({ async: !0 });
  return t;
}
var Q = typeof SuppressedError == "function" ? SuppressedError : function(e, t, n) {
  var r = new Error(n);
  return r.name = "SuppressedError", r.error = e, r.suppressed = t, r;
};
function U(e) {
  function t(r) {
    e.error = e.hasError ? new Q(r, e.error, "An error was suppressed during disposal.") : r, e.hasError = !0;
  }
  function n() {
    for (; e.stack.length; ) {
      var r = e.stack.pop();
      try {
        var i = r.dispose && r.dispose.call(r.value);
        if (r.async)
          return Promise.resolve(i).then(n, function(o) {
            return t(o), n();
          });
      } catch (o) {
        t(o);
      }
    }
    if (e.hasError)
      throw e.error;
  }
  return n();
}
const $ = {
  __extends: S,
  __assign: m,
  __rest: E,
  __decorate: P,
  __param: T,
  __metadata: D,
  __awaiter: x,
  __generator: R,
  __createBinding: O,
  __exportStar: A,
  __values: g,
  __read: j,
  __spread: C,
  __spreadArrays: F,
  __spreadArray: M,
  __await: w,
  __asyncGenerator: G,
  __asyncDelegator: I,
  __asyncValues: V,
  __makeTemplateObject: q,
  __importStar: K,
  __importDefault: N,
  __classPrivateFieldGet: z,
  __classPrivateFieldSet: H,
  __classPrivateFieldIn: J,
  __addDisposableResource: L,
  __disposeResources: U
};
export {
  L as __addDisposableResource,
  m as __assign,
  I as __asyncDelegator,
  G as __asyncGenerator,
  V as __asyncValues,
  w as __await,
  x as __awaiter,
  z as __classPrivateFieldGet,
  J as __classPrivateFieldIn,
  H as __classPrivateFieldSet,
  O as __createBinding,
  P as __decorate,
  U as __disposeResources,
  W as __esDecorate,
  A as __exportStar,
  S as __extends,
  R as __generator,
  N as __importDefault,
  K as __importStar,
  q as __makeTemplateObject,
  D as __metadata,
  T as __param,
  Y as __propKey,
  j as __read,
  E as __rest,
  X as __runInitializers,
  Z as __setFunctionName,
  C as __spread,
  M as __spreadArray,
  F as __spreadArrays,
  g as __values,
  $ as default
};
