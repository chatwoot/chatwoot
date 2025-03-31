import { defineAsyncComponent, openBlock, createElementVNode, unref, createVNode, createElementBlock, vShow, withDirectives, defineComponent } from "@histoire/vendors/vue";
import "./SearchLoading.vue.js";
import _sfc_main$1 from "./SearchLoading.vue2.js";
"use strict";
const _hoisted_1 = {
  class: "histoire-search-modal htw-fixed htw-inset-0 htw-bg-white/80 dark:htw-bg-gray-900/80 htw-z-20",
  "data-test-id": "search-modal"
};
const _hoisted_2 = { class: "htw-bg-white dark:htw-bg-gray-900 md:htw-mt-16 md:htw-mx-auto htw-w-screen htw-max-w-[512px] htw-shadow-xl htw-border htw-border-gray-200 dark:htw-border-gray-750 htw-rounded-lg htw-relative htw-divide-y htw-divide-gray-200 dark:htw-divide-gray-850" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "SearchModal",
  props: {
    shown: {
      type: Boolean,
      default: false
    }
  },
  emits: {
    close: () => true
  },
  setup(__props, { emit: __emit }) {
    const SearchPane = defineAsyncComponent({
      loader: () => import("./SearchPane.vue.js"),
      loadingComponent: _sfc_main$1,
      delay: 0
    });
    const emit = __emit;
    function close() {
      emit("close");
    }
    return (_ctx, _cache) => {
      return withDirectives((openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", {
          class: "htw-absolute htw-inset-0",
          onClick: _cache[0] || (_cache[0] = ($event) => close())
        }),
        createElementVNode("div", _hoisted_2, [
          createVNode(unref(SearchPane), {
            shown: __props.shown,
            onClose: _cache[1] || (_cache[1] = ($event) => close())
          }, null, 8, ["shown"])
        ])
      ], 512)), [
        [vShow, __props.shown]
      ]);
    };
  }
});
export {
  _sfc_main as default
};
