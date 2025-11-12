import { defineComponent, computed, openBlock, createElementBlock, createElementVNode, createVNode } from "@histoire/vendors/vue";
import { histoireConfig, customLogos } from "../util/config.js";
import HistoireLogo from "../assets/histoire.svg.js";
import { useStoryStore } from "../stores/story.js";
import "./app/HomeCounter.vue.js";
import _sfc_main$1 from "./app/HomeCounter.vue2.js";
"use strict";
const _hoisted_1 = { class: "histoire-home-view htw-flex md:htw-flex-col htw-gap-12 htw-items-center htw-justify-center htw-h-full" };
const _hoisted_2 = ["src"];
const _hoisted_3 = { class: "htw-flex !md:htw-flex-col htw-flex-wrap htw-justify-evenly htw-gap-2 htw-px-4 htw-py-2 htw-bg-gray-100 dark:htw-bg-gray-750 htw-rounded htw-border htw-border-gray-500/30" };
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "HomeView",
  setup(__props) {
    const logoUrl = computed(() => {
      var _a, _b;
      return ((_b = (_a = histoireConfig.theme) == null ? void 0 : _a.logo) == null ? void 0 : _b.square) ? customLogos.square : HistoireLogo;
    });
    const storyStore = useStoryStore();
    const stats = computed(() => {
      let storyCount = 0;
      let variantCount = 0;
      let docsCount = 0;
      (storyStore.stories || []).forEach((story) => {
        if (story.docsOnly) {
          docsCount++;
        } else {
          storyCount++;
          if (story.variants) {
            variantCount += story.variants.length;
          }
        }
      });
      return {
        storyCount,
        variantCount,
        docsCount
      };
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        createElementVNode("img", {
          src: logoUrl.value,
          alt: "Logo",
          class: "htw-w-64 htw-h-64 htw-opacity-25 htw-mb-8 htw-hidden md:htw-block"
        }, null, 8, _hoisted_2),
        createElementVNode("div", _hoisted_3, [
          createVNode(_sfc_main$1, {
            title: "Stories",
            icon: "carbon:cube",
            count: stats.value.storyCount
          }, null, 8, ["count"]),
          createVNode(_sfc_main$1, {
            title: "Variants",
            icon: "carbon:cube-view",
            count: stats.value.variantCount
          }, null, 8, ["count"]),
          createVNode(_sfc_main$1, {
            title: "Documents",
            icon: "carbon:document-blank",
            count: stats.value.docsCount
          }, null, 8, ["count"])
        ])
      ]);
    };
  }
});
export {
  _sfc_main as default
};
