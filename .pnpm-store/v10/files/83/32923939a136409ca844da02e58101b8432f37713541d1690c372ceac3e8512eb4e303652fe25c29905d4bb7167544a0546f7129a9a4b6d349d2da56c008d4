import { unindent } from "@histoire/shared";
import { clientSupportPlugins } from "virtual:$histoire-support-plugins-client";
"use strict";
async function getSourceCode(story, variant) {
  var _a, _b, _c, _d;
  if (variant.source) {
    return variant.source;
  } else if ((_a = variant.slots) == null ? void 0 : _a.call(variant).source) {
    const source = (_b = variant.slots) == null ? void 0 : _b.call(variant).source()[0].children;
    if (source) {
      return unindent(source);
    }
  } else {
    const clientPlugin = clientSupportPlugins[(_c = story.file) == null ? void 0 : _c.supportPluginId];
    if (clientPlugin) {
      const pluginModule = await clientPlugin();
      return pluginModule.generateSourceCode(variant);
    }
  }
  const sourceLoader = (_d = story.file) == null ? void 0 : _d.source;
  if (sourceLoader) {
    return (await sourceLoader()).default;
  }
}
export {
  getSourceCode
};
