'use strict';
var $ = require('../internals/export');
var uncurryThis = require('../internals/function-uncurry-this');
var aDataView = require('../internals/a-data-view');
var toIndex = require('../internals/to-index');
var packIEEE754 = require('../internals/ieee754').pack;
var f16round = require('../internals/math-f16round');

// eslint-disable-next-line es/no-typed-arrays -- safe
var setUint16 = uncurryThis(DataView.prototype.setUint16);

// `DataView.prototype.setFloat16` method
// https://github.com/tc39/proposal-float16array
$({ target: 'DataView', proto: true }, {
  setFloat16: function setFloat16(byteOffset, value /* , littleEndian */) {
    aDataView(this);
    var offset = toIndex(byteOffset);
    var bytes = packIEEE754(f16round(value), 10, 2);
    return setUint16(this, offset, bytes[1] << 8 | bytes[0], arguments.length > 2 ? arguments[2] : false);
  }
});
