import { defineAsyncComponent, openBlock, createElementVNode, unref, createVNode, createElementBlock, createCommentVNode, defineComponent } from "@histoire/vendors/vue";
import { useCommandStore } from "../../stores/command.js";
"use strict";
const _hoisted_1 = {
  key: 0,
  class: "histoire-command-prompts-modal htw-fixed htw-inset-0 htw-bg-white/80 dark:htw-bg-gray-900/80 htw-z-20"
};
const _hoisted_2 = { class: "htw-bg-white dark:htw-bg-gray-900 md:htw-mt-16 md:htw-mx-auto htw-w-screen htw-max-w-[512px] htw-max-h-[80vh] htw-overflow-y-auto htw-scroll-smooth htw-shadow-xl htw-border htw-border-gray-200 dark:htw-border-gray-750 htw-rounded-lg htw-relative htw-divide-y htw-divide-gray-200 dark:htw-divide-gray-850" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "CommandPromptsModal",
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
    const CommandPrompts = defineAsyncComponent(() => import("./CommandPrompts.vue.js"));
    const emit = __emit;
    function close() {
      emit("close");
    }
    const commandStore = useCommandStore();
    return (_ctx, _cache) => {
      return __props.shown ? (openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", {
          class: "htw-absolute htw-inset-0",
          onClick: _cache[0] || (_cache[0] = ($event) => close())
        }),
        createElementVNode("div", _hoisted_2, [
          createVNode(unref(CommandPrompts), {
            command: unref(commandStore).selectedCommand,
            onClose: _cache[1] || (_cache[1] = ($event) => close())
          }, null, 8, ["command"])
        ])
      ])) : createCommentVNode("", true);
    };
  }
});
export {
  _sfc_main as default
};
