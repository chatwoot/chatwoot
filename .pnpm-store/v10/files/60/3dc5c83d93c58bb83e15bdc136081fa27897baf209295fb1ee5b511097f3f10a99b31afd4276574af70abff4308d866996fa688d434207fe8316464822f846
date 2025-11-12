var tfhd = function(data) {
  var
  view = new DataView(data.buffer, data.byteOffset, data.byteLength),
    result = {
      version: data[0],
      flags: new Uint8Array(data.subarray(1, 4)),
      trackId: view.getUint32(4)
    },
    baseDataOffsetPresent = result.flags[2] & 0x01,
    sampleDescriptionIndexPresent = result.flags[2] & 0x02,
    defaultSampleDurationPresent = result.flags[2] & 0x08,
    defaultSampleSizePresent = result.flags[2] & 0x10,
    defaultSampleFlagsPresent = result.flags[2] & 0x20,
    durationIsEmpty = result.flags[0] & 0x010000,
    defaultBaseIsMoof =  result.flags[0] & 0x020000,
    i;

  i = 8;
  if (baseDataOffsetPresent) {
    i += 4; // truncate top 4 bytes
    // FIXME: should we read the full 64 bits?
    result.baseDataOffset = view.getUint32(12);
    i += 4;
  }
  if (sampleDescriptionIndexPresent) {
    result.sampleDescriptionIndex = view.getUint32(i);
    i += 4;
  }
  if (defaultSampleDurationPresent) {
    result.defaultSampleDuration = view.getUint32(i);
    i += 4;
  }
  if (defaultSampleSizePresent) {
    result.defaultSampleSize = view.getUint32(i);
    i += 4;
  }
  if (defaultSampleFlagsPresent) {
    result.defaultSampleFlags = view.getUint32(i);
  }
  if (durationIsEmpty) {
    result.durationIsEmpty = true;
  }
  if (!baseDataOffsetPresent && defaultBaseIsMoof) {
    result.baseDataOffsetIsMoof = true;
  }
  return result;
};

module.exports = tfhd;
