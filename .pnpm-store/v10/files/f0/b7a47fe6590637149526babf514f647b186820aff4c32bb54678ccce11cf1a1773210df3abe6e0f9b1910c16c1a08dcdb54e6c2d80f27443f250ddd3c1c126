"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isDisabledIntegration = exports.isInstallableIntegration = void 0;
var isInstallableIntegration = function (name, integrationSettings) {
    var _a;
    var type = integrationSettings.type, bundlingStatus = integrationSettings.bundlingStatus, versionSettings = integrationSettings.versionSettings;
    // We use `!== 'unbundled'` (versus `=== 'bundled'`) to be inclusive of
    // destinations without a defined value for `bundlingStatus`
    var deviceMode = bundlingStatus !== 'unbundled' &&
        (type === 'browser' || ((_a = versionSettings === null || versionSettings === void 0 ? void 0 : versionSettings.componentTypes) === null || _a === void 0 ? void 0 : _a.includes('browser')));
    // checking for iterable is a quick fix we need in place to prevent
    // errors showing Iterable as a failed destiantion. Ideally, we should
    // fix the Iterable metadata instead, but that's a longer process.
    return !name.startsWith('Segment') && name !== 'Iterable' && deviceMode;
};
exports.isInstallableIntegration = isInstallableIntegration;
var isDisabledIntegration = function (integrationName, globalIntegrations) {
    var allDisableAndNotDefined = globalIntegrations.All === false &&
        globalIntegrations[integrationName] === undefined;
    return (globalIntegrations[integrationName] === false || allDisableAndNotDefined);
};
exports.isDisabledIntegration = isDisabledIntegration;
//# sourceMappingURL=utils.js.map