import { computed, openBlock, createElementBlock, defineComponent } from "@histoire/vendors/vue";
import { isDark } from "../../util/dark.js";
import { histoireConfig, customLogos } from "../../util/config.js";
import HistoireLogoDark from "../../assets/histoire-text-dark.svg.js";
import HistoireLogoLight from "../../assets/histoire-text.svg.js";
"use strict";
const _hoisted_1 = ["src", "alt"];
const _sfc_main = /* @__PURE__ */ defineComponent({
  __name: "AppLogo",
  setup(__props) {
    const logoUrl = computed(() => {
      var _a, _b;
      if (isDark.value) {
        return ((_a = histoireConfig.theme.logo) == null ? void 0 : _a.dark) ? customLogos.dark : HistoireLogoDark;
      }
      return ((_b = histoireConfig.theme.logo) == null ? void 0 : _b.light) ? customLogos.light : HistoireLogoLight;
    });
    const altText = computed(() => `${histoireConfig.theme.title} logo`);
    return (_ctx, _cache) => {
      return openBlock(), createElementBlock("img", {
        class: "histoire-app-logo",
        src: logoUrl.value,
        alt: altText.value
      }, null, 8, _hoisted_1);
    };
  }
});
export {
  _sfc_main as default
};
