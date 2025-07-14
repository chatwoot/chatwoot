import { useAttrs as o, getCurrentInstance as r, inject as u, defineComponent as p } from "vue";
import { applyState as l } from "@histoire/shared";
import { toRawDeep as d, syncStateBundledAndExternal as c } from "./util.js";
const v = p({
  // eslint-disable-next-line vue/multi-word-component-names
  name: "Variant",
  __histoireType: "variant",
  props: {
    initState: {
      type: Function,
      default: void 0
    },
    source: {
      type: String,
      default: void 0
    },
    responsiveDisabled: {
      type: Boolean,
      default: !1
    },
    autoPropsDisabled: {
      type: Boolean,
      default: !1
    },
    setupApp: {
      type: Function,
      default: void 0
    },
    meta: {
      type: Object,
      default: void 0
    }
  },
  async setup(t) {
    const e = o(), i = r(), n = u("implicitState");
    if (typeof t.initState == "function") {
      const s = await t.initState();
      l(e.variant.state, d(s));
    }
    c(e.variant.state, n());
    function a() {
      Object.assign(e.variant, {
        slots: () => i.proxy.$slots,
        source: t.source,
        responsiveDisabled: t.responsiveDisabled,
        autoPropsDisabled: t.autoPropsDisabled,
        setupApp: t.setupApp,
        meta: t.meta,
        configReady: !0
      });
    }
    return a(), {
      updateVariant: a
    };
  },
  render() {
    return this.updateVariant(), null;
  }
});
export {
  v as default
};
