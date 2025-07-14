import { useAttrs as n, inject as l, provide as i, onMounted as d, defineComponent as u } from "vue";
import { autoStubComponents as s } from "./stub.js";
const y = u({
  name: "HistoireStory",
  inheritAttrs: !1,
  props: {
    title: {
      type: String,
      default: void 0
    },
    id: {
      type: String,
      default: void 0
    },
    group: {
      type: String,
      default: void 0
    },
    layout: {
      type: Object,
      default: void 0
    },
    icon: {
      type: String,
      default: void 0
    },
    iconColor: {
      type: String,
      default: void 0
    },
    docsOnly: {
      type: Boolean,
      default: !1
    },
    meta: {
      type: Object,
      default: void 0
    }
  },
  setup(t) {
    const r = n(), e = {
      id: t.id ?? r.data.id,
      title: t.title ?? r.data.fileName,
      group: t.group,
      layout: t.layout,
      icon: t.icon,
      iconColor: t.iconColor,
      docsOnly: t.docsOnly,
      meta: t.meta,
      variants: []
    }, o = l("addStory", null);
    return o == null || o(e), i("story", e), i("addVariant", (a) => {
      e.variants.push(a);
    }), d(() => {
      e.variants.length || e.variants.push({
        id: "_default",
        title: "default"
      });
    }), {
      story: e
    };
  },
  render() {
    var r, e;
    let t = !1;
    try {
      const o = (e = (r = this.$slots).default) == null ? void 0 : e.call(r, {
        get state() {
          return t = !0, {};
        }
      });
      return Array.isArray(o) && s(o), o;
    } catch (o) {
      return t || console.error(o), null;
    }
  }
});
export {
  y as default
};
