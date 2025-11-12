import { defineComponent, ref, watch, computed, openBlock, createBlock, withCtx, createElementVNode, normalizeClass, normalizeStyle, toRaw } from "@histoire/vendors/vue";
import { useEventListener } from "@histoire/vendors/vue-use";
import { applyState } from "@histoire/shared";
import { SANDBOX_READY, EVENT_SEND, STATE_SYNC, PREVIEW_SETTINGS_SYNC } from "../../util/const.js";
import { getSandboxUrl } from "../../util/sandbox.js";
import { usePreviewSettingsStore } from "../../stores/preview-settings.js";
import { useEventsStore } from "../../stores/events.js";
import { toRawDeep } from "../../util/state.js";
import StoryResponsivePreview from "./StoryResponsivePreview.vue.js";
"use strict";
const _hoisted_1 = ["src"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "StoryVariantSinglePreviewRemote",
  props: {
    story: {},
    variant: {}
  },
  setup(__props) {
    const props = __props;
    const settings = usePreviewSettingsStore().currentSettings;
    const iframe = ref();
    function syncState() {
      if (iframe.value && props.variant.previewReady) {
        iframe.value.contentWindow.postMessage({
          type: STATE_SYNC,
          state: toRawDeep(props.variant.state, true)
        });
      }
    }
    let synced = false;
    watch(() => props.variant.state, () => {
      if (synced) {
        synced = false;
        return;
      }
      syncState();
    }, {
      deep: true,
      immediate: true
    });
    Object.assign(props.variant, {
      previewReady: false
    });
    useEventListener(window, "message", (event) => {
      switch (event.data.type) {
        case STATE_SYNC:
          updateVariantState(event.data.state);
          break;
        case EVENT_SEND:
          logEvent(event.data.event);
          break;
        case SANDBOX_READY:
          setPreviewReady();
          break;
      }
    });
    function updateVariantState(state) {
      synced = true;
      applyState(props.variant.state, state);
    }
    function logEvent(event) {
      const eventsStore = useEventsStore();
      eventsStore.addEvent(event);
    }
    function setPreviewReady() {
      Object.assign(props.variant, {
        previewReady: true
      });
    }
    const sandboxUrl = computed(() => {
      return getSandboxUrl(props.story, props.variant);
    });
    const isIframeLoaded = ref(false);
    watch(sandboxUrl, () => {
      isIframeLoaded.value = false;
      Object.assign(props.variant, {
        previewReady: false
      });
    });
    function syncSettings() {
      if (iframe.value) {
        iframe.value.contentWindow.postMessage({
          type: PREVIEW_SETTINGS_SYNC,
          settings: toRaw(settings)
        });
      }
    }
    watch(() => settings, () => {
      syncSettings();
    }, {
      deep: true,
      immediate: true
    });
    function onIframeLoad() {
      isIframeLoaded.value = true;
      syncState();
      syncSettings();
    }
    return (_ctx, _cache) => {
      return openBlock(), createBlock(StoryResponsivePreview, {
        class: "histoire-story-variant-single-preview-remote",
        variant: _ctx.variant
      }, {
        default: withCtx(({ isResponsiveEnabled, finalWidth, finalHeight, resizing }) => [
          createElementVNode("iframe", {
            ref_key: "iframe",
            ref: iframe,
            src: sandboxUrl.value,
            class: normalizeClass(["htw-w-full htw-h-full htw-relative", {
              "htw-invisible": !isIframeLoaded.value,
              "htw-pointer-events-none": resizing
            }]),
            style: normalizeStyle(isResponsiveEnabled ? {
              width: finalWidth ? `${finalWidth}px` : null,
              height: finalHeight ? `${finalHeight}px` : null
            } : void 0),
            "data-test-id": "preview-iframe",
            onLoad: _cache[0] || (_cache[0] = ($event) => onIframeLoad())
          }, null, 46, _hoisted_1)
        ]),
        _: 1
      }, 8, ["variant"]);
    };
  }
});
export {
  _sfc_main as default
};
