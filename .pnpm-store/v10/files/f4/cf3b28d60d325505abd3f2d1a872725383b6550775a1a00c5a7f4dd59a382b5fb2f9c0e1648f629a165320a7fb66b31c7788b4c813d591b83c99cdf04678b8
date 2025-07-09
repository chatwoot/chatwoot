import { _optionalChain } from '@sentry/utils';
import { defineIntegration } from '@sentry/core';

var NodeType;
(function (NodeType) {
    NodeType[NodeType["Document"] = 0] = "Document";
    NodeType[NodeType["DocumentType"] = 1] = "DocumentType";
    NodeType[NodeType["Element"] = 2] = "Element";
    NodeType[NodeType["Text"] = 3] = "Text";
    NodeType[NodeType["CDATA"] = 4] = "CDATA";
    NodeType[NodeType["Comment"] = 5] = "Comment";
})(NodeType || (NodeType = {}));
function elementClassMatchesRegex(el, regex) {
    for (let eIndex = el.classList.length; eIndex--;) {
        const className = el.classList[eIndex];
        if (regex.test(className)) {
            return true;
        }
    }
    return false;
}
function distanceToMatch(node, matchPredicate, limit = Infinity, distance = 0) {
    if (!node)
        return -1;
    if (node.nodeType !== node.ELEMENT_NODE)
        return -1;
    if (distance > limit)
        return -1;
    if (matchPredicate(node))
        return distance;
    return distanceToMatch(node.parentNode, matchPredicate, limit, distance + 1);
}
function createMatchPredicate(className, selector) {
    return (node) => {
        const el = node;
        if (el === null)
            return false;
        try {
            if (className) {
                if (typeof className === 'string') {
                    if (el.matches(`.${className}`))
                        return true;
                }
                else if (elementClassMatchesRegex(el, className)) {
                    return true;
                }
            }
            if (selector && el.matches(selector))
                return true;
            return false;
        }
        catch (e2) {
            return false;
        }
    };
}

const DEPARTED_MIRROR_ACCESS_WARNING = 'Please stop import mirror directly. Instead of that,' +
    '\r\n' +
    'now you can use replayer.getMirror() to access the mirror instance of a replayer,' +
    '\r\n' +
    'or you can use record.mirror to access the mirror instance during recording.';
