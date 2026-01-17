import { defineComponent, computed, resolveComponent, openBlock, createBlock, withCtx, createElementVNode, normalizeClass, toDisplayString, createElementBlock, createCommentVNode } from "@histoire/vendors/vue";
"use strict";
const _hoisted_1 = {
  key: 0,
  class: "htw-text-xs htw-opacity-50 htw-truncate"
};
const _hoisted_2 = { class: "htw-overflow-auto htw-max-w-[400px] htw-max-h-[400px]" };
const _hoisted_3 = { class: "htw-p-4" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryEvent",
  props: {
    event: {}
  },
  setup(__props) {
    const props = __props;
    const formattedArgument = computed(() => {
      switch (typeof props.event.argument) {
        case "string":
          return `"${props.event.argument}"`;
        case "object":
          return `{ ${Object.keys(props.event.argument).map((key) => `${key}: ${props.event.argument[key]}`).join(", ")} }`;
        default:
          return props.event.argument;
      }
    });
    return (_ctx, _cache) => {
      const _component_VDropdown = resolveComponent("VDropdown");
      return openBlock(), createBlock(_component_VDropdown, {
        class: "histoire-story-event htw-group",
        placement: "right",
        "data-test-id": "event-item"
      }, {
        default: withCtx(({ shown }) => [
          createElementVNode("div", {
            class: normalizeClass(["group-hover:htw-bg-primary-100 dark:group-hover:htw-bg-primary-700 htw-cursor-pointer htw-py-2 htw-px-4 htw-flex htw-items-baseline htw-gap-1 htw-leading-normal", [
              shown ? "htw-bg-primary-50 dark:htw-bg-primary-600" : "group-odd:htw-bg-gray-100/50 dark:group-odd:htw-bg-gray-750/40"
            ]])
          }, [
            createElementVNode("span", {
              class: normalizeClass({
                "htw-text-primary-500": shown
              })
            }, toDisplayString(_ctx.event.name), 3),
            _ctx.event.argument ? (openBlock(), createElementBlock("span", _hoisted_1, toDisplayString(formattedArgument.value), 1)) : createCommentVNode("", true)
          ], 2)
        ]),
        popper: withCtx(() => [
          createElementVNode("div", _hoisted_2, [
            createElementVNode("pre", _hoisted_3, toDisplayString(_ctx.event.argument), 1)
          ])
        ]),
        _: 1
      });
    };
  }
});
export {
  _sfc_main as default
};
