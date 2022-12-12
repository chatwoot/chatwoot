export var OPUS_HEAD = new Uint8Array([// O, p, u, s
0x4f, 0x70, 0x75, 0x73, // H, e, a, d
0x48, 0x65, 0x61, 0x64]); // https://wiki.xiph.org/OggOpus
// https://vfrmaniac.fushizen.eu/contents/opus_in_isobmff.html
// https://opus-codec.org/docs/opusfile_api-0.7/structOpusHead.html

export var parseOpusHead = function parseOpusHead(bytes) {
  var view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  var version = view.getUint8(0); // version 0, from mp4, does not use littleEndian.

  var littleEndian = version !== 0;
  var config = {
    version: version,
    channels: view.getUint8(1),
    preSkip: view.getUint16(2, littleEndian),
    sampleRate: view.getUint32(4, littleEndian),
    outputGain: view.getUint16(8, littleEndian),
    channelMappingFamily: view.getUint8(10)
  };

  if (config.channelMappingFamily > 0 && bytes.length > 10) {
    config.streamCount = view.getUint8(11);
    config.twoChannelStreamCount = view.getUint8(12);
    config.channelMapping = [];

    for (var c = 0; c < config.channels; c++) {
      config.channelMapping.push(view.getUint8(13 + c));
    }
  }

  return config;
};
export var setOpusHead = function setOpusHead(config) {
  var size = config.channelMappingFamily <= 0 ? 11 : 12 + config.channels;
  var view = new DataView(new ArrayBuffer(size));
  var littleEndian = config.version !== 0;
  view.setUint8(0, config.version);
  view.setUint8(1, config.channels);
  view.setUint16(2, config.preSkip, littleEndian);
  view.setUint32(4, config.sampleRate, littleEndian);
  view.setUint16(8, config.outputGain, littleEndian);
  view.setUint8(10, config.channelMappingFamily);

  if (config.channelMappingFamily > 0) {
    view.setUint8(11, config.streamCount);
    config.channelMapping.foreach(function (cm, i) {
      view.setUint8(12 + i, cm);
    });
  }

  return new Uint8Array(view.buffer);
};