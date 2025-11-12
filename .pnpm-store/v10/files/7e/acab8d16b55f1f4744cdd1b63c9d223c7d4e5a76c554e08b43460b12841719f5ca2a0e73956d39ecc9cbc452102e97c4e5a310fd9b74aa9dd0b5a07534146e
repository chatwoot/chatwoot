import { defineComponent, resolveDirective, withDirectives, openBlock, createElementBlock, unref, createVNode } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { openInEditor } from "../../util/open-in-editor.js";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "DevOnlyToolbarOpenInEditor",
  props: {
    file: {},
    tooltip: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return withDirectives((openBlock(), createElementBlock("a", {
        target: "_blank",
        class: "histoire-toolbar-open-in-editor htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100",
        onClick: _cache[0] || (_cache[0] = ($event) => unref(openInEditor)(_ctx.file))
      }, [
        createVNode(unref(Icon), {
          icon: "carbon:script-reference",
          class: "htw-w-4 htw-h-4"
        })
      ])), [
        [_directive_tooltip, _ctx.tooltip]
      ]);
    };
  }
});
export {
  _sfc_main as default
};
