import { defineComponent, ref, watchEffect, markRaw, openBlock, createBlock, resolveDynamicComponent, mergeProps, createCommentVNode } from "@histoire/vendors/vue";
import { clientSupportPlugins } from "virtual:$histoire-support-plugins-client";
"use strict";
const __default__ = {
  inheritAttrs: false
};
const _sfc_main = /* @__PURE__ */ defineComponent({
  ...__default__,
  __name: "GenericRenderStory",
  props: {
    story: {}
  },
  setup(__props) {
    const props = __props;
    const mountComponent = ref(null);
    watchEffect(async () => {
      var _a;
      const clientPlugin = clientSupportPlugins[(_a = props.story.file) == null ? void 0 : _a.supportPluginId];
      if (clientPlugin) {
        try {
          const pluginModule = await clientPlugin();
          mountComponent.value = markRaw(pluginModule.RenderStory);
        } catch (e) {
          console.error(e);
          throw e;
        }
      }
    });
    return (_ctx, _cache) => {
      return mountComponent.value ? (openBlock(), createBlock(resolveDynamicComponent(mountComponent.value), mergeProps({
        key: 0,
        class: "histoire-generic-render-story __histoire-render-story",
        story: _ctx.story
      }, _ctx.$attrs), null, 16, ["story"])) : createCommentVNode("", true);
    };
  }
});
export {
  _sfc_main as default
};
