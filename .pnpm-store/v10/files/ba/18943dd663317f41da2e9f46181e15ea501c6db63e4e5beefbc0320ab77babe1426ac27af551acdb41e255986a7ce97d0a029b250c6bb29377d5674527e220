import { defineComponent, useCssVars, unref, ref, onUnmounted, computed, openBlock, createElementBlock, createVNode, createCommentVNode, createElementVNode, normalizeClass, createBlock, renderSlot, Fragment, withDirectives, pushScopeId, popScopeId, createStaticVNode } from "@histoire/vendors/vue";
import { useEventListener } from "@histoire/vendors/vue-use";
import { Icon } from "@histoire/vendors/iconify";
import { VTooltip } from "@histoire/vendors/floating-vue";
import HatchedPattern from "../misc/HatchedPattern.vue.js";
import CheckerboardPattern from "../misc/CheckerboardPattern.vue.js";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-9bc3d486"), n = n(), popScopeId(), n);
const _hoisted_1 = { class: "histoire-story-responsive-preview htw-w-full htw-h-full htw-flex-1 htw-rounded-lg htw-relative htw-overflow-hidden" };
const _hoisted_2 = {
  key: 0,
  class: "htw-absolute htw-inset-0 htw-w-full htw-h-full htw-bg-gray-100 dark:htw-bg-gray-750 htw-rounded-r-lg htw-border-l-2 htw-border-gray-500/10 dark:htw-border-gray-700/30 htw-overflow-hidden"
};
const _hoisted_3 = {
  class: "bind-preview-bg htw-rounded-lg htw-h-full",
  "data-test-id": "responsive-preview-bg"
};
const _hoisted_4 = { class: "htw-p-8 htw-h-full htw-relative" };
const _hoisted_5 = { class: "htw-w-full htw-h-full htw-relative" };
const _hoisted_6 = /* @__PURE__ */ _withScopeId(() => /* @__PURE__ */ createElementVNode("div", { class: "htw-absolute htw-inset-0" }, null, -1));
const _hoisted_7 = /* @__PURE__ */ createStaticVNode('<div class="htw-absolute htw-top-5 htw-left-8 htw-h-2 htw-w-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-top-5 htw-right-8 htw-h-2 htw-w-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-bottom-5 htw-left-8 htw-h-2 htw-w-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-bottom-5 htw-right-8 htw-h-2 htw-w-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-left-5 htw-top-8 htw-w-2 htw-h-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-left-5 htw-bottom-8 htw-w-2 htw-h-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-right-5 htw-top-8 htw-w-2 htw-h-px htw-bg-gray-400/25" data-v-9bc3d486></div><div class="htw-absolute htw-right-5 htw-bottom-8 htw-w-2 htw-h-px htw-bg-gray-400/25" data-v-9bc3d486></div>', 8);
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryResponsivePreview",
  props: {
    variant: {}
  },
  setup(__props) {
    useCssVars((_ctx) => ({
      "321f9a07": unref(settings).backgroundColor
    }));
    const props = __props;
    const settings = usePreviewSettingsStore().currentSettings;
    const resizing = ref(false);
    const onUnmountedCleanupFns = [];
    onUnmounted(() => {
      onUnmountedCleanupFns.forEach((fn) => fn());
    });
    function addWindowListener(event, listener) {
      window.addEventListener(event, listener);
      const removeListener = () => window.removeEventListener(event, listener);
      onUnmountedCleanupFns.push(removeListener);
      return () => {
        removeListener();
        onUnmountedCleanupFns.splice(onUnmountedCleanupFns.indexOf(removeListener), 1);
      };
    }
    function useDragger(el, value, min, max, axis) {
      function onMouseDown(event) {
        event.preventDefault();
        event.stopPropagation();
        const start = axis === "x" ? event.clientX : event.clientY;
        const startValue = value.value ?? (axis === "x" ? previewWrapper.value.clientWidth - 67 : previewWrapper.value.clientHeight - 70);
        resizing.value = true;
        const removeListeners = [
          addWindowListener("mousemove", onMouseMove),
          addWindowListener("mouseup", onMouseUp)
        ];
        function onMouseMove(event2) {
          const snapTarget = axis === "x" ? previewWrapper.value.clientWidth : previewWrapper.value.clientHeight;
          const delta = (axis === "x" ? event2.clientX : event2.clientY) - start;
          value.value = Math.max(min, Math.min(max, startValue + delta));
          if (Math.abs(value.value - (snapTarget - 67)) < 16) {
            value.value = null;
          }
        }
        function onMouseUp() {
          removeListeners.forEach((fn) => fn());
          resizing.value = false;
        }
      }
      useEventListener(el, "mousedown", onMouseDown);
      function onTouchStart(event) {
        event.preventDefault();
        event.stopPropagation();
        const start = axis === "x" ? event.touches[0].clientX : event.touches[0].clientY;
        const startValue = value.value;
        resizing.value = true;
        const removeListeners = [
          addWindowListener("touchmove", onTouchMove),
          addWindowListener("touchend", onTouchEnd),
          addWindowListener("touchcancel", onTouchEnd)
        ];
        function onTouchMove(event2) {
          const delta = (axis === "x" ? event2.touches[0].clientX : event2.touches[0].clientY) - start;
          value.value = Math.max(min, Math.min(max, startValue + delta));
        }
        function onTouchEnd() {
          removeListeners.forEach((fn) => fn());
          resizing.value = false;
        }
      }
      useEventListener(el, "touchstart", onTouchStart);
    }
    const responsiveWidth = computed({
      get: () => settings[settings.rotate ? "responsiveHeight" : "responsiveWidth"],
      set: (value) => {
        settings[settings.rotate ? "responsiveHeight" : "responsiveWidth"] = value;
      }
    });
    const responsiveHeight = computed({
      get: () => settings[settings.rotate ? "responsiveWidth" : "responsiveHeight"],
      set: (value) => {
        settings[settings.rotate ? "responsiveWidth" : "responsiveHeight"] = value;
      }
    });
    const horizontalDragger = ref();
    const verticalDragger = ref();
    const cornerDragger = ref();
    const previewWrapper = ref();
    useDragger(horizontalDragger, responsiveWidth, 32, 2e4, "x");
    useDragger(verticalDragger, responsiveHeight, 32, 2e4, "y");
    useDragger(cornerDragger, responsiveWidth, 32, 2e4, "x");
    useDragger(cornerDragger, responsiveHeight, 32, 2e4, "y");
    const finalWidth = computed(() => settings.rotate ? settings.responsiveHeight : settings.responsiveWidth);
    const finalHeight = computed(() => settings.rotate ? settings.responsiveWidth : settings.responsiveHeight);
    const isResponsiveEnabled = computed(() => !props.variant.responsiveDisabled);
    const sizeTooltip = computed(() => `${responsiveWidth.value ?? "Auto"} × ${responsiveHeight.value ?? "Auto"}`);
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", _hoisted_1, [
        isResponsiveEnabled.value ? (openBlock(), createElementBlock("div", _hoisted_2, [
          createVNode(HatchedPattern, { class: "htw-w-full htw-h-full htw-text-black/[1%] dark:htw-text-white/[1%]" })
        ])) : createCommentVNode("", true),
        createElementVNode("div", {
          ref_key: "previewWrapper",
          ref: previewWrapper,
          class: "htw-h-full htw-overflow-auto htw-relative"
        }, [
          createElementVNode("div", {
            class: normalizeClass(["htw-overflow-hidden htw-bg-white dark:htw-bg-gray-700 htw-rounded-lg htw-relative", isResponsiveEnabled.value ? {
              "htw-w-fit": !!finalWidth.value,
              "htw-h-fit": !!finalHeight.value,
              "htw-h-full": !finalHeight.value
            } : "htw-h-full"])
          }, [
            createElementVNode("div", _hoisted_3, [
              unref(settings).checkerboard ? (openBlock(), createBlock(CheckerboardPattern, {
                key: 0,
                class: "htw-absolute htw-inset-0 htw-w-full htw-h-full htw-text-gray-500/20"
              })) : createCommentVNode("", true),
              createElementVNode("div", _hoisted_4, [
                createElementVNode("div", _hoisted_5, [
                  _hoisted_6,
                  renderSlot(_ctx.$slots, "default", {
                    isResponsiveEnabled: isResponsiveEnabled.value,
                    finalWidth: finalWidth.value,
                    finalHeight: finalHeight.value,
                    resizing: resizing.value
                  }, void 0, true)
                ]),
                _hoisted_7
              ]),
              isResponsiveEnabled.value ? (openBlock(), createElementBlock(Fragment, { key: 1 }, [
                withDirectives((openBlock(), createElementBlock("div", {
                  ref_key: "horizontalDragger",
                  ref: horizontalDragger,
                  class: "htw-absolute htw-w-4 htw-top-0 htw-bottom-4 htw-right-0 hover:htw-bg-primary-500/30 htw-flex htw-items-center htw-justify-center htw-cursor-ew-resize htw-group hover:htw-text-primary-500"
                }, [
                  createVNode(unref(Icon), {
                    icon: "mdi:drag-vertical-variant",
                    class: "htw-w-4 htw-h-4 htw-opacity-20 group-hover:htw-opacity-90"
                  })
                ])), [
                  [
                    unref(VTooltip),
                    sizeTooltip.value,
                    void 0,
                    { right: true }
                  ]
                ]),
                withDirectives((openBlock(), createElementBlock("div", {
                  ref_key: "verticalDragger",
                  ref: verticalDragger,
                  class: "htw-absolute htw-h-4 htw-left-0 htw-right-4 htw-bottom-0 hover:htw-bg-primary-500/30 htw-flex htw-items-center htw-justify-center htw-cursor-ns-resize htw-group hover:htw-text-primary-500"
                }, [
                  createVNode(unref(Icon), {
                    icon: "mdi:drag-horizontal-variant",
                    class: "htw-w-4 htw-h-4 htw-opacity-20 group-hover:htw-opacity-90"
                  })
                ])), [
                  [
                    unref(VTooltip),
                    sizeTooltip.value,
                    void 0,
                    { bottom: true }
                  ]
                ]),
                withDirectives(createElementVNode("div", {
                  ref_key: "cornerDragger",
                  ref: cornerDragger,
                  class: "htw-absolute htw-w-4 htw-h-4 htw-right-0 htw-bottom-0 hover:htw-bg-primary-500/30 htw-flex htw-items-center htw-justify-center htw-cursor-nwse-resize htw-group hover:htw-text-primary-500"
                }, null, 512), [
                  [
                    unref(VTooltip),
                    sizeTooltip.value,
                    void 0,
                    { bottom: true }
                  ]
                ])
              ], 64)) : createCommentVNode("", true)
            ])
          ], 2)
        ], 512)
      ]);
    };
  }
});
export {
  _sfc_main as default
};
