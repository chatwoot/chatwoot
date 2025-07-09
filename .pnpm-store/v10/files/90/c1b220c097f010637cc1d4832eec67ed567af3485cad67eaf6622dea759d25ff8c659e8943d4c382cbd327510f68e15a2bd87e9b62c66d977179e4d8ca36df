import { defineComponent, ref, computed, resolveComponent, openBlock, createElementBlock, createVNode, withCtx, renderSlot, createBlock, createElementVNode, unref, createCommentVNode, reactive, onBeforeUnmount, h } from "@histoire/vendors/vue";
import { useResizeObserver } from "@histoire/vendors/vue-use";
import { Icon } from "@histoire/vendors/iconify";
"use strict";
const _hoisted_1 = {
  role: "button",
  class: "htw-cursor-pointer hover:htw-bg-primary-50 dark:hover:htw-bg-primary-900 htw-w-8 htw-h-full htw-flex htw-items-center htw-justify-center htw-absolute htw-top-0 htw-right-0"
};
const _hoisted_2 = { class: "htw-flex htw-flex-col htw-items-stretch" };
const overflowButtonWidth = 32;
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "BaseOverflowMenu",
  setup(__props) {
    const el = ref();
    const availableWidth = ref(0);
    useResizeObserver(el, (entries) => {
      const containerWidth = entries[0].contentRect.width;
      availableWidth.value = containerWidth - overflowButtonWidth;
    });
    const children = ref(/* @__PURE__ */ new Map());
    const visibleChildrenCount = computed(() => {
      let width = 0;
      const c = [...children.value.values()].sort((a, b) => a.index - b.index);
      for (let i = 0; i < c.length; i++) {
        width += c[i].width;
        if (width > availableWidth.value) {
          return i;
        }
      }
      return c.length;
    });
    const ChildWrapper = {
      name: "ChildWrapper",
      props: ["index"],
      setup(props, { slots }) {
        const el2 = ref();
        const state = reactive({ width: 0, index: props.index });
        useResizeObserver(el2, (entries) => {
          const width = entries[0].contentRect.width;
          if (!children.value.has(el2.value)) {
            children.value.set(el2.value, state);
          }
          state.width = width;
        });
        onBeforeUnmount(() => {
          children.value.delete(el2.value);
        });
        const visible = computed(() => visibleChildrenCount.value > state.index);
        return () => h("div", { ref: el2, style: { visibility: visible.value ? "visible" : "hidden" } }, slots.default());
      }
    };
    function ChildrenRender(props, { slots }) {
      const [fragment] = slots.default();
      return fragment.children.map((vnode, index) => h(ChildWrapper, { index }, () => [vnode]));
    }
    function ChildrenSlice(props, { slots }) {
      const [fragment] = slots.default();
      return fragment.children.slice(props.start, props.end);
    }
    return (_ctx, _cache) => {
      const _component_VDropdown = resolveComponent("VDropdown");
      return openBlock(), createElementBlock("div", {
        ref_key: "el",
        ref: el,
        class: "histoire-base-overflow-menu htw-flex htw-overflow-hidden htw-relative"
      }, [
        createVNode(ChildrenRender, null, {
          default: withCtx(() => [
            renderSlot(_ctx.$slots, "default")
          ]),
          _: 3
        }),
        visibleChildrenCount.value < children.value.size ? (openBlock(), createBlock(_component_VDropdown, { key: 0 }, {
          popper: withCtx(() => [
            createElementVNode("div", _hoisted_2, [
              createVNode(ChildrenSlice, { start: visibleChildrenCount.value }, {
                default: withCtx(() => [
                  renderSlot(_ctx.$slots, "overflow")
                ]),
                _: 3
              }, 8, ["start"])
            ])
          ]),
          default: withCtx(() => [
            createElementVNode("div", _hoisted_1, [
              createVNode(unref(Icon), {
                icon: "carbon:caret-down",
                class: "htw-w-4 htw-h-4 htw-opacity-50 group-hover:htw-opacity-100"
              })
            ])
          ]),
          _: 3
        })) : createCommentVNode("", true)
      ], 512);
    };
  }
});
export {
  _sfc_main as default
};
