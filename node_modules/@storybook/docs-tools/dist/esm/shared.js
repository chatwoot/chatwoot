export var ADDON_ID = 'storybook/docs';
export var PANEL_ID = "".concat(ADDON_ID, "/panel");
export var PARAM_KEY = "docs";
export var SNIPPET_RENDERED = "".concat(ADDON_ID, "/snippet-rendered");
export var SourceType;

(function (SourceType) {
  SourceType["AUTO"] = "auto";
  SourceType["CODE"] = "code";
  SourceType["DYNAMIC"] = "dynamic";
})(SourceType || (SourceType = {}));