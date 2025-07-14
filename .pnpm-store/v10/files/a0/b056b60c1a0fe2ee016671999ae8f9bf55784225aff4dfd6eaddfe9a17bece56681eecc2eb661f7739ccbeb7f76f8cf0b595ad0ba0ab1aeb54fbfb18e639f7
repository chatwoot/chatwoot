import { getCurrentInstance as u, useAttrs as l, computed as _, provide as S, reactive as $, h as x, cloneVNode as g, defineComponent as A } from "vue";
import { omitInheritStoryProps as C } from "@histoire/shared";
import I from "./Variant.js";
const k = A({
  // eslint-disable-next-line vue/multi-word-component-names
  name: "Story",
  __histoireType: "story",
  inheritAttrs: !1,
  props: {
    initState: {
      type: Function,
      default: void 0
    },
    meta: {
      type: Object,
      default: void 0
    }
  },
  setup(d) {
    const a = u(), f = l(), n = _(() => f.story);
    S("story", n);
    const e = a.parent, r = {
      $data: e.data
    };
    function c(i, t) {
      typeof t == "function" || t != null && t.__file || typeof (t == null ? void 0 : t.render) == "function" || typeof (t == null ? void 0 : t.setup) == "function" || (r[i] = t);
    }
    for (const i in e.exposed)
      c(i, e.exposed[i]);
    for (const i in e.devtoolsRawSetupState)
      c(i, e.devtoolsRawSetupState[i]);
    S("implicitState", () => $({ ...r }));
    function y() {
      Object.assign(f.story, {
        meta: d.meta,
        slots: () => a.proxy.$slots
      });
    }
    return {
      story: n,
      updateStory: y
    };
  },
  render() {
    this.updateStory();
    const [d] = this.story.variants;
    if (d.id === "_default")
      return x(I, {
        variant: d,
        initState: this.initState,
        ...this.$attrs
      }, this.$slots);
    let a = 0;
    const f = (e) => {
      var c, y, i, t, h, m;
      const r = [];
      for (const o of e)
        if (((c = o.type) == null ? void 0 : c.__histoireType) === "variant") {
          const p = {};
          if (p.variant = this.story.variants[a], !p.variant)
            continue;
          !((y = o.props) != null && y.initState) && !((i = o.props) != null && i["init-state"]) && (p.initState = this.initState);
          for (const s in this.$attrs)
            typeof ((t = o.props) == null ? void 0 : t[s]) > "u" && (p[s] = this.$attrs[s]);
          for (const s in this.story)
            !C.includes(s) && typeof ((h = o.props) == null ? void 0 : h[s]) > "u" && (p[s] = this.story[s]);
          a++, r.push(g(o, p));
        } else
          (m = o.children) != null && m.length && (o.children = f(o.children)), r.push(o);
      return r;
    };
    let n = this.$slots.default();
    return n = f(n), n;
  }
});
export {
  k as default
};
