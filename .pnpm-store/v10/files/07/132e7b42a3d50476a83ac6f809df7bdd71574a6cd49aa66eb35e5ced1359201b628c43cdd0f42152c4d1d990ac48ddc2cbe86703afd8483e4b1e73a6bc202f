import { defineComponent, computed, unref, openBlock, createBlock, withCtx, createElementVNode, createVNode, resolveDynamicComponent } from "@histoire/vendors/vue";
import { useRoute } from "@histoire/vendors/vue-router";
import { useStoryStore } from "../../stores/story.js";
import BaseSplitPane from "../base/BaseSplitPane.vue.js";
import BaseEmpty from "../base/BaseEmpty.vue.js";
import "./StoryControls.vue.js";
import "./StoryDocs.vue.js";
import "./StoryEvents.vue.js";
import StorySourceCode from "./StorySourceCode.vue.js";
import "./PaneTabs.vue.js";
import _sfc_main$1 from "./StoryControls.vue2.js";
import _sfc_main$2 from "./StoryEvents.vue2.js";
import _sfc_main$3 from "./StoryDocs.vue2.js";
import _sfc_main$4 from "./PaneTabs.vue2.js";
"use strict";
const _hoisted_1 = /* @__PURE__ */ createElementVNode("span", null, "Select a variant", -1);
const _hoisted_2 = /* @__PURE__ */ createElementVNode("span", null, "Loading...", -1);
const _hoisted_3 = { class: "htw-flex htw-flex-col htw-h-full" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StorySidePanel",
  setup(__props) {
    const storyStore = useStoryStore();
    const route = useRoute();
    const panelContentComponent = computed(() => {
      switch (route.query.tab) {
        case "docs":
          return _sfc_main$3;
        case "events":
          return _sfc_main$2;
        default:
          return _sfc_main$1;
      }
    });
    return (_ctx, _cache) => {
      return !unref(storyStore).currentVariant ? (openBlock(), createBlock(BaseEmpty, {
        key: 0,
        class: "histoire-story-side-panel histoire-selection"
      }, {
        default: withCtx(() => [
          _hoisted_1
        ]),
        _: 1
      })) : !unref(storyStore).currentVariant.configReady || !unref(storyStore).currentVariant.previewReady ? (openBlock(), createBlock(BaseEmpty, {
        key: 1,
        class: "histoire-story-side-panel histoire-loading"
      }, {
        default: withCtx(() => [
          _hoisted_2
        ]),
        _: 1
      })) : (openBlock(), createBlock(BaseSplitPane, {
        key: 2,
        "save-id": "story-sidepane",
        orientation: "portrait",
        class: "histoire-story-side-panel histoire-loaded htw-h-full",
        "data-test-id": "story-side-panel"
      }, {
        first: withCtx(() => [
          createElementVNode("div", _hoisted_3, [
            createVNode(_sfc_main$4, {
              story: unref(storyStore).currentStory,
              variant: unref(storyStore).currentVariant
            }, null, 8, ["story", "variant"]),
            (openBlock(), createBlock(resolveDynamicComponent(panelContentComponent.value), {
              story: unref(storyStore).currentStory,
              variant: unref(storyStore).currentVariant,
              class: "htw-h-full htw-overflow-auto"
            }, null, 8, ["story", "variant"]))
          ])
        ]),
        last: withCtx(() => [
          createVNode(StorySourceCode, {
            story: unref(storyStore).currentStory,
            variant: unref(storyStore).currentVariant,
            class: "htw-h-full"
          }, null, 8, ["story", "variant"])
        ]),
        _: 1
      }));
    };
  }
});
export {
  _sfc_main as default
};
