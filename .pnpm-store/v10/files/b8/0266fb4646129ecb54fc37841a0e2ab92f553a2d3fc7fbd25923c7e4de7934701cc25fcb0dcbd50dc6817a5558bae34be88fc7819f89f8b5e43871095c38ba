import { defineComponent, computed, openBlock, createBlock, resolveDynamicComponent, normalizeClass, withCtx, renderSlot } from "@histoire/vendors/vue";
import { RouterLink } from "@histoire/vendors/vue-router";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseButton",
  props: {
    to: {},
    href: {},
    color: {}
  },
  setup(__props) {
    const props = __props;
    const comp = computed(() => {
      if (props.to) {
        return RouterLink;
      }
      if (props.href) {
        return "a";
      }
      return "button";
    });
    return (_ctx, _cache) => {
      return openBlock(), createBlock(resolveDynamicComponent(comp.value), {
        class: normalizeClass(["histoire-base-button htw-rounded htw-cursor-pointer", {
          "htw-bg-primary-200 dark:htw-bg-primary-800 hover:htw-bg-primary-300 dark:hover:htw-bg-primary-700": _ctx.color === "primary" || !_ctx.color,
          "htw-bg-grey-100 dark:htw-bg-grey-900 hover:htw-bg-grey-200 dark:hover:htw-bg-grey-800": _ctx.color === "grey"
        }])
      }, {
        default: withCtx(() => [
          renderSlot(_ctx.$slots, "default")
        ]),
        _: 3
      }, 8, ["class"]);
    };
  }
});
export {
  _sfc_main as default
};
