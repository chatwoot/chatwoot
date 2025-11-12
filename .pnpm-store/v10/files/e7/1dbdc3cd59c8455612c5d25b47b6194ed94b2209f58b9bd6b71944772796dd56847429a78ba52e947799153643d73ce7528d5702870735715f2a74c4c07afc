"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var surveys_1 = require("../extensions/surveys");
var globals_1 = require("../utils/globals");
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.generateSurveys = surveys_1.generateSurveys;
// this used to be directly on window, but we moved it to __PosthogExtensions__
// it is still on window for backwards compatibility
globals_1.assignableWindow.extendPostHogWithSurveys = surveys_1.generateSurveys;
exports.default = surveys_1.generateSurveys;
//# sourceMappingURL=surveys.js.map