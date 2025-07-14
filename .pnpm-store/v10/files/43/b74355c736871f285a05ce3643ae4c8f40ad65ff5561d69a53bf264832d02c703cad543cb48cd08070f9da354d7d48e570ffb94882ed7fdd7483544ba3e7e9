/*
  @license
	Rollup.js v4.40.2
	Tue, 06 May 2025 07:26:21 GMT - commit 02da7efedcf373f0f819b78e3acbe50de05d9a5b

	https://github.com/rollup/rollup

	Released under the MIT License.
*/
'use strict';

Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });

const rollup = require('./shared/rollup.js');
const parseAst_js = require('./shared/parseAst.js');
const fseventsImporter = require('./shared/fsevents-importer.js');
require('node:process');
require('node:path');
require('path');
require('./native.js');
require('node:perf_hooks');
require('node:fs/promises');

class WatchEmitter {
    constructor() {
        this.currentHandlers = Object.create(null);
        this.persistentHandlers = Object.create(null);
    }
    // Will be overwritten by Rollup
    async close() { }
    emit(event, ...parameters) {
        return Promise.all([...this.getCurrentHandlers(event), ...this.getPersistentHandlers(event)].map(handler => handler(...parameters)));
    }
    off(event, listener) {
        const listeners = this.persistentHandlers[event];
        if (listeners) {
            // A hack stolen from "mitt": ">>> 0" does not change numbers >= 0, but -1
            // (which would remove the last array element if used unchanged) is turned
            // into max_int, which is outside the array and does not change anything.
            listeners.splice(listeners.indexOf(listener) >>> 0, 1);
        }
        return this;
    }
    on(event, listener) {
        this.getPersistentHandlers(event).push(listener);
        return this;
    }
    onCurrentRun(event, listener) {
        this.getCurrentHandlers(event).push(listener);
        return this;
    }
    once(event, listener) {
        const selfRemovingListener = (...parameters) => {
            this.off(event, selfRemovingListener);
            return listener(...parameters);
        };
        this.on(event, selfRemovingListener);
        return this;
    }
    removeAllListeners() {
        this.removeListenersForCurrentRun();
        this.persistentHandlers = Object.create(null);
        return this;
    }
    removeListenersForCurrentRun() {
        this.currentHandlers = Object.create(null);
        return this;
    }
    getCurrentHandlers(event) {
        return this.currentHandlers[event] || (this.currentHandlers[event] = []);
    }
    getPersistentHandlers(event) {
        return this.persistentHandlers[event] || (this.persistentHandlers[event] = []);
    }
}

function watch(configs) {
    const emitter = new WatchEmitter();
    watchInternal(configs, emitter).catch(error => {
        rollup.handleError(error);
    });
    return emitter;
}
function withTrailingSlash(path) {
    if (path[path.length - 1] !== '/') {
        return `${path}/`;
    }
    return path;
}
function checkWatchConfig(config) {
    for (const item of config) {
        if (item.input && item.output) {
            const input = typeof item.input === 'string' ? rollup.ensureArray(item.input) : item.input;
            const output = rollup.ensureArray(item.output);
            for (const index in input) {
                const inputPath = input[index];
                const subPath = output.find(o => {
                    if (!o.dir || typeof inputPath !== 'string') {
                        return false;
                    }
                    const _outPath = withTrailingSlash(o.dir);
                    const _inputPath = withTrailingSlash(inputPath);
                    return _inputPath.startsWith(_outPath);
                });
                if (subPath) {
                    parseAst_js.error(parseAst_js.logInvalidOption('watch', parseAst_js.URL_WATCH, `the input "${inputPath}" is a subpath of the output "${subPath.dir}"`));
                }
            }
        }
    }
}
async function watchInternal(configs, emitter) {
    const optionsList = await Promise.all(rollup.ensureArray(configs).map(config => rollup.mergeOptions(config, true)));
    const watchOptionsList = optionsList.filter(config => config.watch !== false);
    if (watchOptionsList.length === 0) {
        return parseAst_js.error(parseAst_js.logInvalidOption('watch', parseAst_js.URL_WATCH, 'there must be at least one config where "watch" is not set to "false"'));
    }
    checkWatchConfig(watchOptionsList);
    await fseventsImporter.loadFsEvents();
    const { Watcher } = await Promise.resolve().then(() => require('./shared/watch.js'));
    new Watcher(watchOptionsList, emitter);
}

exports.VERSION = rollup.version;
exports.defineConfig = rollup.defineConfig;
exports.rollup = rollup.rollup;
exports.watch = watch;
//# sourceMappingURL=rollup.js.map
