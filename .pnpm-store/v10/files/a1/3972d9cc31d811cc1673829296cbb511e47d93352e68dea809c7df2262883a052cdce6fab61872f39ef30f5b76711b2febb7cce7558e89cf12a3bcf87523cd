export * from "./bucketed-rate-limiter.mjs";
export * from "./number-utils.mjs";
export * from "./string-utils.mjs";
export * from "./type-utils.mjs";
const STRING_FORMAT = 'utf8';
function assert(truthyValue, message) {
    if (!truthyValue || 'string' != typeof truthyValue || isEmpty(truthyValue)) throw new Error(message);
}
function isEmpty(truthyValue) {
    if (0 === truthyValue.trim().length) return true;
    return false;
}
function removeTrailingSlash(url) {
    return null == url ? void 0 : url.replace(/\/+$/, '');
}
async function retriable(fn, props) {
    let lastError = null;
    for(let i = 0; i < props.retryCount + 1; i++){
        if (i > 0) await new Promise((r)=>setTimeout(r, props.retryDelay));
        try {
            const res = await fn();
            return res;
        } catch (e) {
            lastError = e;
            if (!props.retryCheck(e)) throw e;
        }
    }
    throw lastError;
}
function currentTimestamp() {
    return new Date().getTime();
}
function currentISOTime() {
    return new Date().toISOString();
}
function safeSetTimeout(fn, timeout) {
    const t = setTimeout(fn, timeout);
    (null == t ? void 0 : t.unref) && (null == t || t.unref());
    return t;
}
const isPromise = (obj)=>obj && 'function' == typeof obj.then;
const isError = (x)=>x instanceof Error;
function getFetch() {
    return 'undefined' != typeof fetch ? fetch : void 0 !== globalThis.fetch ? globalThis.fetch : void 0;
}
function allSettled(promises) {
    return Promise.all(promises.map((p)=>(null != p ? p : Promise.resolve()).then((value)=>({
                status: 'fulfilled',
                value
            }), (reason)=>({
                status: 'rejected',
                reason
            }))));
}
export { STRING_FORMAT, allSettled, assert, currentISOTime, currentTimestamp, getFetch, isError, isPromise, removeTrailingSlash, retriable, safeSetTimeout };
