export const ADDON_ID = 'storybook/docs';
export const PANEL_ID = `${ADDON_ID}/panel`;
export const PARAM_KEY = `docs`;
export const SNIPPET_RENDERED = `${ADDON_ID}/snippet-rendered`;
export let SourceType;

(function (SourceType) {
  SourceType["AUTO"] = "auto";
  SourceType["CODE"] = "code";
  SourceType["DYNAMIC"] = "dynamic";
})(SourceType || (SourceType = {}));