/**
 * @file browser-shim.js
 * @since 2.0.0
 */

const setSrcObject = function (stream, element) {
    if ('srcObject' in element) {
        element.srcObject = stream;
    } else if ('mozSrcObject' in element) {
        element.mozSrcObject = stream;
    } else {
        element.srcObject = stream;
    }
};

export default setSrcObject;
