/*
 * Code from vitest https://github.com/vitest-dev/vitest/blob/98974ba4a5b95a57a98bc2077b74bc5609d6bb3a/packages/vitest/src/integrations/env/utils.ts#L1 by @antfu and @patak
 */
import { KEYS } from './dom-keys.js';
const skipKeys = [
    'window',
    'self',
    'top',
    'parent',
];
export function getWindowKeys(global, win) {
    const keys = new Set(KEYS.concat(Object.getOwnPropertyNames(win))
        .filter((k) => {
        if (skipKeys.includes(k)) {
            return false;
        }
        if (k in global) {
            return KEYS.includes(k);
        }
        return true;
    }));
    return keys;
}
function isClassLikeName(name) {
    return name[0] === name[0].toUpperCase();
}
export function populateGlobal(global, win, options = {}) {
    const { bindFunctions = false } = options;
    const keys = getWindowKeys(global, win);
    const originals = new Map();
    const overrideObject = new Map();
    for (const key of keys) {
        const boundFunction = bindFunctions &&
            typeof win[key] === 'function' &&
            !isClassLikeName(key) &&
            win[key].bind(win);
        if (KEYS.includes(key) && key in global) {
            originals.set(key, global[key]);
        }
        Object.defineProperty(global, key, {
            get() {
                if (overrideObject.has(key)) {
                    return overrideObject.get(key);
                }
                if (boundFunction) {
                    return boundFunction;
                }
                return win[key];
            },
            set(v) {
                overrideObject.set(key, v);
            },
            configurable: true,
        });
    }
    global.window = global;
    global.self = global;
    global.top = global;
    global.parent = global;
    if (global.global) {
        global.global = global;
    }
    skipKeys.forEach(k => keys.add(k));
    return {
        keys,
        skipKeys,
        originals,
    };
}