let _mirror = {
    map: {},
    getId() {
        console.error(DEPARTED_MIRROR_ACCESS_WARNING);
        return -1;
    },
    getNode() {
        console.error(DEPARTED_MIRROR_ACCESS_WARNING);
        return null;
    },
    removeNodeFromMap() {
        console.error(DEPARTED_MIRROR_ACCESS_WARNING);
    },
    has() {
        console.error(DEPARTED_MIRROR_ACCESS_WARNING);
        return false;
    },
    reset() {
        console.error(DEPARTED_MIRROR_ACCESS_WARNING);
    },
};
if (typeof window !== 'undefined' && window.Proxy && window.Reflect) {
    _mirror = new Proxy(_mirror, {
        get(target, prop, receiver) {
            if (prop === 'map') {
                console.error(DEPARTED_MIRROR_ACCESS_WARNING);
            }
            return Reflect.get(target, prop, receiver);
        },
    });
}
function hookSetter(target, key, d, isRevoked, win = window) {
    const original = win.Object.getOwnPropertyDescriptor(target, key);
    win.Object.defineProperty(target, key, isRevoked
        ? d
        : {
            set(value) {
                setTimeout(() => {
                    d.set.call(this, value);
                }, 0);
                if (original && original.set) {
                    original.set.call(this, value);
                }
            },
        });
    return () => hookSetter(target, key, original || {}, true);
}
function patch(source, name, replacement) {
    try {
        if (!(name in source)) {
            return () => {
            };
        }
        const original = source[name];
        const wrapped = replacement(original);
        if (typeof wrapped === 'function') {
            wrapped.prototype = wrapped.prototype || {};
            Object.defineProperties(wrapped, {
                __rrweb_original__: {
                    enumerable: false,
                    value: original,
                },
            });
        }
        source[name] = wrapped;
        return () => {
            source[name] = original;
        };
    }
    catch (e2) {
        return () => {
        };
    }
}
if (!(/[1-9][0-9]{12}/.test(Date.now().toString()))) ;
function closestElementOfNode(node) {
    if (!node) {
        return null;
    }
    const el = node.nodeType === node.ELEMENT_NODE
        ? node
        : node.parentElement;
    return el;
}
function isBlocked(node, blockClass, blockSelector, unblockSelector, checkAncestors) {
    if (!node) {
        return false;
    }
    const el = closestElementOfNode(node);
    if (!el) {
        return false;
    }
    const blockedPredicate = createMatchPredicate(blockClass, blockSelector);
    if (!checkAncestors) {
        const isUnblocked = unblockSelector && el.matches(unblockSelector);
        return blockedPredicate(el) && !isUnblocked;
    }
    const blockDistance = distanceToMatch(el, blockedPredicate);
    let unblockDistance = -1;
    if (blockDistance < 0) {
        return false;
    }
    if (unblockSelector) {
        unblockDistance = distanceToMatch(el, createMatchPredicate(null, unblockSelector));
    }
    if (blockDistance > -1 && unblockDistance < 0) {
        return true;
    }
    return blockDistance < unblockDistance;
}
const cachedImplementations = {};
function getImplementation(name) {
    const cached = cachedImplementations[name];
    if (cached) {
        return cached;
    }
    const document = window.document;
    let impl = window[name];
    if (document && typeof document.createElement === 'function') {
        try {
            const sandbox = document.createElement('iframe');
            sandbox.hidden = true;
            document.head.appendChild(sandbox);
            const contentWindow = sandbox.contentWindow;
            if (contentWindow && contentWindow[name]) {
                impl =
                    contentWindow[name];
            }
            document.head.removeChild(sandbox);
        }
        catch (e) {
        }
    }
    return (cachedImplementations[name] = impl.bind(window));
}
function onRequestAnimationFrame(...rest) {
    return getImplementation('requestAnimationFrame')(...rest);
}
function setTimeout(...rest) {
    return getImplementation('setTimeout')(...rest);
}

var CanvasContext = /* @__PURE__ */ ((CanvasContext2) => {
  CanvasContext2[CanvasContext2["2D"] = 0] = "2D";
  CanvasContext2[CanvasContext2["WebGL"] = 1] = "WebGL";
  CanvasContext2[CanvasContext2["WebGL2"] = 2] = "WebGL2";
  return CanvasContext2;
})(CanvasContext || {});

let errorHandler;
function registerErrorHandler(handler) {
    errorHandler = handler;
}
const callbackWrapper = (cb) => {
    if (!errorHandler) {
        return cb;
    }
    const rrwebWrapped = ((...rest) => {
        try {
            return cb(...rest);
        }
        catch (error) {
            if (errorHandler && errorHandler(error) === true) {
                return () => {
                };
            }
            throw error;
        }
    });
    return rrwebWrapped;
};

/*
 * base64-arraybuffer 1.0.1 <https://github.com/niklasvh/base64-arraybuffer>
 * Copyright (c) 2021 Niklas von Hertzen <https://hertzen.com>
 * Released under MIT License
 */
var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
// Use a lookup table to find the index.
var lookup = typeof Uint8Array === 'undefined' ? [] : new Uint8Array(256);
for (var i = 0; i < chars.length; i++) {
    lookup[chars.charCodeAt(i)] = i;
}
var encode = function (arraybuffer) {
    var bytes = new Uint8Array(arraybuffer), i, len = bytes.length, base64 = '';
    for (i = 0; i < len; i += 3) {
        base64 += chars[bytes[i] >> 2];
        base64 += chars[((bytes[i] & 3) << 4) | (bytes[i + 1] >> 4)];
        base64 += chars[((bytes[i + 1] & 15) << 2) | (bytes[i + 2] >> 6)];
        base64 += chars[bytes[i + 2] & 63];
    }
    if (len % 3 === 2) {
        base64 = base64.substring(0, base64.length - 1) + '=';
    }
    else if (len % 3 === 1) {
        base64 = base64.substring(0, base64.length - 2) + '==';
    }
    return base64;
};

