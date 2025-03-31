import { Text as z, vModelText as D, vModelSelect as F, vModelRadio as E, vModelCheckbox as J, vModelDynamic as O } from "vue";
import "../node_modules/.pnpm/change-case@4.1.2/node_modules/change-case/dist.es2015/index.js";
import { createAutoBuildingObject as G, indent as C, voidElements as q, serializeJs as H } from "@histoire/shared";
import { camelCase as N } from "../node_modules/.pnpm/camel-case@4.1.2/node_modules/camel-case/dist.es2015/index.js";
import { pascalCase as I } from "../node_modules/.pnpm/pascal-case@3.1.2/node_modules/pascal-case/dist.es2015/index.js";
async function te(e) {
  var _, d, y, x;
  const o = ((d = (_ = e.slots()).default) == null ? void 0 : d.call(_, { state: e.state ?? {} })) ?? [], c = Array.isArray(o) ? o : [o], m = [];
  for (const a in c) {
    const A = c[a];
    m.push(...(await k(A, (x = (y = e.state) == null ? void 0 : y._hPropState) == null ? void 0 : x[a])).lines);
  }
  return m.join(`
`);
}
async function k(e, o = null) {
  var d;
  if (e.type === z)
    return {
      // @ts-ignore
      lines: [e.children],
      isText: !0
    };
  const c = [];
  if (typeof e.type == "object" || typeof e.type == "string") {
    let y = function(t, s, i = null) {
      let r = "";
      for (const T in s.modifiers)
        s.modifiers[T] && (r += `.${T}`);
      let u = "";
      s.arg && (u = `:${s.arg}`), i && (i = i.replace(/^\$(setup|props|data)\./g, ""));
      const l = i ? [i] : U(s.value), f = [], L = `v-${t}${u}${r}="`;
      l.length > 1 ? (f.push(`${L}${l[0]}`), f.push(...l.slice(1, l.length - 1)), f.push(`${l[l.length - 1]}"`), A = !0) : f.push(`${L}${l[0] ?? ""}"`), a.push(f);
    }, x = function(t, s) {
      var i, r, u, l;
      if (typeof s != "string" || (i = e.dynamicProps) != null && i.includes(t)) {
        let f = ":";
        t.startsWith("on") && (f = "@");
        const L = f === "@" ? `${t[2].toLowerCase()}${t.slice(3)}` : t, M = [`onUpdate:${t}`, `onUpdate:${N(t)}`].find((p) => {
          var $;
          return (($ = e.dynamicProps) == null ? void 0 : $.includes(p)) || e.props && p in e.props;
        });
        if (f === ":" && M) {
          j.push(M);
          const $ = e.props[M].toString();
          let V;
          const B = /\(\$event\) => (.*?) = \$event/.exec($);
          B && (V = B[1]);
          const K = `${t === "modelValue" ? "model" : t}Modifiers`, W = e.props[K] ?? {};
          j.push(K), y("model", {
            arg: t === "modelValue" ? null : t,
            modifiers: W,
            value: s
          }, V);
          return;
        }
        if (typeof s > "u")
          return;
        let h;
        if (typeof s == "string" && s.startsWith("{{") && s.endsWith("}}"))
          h = S(s.substring(2, s.length - 2).trim()).split(`
`);
        else if (typeof s == "function") {
          let p = S(s.toString().replace(/'/g, "\\'").replace(/"/g, "'"));
          const $ = /function ([^\s]+)\(/.exec(p);
          $ ? h = [$[1]] : (p.startsWith("($event) => ") && (p = p.substring(12)), h = p.split(`
`));
        } else
          h = U(s);
        if (h.length > 1) {
          A = !0;
          const p = [`${f}${L}="${h[0]}`];
          p.push(...h.slice(1, h.length - 1)), p.push(`${h[h.length - 1]}"`), a.push(p);
        } else
          a.push([`${f}${L}="${h[0]}"`]);
      } else
        ((l = (u = (r = e.type) == null ? void 0 : r.props) == null ? void 0 : u[t]) == null ? void 0 : l.type) === Boolean ? a.push([t]) : a.push([`${t}="${s}"`]);
    };
    var m = y, _ = x;
    (d = e.type) != null && d.__asyncLoader && !e.type.__asyncResolved && await e.type.__asyncLoader();
    const a = [];
    let A = !1;
    const j = [
      "key"
    ];
    if (e.dirs) {
      for (const t of e.dirs)
        if (t.dir === D || t.dir === F || t.dir === E || t.dir === J || t.dir === O) {
          const i = [`onUpdate:${t.arg ?? "modelValue"}`, `onUpdate:${N(t.arg ?? "modelValue")}`].find((l) => e.props[l]), r = e.props[i];
          let u = null;
          if (r) {
            j.push(i);
            const l = r.toString(), f = /\(\$event\) => (.*?) = \$event/.exec(l);
            f && (u = f[1]);
          }
          y("model", t, u);
        } else if (t.instance._ || t.instance.$) {
          const s = t.instance.$ ?? t.instance._;
          let i;
          for (const r of [s.directives, s.appContext.directives]) {
            for (const u in r)
              if (r[u] === t.dir) {
                i = u;
                break;
              }
            if (i)
              break;
          }
          i && y(i, t);
        }
    }
    for (const t in e.props) {
      if (j.includes(t) || o && t in o)
        continue;
      const s = e.props[t];
      x(t, s);
    }
    if (o)
      for (const t in o)
        x(t, o[t]);
    a.length > 1 && (A = !0);
    const b = Q(e);
    let w = !1;
    const n = [];
    if (typeof e.children == "string")
      b === "pre" ? n.push(e.children) : n.push(...e.children.split(`
`)), w = !0;
    else if (Array.isArray(e.children)) {
      let t;
      for (const s of e.children) {
        const i = await k(s);
        if (i.isText) {
          t === void 0 && (t = !0);
          const r = i.lines[0];
          !n.length || /^\s/.test(r) ? n.push(r.trim()) : n[n.length - 1] += r;
        } else
          t === void 0 && (t = !1), n.push(...i.lines);
      }
      t !== void 0 && (w = t);
    }
    if (e.children && typeof e.children == "object" && !Array.isArray(e.children)) {
      for (const t in e.children)
        if (typeof e.children[t] == "function") {
          const s = G((l) => `{{ ${l} }}`, (l, f) => {
            if (f === "__v_isRef")
              return () => !1;
          }), i = e.children[t](s.proxy), r = [];
          for (const l of i)
            r.push(...(await k(l)).lines);
          const u = Object.keys(s.cache);
          u.length ? (n.push(`<template #${t}="{ ${u.join(", ")} }">`), n.push(...C(r)), n.push("</template>")) : t === "default" ? n.push(...r) : (n.push(`<template #${t}>`), n.push(...C(r)), n.push("</template>"));
        }
    }
    const g = [`<${b}`];
    if (A) {
      for (const t of a)
        g.push(...C(t));
      n.length > 0 && g.push(">");
    } else
      a.length === 1 && (g[0] += ` ${a[0]}`), n.length > 0 && (g[0] += ">");
    const R = q.includes(b.toLowerCase());
    n.length > 0 ? n.length === 1 && g.length === 1 && !a.length && w ? c.push(`${g[0]}${n[0]}</${b}>`) : (c.push(...g), c.push(...C(n)), c.push(`</${b}>`)) : g.length > 1 ? (c.push(...g), c.push(R ? ">" : "/>")) : c.push(`${g[0]}${R ? "" : " /"}>`);
  } else if ((e == null ? void 0 : e.shapeFlag) & 16)
    for (const y of e.children)
      c.push(...(await k(y)).lines);
  return {
    lines: c
  };
}
function Q(e) {
  var o, c, m, _;
  if (typeof e.type == "string")
    return e.type;
  if ((o = e.type) != null && o.__asyncResolved) {
    const d = (c = e.type) == null ? void 0 : c.__asyncResolved;
    return d.name ?? P(d.__file);
  } else {
    if ((m = e.type) != null && m.name)
      return e.type.name;
    if ((_ = e.type) != null && _.__file)
      return P(e.type.__file);
  }
  return "Anonymous";
}
function P(e) {
  const o = /([^/]+)\.vue$/.exec(e);
  return o ? I(o[1]) : "Anonymous";
}
function U(e) {
  const o = !!(e != null && e.__autoBuildingObject), c = H(e);
  return o ? [S(c.__autoBuildingObjectGetKey)] : S(c).split(`
`);
}
function S(e) {
  return e.replace(/\$setup\./g, "");
}
export {
  te as generateSourceCode,
  Q as getTagName
};
