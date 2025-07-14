import { reactive as V, onMounted as x, h as S, Suspense as _, createApp as j } from "vue";
import { ref as T, onMounted as k, watch as q, onBeforeUnmount as F, h as O, defineComponent as B } from "@histoire/vendors/vue";
import { applyState as P } from "@histoire/shared";
import { getTagName as C } from "../codegen.js";
import { registerGlobalComponents as D } from "./global-components.js";
import { RouterLinkStub as M } from "./RouterLinkStub.js";
import * as h from "virtual:$histoire-setup";
import * as v from "virtual:$histoire-generated-global-setup";
import { syncStateBundledAndExternal as $ } from "./util.js";
const H = B({
  name: "RenderStory",
  props: {
    variant: {
      type: Object,
      required: !0
    },
    story: {
      type: Object,
      required: !0
    },
    slotName: {
      type: String,
      default: "default"
    }
  },
  emits: {
    ready: () => !0
  },
  setup(e, { emit: N }) {
    const b = T();
    let a, m = !1;
    const i = V({});
    $(e.variant.state, i);
    function g() {
      a && (a.unmount(), a = null);
    }
    async function w() {
      if (m)
        return;
      m = !0, g();
      let u;
      const p = [];
      a = j({
        name: "RenderStorySubApp",
        setup() {
          x(() => {
            m = !1;
          });
        },
        render: () => {
          var f, o, n, y;
          const r = ((o = (f = e.variant.slots()) == null ? void 0 : f[e.slotName]) == null ? void 0 : o.call(f, {
            state: i
          })) ?? ((y = (n = e.story.slots()) == null ? void 0 : n[e.slotName]) == null ? void 0 : y.call(n, {
            state: i
          }));
          if (e.slotName === "default" && !e.variant.autoPropsDisabled) {
            const c = A(r), l = JSON.stringify(c);
            (!u || u !== l) && (P(e.variant.state, {
              _hPropDefs: c
            }), e.variant.state._hPropState || P(e.variant.state, {
              _hPropState: {}
            }), u = l);
          }
          const t = [];
          t.push(r);
          for (const [c, l] of p.entries())
            t.push(
              S(l, {
                story: e.story,
                variant: e.variant
              }, () => t[c])
            );
          return t.push(S("div", t.at(-1))), t.push(S(_, {}, t.at(-1))), t.at(-1);
        }
      }), D(a), a.component("RouterLink", M);
      const s = {
        app: a,
        story: e.story,
        variant: e.variant,
        addWrapper: (r) => {
          p.push(r);
        }
      };
      if (typeof (v == null ? void 0 : v.setupVue3) == "function") {
        const r = v.setupVue3;
        await r(s);
      }
      if (typeof (h == null ? void 0 : h.setupVue3) == "function") {
        const r = h.setupVue3;
        await r(s);
      }
      if (typeof e.variant.setupApp == "function") {
        const r = e.variant.setupApp;
        await r(s);
      }
      p.reverse();
      const d = document.createElement("div");
      b.value.appendChild(d), a.mount(d), N("ready");
    }
    function A(u) {
      var d, r;
      const p = [];
      let s = 0;
      for (const t of u) {
        if (typeof t.type == "object") {
          const f = [];
          for (const o in t.type.props) {
            const n = t.type.props[o];
            let y, c;
            n && (y = (Array.isArray(n.type) ? n.type : typeof n == "function" ? [n] : [n.type]).map((R) => {
              switch (R) {
                case String:
                  return "string";
                case Number:
                  return "number";
                case Boolean:
                  return "boolean";
                case Object:
                  return "object";
                case Array:
                  return "array";
                default:
                  return "unknown";
              }
            }), c = typeof n.default == "function" ? n.default.toString() : n.default), f.push({
              name: o,
              types: y,
              required: n == null ? void 0 : n.required,
              default: c
            }), ((r = (d = i == null ? void 0 : i._hPropState) == null ? void 0 : d[s]) == null ? void 0 : r[o]) != null && (t.props || (t.props = {}), t.props[o] = i._hPropState[s][o], t.dynamicProps || (t.dynamicProps = []), t.dynamicProps.includes(o) || t.dynamicProps.push(o));
          }
          p.push({
            name: C(t),
            index: s,
            props: f
          }), s++;
        }
        Array.isArray(t.children) && p.push(...A(t.children));
      }
      return p.filter((t) => t.props.length);
    }
    return k(async () => {
      e.variant.configReady && await w();
    }), q(() => e.variant, async (u) => {
      u.configReady && !m && (a ? a._instance.proxy.$forceUpdate() : await w());
    }, {
      deep: !0
    }), F(() => {
      g();
    }), {
      sandbox: b
    };
  },
  render() {
    return O("div", {
      ref: "sandbox"
    });
  }
});
export {
  H as default
};
