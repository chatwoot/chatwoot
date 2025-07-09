import { defineComponent, computed, resolveDirective, withDirectives, openBlock, createElementBlock, createVNode, unref } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { getSandboxUrl } from "../../util/sandbox.js";
"use strict";
const _hoisted_1 = ["href"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ToolbarNewTab",
  props: {
    variant: {},
    story: {}
  },
  setup(__props) {
    const props = __props;
    const sandboxUrl = computed(() => {
      return getSandboxUrl(props.story, props.variant);
    });
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return withDirectives((openBlock(), createElementBlock("a", {
        href: sandboxUrl.value,
        target: "_blank",
        class: "histoire-toolbar-new-tab htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100"
      }, [
        createVNode(unref(Icon), {
          icon: "carbon:launch",
          class: "htw-w-4 htw-h-4"
        })
      ], 8, _hoisted_1)), [
        [_directive_tooltip, "Open variant in new tab"]
      ]);
    };
  }
});
export {
  _sfc_main as default
};
