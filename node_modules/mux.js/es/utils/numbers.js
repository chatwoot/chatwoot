var MAX_UINT32 = Math.pow(2, 32);

var getUint64 = function getUint64(uint8) {
  var dv = new DataView(uint8.buffer, uint8.byteOffset, uint8.byteLength);
  var value;

  if (dv.getBigUint64) {
    value = dv.getBigUint64(0);

    if (value < Number.MAX_SAFE_INTEGER) {
      return Number(value);
    }

    return value;
  }

  return dv.getUint32(0) * MAX_UINT32 + dv.getUint32(4);
};

module.exports = {
  getUint64: getUint64,
  MAX_UINT32: MAX_UINT32
};