const canvasVarMap = new Map();
function variableListFor(ctx, ctor) {
    let contextMap = canvasVarMap.get(ctx);
    if (!contextMap) {
        contextMap = new Map();
        canvasVarMap.set(ctx, contextMap);
    }
    if (!contextMap.has(ctor)) {
        contextMap.set(ctor, []);
    }
    return contextMap.get(ctor);
}
const saveWebGLVar = (value, win, ctx) => {
    if (!value ||
        !(isInstanceOfWebGLObject(value, win) || typeof value === 'object'))
        return;
    const name = value.constructor.name;
    const list = variableListFor(ctx, name);
    let index = list.indexOf(value);
    if (index === -1) {
        index = list.length;
        list.push(value);
    }
    return index;
};
function serializeArg(value, win, ctx) {
    if (value instanceof Array) {
        return value.map((arg) => serializeArg(arg, win, ctx));
    }
    else if (value === null) {
        return value;
    }
    else if (value instanceof Float32Array ||
        value instanceof Float64Array ||
        value instanceof Int32Array ||
        value instanceof Uint32Array ||
        value instanceof Uint8Array ||
        value instanceof Uint16Array ||
        value instanceof Int16Array ||
        value instanceof Int8Array ||
        value instanceof Uint8ClampedArray) {
        const name = value.constructor.name;
        return {
            rr_type: name,
            args: [Object.values(value)],
        };
    }
    else if (value instanceof ArrayBuffer) {
        const name = value.constructor.name;
        const base64 = encode(value);
        return {
            rr_type: name,
            base64,
        };
    }
    else if (value instanceof DataView) {
        const name = value.constructor.name;
        return {
            rr_type: name,
            args: [
                serializeArg(value.buffer, win, ctx),
                value.byteOffset,
                value.byteLength,
            ],
        };
    }
    else if (value instanceof HTMLImageElement) {
        const name = value.constructor.name;
        const { src } = value;
        return {
            rr_type: name,
            src,
        };
    }
    else if (value instanceof HTMLCanvasElement) {
        const name = 'HTMLImageElement';
        const src = value.toDataURL();
        return {
            rr_type: name,
            src,
        };
    }
    else if (value instanceof ImageData) {
        const name = value.constructor.name;
        return {
            rr_type: name,
            args: [serializeArg(value.data, win, ctx), value.width, value.height],
        };
    }
    else if (isInstanceOfWebGLObject(value, win) || typeof value === 'object') {
        const name = value.constructor.name;
        const index = saveWebGLVar(value, win, ctx);
        return {
            rr_type: name,
            index: index,
        };
    }
    return value;
}
const serializeArgs = (args, win, ctx) => {
    return args.map((arg) => serializeArg(arg, win, ctx));
};
const isInstanceOfWebGLObject = (value, win) => {
    const webGLConstructorNames = [
        'WebGLActiveInfo',
        'WebGLBuffer',
        'WebGLFramebuffer',
        'WebGLProgram',
        'WebGLRenderbuffer',
        'WebGLShader',
        'WebGLShaderPrecisionFormat',
        'WebGLTexture',
        'WebGLUniformLocation',
        'WebGLVertexArrayObject',
        'WebGLVertexArrayObjectOES',
    ];
    const supportedWebGLConstructorNames = webGLConstructorNames.filter((name) => typeof win[name] === 'function');
    return Boolean(supportedWebGLConstructorNames.find((name) => value instanceof win[name]));
};

