"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildDirective = void 0;
var dompurify_1 = __importDefault(require("dompurify"));
function setUpHooks(config) {
    var _a;
    var hooks = (_a = config.hooks) !== null && _a !== void 0 ? _a : {};
    var hookName;
    for (hookName in hooks) {
        var hook = hooks[hookName];
        if (hook !== undefined) {
            dompurify_1.default.addHook(hookName, hook);
        }
    }
}
function buildDirective(config) {
    if (config === void 0) { config = {}; }
    setUpHooks(config);
    var updateComponent = function (el, binding) {
        var _a;
        if (binding.oldValue === binding.value) {
            return;
        }
        var arg = binding.arg;
        var namedConfigurations = config.namedConfigurations;
        if (namedConfigurations &&
            arg !== undefined &&
            typeof namedConfigurations[arg] !== 'undefined') {
            el.innerHTML = dompurify_1.default.sanitize(binding.value, namedConfigurations[arg]);
            return;
        }
        el.innerHTML = dompurify_1.default.sanitize(binding.value, (_a = config.default) !== null && _a !== void 0 ? _a : {});
    };
    return {
        inserted: updateComponent,
        update: updateComponent,
        unbind: function (el) {
            el.innerHTML = '';
        },
    };
}
exports.buildDirective = buildDirective;
