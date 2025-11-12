import { parentPort } from 'node:worker_threads';
import { expose, proxy } from 'comlink';
import nodeEndpoint from 'comlink/dist/esm/node-adapter.mjs';
import { Core } from './core.js';
/**
 * @file This is a wrapper module for using the Core API with comlink.
 */
if (parentPort === null)
    throw new Error('This module must be started on a worker.');
/**
 * This is a wrapper for using the Core API from comlink.
 *
 * The arguments of the methods wrapped in comlink must be serializable.
 * The methods in this class are serializable versions of the Core API methods.
 */
export class SerializableCore {
    core;
    constructor(config) {
        this.core = new Core(config);
    }
    async lint(...args) {
        return this.core.lint(...args);
    }
    formatResultSummary(...args) {
        return this.core.formatResultSummary(...args);
    }
    async formatResultDetails(...args) {
        return this.core.formatResultDetails(...args);
    }
    async applyAutoFixes(...args) {
        return proxy(await this.core.applyAutoFixes(...args));
    }
    async disablePerLine(...args) {
        return proxy(await this.core.disablePerLine(...args));
    }
    async disablePerFile(...args) {
        return proxy(await this.core.disablePerFile(...args));
    }
    async convertErrorToWarningPerFile(...args) {
        return proxy(await this.core.convertErrorToWarningPerFile(...args));
    }
    async applySuggestions(results, ruleIds, filterScript) {
        // eslint-disable-next-line no-eval -- TODO: replace with a better solution
        const filter = eval(filterScript);
        return proxy(await this.core.applySuggestions(results, ruleIds, filter));
    }
    async makeFixableAndFix(results, ruleIds, fixableMakerScript) {
        // eslint-disable-next-line no-eval -- TODO: replace with a better solution
        const fixableMaker = eval(fixableMakerScript);
        return proxy(await this.core.makeFixableAndFix(results, ruleIds, fixableMaker));
    }
}
// eslint-disable-next-line @typescript-eslint/no-explicit-any
expose(SerializableCore, nodeEndpoint(parentPort));
//# sourceMappingURL=core-worker.js.map