function initCanvas2DMutationObserver(cb, win, blockClass, blockSelector, unblockSelector) {
    const handlers = [];
    const props2D = Object.getOwnPropertyNames(win.CanvasRenderingContext2D.prototype);
    for (const prop of props2D) {
        try {
            if (typeof win.CanvasRenderingContext2D.prototype[prop] !== 'function') {
                continue;
            }
            const restoreHandler = patch(win.CanvasRenderingContext2D.prototype, prop, function (original) {
                return function (...args) {
                    if (!isBlocked(this.canvas, blockClass, blockSelector, unblockSelector, true)) {
                        setTimeout(() => {
                            const recordArgs = serializeArgs(args, win, this);
                            cb(this.canvas, {
                                type: CanvasContext['2D'],
                                property: prop,
                                args: recordArgs,
                            });
                        }, 0);
                    }
                    return original.apply(this, args);
                };
            });
            handlers.push(restoreHandler);
        }
        catch (e) {
            const hookHandler = hookSetter(win.CanvasRenderingContext2D.prototype, prop, {
                set(v) {
                    cb(this.canvas, {
                        type: CanvasContext['2D'],
                        property: prop,
                        args: [v],
                        setter: true,
                    });
                },
            });
            handlers.push(hookHandler);
        }
    }
    return () => {
        handlers.forEach((h) => h());
    };
}

function getNormalizedContextName(contextType) {
    return contextType === 'experimental-webgl' ? 'webgl' : contextType;
}
function initCanvasContextObserver(win, blockClass, blockSelector, unblockSelector, setPreserveDrawingBufferToTrue) {
    const handlers = [];
    try {
        const restoreHandler = patch(win.HTMLCanvasElement.prototype, 'getContext', function (original) {
            return function (contextType, ...args) {
                if (!isBlocked(this, blockClass, blockSelector, unblockSelector, true)) {
                    const ctxName = getNormalizedContextName(contextType);
                    if (!('__context' in this))
                        this.__context = ctxName;
                    if (setPreserveDrawingBufferToTrue &&
                        ['webgl', 'webgl2'].includes(ctxName)) {
                        if (args[0] && typeof args[0] === 'object') {
                            const contextAttributes = args[0];
                            if (!contextAttributes.preserveDrawingBuffer) {
                                contextAttributes.preserveDrawingBuffer = true;
                            }
                        }
                        else {
                            args.splice(0, 1, {
                                preserveDrawingBuffer: true,
                            });
                        }
                    }
                }
                return original.apply(this, [contextType, ...args]);
            };
        });
        handlers.push(restoreHandler);
    }
    catch (e) {
        console.error('failed to patch HTMLCanvasElement.prototype.getContext');
    }
    return () => {
        handlers.forEach((h) => h());
    };
}

function patchGLPrototype(prototype, type, cb, blockClass, blockSelector, unblockSelector, mirror, win) {
    const handlers = [];
    const props = Object.getOwnPropertyNames(prototype);
    for (const prop of props) {
        if ([
            'isContextLost',
            'canvas',
            'drawingBufferWidth',
            'drawingBufferHeight',
        ].includes(prop)) {
            continue;
        }
        try {
            if (typeof prototype[prop] !== 'function') {
                continue;
            }
            const restoreHandler = patch(prototype, prop, function (original) {
                return function (...args) {
                    const result = original.apply(this, args);
                    saveWebGLVar(result, win, this);
                    if ('tagName' in this.canvas &&
                        !isBlocked(this.canvas, blockClass, blockSelector, unblockSelector, true)) {
                        const recordArgs = serializeArgs(args, win, this);
                        const mutation = {
                            type,
                            property: prop,
                            args: recordArgs,
                        };
                        cb(this.canvas, mutation);
                    }
                    return result;
                };
            });
            handlers.push(restoreHandler);
        }
        catch (e) {
            const hookHandler = hookSetter(prototype, prop, {
                set(v) {
                    cb(this.canvas, {
                        type,
                        property: prop,
                        args: [v],
                        setter: true,
                    });
                },
            });
            handlers.push(hookHandler);
        }
    }
    return handlers;
}
function initCanvasWebGLMutationObserver(cb, win, blockClass, blockSelector, unblockSelector, mirror) {
    const handlers = [];
    handlers.push(...patchGLPrototype(win.WebGLRenderingContext.prototype, CanvasContext.WebGL, cb, blockClass, blockSelector, unblockSelector, mirror, win));
    if (typeof win.WebGL2RenderingContext !== 'undefined') {
        handlers.push(...patchGLPrototype(win.WebGL2RenderingContext.prototype, CanvasContext.WebGL2, cb, blockClass, blockSelector, unblockSelector, mirror, win));
    }
    return () => {
        handlers.forEach((h) => h());
    };
}

