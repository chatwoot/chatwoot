import { watch, onMounted } from "@histoire/vendors/vue";
import scrollIntoView from "@histoire/vendors/scroll";
"use strict";
function useScrollOnActive(active, el) {
  watch(active, (value) => {
    if (value) {
      autoScroll();
    }
  });
  function autoScroll() {
    if (el.value) {
      scrollIntoView(el.value, {
        scrollMode: "if-needed",
        block: "center",
        inline: "nearest",
        behavior: "smooth"
      });
    }
  }
  onMounted(() => {
    if (active.value) {
      autoScroll();
    }
  });
  return {
    autoScroll
  };
}
export {
  useScrollOnActive
};
