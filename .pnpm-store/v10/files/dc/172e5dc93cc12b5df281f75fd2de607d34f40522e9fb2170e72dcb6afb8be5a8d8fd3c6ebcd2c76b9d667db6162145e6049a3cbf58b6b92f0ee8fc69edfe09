import { defineComponent, openBlock, createElementBlock, unref, createVNode, createBlock, createCommentVNode } from "@histoire/vendors/vue";
import { isMobile } from "../../util/responsive.js";
import "../toolbar/ToolbarTitle.vue.js";
import "../toolbar/ToolbarResponsiveSize.vue.js";
import ToolbarBackground from "../toolbar/ToolbarBackground.vue.js";
import "../toolbar/ToolbarTextDirection.vue.js";
import "../toolbar/ToolbarNewTab.vue.js";
import "../toolbar/DevOnlyToolbarOpenInEditor.vue.js";
import "./StoryVariantSinglePreviewNative.vue.js";
import "./StoryVariantSinglePreviewRemote.vue.js";
import _sfc_main$1 from "../toolbar/ToolbarTitle.vue2.js";
import _sfc_main$2 from "../toolbar/ToolbarResponsiveSize.vue2.js";
import _sfc_main$3 from "../toolbar/ToolbarTextDirection.vue2.js";
import _sfc_main$4 from "../toolbar/ToolbarNewTab.vue2.js";
import _sfc_main$5 from "../toolbar/DevOnlyToolbarOpenInEditor.vue2.js";
import _sfc_main$6 from "./StoryVariantSinglePreviewNative.vue2.js";
import _sfc_main$7 from "./StoryVariantSinglePreviewRemote.vue2.js";
"use strict";
const _hoisted_1 = {
  class: "histoire-story-variant-single-view htw-h-full htw-flex htw-flex-col",
  "data-test-id": "story-variant-single-view"
};
const _hoisted_2 = {
  key: 0,
  class: "htw-flex-none htw-flex htw-items-center htw-h-8 -htw-mt-1"
};
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantSingleView",
  props: {
    variant: {},
    story: {}
  },
  setup(__props) {
    return (_ctx, _cache) => {
      var _a, _b;
      return openBlock(), createElementBlock("div", _hoisted_1, [
        !unref(isMobile) ? (openBlock(), createElementBlock("div", _hoisted_2, [
          createVNode(_sfc_main$1, { variant: _ctx.variant }, null, 8, ["variant"]),
          !_ctx.variant.responsiveDisabled ? (openBlock(), createBlock(_sfc_main$2, { key: 0 })) : createCommentVNode("", true),
          createVNode(ToolbarBackground),
          createVNode(_sfc_main$3),
          createVNode(_sfc_main$4, {
            variant: _ctx.variant,
            story: _ctx.story
          }, null, 8, ["variant", "story"]),
          _ctx.__HISTOIRE_DEV__ ? (openBlock(), createBlock(_sfc_main$5, {
            key: 1,
            file: (_a = _ctx.story.file) == null ? void 0 : _a.filePath,
            tooltip: "Edit story in editor"
          }, null, 8, ["file"])) : createCommentVNode("", true)
        ])) : createCommentVNode("", true),
        ((_b = _ctx.story.layout) == null ? void 0 : _b.iframe) === false ? (openBlock(), createBlock(_sfc_main$6, {
          key: 1,
          story: _ctx.story,
          variant: _ctx.variant
        }, null, 8, ["story", "variant"])) : (openBlock(), createBlock(_sfc_main$7, {
          key: 2,
          story: _ctx.story,
          variant: _ctx.variant
        }, null, 8, ["story", "variant"]))
      ]);
    };
  }
});
export {
  _sfc_main as default
};
