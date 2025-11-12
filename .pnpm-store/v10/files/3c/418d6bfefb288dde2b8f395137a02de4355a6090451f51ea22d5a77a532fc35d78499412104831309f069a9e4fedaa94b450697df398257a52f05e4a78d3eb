"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var rrweb_record_1 = require("@posthog/rrweb-record");
var rrweb_plugin_console_record_1 = require("@posthog/rrweb-plugin-console-record");
var globals_1 = require("../utils/globals");
var network_plugin_1 = require("../extensions/replay/external/network-plugin");
globals_1.assignableWindow.__PosthogExtensions__ = globals_1.assignableWindow.__PosthogExtensions__ || {};
globals_1.assignableWindow.__PosthogExtensions__.rrwebPlugins = { getRecordConsolePlugin: rrweb_plugin_console_record_1.getRecordConsolePlugin, getRecordNetworkPlugin: network_plugin_1.getRecordNetworkPlugin };
globals_1.assignableWindow.__PosthogExtensions__.rrweb = { record: rrweb_record_1.record, version: 'v2' };
// we used to put all of these items directly on window, and now we put it on __PosthogExtensions__
// but that means that old clients which lazily load this extension are looking in the wrong place
// yuck,
// so we also put them directly on the window
// when 1.161.1 is the oldest version seen in production we can remove this
globals_1.assignableWindow.rrweb = { record: rrweb_record_1.record, version: 'v2' };
globals_1.assignableWindow.rrwebConsoleRecord = { getRecordConsolePlugin: rrweb_plugin_console_record_1.getRecordConsolePlugin };
globals_1.assignableWindow.getRecordNetworkPlugin = network_plugin_1.getRecordNetworkPlugin;
exports.default = rrweb_record_1.record;
//# sourceMappingURL=posthog-recorder.js.map