import { isRef as c, unref as p, watch as l } from "vue";
import { isRef as m, unref as w, watch as y } from "@histoire/vendors/vue";
import { applyState as f } from "@histoire/shared";
const i = (s) => s !== null && typeof s == "object";
function o(s, e = /* @__PURE__ */ new WeakMap()) {
  const t = c(s) ? p(s) : s;
  if (typeof t == "symbol")
    return t.toString();
  if (!i(t))
    return t;
  if (e.has(t))
    return e.get(t);
  if (Array.isArray(t)) {
    const r = [];
    return e.set(t, r), r.push(...t.map((n) => o(n, e))), r;
  } else {
    const r = {};
    return e.set(t, r), h(t, r, e), r;
  }
}
const h = (s, e, t = /* @__PURE__ */ new WeakMap()) => {
  Object.keys(s).forEach((r) => {
    e[r] = o(s[r], t);
  });
};
function a(s, e = /* @__PURE__ */ new WeakMap()) {
  const t = m(s) ? w(s) : s;
  if (typeof t == "symbol")
    return t.toString();
  if (!i(t))
    return t;
  if (e.has(t))
    return e.get(t);
  if (Array.isArray(t)) {
    const r = [];
    return e.set(t, r), r.push(...t.map((n) => a(n, e))), r;
  } else {
    const r = {};
    return e.set(t, r), d(t, r, e), r;
  }
}
const d = (s, e, t = /* @__PURE__ */ new WeakMap()) => {
  Object.keys(s).forEach((r) => {
    e[r] = o(s[r], t);
  });
};
function A(s, e) {
  let t = !1;
  const r = y(() => s, (u) => {
    u != null && (t ? t = !1 : (t = !0, f(e, a(u))));
  }, {
    deep: !0,
    immediate: !0
  }), n = l(() => e, (u) => {
    u != null && (t ? t = !1 : (t = !0, f(s, o(u))));
  }, {
    deep: !0,
    immediate: !0
  });
  return {
    stop() {
      r(), n();
    }
  };
}
export {
  a as _toRawDeep,
  A as syncStateBundledAndExternal,
  o as toRawDeep
};
