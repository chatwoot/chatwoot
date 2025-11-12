import { defineComponent, watch, ref, unref, openBlock, createBlock, withCtx, createVNode, createElementBlock } from "@histoire/vendors/vue";
import { useRouter, useRoute } from "@histoire/vendors/vue-router";
import { Icon } from "@histoire/vendors/iconify";
import { useStoryStore } from "../../stores/story.js";
import BaseSplitPane from "../base/BaseSplitPane.vue.js";
import BaseEmpty from "../base/BaseEmpty.vue.js";
import { isMobile } from "../../util/responsive.js";
import "../panel/StorySidePanel.vue.js";
import "../panel/StoryDocs.vue.js";
import StoryViewer from "./StoryViewer.vue.js";
import _sfc_main$1 from "../panel/StoryDocs.vue2.js";
import _sfc_main$2 from "../panel/StorySidePanel.vue2.js";
"use strict";
const _hoisted_1 = {
  key: 1,
  class: "histoire-story-view histoire-with-story htw-h-full"
};
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryView",
  setup(__props) {
    const storyStore = useStoryStore();
    const router = useRouter();
    const route = useRoute();
    watch(() => storyStore.currentVariant, (value) => {
      if (value) {
        storyStore.currentStory.lastSelectedVariant = value;
      }
    }, {
      immediate: true
    });
    watch(() => [storyStore.currentStory, storyStore.currentVariant], () => {
      var _a, _b;
      if (!storyStore.currentVariant) {
        if ((_a = storyStore.currentStory) == null ? void 0 : _a.lastSelectedVariant) {
          setVariant(storyStore.currentStory.lastSelectedVariant.id);
          return;
        }
        if (((_b = storyStore.currentStory) == null ? void 0 : _b.variants.length) === 1) {
          setVariant(storyStore.currentStory.variants[0].id);
        }
      }
    }, {
      immediate: true
    });
    function setVariant(variantId) {
      router.replace({
        ...route,
        query: {
          ...route.query,
          variantId
        }
      });
    }
    const docsOnlyScroller = ref(null);
    function scrollDocsToTop() {
      var _a;
      (_a = docsOnlyScroller.value) == null ? void 0 : _a.scrollTo(0, 0);
    }
    return (_ctx, _cache) => {
      return !unref(storyStore).currentStory ? (openBlock(), createBlock(BaseEmpty, {
        key: 0,
        class: "histoire-story-view histoire-no-story"
      }, {
        default: withCtx(() => [
          createVNode(unref(Icon), {
            icon: "carbon:software-resource-resource",
            class: "htw-w-16 htw-h-16 htw-opacity-50"
          })
        ]),
        _: 1
      })) : (openBlock(), createElementBlock("div", _hoisted_1, [
        unref(storyStore).currentStory.docsOnly ? (openBlock(), createElementBlock("div", {
          key: 0,
          ref_key: "docsOnlyScroller",
          ref: docsOnlyScroller,
          class: "htw-h-full htw-overflow-auto"
        }, [
          createVNode(_sfc_main$1, {
            story: unref(storyStore).currentStory,
            standalone: "",
            class: "md:htw-p-12 htw-w-full md:htw-max-w-[600px] lg:htw-max-w-[800px] xl:htw-max-w-[900px]",
            onScrollTop: _cache[0] || (_cache[0] = ($event) => scrollDocsToTop())
          }, null, 8, ["story"])
        ], 512)) : unref(isMobile) ? (openBlock(), createBlock(StoryViewer, { key: 1 })) : (openBlock(), createBlock(BaseSplitPane, {
          key: 2,
          "save-id": "story-main",
          min: 30,
          max: 95,
          "default-split": 75,
          class: "htw-h-full"
        }, {
          first: withCtx(() => [
            createVNode(StoryViewer)
          ]),
          last: withCtx(() => [
            createVNode(_sfc_main$2)
          ]),
          _: 1
        }))
      ]));
    };
  }
});
export {
  _sfc_main as default
};
