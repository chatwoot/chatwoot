import { __read, __spread } from "tslib";
import { isPrimitive } from './is';
/**
 * Creates an envelope.
 * Make sure to always explicitly provide the generic to this function
 * so that the envelope types resolve correctly.
 */
export function createEnvelope(headers, items) {
    if (items === void 0) { items = []; }
    return [headers, items];
}
/**
 * Add an item to an envelope.
 * Make sure to always explicitly provide the generic to this function
 * so that the envelope types resolve correctly.
 */
export function addItemToEnvelope(envelope, newItem) {
    var _a = __read(envelope, 2), headers = _a[0], items = _a[1];
    return [headers, __spread(items, [newItem])];
}
/**
 * Get the type of the envelope. Grabs the type from the first envelope item.
 */
export function getEnvelopeType(envelope) {
    var _a = __read(envelope, 2), _b = __read(_a[1], 1), _c = __read(_b[0], 1), firstItemHeader = _c[0];
    return firstItemHeader.type;
}
/**
 * Serializes an envelope into a string.
 */
export function serializeEnvelope(envelope) {
    var _a = __read(envelope, 2), headers = _a[0], items = _a[1];
    var serializedHeaders = JSON.stringify(headers);
    // Have to cast items to any here since Envelope is a union type
    // Fixed in Typescript 4.2
    // TODO: Remove any[] cast when we upgrade to TS 4.2
    // https://github.com/microsoft/TypeScript/issues/36390
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return items.reduce(function (acc, item) {
        var _a = __read(item, 2), itemHeaders = _a[0], payload = _a[1];
        // We do not serialize payloads that are primitives
        var serializedPayload = isPrimitive(payload) ? String(payload) : JSON.stringify(payload);
        return acc + "\n" + JSON.stringify(itemHeaders) + "\n" + serializedPayload;
    }, serializedHeaders);
}
//# sourceMappingURL=envelope.js.map