var r = `for(var e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",t="undefined"==typeof Uint8Array?[]:new Uint8Array(256),a=0;a<64;a++)t[e.charCodeAt(a)]=a;var n=function(t){var a,n=new Uint8Array(t),r=n.length,s="";for(a=0;a<r;a+=3)s+=e[n[a]>>2],s+=e[(3&n[a])<<4|n[a+1]>>4],s+=e[(15&n[a+1])<<2|n[a+2]>>6],s+=e[63&n[a+2]];return r%3==2?s=s.substring(0,s.length-1)+"=":r%3==1&&(s=s.substring(0,s.length-2)+"=="),s};const r=new Map,s=new Map;const i=self;i.onmessage=async function(e){if(!("OffscreenCanvas"in globalThis))return i.postMessage({id:e.data.id});{const{id:t,bitmap:a,width:o,height:f,maxCanvasSize:c,dataURLOptions:g}=e.data,u=async function(e,t,a){const r=e+"-"+t;if("OffscreenCanvas"in globalThis){if(s.has(r))return s.get(r);const i=new OffscreenCanvas(e,t);i.getContext("2d");const o=await i.convertToBlob(a),f=await o.arrayBuffer(),c=n(f);return s.set(r,c),c}return""}(o,f,g),[h,d]=function(e,t,a){if(!a)return[e,t];const[n,r]=a;if(e<=n&&t<=r)return[e,t];let s=e,i=t;return s>n&&(i=Math.floor(n*t/e),s=n),i>r&&(s=Math.floor(r*e/t),i=r),[s,i]}(o,f,c),l=new OffscreenCanvas(h,d),w=l.getContext("bitmaprenderer"),p=h===o&&d===f?a:await createImageBitmap(a,{resizeWidth:h,resizeHeight:d,resizeQuality:"low"});w.transferFromImageBitmap(p),a.close();const y=await l.convertToBlob(g),v=y.type,b=await y.arrayBuffer(),m=n(b);if(p.close(),!r.has(t)&&await u===m)return r.set(t,m),i.postMessage({id:t});if(r.get(t)===m)return i.postMessage({id:t});i.postMessage({id:t,type:v,base64:m,width:o,height:f}),r.set(t,m)}};`;

function t(){const t=new Blob([r]);return URL.createObjectURL(t)}

