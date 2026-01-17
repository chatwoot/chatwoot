import { defineComponent, computed, ref, watch, onMounted, openBlock, createElementBlock, unref, createVNode, createBlock, createCommentVNode, createElementVNode, normalizeStyle, Fragment, renderList } from "@histoire/vendors/vue";
import { useResizeObserver } from "@histoire/vendors/vue-use";
import { useStoryStore } from "../../stores/story.js";
import { isMobile } from "../../util/responsive.js";
import ToolbarBackground from "../toolbar/ToolbarBackground.vue.js";
import "../toolbar/ToolbarTextDirection.vue.js";
import "../toolbar/DevOnlyToolbarOpenInEditor.vue.js";
import StoryVariantGridItem from "./StoryVariantGridItem.vue.js";
import _sfc_main$1 from "../toolbar/ToolbarTextDirection.vue2.js";
import _sfc_main$2 from "../toolbar/DevOnlyToolbarOpenInEditor.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-story-variant-grid htw-flex htw-flex-col htw-items-stretch htw-h-full __histoire-pane-shadow-from-right" };
const _hoisted_2 = {
  key: 0,
  class: "htw-flex-none htw-flex htw-items-center htw-justify-end htw-h-8 htw-mx-2 htw-mt-1"
};
const _hoisted_3 = { class: "htw-flex htw-w-0 htw-flex-1 htw-mx-4" };
const margin = 16;
const gap = 16;
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantGrid",
  setup(__props) {
    const storyStore = useStoryStore();
    const gridTemplateWidth = computed(() => {
      if (storyStore.currentStory.layout.type !== "grid") {
        return;
      }
      const layoutWidth = storyStore.currentStory.layout.width;
      if (!layoutWidth) {
        return "200px";
      }
      if (typeof layoutWidth === "number") {
        return `${layoutWidth}px`;
      }
      return layoutWidth;
    });
    const itemWidth = ref(16);
    const maxItemHeight = ref(0);
    const maxCount = ref(10);
    const countPerRow = ref(0);
    const visibleRows = ref(0);
    const el = ref(null);
    useResizeObserver(el, () => {
      updateMaxCount();
      updateSize();
    });
    function updateMaxCount() {
      if (!maxItemHeight.value)
        return;
      const width = el.value.clientWidth - margin * 2;
      const height = el.value.clientHeight;
      const scrollTop = el.value.scrollTop;
      countPerRow.value = Math.floor((width + gap) / (itemWidth.value + gap));
      visibleRows.value = Math.ceil((height + scrollTop + gap) / (maxItemHeight.value + gap));
      const newMaxCount = countPerRow.value * visibleRows.value;
      if (maxCount.value < newMaxCount) {
        maxCount.value = newMaxCount;
      }
      if (storyStore.currentVariant) {
        const index = storyStore.currentStory.variants.indexOf(storyStore.currentVariant);
        if (index + 1 > maxCount.value) {
          maxCount.value = index + 1;
        }
      }
    }
    function onItemResize(w, h) {
      itemWidth.value = w;
      if (maxItemHeight.value < h) {
        maxItemHeight.value = h;
        updateMaxCount();
      }
    }
    watch(() => storyStore.currentVariant, () => {
      maxItemHeight.value = 0;
      updateMaxCount();
    });
    const gridEl = ref(null);
    const gridColumnWidth = ref(1);
    const viewWidth = ref(1);
    function updateSize() {
      if (!el.value)
        return;
      viewWidth.value = el.value.clientWidth;
      if (!gridEl.value)
        return;
      if (gridTemplateWidth.value.endsWith("%")) {
        gridColumnWidth.value = viewWidth.value * Number.parseInt(gridTemplateWidth.value) / 100 - gap;
      } else {
        gridColumnWidth.value = Number.parseInt(gridTemplateWidth.value);
      }
    }
    onMounted(() => {
      updateSize();
    });
    useResizeObserver(gridEl, () => {
      updateSize();
    });
    const columnCount = computed(() => Math.min(storyStore.currentStory.variants.length, Math.floor((viewWidth.value + gap) / (gridColumnWidth.value + gap))));
    return (_ctx, _cache) => {
      var _a;
      return openBlock(), createElementBlock("div", _hoisted_1, [
        !unref(isMobile) ? (openBlock(), createElementBlock("div", _hoisted_2, [
          createVNode(ToolbarBackground),
          createVNode(_sfc_main$1),
          _ctx.__HISTOIRE_DEV__ ? (openBlock(), createBlock(_sfc_main$2, {
            key: 0,
            file: (_a = unref(storyStore).currentStory.file) == null ? void 0 : _a.filePath,
            tooltip: "Edit story in editor"
          }, null, 8, ["file"])) : createCommentVNode("", true)
        ])) : createCommentVNode("", true),
        createElementVNode("div", {
          ref_key: "el",
          ref: el,
          class: "htw-overflow-y-auto htw-flex htw-flex-1",
          onScroll: _cache[0] || (_cache[0] = ($event) => updateMaxCount())
        }, [
          createElementVNode("div", _hoisted_3, [
            createElementVNode("div", {
              class: "htw-m-auto",
              style: normalizeStyle({
                minHeight: `${unref(storyStore).currentStory.variants.length / countPerRow.value * (maxItemHeight.value + gap) - gap}px`
              })
            }, [
              createElementVNode("div", {
                ref_key: "gridEl",
                ref: gridEl,
                class: "htw-grid htw-gap-4 htw-my-4",
                style: normalizeStyle({
                  gridTemplateColumns: `repeat(${columnCount.value}, ${gridColumnWidth.value}px)`
                })
              }, [
                (openBlock(true), createElementBlock(Fragment, null, renderList(unref(storyStore).currentStory.variants.slice(0, maxCount.value), (variant, index) => {
                  return openBlock(), createBlock(StoryVariantGridItem, {
                    key: index,
                    variant,
                    story: unref(storyStore).currentStory,
                    onResize: onItemResize
                  }, null, 8, ["variant", "story"]);
                }), 128))
              ], 4)
            ], 4)
          ])
        ], 544)
      ]);
    };
  }
});
export {
  _sfc_main as default
};
