import { defineComponent, computed, openBlock, createBlock, withCtx, createElementVNode, normalizeStyle, normalizeClass, unref } from "@histoire/vendors/vue";
import { isDark } from "../../util/dark.js";
import { histoireConfig } from "../../util/config.js";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
import { getContrastColor } from "../../util/preview-settings.js";
import "./GenericRenderStory.vue.js";
import StoryResponsivePreview from "./StoryResponsivePreview.vue.js";
import _sfc_main$1 from "./GenericRenderStory.vue2.js";
"use strict";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantSinglePreviewNative",
  props: {
    story: {},
    variant: {}
  },
  setup(__props) {
    const props = __props;
    Object.assign(props.variant, {
      previewReady: false
    });
    function onReady() {
      Object.assign(props.variant, {
        previewReady: true
      });
    }
    const settings = usePreviewSettingsStore().currentSettings;
    const contrastColor = computed(() => getContrastColor(settings));
    const autoApplyContrastColor = computed(() => !!histoireConfig.autoApplyContrastColor);
    return (_ctx, _cache) => {
      return openBlock(), createBlock(StoryResponsivePreview, {
        class: "histoire-story-variant-single-preview-native",
        variant: _ctx.variant
      }, {
        default: withCtx(({ isResponsiveEnabled, finalWidth, finalHeight }) => [
          createElementVNode("div", {
            style: normalizeStyle([
              isResponsiveEnabled ? {
                width: finalWidth ? `${finalWidth}px` : "100%",
                height: finalHeight ? `${finalHeight}px` : "100%"
              } : { width: "100%", height: "100%" },
              {
                "--histoire-contrast-color": contrastColor.value,
                "color": autoApplyContrastColor.value ? contrastColor.value : void 0
              }
            ]),
            class: "htw-relative",
            "data-test-id": "sandbox-render"
          }, [
            (openBlock(), createBlock(_sfc_main$1, {
              key: `${_ctx.story.id}-${_ctx.variant.id}`,
              variant: _ctx.variant,
              story: _ctx.story,
              class: normalizeClass(["htw-h-full", {
                [unref(histoireConfig).sandboxDarkClass]: unref(isDark),
                // @TODO remove
                [unref(histoireConfig).theme.darkClass]: unref(isDark)
              }]),
              dir: unref(settings).textDirection,
              onReady
            }, null, 8, ["variant", "story", "class", "dir"]))
          ], 4)
        ]),
        _: 1
      }, 8, ["variant"]);
    };
  }
});
export {
  _sfc_main as default
};
