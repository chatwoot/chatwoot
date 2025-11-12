import { defineComponent, computed, openBlock, createElementBlock, createBlock, unref, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-2114f510"), n = n(), popScopeId(), n);
const _hoisted_1 = ["src", "alt"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseIcon",
  props: {
    icon: {}
  },
  setup(__props) {
    const props = __props;
    const isUrl = computed(() => props.icon.startsWith("http") || props.icon.startsWith("data:image") || props.icon.startsWith(".") || props.icon.startsWith("/"));
    return (_ctx, _cache) => {
      return isUrl.value ? (openBlock(), createElementBlock("img", {
        key: 0,
        src: _ctx.icon,
        alt: _ctx.icon,
        class: "histoire-base-icon"
      }, null, 8, _hoisted_1)) : (openBlock(), createBlock(unref(Icon), {
        key: 1,
        icon: _ctx.icon,
        class: "histoire-base-icon"
      }, null, 8, ["icon"]));
    };
  }
});
export {
  _sfc_main as default
};
