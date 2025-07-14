import { defineComponent, ref, watch, computed, onUnmounted, openBlock, createElementBlock, normalizeClass, createElementVNode, normalizeStyle, renderSlot, withModifiers, pushScopeId, popScopeId } from "@histoire/vendors/vue";
"use strict";
const _withScopeId = (n) => (pushScopeId("data-v-4f40a1bb"), n = n(), popScopeId(), n);
const _hoisted_1 = ["onMousedown"];
const SAVE_PREFIX = "__histoire";
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseSplitPane",
  props: {
    orientation: {
      type: String,
      default: "landscape",
      validator: (value) => ["landscape", "portrait"].includes(value)
    },
    defaultSplit: {
      type: Number,
      default: 50
    },
    split: {
      type: Number,
      default: void 0
    },
    min: {
      type: Number,
      default: 20
    },
    max: {
      type: Number,
      default: 80
    },
    draggerOffset: {
      type: String,
      default: "center",
      validator: (value) => ["before", "center", "after"].includes(value)
    },
    saveId: {
      type: String,
      default: null
    },
    fixed: {
      type: Boolean,
      default: false
    }
  },
  emits: {
    "update:split": (_value) => true
  },
  setup(__props, { emit: __emit }) {
    const props = __props;
    const emit = __emit;
    const currentSplit = ref(props.defaultSplit);
    watch(() => props.split, (value) => {
      if (value !== void 0) {
        currentSplit.value = value;
      }
    }, {
      immediate: true
    });
    if (props.saveId) {
      const storageKey = `${SAVE_PREFIX}-split-pane-${props.saveId}`;
      const savedValue = localStorage.getItem(storageKey);
      if (savedValue != null) {
        let parsedValue;
        try {
          parsedValue = JSON.parse(savedValue);
        } catch (e) {
          console.error(e);
        }
        if (typeof parsedValue === "number") {
          currentSplit.value = parsedValue;
        }
      }
      watch(currentSplit, (value) => {
        localStorage.setItem(storageKey, JSON.stringify(value));
      });
      watch(currentSplit, (value) => {
        if (value !== props.split) {
          emit("update:split", value);
        }
      }, {
        immediate: true
      });
    }
    const boundSplit = computed(() => {
      if (currentSplit.value < props.min) {
        return props.min;
      } else if (currentSplit.value > props.max) {
        return props.max;
      } else {
        return currentSplit.value;
      }
    });
    const leftStyle = computed(() => ({
      [props.orientation === "landscape" ? "width" : "height"]: props.fixed ? `${boundSplit.value}px` : `${boundSplit.value}%`
    }));
    const rightStyle = computed(() => ({
      [props.orientation === "landscape" ? "width" : "height"]: props.fixed ? null : `${100 - boundSplit.value}%`
    }));
    const dragging = ref(false);
    let startPosition = 0;
    let startSplit = 0;
    const el = ref(null);
    function dragStart(e) {
      dragging.value = true;
      startPosition = props.orientation === "landscape" ? e.pageX : e.pageY;
      startSplit = boundSplit.value;
      window.addEventListener("mousemove", dragMove);
      window.addEventListener("mouseup", dragEnd);
    }
    function dragMove(e) {
      if (dragging.value) {
        let position;
        let totalSize;
        if (props.orientation === "landscape") {
          position = e.pageX;
          totalSize = el.value.offsetWidth;
        } else {
          position = e.pageY;
          totalSize = el.value.offsetHeight;
        }
        const dPosition = position - startPosition;
        if (props.fixed) {
          currentSplit.value = startSplit + dPosition;
        } else {
          currentSplit.value = startSplit + ~~(dPosition / totalSize * 200) / 2;
        }
      }
    }
    function dragEnd() {
      dragging.value = false;
      removeDragListeners();
    }
    function removeDragListeners() {
      window.removeEventListener("mousemove", dragMove);
      window.removeEventListener("mouseup", dragEnd);
    }
    onUnmounted(() => {
      removeDragListeners();
    });
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("div", {
        ref_key: "el",
        ref: el,
        class: normalizeClass(["histoire-base-split-pane htw-flex htw-h-full htw-isolate htw-overflow-auto", {
          "htw-flex-col": __props.orientation === "portrait",
          "htw-cursor-ew-resize": dragging.value && __props.orientation === "landscape",
          "htw-cursor-ns-resize": dragging.value && __props.orientation === "portrait",
          [__props.orientation]: true
        }])
      }, [
        createElementVNode("div", {
          class: normalizeClass(["htw-relative htw-top-0 htw-left-0 htw-z-20", {
            "htw-pointer-events-none": dragging.value,
            "htw-border-r htw-border-gray-300/30 dark:htw-border-gray-800": __props.orientation === "landscape",
            "htw-flex-none": __props.fixed
          }]),
          style: normalizeStyle(leftStyle.value)
        }, [
          renderSlot(_ctx.$slots, "first", {}, void 0, true),
          createElementVNode("div", {
            class: normalizeClass(["dragger htw-absolute htw-z-100 hover:htw-bg-primary-500/50 htw-transition-colors htw-duration-150 htw-delay-150", {
              "htw-top-0 htw-bottom-0 htw-cursor-ew-resize": __props.orientation === "landscape",
              "htw-left-0 htw-right-0 htw-cursor-ns-resize": __props.orientation === "portrait",
              [`dragger-offset-${__props.draggerOffset}`]: true,
              "htw-bg-primary-500/25": dragging.value
            }]),
            onMousedown: withModifiers(dragStart, ["prevent"])
          }, null, 42, _hoisted_1)
        ], 6),
        createElementVNode("div", {
          class: normalizeClass(["htw-relative htw-bottom-0 htw-right-0", {
            "htw-pointer-events-none": dragging.value,
            "htw-border-t htw-border-gray-300/30 dark:htw-border-gray-800": __props.orientation === "portrait",
            "htw-flex-1": __props.fixed
          }]),
          style: normalizeStyle(rightStyle.value)
        }, [
          renderSlot(_ctx.$slots, "last", {}, void 0, true)
        ], 6)
      ], 2);
    };
  }
});
export {
  _sfc_main as default
};
