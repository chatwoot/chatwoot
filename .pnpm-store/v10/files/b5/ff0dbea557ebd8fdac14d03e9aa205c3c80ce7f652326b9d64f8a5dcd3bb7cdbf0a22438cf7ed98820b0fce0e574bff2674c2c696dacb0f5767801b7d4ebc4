import { defineComponent, ref, watch, computed, openBlock, createElementBlock, createElementVNode, createBlock, createCommentVNode, createVNode, withCtx, unref, Fragment, renderList } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import "../story/GenericRenderStory.vue.js";
import BaseEmpty from "../base/BaseEmpty.vue.js";
import "./StatePresets.vue.js";
import "./ControlsComponentProps.vue.js";
import "./ControlsComponentState.vue.js";
import _sfc_main$1 from "./StatePresets.vue2.js";
import _sfc_main$2 from "../story/GenericRenderStory.vue2.js";
import _sfc_main$3 from "./ControlsComponentState.vue2.js";
import _sfc_main$4 from "./ControlsComponentProps.vue2.js";
"use strict";
const _hoisted_1 = {
  "data-test-id": "story-controls",
  class: "histoire-story-controls htw-flex htw-flex-col htw-divide-y htw-divide-gray-100 dark:htw-divide-gray-750"
};
const _hoisted_2 = { class: "htw-h-9 htw-flex-none htw-px-2 htw-flex htw-items-center" };
const _hoisted_3 = { key: 1 };
const _hoisted_4 = /* @__PURE__ */ createElementVNode("span", null, "No controls available for this story", -1);
const _hoisted_5 = { key: 3 };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryControls",
  props: {
    variant: {
      type: Object,
      required: true
    },
    story: {
      type: Object,
      required: true
    }
  },
  setup(__props) {
    const props = __props;
    const ready = ref(false);
    watch(() => props.variant, () => {
      ready.value = false;
    });
    const hasCustomControls = computed(() => props.variant.slots().controls || props.story.slots().controls);
    const hasInitState = computed(() => Object.entries(props.variant.state || {}).filter(([key]) => !key.startsWith("_h")).length > 0);
    return (_ctx, _cache) => {
      var _a, _b, _c, _d;
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("div", _hoisted_2, [
          ready.value || !hasCustomControls.value ? (openBlock(), createBlock(_sfc_main$1, {
            key: 0,
            story: __props.story,
            variant: __props.variant
          }, null, 8, ["story", "variant"])) : createCommentVNode("", true)
        ]),
        hasCustomControls.value ? (openBlock(), createBlock(_sfc_main$2, {
          key: `${__props.story.id}-${__props.variant.id}`,
          "slot-name": "controls",
          variant: __props.variant,
          story: __props.story,
          class: "__histoire-render-custom-controls htw-flex-none",
          onReady: _cache[0] || (_cache[0] = ($event) => ready.value = true)
        }, null, 8, ["variant", "story"])) : hasInitState.value ? (openBlock(), createElementBlock("div", _hoisted_3, [
          createVNode(_sfc_main$3, {
            class: "htw-flex-none htw-my-2",
            variant: __props.variant
          }, null, 8, ["variant"])
        ])) : !((_b = (_a = __props.variant.state) == null ? void 0 : _a._hPropDefs) == null ? void 0 : _b.length) ? (openBlock(), createBlock(BaseEmpty, { key: 2 }, {
          default: withCtx(() => [
            createVNode(unref(Icon), {
              icon: "carbon:audio-console",
              class: "htw-w-8 htw-h-8 htw-opacity-50 htw-mb-6"
            }),
            _hoisted_4
          ]),
          _: 1
        })) : createCommentVNode("", true),
        ((_d = (_c = __props.variant.state) == null ? void 0 : _c._hPropDefs) == null ? void 0 : _d.length) ? (openBlock(), createElementBlock("div", _hoisted_5, [
          (openBlock(true), createElementBlock(Fragment, null, renderList(__props.variant.state._hPropDefs, (def, index) => {
            return openBlock(), createBlock(_sfc_main$4, {
              key: index,
              variant: __props.variant,
              definition: def,
              class: "htw-flex-none htw-my-2"
            }, null, 8, ["variant", "definition"]);
          }), 128))
        ])) : createCommentVNode("", true)
      ]);
    };
  }
});
export {
  _sfc_main as default
};
