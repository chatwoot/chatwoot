Object.defineProperty(exports, "__esModule", { value: true });
var tslib_1 = require("tslib");
var is_1 = require("./is");
/**
 * Creates an envelope.
 * Make sure to always explicitly provide the generic to this function
 * so that the envelope types resolve correctly.
 */
function createEnvelope(headers, items) {
    if (items === void 0) { items = []; }
    return [headers, items];
}
exports.createEnvelope = createEnvelope;
/**
 * Add an item to an envelope.
 * Make sure to always explicitly provide the generic to this function
 * so that the envelope types resolve correctly.
 */
function addItemToEnvelope(envelope, newItem) {
    var _a = tslib_1.__read(envelope, 2), headers = _a[0], items = _a[1];
    return [headers, tslib_1.__spread(items, [newItem])];
}
exports.addItemToEnvelope = addItemToEnvelope;
/**
 * Get the type of the envelope. Grabs the type from the first envelope item.
 */
function getEnvelopeType(envelope) {
    var _a = tslib_1.__read(envelope, 2), _b = tslib_1.__read(_a[1], 1), _c = tslib_1.__read(_b[0], 1), firstItemHeader = _c[0];
    return firstItemHeader.type;
}
exports.getEnvelopeType = getEnvelopeType;
/**
 * Serializes an envelope into a string.
 */
function serializeEnvelope(envelope) {
    var _a = tslib_1.__read(envelope, 2), headers = _a[0], items = _a[1];
    var serializedHeaders = JSON.stringify(headers);
    // Have to cast items to any here since Envelope is a union type
    // Fixed in Typescript 4.2
    // TODO: Remove any[] cast when we upgrade to TS 4.2
    // https://github.com/microsoft/TypeScript/issues/36390
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    return items.reduce(function (acc, item) {
        var _a = tslib_1.__read(item, 2), itemHeaders = _a[0], payload = _a[1];
        // We do not serialize payloads that are primitives
        var serializedPayload = is_1.isPrimitive(payload) ? String(payload) : JSON.stringify(payload);
        return acc + "\n" + JSON.stringify(itemHeaders) + "\n" + serializedPayload;
    }, serializedHeaders);
}
exports.serializeEnvelope = serializeEnvelope;
//# sourceMappingURL=envelope.js.map