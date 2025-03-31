/**!
 * FlexSearch.js v0.7.21 (Debug)
 * Copyright 2018-2021 Nextapps GmbH
 * Author: Thomas Wilkerling
 * Licence: Apache-2.0
 * https://github.com/nextapps-de/flexsearch
 */
(function(self){'use strict';
function r(a, b) {
  return "undefined" !== typeof a ? a : b;
}
function v(a) {
  const b = Array(a);
  for (let c = 0; c < a; c++) {
    b[c] = w();
  }
  return b;
}
function w() {
  return Object.create(null);
}
function aa(a, b) {
  return b.length - a.length;
}
function x(a) {
  return "string" === typeof a;
}
function z(a) {
  return "object" === typeof a;
}
function D(a) {
  return "function" === typeof a;
}
;function ba(a, b, c, d) {
  if (a && (b && (a = E(a, b)), this.matcher && (a = E(a, this.matcher)), this.stemmer && 1 < a.length && (a = E(a, this.stemmer)), d && 1 < a.length && (a = F(a)), c || "" === c)) {
    a = a.split(c);
    if (this.filter) {
      b = this.filter;
      c = a.length;
      d = [];
      for (let e = 0, f = 0; e < c; e++) {
        const g = a[e];
        g && !b[g] && (d[f++] = g);
      }
      a = d;
    }
    return a;
  }
  return a;
}
const ca = /[\p{Z}\p{S}\p{P}\p{C}]+/u, da = /[\u0300-\u036f]/g;
function ea(a, b) {
  const c = Object.keys(a), d = c.length, e = [];
  let f = "", g = 0;
  for (let h = 0, k, m; h < d; h++) {
    k = c[h], (m = a[k]) ? (e[g++] = G(b ? "(?!\\b)" + k + "(\\b|_)" : k), e[g++] = m) : f += (f ? "|" : "") + k;
  }
  f && (e[g++] = G(b ? "(?!\\b)(" + f + ")(\\b|_)" : "(" + f + ")"), e[g] = "");
  return e;
}
function E(a, b) {
  for (let c = 0, d = b.length; c < d && (a = a.replace(b[c], b[c + 1]), a); c += 2) {
  }
  return a;
}
function G(a) {
  return new RegExp(a, "g");
}
function F(a) {
  let b = "", c = "";
  for (let d = 0, e = a.length, f; d < e; d++) {
    (f = a[d]) !== c && (b += c = f);
  }
  return b;
}
;var ha = {encode:fa, rtl:!1, tokenize:""};
function fa(a) {
  return ba.call(this, ("" + a).toLowerCase(), !1, ca, !1);
}
;const ia = {}, I = {};
function ja(a) {
  J(a, "add");
  J(a, "append");
  J(a, "search");
  J(a, "update");
  J(a, "remove");
}
function J(a, b) {
  a[b + "Async"] = function() {
    const c = this, d = arguments;
    var e = d[d.length - 1];
    let f;
    D(e) && (f = e, delete d[d.length - 1]);
    e = new Promise(function(g) {
      setTimeout(function() {
        c.async = !0;
        const h = c[b].apply(c, d);
        c.async = !1;
        g(h);
      });
    });
    return f ? (e.then(f), this) : e;
  };
}
;function ka(a, b, c, d) {
  const e = a.length;
  let f = [], g, h, k = 0;
  d && (d = []);
  for (let m = e - 1; 0 <= m; m--) {
    const p = a[m], u = p.length, q = w();
    let n = !g;
    for (let l = 0; l < u; l++) {
      const t = p[l], y = t.length;
      if (y) {
        for (let C = 0, B, A; C < y; C++) {
          if (A = t[C], g) {
            if (g[A]) {
              if (!m) {
                if (c) {
                  c--;
                } else {
                  if (f[k++] = A, k === b) {
                    return f;
                  }
                }
              }
              if (m || d) {
                q[A] = 1;
              }
              n = !0;
            }
            if (d && (h[A] = (B = h[A]) ? ++B : B = 1, B < e)) {
              const H = d[B - 2] || (d[B - 2] = []);
              H[H.length] = A;
            }
          } else {
            q[A] = 1;
          }
        }
      }
    }
    if (d) {
      g || (h = q);
    } else {
      if (!n) {
        return [];
      }
    }
    g = q;
  }
  if (d) {
    for (let m = d.length - 1, p, u; 0 <= m; m--) {
      p = d[m];
      u = p.length;
      for (let q = 0, n; q < u; q++) {
        if (n = p[q], !g[n]) {
          if (c) {
            c--;
          } else {
            if (f[k++] = n, k === b) {
              return f;
            }
          }
          g[n] = 1;
        }
      }
    }
  }
  return f;
}
function la(a, b) {
  const c = w(), d = w(), e = [];
  for (let f = 0; f < a.length; f++) {
    c[a[f]] = 1;
  }
  for (let f = 0, g; f < b.length; f++) {
    g = b[f];
    for (let h = 0, k; h < g.length; h++) {
      k = g[h], c[k] && !d[k] && (d[k] = 1, e[e.length] = k);
    }
  }
  return e;
}
;function K(a) {
  this.limit = !0 !== a && a;
  this.cache = w();
  this.queue = [];
}
function ma(a, b, c) {
  z(a) && (a = a.query);
  let d = this.cache.get(a);
  d || (d = this.search(a, b, c), this.cache.set(a, d));
  return d;
}
K.prototype.set = function(a, b) {
  if (!this.cache[a]) {
    var c = this.queue.length;
    c === this.limit ? delete this.cache[this.queue[c - 1]] : c++;
    for (--c; 0 < c; c--) {
      this.queue[c] = this.queue[c - 1];
    }
    this.queue[0] = a;
  }
  this.cache[a] = b;
};
K.prototype.get = function(a) {
  const b = this.cache[a];
  if (this.limit && b && (a = this.queue.indexOf(a))) {
    const c = this.queue[a - 1];
    this.queue[a - 1] = this.queue[a];
    this.queue[a] = c;
  }
  return b;
};
K.prototype.del = function(a) {
  for (let b = 0, c, d; b < this.queue.length; b++) {
    d = this.queue[b], c = this.cache[d], -1 !== c.indexOf(a) && (this.queue.splice(b--, 1), delete this.cache[d]);
  }
};
const na = {memory:{charset:"latin:extra", resolution:3, minlength:4, fastupdate:!1}, performance:{resolution:3, minlength:3, optimize:!1, context:{depth:2, resolution:1}}, match:{charset:"latin:extra", tokenize:"reverse", }, score:{charset:"latin:advanced", resolution:20, minlength:3, context:{depth:3, resolution:9, }}, "default":{}, };
function pa(a, b, c, d, e, f) {
  setTimeout(function() {
    const g = a(c, JSON.stringify(f));
    g && g.then ? g.then(function() {
      b.export(a, b, c, d, e + 1);
    }) : b.export(a, b, c, d, e + 1);
  });
}
;function L(a, b) {
  if (!(this instanceof L)) {
    return new L(a);
  }
  var c;
  if (a) {
    if (x(a)) {
      na[a] || console.warn("Preset not found: " + a), a = na[a];
    } else {
      if (c = a.preset) {
        c[c] || console.warn("Preset not found: " + c), a = Object.assign({}, c[c], a);
      }
    }
    c = a.charset;
    var d = a.lang;
    x(c) && (-1 === c.indexOf(":") && (c += ":default"), c = I[c]);
    x(d) && (d = ia[d]);
  } else {
    a = {};
  }
  let e, f, g = a.context || {};
  this.encode = a.encode || c && c.encode || fa;
  this.register = b || w();
  this.resolution = e = a.resolution || 9;
  this.tokenize = b = c && c.tokenize || a.tokenize || "strict";
  this.depth = "strict" === b && g.depth;
  this.bidirectional = r(g.bidirectional, !0);
  this.optimize = f = r(a.optimize, !0);
  this.fastupdate = r(a.fastupdate, !0);
  this.minlength = a.minlength || 1;
  this.boost = a.boost;
  this.map = f ? v(e) : w();
  this.resolution_ctx = e = g.resolution || 1;
  this.ctx = f ? v(e) : w();
  this.rtl = c && c.rtl || a.rtl;
  this.matcher = (b = a.matcher || d && d.matcher) && ea(b, !1);
  this.stemmer = (b = a.stemmer || d && d.stemmer) && ea(b, !0);
  if (c = b = a.filter || d && d.filter) {
    c = b;
    d = w();
    for (let h = 0, k = c.length; h < k; h++) {
      d[c[h]] = 1;
    }
    c = d;
  }
  this.filter = c;
  this.cache = (b = a.cache) && new K(b);
}
L.prototype.append = function(a, b) {
  return this.add(a, b, !0);
};
L.prototype.add = function(a, b, c, d) {
  if (b && (a || 0 === a)) {
    if (!d && !c && this.register[a]) {
      return this.update(a, b);
    }
    b = this.encode(b);
    if (d = b.length) {
      const m = w(), p = w(), u = this.depth, q = this.resolution;
      for (let n = 0; n < d; n++) {
        let l = b[this.rtl ? d - 1 - n : n];
        var e = l.length;
        if (l && e >= this.minlength && (u || !p[l])) {
          var f = M(q, d, n), g = "";
          switch(this.tokenize) {
            case "full":
              if (3 < e) {
                for (f = 0; f < e; f++) {
                  for (var h = e; h > f; h--) {
                    if (h - f >= this.minlength) {
                      var k = M(q, d, n, e, f);
                      g = l.substring(f, h);
                      this.push_index(p, g, k, a, c);
                    }
                  }
                }
                break;
              }
            case "reverse":
              if (2 < e) {
                for (h = e - 1; 0 < h; h--) {
                  g = l[h] + g, g.length >= this.minlength && (k = M(q, d, n, e, h), this.push_index(p, g, k, a, c));
                }
                g = "";
              }
            case "forward":
              if (1 < e) {
                for (h = 0; h < e; h++) {
                  g += l[h], g.length >= this.minlength && this.push_index(p, g, f, a, c);
                }
                break;
              }
            default:
              if (this.boost && (f = Math.min(f / this.boost(b, l, n) | 0, q - 1)), this.push_index(p, l, f, a, c), u && 1 < d && n < d - 1) {
                for (e = w(), g = this.resolution_ctx, f = l, h = Math.min(u + 1, d - n), e[f] = 1, k = 1; k < h; k++) {
                  if ((l = b[this.rtl ? d - 1 - n - k : n + k]) && l.length >= this.minlength && !e[l]) {
                    e[l] = 1;
                    const t = M(g + (d / 2 > g ? 0 : 1), d, n, h - 1, k - 1), y = this.bidirectional && l > f;
                    this.push_index(m, y ? f : l, t, a, c, y ? l : f);
                  }
                }
              }
          }
        }
      }
      this.fastupdate || (this.register[a] = 1);
    }
  }
  return this;
};
function M(a, b, c, d, e) {
  return c && 1 < a ? b + (d || 0) <= a ? c + (e || 0) : (a - 1) / (b + (d || 0)) * (c + (e || 0)) + 1 | 0 : 0;
}
L.prototype.push_index = function(a, b, c, d, e, f) {
  let g = f ? this.ctx : this.map;
  if (!a[b] || f && !a[b][f]) {
    this.optimize && (g = g[c]), f ? (a = a[b] || (a[b] = w()), a[f] = 1, g = g[f] || (g[f] = w())) : a[b] = 1, g = g[b] || (g[b] = []), this.optimize || (g = g[c] || (g[c] = [])), e && -1 !== g.indexOf(d) || (g[g.length] = d, this.fastupdate && (a = this.register[d] || (this.register[d] = []), a[a.length] = g));
  }
};
L.prototype.search = function(a, b, c) {
  c || (!b && z(a) ? (c = a, a = c.query) : z(b) && (c = b));
  let d = [], e;
  let f, g = 0;
  if (c) {
    b = c.limit;
    g = c.offset || 0;
    var h = c.context;
    f = c.suggest;
  }
  if (a && (a = this.encode(a), e = a.length, 1 < e)) {
    c = w();
    var k = [];
    for (let p = 0, u = 0, q; p < e; p++) {
      if ((q = a[p]) && q.length >= this.minlength && !c[q]) {
        if (this.optimize || f || this.map[q]) {
          k[u++] = q, c[q] = 1;
        } else {
          return d;
        }
      }
    }
    a = k;
    e = a.length;
  }
  if (!e) {
    return d;
  }
  b || (b = 100);
  h = this.depth && 1 < e && !1 !== h;
  c = 0;
  let m;
  h ? (m = a[0], c = 1) : 1 < e && a.sort(aa);
  for (let p, u; c < e; c++) {
    u = a[c];
    h ? (p = this.add_result(d, f, b, g, 2 === e, u, m), f && !1 === p && d.length || (m = u)) : p = this.add_result(d, f, b, g, 1 === e, u);
    if (p) {
      return p;
    }
    if (f && c === e - 1) {
      k = d.length;
      if (!k) {
        if (h) {
          h = 0;
          c = -1;
          continue;
        }
        return d;
      }
      if (1 === k) {
        return qa(d[0], b, g);
      }
    }
  }
  return ka(d, b, g, f);
};
L.prototype.add_result = function(a, b, c, d, e, f, g) {
  let h = [], k = g ? this.ctx : this.map;
  this.optimize || (k = ra(k, f, g, this.bidirectional));
  if (k) {
    let m = 0;
    const p = Math.min(k.length, g ? this.resolution_ctx : this.resolution);
    for (let u = 0, q = 0, n, l; u < p; u++) {
      if (n = k[u]) {
        if (this.optimize && (n = ra(n, f, g, this.bidirectional)), d && n && e && (l = n.length, l <= d ? (d -= l, n = null) : (n = n.slice(d), d = 0)), n && (h[m++] = n, e && (q += n.length, q >= c))) {
          break;
        }
      }
    }
    if (m) {
      if (e) {
        return qa(h, c, 0);
      }
      a[a.length] = h;
      return;
    }
  }
  return !b && h;
};
function qa(a, b, c) {
  a = 1 === a.length ? a[0] : [].concat.apply([], a);
  return c || a.length > b ? a.slice(c, c + b) : a;
}
function ra(a, b, c, d) {
  c ? (d = d && b > c, a = (a = a[d ? b : c]) && a[d ? c : b]) : a = a[b];
  return a;
}
L.prototype.contain = function(a) {
  return !!this.register[a];
};
L.prototype.update = function(a, b) {
  return this.remove(a).add(a, b);
};
L.prototype.remove = function(a, b) {
  const c = this.register[a];
  if (c) {
    if (this.fastupdate) {
      for (let d = 0, e; d < c.length; d++) {
        e = c[d], e.splice(e.indexOf(a), 1);
      }
    } else {
      N(this.map, a, this.resolution, this.optimize), this.depth && N(this.ctx, a, this.resolution_ctx, this.optimize);
    }
    b || delete this.register[a];
    this.cache && this.cache.del(a);
  }
  return this;
};
function N(a, b, c, d, e) {
  let f = 0;
  if (a.constructor === Array) {
    if (e) {
      b = a.indexOf(b), -1 !== b ? 1 < a.length && (a.splice(b, 1), f++) : f++;
    } else {
      e = Math.min(a.length, c);
      for (let g = 0, h; g < e; g++) {
        if (h = a[g]) {
          f = N(h, b, c, d, e), d || f || delete a[g];
        }
      }
    }
  } else {
    for (let g in a) {
      (f = N(a[g], b, c, d, e)) || delete a[g];
    }
  }
  return f;
}
L.prototype.searchCache = ma;
L.prototype.export = function(a, b, c, d, e) {
  let f, g;
  switch(e || (e = 0)) {
    case 0:
      f = "reg";
      if (this.fastupdate) {
        g = w();
        for (let h in this.register) {
          g[h] = 1;
        }
      } else {
        g = this.register;
      }
      break;
    case 1:
      f = "cfg";
      g = {doc:0, opt:this.optimize ? 1 : 0};
      break;
    case 2:
      f = "map";
      g = this.map;
      break;
    case 3:
      f = "ctx";
      g = this.ctx;
      break;
    default:
      return;
  }
  pa(a, b || this, c ? c + "." + f : f, d, e, g);
  return !0;
};
L.prototype.import = function(a, b) {
  if (b) {
    switch(x(b) && (b = JSON.parse(b)), a) {
      case "cfg":
        this.optimize = !!b.opt;
        break;
      case "reg":
        this.fastupdate = !1;
        this.register = b;
        break;
      case "map":
        this.map = b;
        break;
      case "ctx":
        this.ctx = b;
    }
  }
};
ja(L.prototype);
function sa(a) {
  a = a.data;
  var b = self._index;
  const c = a.args;
  var d = a.task;
  switch(d) {
    case "init":
      d = a.options || {};
      a = a.factory;
      b = d.encode;
      d.cache = !1;
      b && 0 === b.indexOf("function") && (d.encode = Function("return " + b)());
      a ? (Function("return " + a)()(self), self._index = new self.FlexSearch.Index(d), delete self.FlexSearch) : self._index = new L(d);
      break;
    default:
      a = a.id, b = b[d].apply(b, c), postMessage("search" === d ? {id:a, msg:b} : {id:a});
  }
}
;let ta = 0;
function O(a) {
  if (!(this instanceof O)) {
    return new O(a);
  }
  var b;
  a ? D(b = a.encode) && (a.encode = b.toString()) : a = {};
  (b = (self || window)._factory) && (b = b.toString());
  const c = self.exports, d = this;
  this.worker = ua(b, c, a.worker);
  this.resolver = w();
  if (this.worker) {
    if (c) {
      this.worker.on("message", function(e) {
        d.resolver[e.id](e.msg);
        delete d.resolver[e.id];
      });
    } else {
      this.worker.onmessage = function(e) {
        e = e.data;
        d.resolver[e.id](e.msg);
        delete d.resolver[e.id];
      };
    }
    this.worker.postMessage({task:"init", factory:b, options:a});
  }
}
Q("add");
Q("append");
Q("search");
Q("update");
Q("remove");
function Q(a) {
  O.prototype[a] = O.prototype[a + "Async"] = function() {
    const b = this, c = [].slice.call(arguments);
    var d = c[c.length - 1];
    let e;
    D(d) && (e = d, c.splice(c.length - 1, 1));
    d = new Promise(function(f) {
      setTimeout(function() {
        b.resolver[++ta] = f;
        b.worker.postMessage({task:a, id:ta, args:c});
      });
    });
    return e ? (d.then(e), this) : d;
  };
}
function ua(a, b, c) {
  let d;
  try {
    d = b ? eval('new (require("worker_threads")["Worker"])("../dist/node/node.js")') : a ? new Worker(URL.createObjectURL(new Blob(["onmessage=" + sa.toString()], {type:"text/javascript"}))) : new Worker(x(c) ? c : "worker/worker.js", {type:"module"});
  } catch (e) {
  }
  return d;
}
;function R(a) {
  if (!(this instanceof R)) {
    return new R(a);
  }
  var b = a.document || a.doc || a, c;
  this.tree = [];
  this.field = [];
  this.marker = [];
  this.register = w();
  this.key = (c = b.key || b.id) && S(c, this.marker) || "id";
  this.fastupdate = r(a.fastupdate, !0);
  this.storetree = (c = b.store) && !0 !== c && [];
  this.store = c && w();
  this.tag = (c = b.tag) && S(c, this.marker);
  this.tagindex = c && w();
  this.cache = (c = a.cache) && new K(c);
  a.cache = !1;
  this.worker = a.worker;
  this.async = !1;
  c = w();
  let d = b.index || b.field || b;
  x(d) && (d = [d]);
  for (let e = 0, f, g; e < d.length; e++) {
    f = d[e], x(f) || (g = f, f = f.field), g = z(g) ? Object.assign({}, a, g) : a, this.worker && (c[f] = new O(g), c[f].worker || (this.worker = !1)), this.worker || (c[f] = new L(g, this.register)), this.tree[e] = S(f, this.marker), this.field[e] = f;
  }
  if (this.storetree) {
    for (a = b.store, x(a) && (a = [a]), b = 0; b < a.length; b++) {
      this.storetree[b] = S(a[b], this.marker);
    }
  }
  this.index = c;
}
function S(a, b) {
  const c = a.split(":");
  let d = 0;
  for (let e = 0; e < c.length; e++) {
    a = c[e], 0 <= a.indexOf("[]") && (a = a.substring(0, a.length - 2)) && (b[d] = !0), a && (c[d++] = a);
  }
  d < c.length && (c.length = d);
  return 1 < d ? c : c[0];
}
function T(a, b) {
  if (x(b)) {
    a = a[b];
  } else {
    for (let c = 0; a && c < b.length; c++) {
      a = a[b[c]];
    }
  }
  return a;
}
function U(a, b, c, d, e) {
  a = a[e];
  if (d === c.length - 1) {
    b[e] = a;
  } else {
    if (a) {
      if (a.constructor === Array) {
        for (b = b[e] = Array(a.length), e = 0; e < a.length; e++) {
          U(a, b, c, d, e);
        }
      } else {
        b = b[e] || (b[e] = w()), e = c[++d], U(a, b, c, d, e);
      }
    }
  }
}
function V(a, b, c, d, e, f, g, h) {
  if (a = a[g]) {
    if (d === b.length - 1) {
      if (a.constructor === Array) {
        if (c[d]) {
          for (b = 0; b < a.length; b++) {
            e.add(f, a[b], !0, !0);
          }
          return;
        }
        a = a.join(" ");
      }
      e.add(f, a, h, !0);
    } else {
      if (a.constructor === Array) {
        for (g = 0; g < a.length; g++) {
          V(a, b, c, d, e, f, g, h);
        }
      } else {
        g = b[++d], V(a, b, c, d, e, f, g, h);
      }
    }
  }
}
R.prototype.add = function(a, b, c) {
  z(a) && (b = a, a = T(b, this.key));
  if (b && (a || 0 === a)) {
    if (!c && this.register[a]) {
      return this.update(a, b);
    }
    for (let d = 0, e, f; d < this.field.length; d++) {
      f = this.field[d], e = this.tree[d], x(e) && (e = [e]), V(b, e, this.marker, 0, this.index[f], a, e[0], c);
    }
    if (this.tag) {
      let d = T(b, this.tag), e = w();
      x(d) && (d = [d]);
      for (let f = 0, g, h; f < d.length; f++) {
        if (g = d[f], !e[g] && (e[g] = 1, h = this.tagindex[g] || (this.tagindex[g] = []), !c || -1 === h.indexOf(a))) {
          if (h[h.length] = a, this.fastupdate) {
            const k = this.register[a] || (this.register[a] = []);
            k[k.length] = h;
          }
        }
      }
    }
    if (this.store && (!c || !this.store[a])) {
      let d;
      if (this.storetree) {
        d = w();
        for (let e = 0, f; e < this.storetree.length; e++) {
          f = this.storetree[e], x(f) ? d[f] = b[f] : U(b, d, f, 0, f[0]);
        }
      }
      this.store[a] = d || b;
    }
  }
  return this;
};
R.prototype.append = function(a, b) {
  return this.add(a, b, !0);
};
R.prototype.update = function(a, b) {
  return this.remove(a).add(a, b);
};
R.prototype.remove = function(a) {
  z(a) && (a = T(a, this.key));
  if (this.register[a]) {
    for (var b = 0; b < this.field.length && (this.index[this.field[b]].remove(a, !this.worker), !this.fastupdate); b++) {
    }
    if (this.tag && !this.fastupdate) {
      for (let c in this.tagindex) {
        b = this.tagindex[c];
        const d = b.indexOf(a);
        -1 !== d && (1 < b.length ? b.splice(d, 1) : delete this.tagindex[c]);
      }
    }
    this.store && delete this.store[a];
    delete this.register[a];
  }
  return this;
};
R.prototype.search = function(a, b, c, d) {
  c || (!b && z(a) ? (c = a, a = c.query) : z(b) && (c = b, b = 0));
  let e = [], f = [], g, h, k, m, p, u, q = 0;
  if (c) {
    if (c.constructor === Array) {
      k = c, c = null;
    } else {
      k = (g = c.pluck) || c.index || c.field;
      m = c.tag;
      h = this.store && c.enrich;
      p = "and" === c.bool;
      b = c.limit || 100;
      u = c.offset || 0;
      if (m && (x(m) && (m = [m]), !a)) {
        for (let l = 0, t; l < m.length; l++) {
          if (t = va.call(this, m[l], b, u, h)) {
            e[e.length] = t, q++;
          }
        }
        return q ? e : [];
      }
      x(k) && (k = [k]);
    }
  }
  k || (k = this.field);
  p = p && (1 < k.length || m && 1 < m.length);
  const n = !d && (this.worker || this.async) && [];
  for (let l = 0, t, y, C; l < k.length; l++) {
    let B;
    y = k[l];
    x(y) || (B = y, y = y.field);
    if (n) {
      n[l] = this.index[y].searchAsync(a, b, B || c);
    } else {
      C = (t = d ? d[l] : this.index[y].search(a, b, B || c)) && t.length;
      if (m && C) {
        const A = [];
        let H = 0;
        p && (A[0] = [t]);
        for (let W = 0, oa, P; W < m.length; W++) {
          if (oa = m[W], C = (P = this.tagindex[oa]) && P.length) {
            H++, A[A.length] = p ? [P] : P;
          }
        }
        H && (t = p ? ka(A, b || 100, u || 0) : la(t, A), C = t.length);
      }
      if (C) {
        f[q] = y, e[q++] = t;
      } else {
        if (p) {
          return [];
        }
      }
    }
  }
  if (n) {
    const l = this;
    return new Promise(function(t) {
      Promise.all(n).then(function(y) {
        t(l.search(a, b, c, y));
      });
    });
  }
  if (!q) {
    return [];
  }
  if (g && (!h || !this.store)) {
    return e[0];
  }
  for (let l = 0, t; l < f.length; l++) {
    t = e[l];
    t.length && h && (t = wa.call(this, t));
    if (g) {
      return t;
    }
    e[l] = {field:f[l], result:t};
  }
  return e;
};
function va(a, b, c, d) {
  let e = this.tagindex[a], f = e && e.length - c;
  if (f && 0 < f) {
    if (f > b || c) {
      e = e.slice(c, c + b);
    }
    d && (e = wa.call(this, e));
    return {tag:a, result:e};
  }
}
function wa(a) {
  const b = Array(a.length);
  for (let c = 0, d; c < a.length; c++) {
    d = a[c], b[c] = {id:d, doc:this.store[d]};
  }
  return b;
}
R.prototype.contain = function(a) {
  return !!this.register[a];
};
R.prototype.get = function(a) {
  return this.store[a];
};
R.prototype.set = function(a, b) {
  this.store[a] = b;
  return this;
};
R.prototype.searchCache = ma;
R.prototype.export = function(a, b, c, d, e) {
  e || (e = 0);
  d || (d = 0);
  if (d < this.field.length) {
    const f = this.field[d], g = this.index[f];
    b = this;
    setTimeout(function() {
      g.export(a, b, e ? f.replace(":", "-") : "", d, e++) || (d++, e = 1, b.export(a, b, f, d, e));
    });
  } else {
    let f;
    switch(e) {
      case 1:
        c = "tag";
        f = this.tagindex;
        break;
      case 2:
        c = "store";
        f = this.store;
        break;
      default:
        return;
    }
    pa(a, this, c, d, e, f);
  }
};
R.prototype.import = function(a, b) {
  if (b) {
    switch(x(b) && (b = JSON.parse(b)), a) {
      case "tag":
        this.tagindex = b;
        break;
      case "reg":
        this.fastupdate = !1;
        this.register = b;
        for (let d = 0, e; d < this.field.length; d++) {
          e = this.index[this.field[d]], e.register = b, e.fastupdate = !1;
        }
        break;
      case "store":
        this.store = b;
        break;
      default:
        a = a.split(".");
        const c = a[0];
        a = a[1];
        c && a && this.index[c].import(a, b);
    }
  }
};
ja(R.prototype);
var ya = {encode:xa, rtl:!1, tokenize:""};
const za = G("[\u00e0\u00e1\u00e2\u00e3\u00e4\u00e5]"), Aa = G("[\u00e8\u00e9\u00ea\u00eb]"), Ba = G("[\u00ec\u00ed\u00ee\u00ef]"), Ca = G("[\u00f2\u00f3\u00f4\u00f5\u00f6\u0151]"), Da = G("[\u00f9\u00fa\u00fb\u00fc\u0171]"), Ea = G("[\u00fd\u0177\u00ff]"), Fa = G("\u00f1"), Ga = G("[\u00e7c]"), Ha = G("\u00df"), Ia = G(" & "), Ja = [za, "a", Aa, "e", Ba, "i", Ca, "o", Da, "u", Ea, "y", Fa, "n", Ga, "k", Ha, "s", Ia, " and "];
function xa(a) {
  var b = a = "" + a;
  b.normalize && (b = b.normalize("NFD").replace(da, ""));
  return ba.call(this, b.toLowerCase(), !a.normalize && Ja, ca, !1);
}
;var La = {encode:Ka, rtl:!1, tokenize:"strict"};
const Ma = /[^a-z0-9]+/, Na = {b:"p", v:"f", w:"f", z:"s", x:"s", "\u00df":"s", d:"t", n:"m", c:"k", g:"k", j:"k", q:"k", i:"e", y:"e", u:"o"};
function Ka(a) {
  a = xa.call(this, a).join(" ");
  const b = [];
  if (a) {
    const c = a.split(Ma), d = c.length;
    for (let e = 0, f, g = 0; e < d; e++) {
      if ((a = c[e]) && (!this.filter || !this.filter[a])) {
        f = a[0];
        let h = Na[f] || f, k = h;
        for (let m = 1; m < a.length; m++) {
          f = a[m];
          const p = Na[f] || f;
          p && p !== k && (h += p, k = p);
        }
        b[g++] = h;
      }
    }
  }
  return b;
}
;var Pa = {encode:Oa, rtl:!1, tokenize:""};
const Qa = G("ae"), Ra = G("oe"), Sa = G("sh"), Ta = G("th"), Ua = G("ph"), Va = G("pf"), Wa = [Qa, "a", Ra, "o", Sa, "s", Ta, "t", Ua, "f", Va, "f", G("(?![aeo])h(?![aeo])"), "", G("(?!^[aeo])h(?!^[aeo])"), ""];
function Oa(a, b) {
  a && (a = Ka.call(this, a).join(" "), 2 < a.length && (a = E(a, Wa)), b || (1 < a.length && (a = F(a)), a && (a = a.split(" "))));
  return a;
}
;var Ya = {encode:Xa, rtl:!1, tokenize:""};
const Za = G("(?!\\b)[aeo]");
function Xa(a) {
  a && (a = Oa.call(this, a, !0), 1 < a.length && (a = a.replace(Za, "")), 1 < a.length && (a = F(a)), a && (a = a.split(" ")));
  return a;
}
;I["latin:default"] = ha;
I["latin:simple"] = ya;
I["latin:balance"] = La;
I["latin:advanced"] = Pa;
I["latin:extra"] = Ya;
const X = self;
let Y;
const Z = {Index:L, Document:R, Worker:O, registerCharset:function(a, b) {
  I[a] = b;
}, registerLanguage:function(a, b) {
  ia[a] = b;
}};
(Y = X.define) && Y.amd ? Y([], function() {
  return Z;
}) : X.exports ? X.exports = Z : X.FlexSearch = Z;
}(this));
