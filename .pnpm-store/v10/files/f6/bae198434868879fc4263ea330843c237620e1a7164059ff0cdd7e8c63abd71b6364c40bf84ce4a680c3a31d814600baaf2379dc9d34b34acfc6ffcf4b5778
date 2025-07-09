import { defineComponent } from "@histoire/vendors/vue";
"use strict";
const _sfc_main = defineComponent({
  inheritAttrs: false,
  props: {
    isActive: {
      type: Boolean,
      default: void 0
    }
  },
  emits: {
    navigate: () => true
  },
  setup(props, { emit }) {
    function handleNavigate(event, navigate) {
      emit("navigate");
      navigate(event);
    }
    return {
      handleNavigate
    };
  }
});
export {
  _sfc_main as default
};