class CanvasManager {
    reset() {
        this.pendingCanvasMutations.clear();
        this.restoreHandlers.forEach((handler) => {
            try {
                handler();
            }
            catch (e) {
            }
        });
        this.restoreHandlers = [];
        this.windowsSet = new WeakSet();
        this.windows = [];
        this.shadowDoms = new Set();
        _optionalChain([this, 'access', _ => _.worker, 'optionalAccess', _2 => _2.terminate, 'call', _3 => _3()]);
        this.worker = null;
        this.snapshotInProgressMap = new Map();
        if ((this.options.recordCanvas &&
            typeof this.options.sampling === 'number') ||
            this.options.enableManualSnapshot) {
            this.worker = this.initFPSWorker();
        }
    }
    freeze() {
        this.frozen = true;
    }
    unfreeze() {
        this.frozen = false;
    }
    lock() {
        this.locked = true;
    }
    unlock() {
        this.locked = false;
    }
    constructor(options) {
        this.pendingCanvasMutations = new Map();
        this.rafStamps = { latestId: 0, invokeId: null };
        this.shadowDoms = new Set();
        this.windowsSet = new WeakSet();
        this.windows = [];
        this.restoreHandlers = [];
        this.frozen = false;
        this.locked = false;
        this.snapshotInProgressMap = new Map();
        this.worker = null;
        this.processMutation = (target, mutation) => {
            const newFrame = this.rafStamps.invokeId &&
                this.rafStamps.latestId !== this.rafStamps.invokeId;
            if (newFrame || !this.rafStamps.invokeId)
                this.rafStamps.invokeId = this.rafStamps.latestId;
            if (!this.pendingCanvasMutations.has(target)) {
                this.pendingCanvasMutations.set(target, []);
            }
            this.pendingCanvasMutations.get(target).push(mutation);
        };
        const { sampling = 'all', win, blockClass, blockSelector, unblockSelector, maxCanvasSize, recordCanvas, dataURLOptions, errorHandler, } = options;
        this.mutationCb = options.mutationCb;
        this.mirror = options.mirror;
        this.options = options;
        if (errorHandler) {
            registerErrorHandler(errorHandler);
        }
        if ((recordCanvas && typeof sampling === 'number') ||
            options.enableManualSnapshot) {
            this.worker = this.initFPSWorker();
        }
        this.addWindow(win);
        if (options.enableManualSnapshot) {
            return;
        }
        callbackWrapper(() => {
            if (recordCanvas && sampling === 'all') {
                this.startRAFTimestamping();
                this.startPendingCanvasMutationFlusher();
            }
            if (recordCanvas && typeof sampling === 'number') {
                this.initCanvasFPSObserver(sampling, blockClass, blockSelector, unblockSelector, maxCanvasSize, {
                    dataURLOptions,
                });
            }
        })();
    }
    addWindow(win) {
        const { sampling = 'all', blockClass, blockSelector, unblockSelector, recordCanvas, enableManualSnapshot, } = this.options;
        if (this.windowsSet.has(win))
            return;
        if (enableManualSnapshot) {
            this.windowsSet.add(win);
            this.windows.push(new WeakRef(win));
            return;
        }
        callbackWrapper(() => {
            if (recordCanvas && sampling === 'all') {
                this.initCanvasMutationObserver(win, blockClass, blockSelector, unblockSelector);
            }
            if (recordCanvas && typeof sampling === 'number') {
                const canvasContextReset = initCanvasContextObserver(win, blockClass, blockSelector, unblockSelector, true);
                this.restoreHandlers.push(() => {
                    canvasContextReset();
                });
            }
        })();
        this.windowsSet.add(win);
        this.windows.push(new WeakRef(win));
    }
    addShadowRoot(shadowRoot) {
        this.shadowDoms.add(new WeakRef(shadowRoot));
    }
    resetShadowRoots() {
        this.shadowDoms = new Set();
    }
    initFPSWorker() {
        const worker = new Worker(t());
        worker.onmessage = (e) => {
            const data = e.data;
            const { id } = data;
            this.snapshotInProgressMap.set(id, false);
            if (!('base64' in data))
                return;
            const { base64, type, width, height } = data;
            this.mutationCb({
                id,
                type: CanvasContext['2D'],
                commands: [
                    {
                        property: 'clearRect',
                        args: [0, 0, width, height],
                    },
                    {
                        property: 'drawImage',
                        args: [
                            {
                                rr_type: 'ImageBitmap',
                                args: [
                                    {
                                        rr_type: 'Blob',
                                        data: [{ rr_type: 'ArrayBuffer', base64 }],
                                        type,
                                    },
                                ],
                            },
                            0,
                            0,
                            width,
                            height,
                        ],
                    },
                ],
            });
        };
        return worker;
    }
    initCanvasFPSObserver(fps, blockClass, blockSelector, unblockSelector, maxCanvasSize, options) {
        const rafId = this.takeSnapshot(false, fps, blockClass, blockSelector, unblockSelector, maxCanvasSize, options.dataURLOptions);
        this.restoreHandlers.push(() => {
            cancelAnimationFrame(rafId);
        });
    }
    initCanvasMutationObserver(win, blockClass, blockSelector, unblockSelector) {
        const canvasContextReset = initCanvasContextObserver(win, blockClass, blockSelector, unblockSelector, false);
        const canvas2DReset = initCanvas2DMutationObserver(this.processMutation.bind(this), win, blockClass, blockSelector, unblockSelector);
        const canvasWebGL1and2Reset = initCanvasWebGLMutationObserver(this.processMutation.bind(this), win, blockClass, blockSelector, unblockSelector, this.mirror);
        this.restoreHandlers.push(() => {
            canvasContextReset();
            canvas2DReset();
            canvasWebGL1and2Reset();
        });
    }
    snapshot(canvasElement) {
        const { options } = this;
        const rafId = this.takeSnapshot(true, options.sampling === 'all' ? 2 : options.sampling || 2, options.blockClass, options.blockSelector, options.unblockSelector, options.maxCanvasSize, options.dataURLOptions, canvasElement);
        this.restoreHandlers.push(() => {
            cancelAnimationFrame(rafId);
        });
    }
    takeSnapshot(isManualSnapshot, fps, blockClass, blockSelector, unblockSelector, maxCanvasSize, dataURLOptions, canvasElement) {
        const timeBetweenSnapshots = 1000 / fps;
        let lastSnapshotTime = 0;
        let rafId;
        const getCanvas = (canvasElement) => {
            if (canvasElement) {
                return [canvasElement];
            }
            const matchedCanvas = [];
            const searchCanvas = (root) => {
                root.querySelectorAll('canvas').forEach((canvas) => {
                    if (!isBlocked(canvas, blockClass, blockSelector, unblockSelector, true)) {
                        matchedCanvas.push(canvas);
                    }
                });
            };
            for (const item of this.windows) {
                const window = item.deref();
                if (window) {
                    searchCanvas(window.document);
                }
            }
            for (const item of this.shadowDoms) {
                const shadowRoot = item.deref();
                if (shadowRoot) {
                    searchCanvas(shadowRoot);
                }
            }
            return matchedCanvas;
        };
        const takeCanvasSnapshots = (timestamp) => {
            if (!this.windows.length) {
                return;
            }
            if (lastSnapshotTime &&
                timestamp - lastSnapshotTime < timeBetweenSnapshots) {
                rafId = onRequestAnimationFrame(takeCanvasSnapshots);
                return;
            }
            lastSnapshotTime = timestamp;
            getCanvas(canvasElement).forEach((canvas) => {
                if (!this.mirror.hasNode(canvas)) {
                    return;
                }
                const id = this.mirror.getId(canvas);
                if (this.snapshotInProgressMap.get(id))
                    return;
                if (!canvas.width || !canvas.height)
                    return;
                this.snapshotInProgressMap.set(id, true);
                if (!isManualSnapshot &&
                    ['webgl', 'webgl2'].includes(canvas.__context)) {
                    const context = canvas.getContext(canvas.__context);
                    if (_optionalChain([context, 'optionalAccess', _4 => _4.getContextAttributes, 'call', _5 => _5(), 'optionalAccess', _6 => _6.preserveDrawingBuffer]) === false) {
                        context.clear(context.COLOR_BUFFER_BIT);
                    }
                }
                createImageBitmap(canvas)
                    .then((bitmap) => {
                    _optionalChain([this, 'access', _7 => _7.worker, 'optionalAccess', _8 => _8.postMessage, 'call', _9 => _9({
                        id,
                        bitmap,
                        width: canvas.width,
                        height: canvas.height,
                        dataURLOptions,
                        maxCanvasSize,
                    }, [bitmap])]);
                })
                    .catch((error) => {
                    callbackWrapper(() => {
                        throw error;
                    })();
                });
            });
            if (!isManualSnapshot) {
                rafId = onRequestAnimationFrame(takeCanvasSnapshots);
            }
        };
        rafId = onRequestAnimationFrame(takeCanvasSnapshots);
        return rafId;
    }
    startPendingCanvasMutationFlusher() {
        onRequestAnimationFrame(() => this.flushPendingCanvasMutations());
    }
    startRAFTimestamping() {
        const setLatestRAFTimestamp = (timestamp) => {
            this.rafStamps.latestId = timestamp;
            onRequestAnimationFrame(setLatestRAFTimestamp);
        };
        onRequestAnimationFrame(setLatestRAFTimestamp);
    }
    flushPendingCanvasMutations() {
        this.pendingCanvasMutations.forEach((values, canvas) => {
            const id = this.mirror.getId(canvas);
            this.flushPendingCanvasMutationFor(canvas, id);
        });
        onRequestAnimationFrame(() => this.flushPendingCanvasMutations());
    }
    flushPendingCanvasMutationFor(canvas, id) {
        if (this.frozen || this.locked) {
            return;
        }
        const valuesWithType = this.pendingCanvasMutations.get(canvas);
        if (!valuesWithType || id === -1)
            return;
        const values = valuesWithType.map((value) => {
            const { type, ...rest } = value;
            return rest;
        });
        const { type } = valuesWithType[0];
        this.mutationCb({ id, type, commands: values });
        this.pendingCanvasMutations.delete(canvas);
    }
}

