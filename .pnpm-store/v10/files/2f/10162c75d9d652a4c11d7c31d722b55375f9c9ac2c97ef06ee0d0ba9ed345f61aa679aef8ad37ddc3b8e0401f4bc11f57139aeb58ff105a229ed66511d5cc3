import { defineComponent, useCssVars, unref, toRefs, ref, computed, resolveComponent, resolveDirective, openBlock, createElementBlock, createElementVNode, withDirectives, createBlock, normalizeClass, withCtx, createVNode, toDisplayString, withModifiers, createCommentVNode, normalizeStyle, pushScopeId, popScopeId } from "@histoire/vendors/vue";
import { Icon } from "@histoire/vendors/iconify";
import { useRouter } from "@histoire/vendors/vue-router";
import { useResizeObserver } from "@histoire/vendors/vue-use";
import { HstCopyIcon } from "@histoire/controls";
import { useCurrentVariantRoute } from "../../util/variant.js";
import { useScrollOnActive } from "../../util/scroll.js";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
import { getContrastColor } from "../../util/preview-settings.js";
import { histoireConfig } from "../../util/config.js";
import { isDark } from "../../util/dark.js";
import { getSourceCode } from "../../util/docs.js";
import "../toolbar/ToolbarNewTab.vue.js";
import CheckerboardPattern from "../misc/CheckerboardPattern.vue.js";
import "./GenericRenderStory.vue.js";
import _sfc_main$1 from "../toolbar/ToolbarNewTab.vue2.js";
import _sfc_main$2 from "./GenericRenderStory.vue2.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-d3ab4dd6"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "htw-flex-none htw-flex htw-items-center" };
const _hoisted_2 = { class: "htw-truncate htw-flex-1" };
const _hoisted_3 = { class: "htw-flex-none htw-ml-auto htw-hidden group-hover:htw-flex htw-items-center" };
const _hoisted_4 = /* @__PURE__ */ _withScopeId(() => /* @__PURE__ */ createElementVNode("div", {
  class: "htw-absolute htw-inset-0 htw-rounded bind-preview-bg",
  "data-test-id": "responsive-preview-bg"
}, null, -1));
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantGridItem",
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
  emits: {
    resize: (_width, _height) => true
  },
  setup(__props, { emit: __emit }) {
    useCssVars((_ctx) => ({
      "bd0f30ce": unref(variant).iconColor,
      "8da98e9c": unref(settings).backgroundColor
    }));
    const props = __props;
    const emit = __emit;
    const { variant } = toRefs(props);
    const { isActive, targetRoute } = useCurrentVariantRoute(variant);
    Object.assign(props.variant, {
      previewReady: false
    });
    function onReady() {
      Object.assign(props.variant, {
        previewReady: true
      });
    }
    const router = useRouter();
    function selectVariant() {
      router.push(targetRoute.value);
    }
    const el = ref();
    const { autoScroll } = useScrollOnActive(isActive, el);
    useResizeObserver(el, () => {
      if (props.variant.previewReady) {
        emit("resize", el.value.clientWidth, el.value.clientHeight);
        if (isActive.value) {
          autoScroll();
        }
      }
    });
    const settings = usePreviewSettingsStore().currentSettings;
    const contrastColor = computed(() => getContrastColor(settings));
    const autoApplyContrastColor = computed(() => !!histoireConfig.autoApplyContrastColor);
    return (_ctx, _cache) => {
      const _component_RouterLink = resolveComponent("RouterLink");
      const _directive_tooltip = resolveDirective("tooltip");
      return openBlock(), createElementBlock("div", {
        ref_key: "el",
        ref: el,
        class: "histoire-story-variant-grid-item htw-cursor-default htw-flex htw-flex-col htw-gap-y-1 htw-group"
      }, [
        createElementVNode("div", _hoisted_1, [
          withDirectives((openBlock(), createBlock(_component_RouterLink, {
            to: unref(targetRoute),
            class: normalizeClass(["htw-rounded htw-w-max htw-px-2 htw-py-0.5 htw-min-w-16 htw-cursor-pointer htw-flex htw-items-center htw-gap-1 htw-flex-shrink", {
              "hover:htw-bg-gray-200 htw-text-gray-500 dark:hover:htw-bg-gray-800": !unref(isActive),
              "htw-bg-primary-200 hover:htw-bg-primary-300 htw-text-primary-800 dark:htw-bg-primary-700 dark:hover:htw-bg-primary-800 dark:htw-text-primary-200": unref(isActive)
            }])
          }, {
            default: withCtx(() => [
              createVNode(unref(Icon), {
                icon: unref(variant).icon ?? "carbon:cube",
                class: normalizeClass(["htw-w-4 htw-h-4 htw-opacity-50", {
                  "htw-text-gray-500": !unref(isActive) && !unref(variant).iconColor,
                  "bind-icon-color": !unref(isActive) && unref(variant).iconColor
                }])
              }, null, 8, ["icon", "class"]),
              createElementVNode("span", _hoisted_2, toDisplayString(unref(variant).title), 1)
            ]),
            _: 1
          }, 8, ["to", "class"])), [
            [_directive_tooltip, unref(variant).title]
          ]),
          createElementVNode("div", _hoisted_3, [
            createVNode(unref(HstCopyIcon), {
              content: () => unref(getSourceCode)(__props.story, unref(variant))
            }, null, 8, ["content"]),
            createVNode(_sfc_main$1, {
              variant: unref(variant),
              story: __props.story
            }, null, 8, ["variant", "story"])
          ])
        ]),
        createElementVNode("div", {
          class: normalizeClass(["htw-border htw-bg-white dark:htw-bg-gray-700 htw-rounded htw-flex-1 htw-p-4 htw-relative", {
            "htw-border-gray-100 dark:htw-border-gray-800": !unref(isActive),
            "htw-border-primary-200 dark:htw-border-primary-900": unref(isActive)
          }]),
          "data-test-id": "sandbox-render",
          onClick: _cache[0] || (_cache[0] = withModifiers(($event) => selectVariant(), ["stop"])),
          onKeyup: _cache[1] || (_cache[1] = ($event) => selectVariant())
        }, [
          _hoisted_4,
          unref(settings).checkerboard ? (openBlock(), createBlock(CheckerboardPattern, {
            key: 0,
            class: "htw-absolute htw-inset-0 htw-w-full htw-h-full htw-text-gray-500/20"
          })) : createCommentVNode("", true),
          createElementVNode("div", {
            class: "htw-relative htw-h-full",
            style: normalizeStyle({
              "--histoire-contrast-color": contrastColor.value,
              "color": autoApplyContrastColor.value ? contrastColor.value : void 0
            })
          }, [
            (openBlock(), createBlock(_sfc_main$2, {
              key: `${__props.story.id}-${unref(variant).id}`,
              variant: unref(variant),
              story: __props.story,
              dir: unref(settings).textDirection,
              class: normalizeClass({
                [unref(histoireConfig).theme.darkClass]: unref(isDark)
              }),
              onReady
            }, null, 8, ["variant", "story", "dir", "class"]))
          ], 4)
        ], 34)
      ], 512);
    };
  }
});
export {
  _sfc_main as default
};
