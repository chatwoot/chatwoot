import { defineComponent, resolveDirective, withDirectives, openBlock, createElementBlock, unref, createVNode } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "ToolbarTextDirection",
  setup(__props) {
    const settings = usePreviewSettingsStore().currentSettings;
    return (_ctx, _cache) => {
      const _directive_tooltip = resolveDirective("tooltip");
      return withDirectives((openBlock(), createElementBlock("a", {
        class: "histoire-toolbar-text-direction htw-flex htw-items-center htw-gap-1 htw-h-full htw-px-2 hover:htw-text-primary-500 htw-opacity-50 hover:htw-opacity-100 dark:hover:htw-text-primary-400 htw-text-gray-900 dark:htw-text-gray-100",
        onClick: _cache[0] || (_cache[0] = ($event) => unref(settings).textDirection = unref(settings).textDirection === "ltr" ? "rtl" : "ltr")
      }, [
        createVNode(unref(Icon), {
          icon: unref(settings).textDirection === "ltr" ? "fluent:text-paragraph-direction-right-16-regular" : "fluent:text-paragraph-direction-left-16-regular",
          class: "htw-w-4 htw-h-4"
        }, null, 8, ["icon"])
      ])), [
        [_directive_tooltip, `Switch to text direction ${unref(settings).textDirection === "ltr" ? "Right to Left" : "Left to Right"}`]
      ]);
    };
  }
});
export {
  _sfc_main as default
};
