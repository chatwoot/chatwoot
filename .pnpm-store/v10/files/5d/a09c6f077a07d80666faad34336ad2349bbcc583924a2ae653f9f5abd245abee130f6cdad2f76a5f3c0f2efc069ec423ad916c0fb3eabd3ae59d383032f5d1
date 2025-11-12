import { defineComponent, useCssVars, computed, ref, watch, openBlock, createElementBlock, Fragment, createElementVNode, unref, createBlock, createCommentVNode, createVNode, withCtx, renderList, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { useStoryStore } from "../../stores/story.js";
import "../app/MobileOverlay.vue.js";
import StoryVariantListItem from "./StoryVariantListItem.vue.js";
import "./StoryVariantGrid.vue.js";
import StoryVariantSingle from "./StoryVariantSingle.vue.js";
import _sfc_main$1 from "./StoryVariantGrid.vue2.js";
import _sfc_main$2 from "../app/MobileOverlay.vue2.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-a5a2e343"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "histoire-story-viewer htw-bg-gray-50 htw-h-full dark:htw-bg-gray-750" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryViewer",
  setup(__props) {
    useCssVars((_ctx) => {
      var _a;
      return {
        "597bf4c4": (_a = variant.value) == null ? void 0 : _a.iconColor
      };
    });
    const storyStore = useStoryStore();
    const variant = computed(() => storyStore.currentVariant);
    const isMenuOpened = ref(false);
    function closeMenu() {
      isMenuOpened.value = false;
    }
    watch(variant, () => {
      isMenuOpened.value = false;
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock(Fragment, null, [
        createElementVNode("div", _hoisted_1, [
          unref(storyStore).currentStory.layout.type === "grid" ? (openBlock(), createBlock(_sfc_main$1, { key: 0 })) : unref(storyStore).currentStory.layout.type === "single" ? (openBlock(), createBlock(StoryVariantSingle, {
            key: 1,
            onOpenVariantMenu: _cache[0] || (_cache[0] = ($event) => isMenuOpened.value = true)
          })) : createCommentVNode("", true)
        ]),
        createVNode(_sfc_main$2, {
          title: "Select a variant",
          opened: isMenuOpened.value,
          onClose: closeMenu
        }, {
          default: withCtx(() => [
            (openBlock(true), createElementBlock(Fragment, null, renderList(unref(storyStore).currentStory.variants, (v, index) => {
              return openBlock(), createBlock(StoryVariantListItem, {
                key: index,
                variant: v
              }, null, 8, ["variant"]);
            }), 128))
          ]),
          _: 1
        }, 8, ["opened"])
      ], 64);
    };
  }
});
export {
  _sfc_main as default
};
