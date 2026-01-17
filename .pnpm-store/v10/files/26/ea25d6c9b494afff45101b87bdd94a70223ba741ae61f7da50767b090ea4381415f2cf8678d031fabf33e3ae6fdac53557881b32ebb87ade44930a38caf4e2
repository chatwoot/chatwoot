import { defineComponent, useCssVars, computed, openBlock, createElementBlock, createVNode, unref, Fragment, createElementVNode, normalizeClass, createTextVNode, toDisplayString, createCommentVNode, createBlock, withCtx, renderList, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useStoryStore } from "../../stores/story.js";
import { isMobile } from "../../util/responsive.js";
import BaseSplitPane from "../base/BaseSplitPane.vue.js";
import StoryVariantListItem from "./StoryVariantListItem.vue.js";
import "./StoryVariantSingleView.vue.js";
import _sfc_main$1 from "./StoryVariantSingleView.vue2.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-abf83c04"), n = n(), popScopeId(), n);
const _hoisted_1 = {
  key: 0,
  class: "histoire-story-variant-single htw-p-2 htw-h-full __histoire-pane-shadow-from-right"
};
const _hoisted_2 = {
  key: 0,
  class: "htw-divide-y htw-divide-gray-100 dark:htw-divide-gray-800 htw-h-full htw-flex htw-flex-col"
};
const _hoisted_3 = {
  key: 0,
  class: "htw-p-2 htw-h-full"
};
const _hoisted_4 = { class: "htw-h-full htw-overflow-y-auto" };
const _hoisted_5 = {
  key: 0,
  class: "htw-p-2 htw-h-full __histoire-pane-shadow-from-right"
};
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantSingle",
  emits: {
    openVariantMenu: () => true
  },
  setup(__props) {
    useCssVars((_ctx) => {
      var _a;
      return {
        "02b8e3da": (_a = variant.value) == null ? void 0 : _a.iconColor
      };
    });
    const storyStore = useStoryStore();
    const hasSingleVariant = computed(() => {
      var _a;
      return ((_a = storyStore.currentStory) == null ? void 0 : _a.variants.length) === 1;
    });
    const variant = computed(() => storyStore.currentVariant);
    return (_ctx, _cache) => {
      return hasSingleVariant.value && variant.value ? (openBlock(), createElementBlock("div", _hoisted_1, [
        createVNode(_sfc_main$1, {
          variant: variant.value,
          story: unref(storyStore).currentStory
        }, null, 8, ["variant", "story"])
      ])) : (openBlock(), createElementBlock(Fragment, { key: 1 }, [
        unref(isMobile) ? (openBlock(), createElementBlock("div", _hoisted_2, [
          createElementVNode("a", {
            class: "htw-px-6 htw-h-12 hover:htw-text-primary-500 dark:hover:htw-text-primary-400 htw-cursor-pointer htw-flex htw-gap-2 htw-flex-wrap htw-w-full htw-items-center htw-flex-none",
            onClick: _cache[0] || (_cache[0] = ($event) => _ctx.$emit("openVariantMenu"))
          }, [
            variant.value ? (openBlock(), createElementBlock(Fragment, { key: 0 }, [
              createVNode(unref(Icon), {
                icon: variant.value.icon ?? "carbon:cube",
                class: normalizeClass(["htw-w-5 htw-h-5 htw-flex-none", {
                  "htw-text-gray-500": !variant.value.iconColor,
                  "bind-icon-color": variant.value.iconColor
                }])
              }, null, 8, ["icon", "class"]),
              createTextVNode(" " + toDisplayString(variant.value.title), 1)
            ], 64)) : (openBlock(), createElementBlock(Fragment, { key: 1 }, [
              createTextVNode(" Select a variant... ")
            ], 64)),
            createVNode(unref(Icon), {
              icon: "carbon:chevron-sort",
              class: "htw-w-5 htw-h-5 htw-shrink-0 htw-ml-auto"
            })
          ]),
          unref(storyStore).currentVariant ? (openBlock(), createElementBlock("div", _hoisted_3, [
            createVNode(_sfc_main$1, {
              variant: unref(storyStore).currentVariant,
              story: unref(storyStore).currentStory
            }, null, 8, ["variant", "story"])
          ])) : createCommentVNode("", true)
        ])) : (openBlock(), createBlock(BaseSplitPane, {
          key: 1,
          "save-id": "story-single-main-split",
          min: 5,
          max: 40,
          "default-split": 17
        }, {
          first: withCtx(() => [
            createElementVNode("div", _hoisted_4, [
              (openBlock(true), createElementBlock(Fragment, null, renderList(unref(storyStore).currentStory.variants, (v, index) => {
                return openBlock(), createBlock(StoryVariantListItem, {
                  key: index,
                  variant: v
                }, null, 8, ["variant"]);
              }), 128))
            ])
          ]),
          last: withCtx(() => [
            unref(storyStore).currentVariant ? (openBlock(), createElementBlock("div", _hoisted_5, [
              createVNode(_sfc_main$1, {
                variant: unref(storyStore).currentVariant,
                story: unref(storyStore).currentStory
              }, null, 8, ["variant", "story"])
            ])) : createCommentVNode("", true)
          ]),
          _: 1
        }))
      ], 64));
    };
  }
});
export {
  _sfc_main as default
};
