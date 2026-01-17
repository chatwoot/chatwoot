import { inject as i, defineComponent as o } from "vue";
const l = o({
  name: "HistoireVariant",
  props: {
    title: {
      type: String,
      default: "untitled"
    },
    id: {
      type: String,
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
    meta: {
      type: Object,
      default: void 0
    }
  },
  setup(t) {
    const e = i("story");
    function n() {
      return `${e.id}-${e.variants.length}`;
    }
    const a = {
      id: t.id ?? n(),
      title: t.title,
      icon: t.icon,
      iconColor: t.iconColor,
      meta: t.meta
    };
    i("addVariant")(a);
  },
  render() {
    return null;
  }
});
export {
  l as default
};
