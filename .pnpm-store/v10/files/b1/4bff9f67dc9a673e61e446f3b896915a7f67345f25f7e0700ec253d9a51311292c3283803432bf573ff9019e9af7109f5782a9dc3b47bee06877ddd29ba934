import { reactive } from "@histoire/vendors/vue";
import { histoireConfig } from "./config.js";
"use strict";
const receivedSettings = reactive({});
function applyPreviewSettings(settings) {
  Object.assign(receivedSettings, settings);
  document.documentElement.setAttribute("dir", settings.textDirection);
  const contrastColor = getContrastColor(settings);
  document.documentElement.style.setProperty("--histoire-contrast-color", contrastColor);
  if (histoireConfig.autoApplyContrastColor) {
    document.documentElement.style.color = contrastColor;
  }
}
function getContrastColor(setting) {
  var _a;
  return ((_a = histoireConfig.backgroundPresets.find((preset) => preset.color === setting.backgroundColor)) == null ? void 0 : _a.contrastColor) ?? "unset";
}
export {
  applyPreviewSettings,
  getContrastColor,
  receivedSettings
};
