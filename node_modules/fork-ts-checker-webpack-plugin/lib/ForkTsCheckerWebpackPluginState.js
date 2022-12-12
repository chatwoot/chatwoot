"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function createForkTsCheckerWebpackPluginState() {
    return {
        reportPromise: Promise.resolve(undefined),
        issuesPromise: Promise.resolve(undefined),
        dependenciesPromise: Promise.resolve(undefined),
        lastDependencies: undefined,
        watching: false,
        initialized: false,
        webpackDevServerDoneTap: undefined,
    };
}
exports.createForkTsCheckerWebpackPluginState = createForkTsCheckerWebpackPluginState;