const CANVAS_QUALITY = {
  low: {
    sampling: {
      canvas: 1,
    },
    dataURLOptions: {
      type: 'image/webp',
      quality: 0.25,
    },
  },
  medium: {
    sampling: {
      canvas: 2,
    },
    dataURLOptions: {
      type: 'image/webp',
      quality: 0.4,
    },
  },
  high: {
    sampling: {
      canvas: 4,
    },
    dataURLOptions: {
      type: 'image/webp',
      quality: 0.5,
    },
  },
};

const INTEGRATION_NAME = 'ReplayCanvas';
const DEFAULT_MAX_CANVAS_SIZE = 1280;

/** Exported only for type safe tests. */
const _replayCanvasIntegration = ((options = {}) => {
  const [maxCanvasWidth, maxCanvasHeight] = options.maxCanvasSize || [];
  const _canvasOptions = {
    quality: options.quality || 'medium',
    enableManualSnapshot: options.enableManualSnapshot,
    maxCanvasSize: [
      maxCanvasWidth ? Math.min(maxCanvasWidth, DEFAULT_MAX_CANVAS_SIZE) : DEFAULT_MAX_CANVAS_SIZE,
      maxCanvasHeight ? Math.min(maxCanvasHeight, DEFAULT_MAX_CANVAS_SIZE) : DEFAULT_MAX_CANVAS_SIZE,
    ] ,
  };

  let canvasManagerResolve;
  const _canvasManager = new Promise(resolve => (canvasManagerResolve = resolve));

  return {
    name: INTEGRATION_NAME,
    getOptions() {
      const { quality, enableManualSnapshot, maxCanvasSize } = _canvasOptions;

      return {
        enableManualSnapshot,
        recordCanvas: true,
        getCanvasManager: (getCanvasManagerOptions) => {
          const manager = new CanvasManager({
            ...getCanvasManagerOptions,
            enableManualSnapshot,
            maxCanvasSize,
            errorHandler: (err) => {
              try {
                if (typeof err === 'object') {
                  (err ).__rrweb__ = true;
                }
              } catch (error) {
                // ignore errors here
                // this can happen if the error is frozen or does not allow mutation for other reasons
              }
            },
          });
          canvasManagerResolve(manager);
          return manager;
        },
        ...(CANVAS_QUALITY[quality || 'medium'] || CANVAS_QUALITY.medium),
      };
    },
    async snapshot(canvasElement) {
      const canvasManager = await _canvasManager;
      canvasManager.snapshot(canvasElement);
    },
  };
}) ;

/**
 * Add this in addition to `replayIntegration()` to enable canvas recording.
 */
const replayCanvasIntegration = defineIntegration(
  _replayCanvasIntegration,
) ;

export { replayCanvasIntegration };
//# sourceMappingURL=index.js.map
