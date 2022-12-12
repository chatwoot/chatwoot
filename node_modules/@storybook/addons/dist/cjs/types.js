"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isSupportedType = isSupportedType;
exports.types = void 0;

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.values.js");

// NOTE: The types exported from this file are simplified versions of the types exported
// by @storybook/csf, with the simpler form retained for backwards compatibility.
// We will likely start exporting the more complex <StoryFnReturnType> based types in 7.0
// The `any` here is the story store's `StoreItem` record. Ideally we should probably only
// pass a defined subset of that full data, but we pass it all so far :shrug:
var types;
exports.types = types;

(function (types) {
  types["TAB"] = "tab";
  types["PANEL"] = "panel";
  types["TOOL"] = "tool";
  types["TOOLEXTRA"] = "toolextra";
  types["PREVIEW"] = "preview";
  types["NOTES_ELEMENT"] = "notes-element";
})(types || (exports.types = types = {}));

function isSupportedType(type) {
  return !!Object.values(types).find(function (typeVal) {
    return typeVal === type;
  });
}