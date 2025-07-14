'use strict';

var segments = require('data-files!segments');

var mp2t = require('../lib/m2ts'),
    codecs = require('../lib/codecs'),
    flv = require('../lib/flv'),
    id3Generator = require('./utils/id3-generator'),
    mp4 = require('../lib/mp4'),
    QUnit = require('qunit'),
    testSegment = segments['test-segment.ts'](),
    testMiddlePatPMT = segments['test-middle-pat-pmt.ts'](),
    mp4Transmuxer = require('../lib/mp4/transmuxer'),
    mp4AudioProperties = mp4Transmuxer.AUDIO_PROPERTIES,
    mp4VideoProperties = mp4Transmuxer.VIDEO_PROPERTIES,
    generateSegmentTimingInfo = mp4Transmuxer.generateSegmentTimingInfo,
    clock = require('../lib/utils/clock'),
    utils = require('./utils'),
    TransportPacketStream = mp2t.TransportPacketStream,
    transportPacketStream,
    TransportParseStream = mp2t.TransportParseStream,
    transportParseStream,
    ElementaryStream = mp2t.ElementaryStream,
    elementaryStream,
    TimestampRolloverStream = mp2t.TimestampRolloverStream,
    timestampRolloverStream,
    H264Stream = codecs.h264.H264Stream,
    h264Stream,

    VideoSegmentStream = mp4.VideoSegmentStream,
    videoSegmentStream,
    AudioSegmentStream = mp4.AudioSegmentStream,
    audioSegmentStream,

    AdtsStream = codecs.Adts,
    adtsStream,
    Transmuxer = mp4.Transmuxer,
    FlvTransmuxer = flv.Transmuxer,
    transmuxer,
    NalByteStream = codecs.h264.NalByteStream,
    nalByteStream,

    H264_STREAM_TYPE = mp2t.H264_STREAM_TYPE,
    ADTS_STREAM_TYPE = mp2t.ADTS_STREAM_TYPE,
    METADATA_STREAM_TYPE = mp2t.METADATA_STREAM_TYPE,

    validateTrack,
    validateTrackFragment,

    PMT = utils.PMT,
    PAT = utils.PAT,
    generatePMT = utils.generatePMT,
    pesHeader = utils.pesHeader,
    packetize = utils.packetize,
    videoPes = utils.videoPes,
    adtsFrame = utils.adtsFrame,
    audioPes = utils.audioPes,
    timedMetadataPes = utils.timedMetadataPes;

mp4.tools = require('../lib/tools/mp4-inspector');

QUnit.module('MP2T Packet Stream', {
  beforeEach: function() {
    transportPacketStream = new TransportPacketStream();
  }
});
QUnit.test('tester', function(assert) {
  assert.ok(true, 'did not throw');
});
QUnit.test('empty input does not error', function(assert) {
  transportPacketStream.push(new Uint8Array([]));
  assert.ok(true, 'did not throw');
});
QUnit.test('parses a generic packet', function(assert) {
  var
    datas = [],
    packet = new Uint8Array(188);

  packet[0] = 0x47; // Sync-byte

  transportPacketStream.on('data', function(event) {
    datas.push(event);
  });
  transportPacketStream.push(packet);
  transportPacketStream.flush();

  assert.equal(1, datas.length, 'fired one event');
  assert.equal(datas[0].byteLength, 188, 'delivered the packet');
});

QUnit.test('buffers partial packets', function(assert) {
  var
    datas = [],
    partialPacket1 = new Uint8Array(187),
    partialPacket2 = new Uint8Array(189);

  partialPacket1[0] = 0x47; // Sync-byte
  partialPacket2[1] = 0x47; // Sync-byte

  transportPacketStream.on('data', function(event) {
    datas.push(event);
  });
  transportPacketStream.push(partialPacket1);

  assert.equal(0, datas.length, 'did not fire an event');

  transportPacketStream.push(partialPacket2);
  transportPacketStream.flush();

  assert.equal(2, datas.length, 'fired events');
  assert.equal(188, datas[0].byteLength, 'parsed the first packet');
  assert.equal(188, datas[1].byteLength, 'parsed the second packet');
});

QUnit.test('parses multiple packets delivered at once', function(assert) {
  var datas = [], packetStream = new Uint8Array(188 * 3);

  packetStream[0] = 0x47; // Sync-byte
  packetStream[188] = 0x47; // Sync-byte
  packetStream[376] = 0x47; // Sync-byte

  transportPacketStream.on('data', function(event) {
    datas.push(event);
  });

  transportPacketStream.push(packetStream);
  transportPacketStream.flush();

  assert.equal(3, datas.length, 'fired three events');
  assert.equal(188, datas[0].byteLength, 'parsed the first packet');
  assert.equal(188, datas[1].byteLength, 'parsed the second packet');
  assert.equal(188, datas[2].byteLength, 'parsed the third packet');
});

QUnit.test('resyncs packets', function(assert) {
  var datas = [], packetStream = new Uint8Array(188 * 3 - 2);

  packetStream[0] = 0x47; // Sync-byte
  packetStream[186] = 0x47; // Sync-byte
  packetStream[374] = 0x47; // Sync-byte

  transportPacketStream.on('data', function(event) {
    datas.push(event);
  });

  transportPacketStream.push(packetStream);
  transportPacketStream.flush();

  assert.equal(datas.length, 2, 'fired three events');
  assert.equal(datas[0].byteLength, 188, 'parsed the first packet');
  assert.equal(datas[1].byteLength, 188, 'parsed the second packet');
});

QUnit.test('buffers extra after multiple packets', function(assert) {
  var datas = [], packetStream = new Uint8Array(188 * 2 + 10);

  packetStream[0] = 0x47; // Sync-byte
  packetStream[188] = 0x47; // Sync-byte
  packetStream[376] = 0x47; // Sync-byte

  transportPacketStream.on('data', function(event) {
    datas.push(event);
  });

  transportPacketStream.push(packetStream);
  assert.equal(2, datas.length, 'fired three events');
  assert.equal(188, datas[0].byteLength, 'parsed the first packet');
  assert.equal(188, datas[1].byteLength, 'parsed the second packet');

  transportPacketStream.push(new Uint8Array(178));
  transportPacketStream.flush();

  assert.equal(3, datas.length, 'fired a final event');
  assert.equal(188, datas[2].length, 'parsed the finel packet');
});

QUnit.module('MP2T TransportParseStream', {
  beforeEach: function() {
    transportPacketStream = new TransportPacketStream();
    transportParseStream = new TransportParseStream();

    transportPacketStream.pipe(transportParseStream);
  }
});

QUnit.test('parses generic packet properties', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });

  transportParseStream.push(packetize(PAT));
  transportParseStream.push(packetize(generatePMT({})));
  transportParseStream.push(new Uint8Array([
    0x47, // sync byte
    // tei:0 pusi:1 tp:0 pid:0 0000 0000 0001 tsc:01 afc:10 cc:11 padding: 00
    0x40, 0x01, 0x6c
  ]));

  assert.ok(packet.payloadUnitStartIndicator, 'parsed payload_unit_start_indicator');
  assert.ok(packet.pid, 'parsed PID');
});

QUnit.test('parses piped data events', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });

  transportParseStream.push(packetize(PAT));
  transportParseStream.push(packetize(generatePMT({})));
  transportParseStream.push(new Uint8Array([
    0x47, // sync byte
    // tei:0 pusi:1 tp:0 pid:0 0000 0000 0001 tsc:01 afc:10 cc:11 padding: 00
    0x40, 0x01, 0x6c
  ]));

  assert.ok(packet, 'parsed a packet');
});

QUnit.test('parses a data packet with adaptation fields', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });

  transportParseStream.push(new Uint8Array([
    0x47, // sync byte
    // tei:0 pusi:1 tp:0 pid:0 0000 0000 0000 tsc:01 afc:10 cc:11 afl:00 0000 00 stuffing:00 0000 00 pscp:00 0001 padding:0000
    0x40, 0x00, 0x6c, 0x00, 0x00, 0x10
  ]));
  assert.strictEqual(packet.type, 'pat', 'parsed the packet type');
});

QUnit.test('parses a PES packet', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });

  // setup a program map table
  transportParseStream.programMapTable = {
    video: 0x0010,
    'timed-metadata': {}
  };

  transportParseStream.push(new Uint8Array([
    0x47, // sync byte
    // tei:0 pusi:1 tp:0 pid:0 0000 0000 0010 tsc:01 afc:01 cc:11 padding:00
    0x40, 0x02, 0x5c
  ]));
  assert.strictEqual(packet.type, 'pes', 'parsed a PES packet');
});

QUnit.test('parses packets with variable length adaptation fields and a payload', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });

  // setup a program map table
  transportParseStream.programMapTable = {
    video: 0x0010,
    'timed-metadata': {}
  };

  transportParseStream.push(new Uint8Array([
    0x47, // sync byte
    // tei:0 pusi:1 tp:0 pid:0 0000 0000 0010 tsc:01 afc:11 cc:11 afl:00 0000 11 stuffing:00 0000 0000 00 pscp:00 0001
    0x40, 0x02, 0x7c, 0x0c, 0x00, 0x01
  ]));
  assert.strictEqual(packet.type, 'pes', 'parsed a PES packet');
});

QUnit.test('parses the program map table pid from the program association table (PAT)', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });

  transportParseStream.push(new Uint8Array(PAT));
  assert.ok(packet, 'parsed a packet');
  assert.strictEqual(0x0010, transportParseStream.pmtPid, 'parsed PMT pid');
});

QUnit.test('does not parse PES packets until after the PES has been parsed', function(assert) {
  var pesCount = 0;

  transportParseStream.on('data', function(data) {
    if (data.type === 'pmt') {
      assert.equal(pesCount, 0, 'have not yet parsed any PES packets');
    } else if (data.type === 'pes') {
      pesCount++;
    }
  });

  transportPacketStream.push(testMiddlePatPMT);
});

QUnit.test('parse the elementary streams from a program map table', function(assert) {
  var packet;
  transportParseStream.on('data', function(data) {
    packet = data;
  });
  transportParseStream.pmtPid = 0x0010;

  transportParseStream.push(new Uint8Array(PMT.concat(0, 0, 0, 0, 0)));

  assert.ok(packet, 'parsed a packet');
  assert.ok(transportParseStream.programMapTable, 'parsed a program map');
  assert.strictEqual(transportParseStream.programMapTable.video, 0x11, 'associated h264 with pid 0x11');
  assert.strictEqual(transportParseStream.programMapTable.audio, 0x12, 'associated adts with pid 0x12');
  assert.deepEqual(transportParseStream.programMapTable, packet.programMapTable, 'recorded the PMT');
});

QUnit.module('MP2T ElementaryStream', {
  beforeEach: function() {
    elementaryStream = new ElementaryStream();
  }
});

QUnit.test('parses metadata events from PSI packets', function(assert) {
  var
    metadatas = [],
    datas = 0,
    sortById = function(left, right) {
      return left.id - right.id;
    };
  elementaryStream.on('data', function(data) {
    if (data.type === 'metadata') {
      metadatas.push(data);
    }
    datas++;
  });
  elementaryStream.push({
    type: 'pat'
  });
  elementaryStream.push({
    type: 'pmt',
    programMapTable: {
      video: 1,
      audio: 2,
      'timed-metadata': {}
    }
  });

  assert.equal(1, datas, 'data fired');
  assert.equal(1, metadatas.length, 'metadata generated');
  metadatas[0].tracks.sort(sortById);
  assert.deepEqual(metadatas[0].tracks, [{
    id: 1,
    codec: 'avc',
    type: 'video',
    timelineStartInfo: {
      baseMediaDecodeTime: 0
    }
  }, {
    id: 2,
    codec: 'adts',
    type: 'audio',
    timelineStartInfo: {
      baseMediaDecodeTime: 0
    }
  }], 'identified two tracks');
});

QUnit.test('parses standalone program stream packets', function(assert) {
  var
    packets = [],
    packetData = [0x01, 0x02],
    pesHead = pesHeader(false, 7, 2);

  elementaryStream.on('data', function(packet) {
    packets.push(packet);
  });
  elementaryStream.push({
    type: 'pes',
    streamType: ADTS_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHead.concat(packetData))
  });
  elementaryStream.flush();

  assert.equal(packets.length, 1, 'built one packet');
  assert.equal(packets[0].type, 'audio', 'identified audio data');
  assert.equal(packets[0].data.byteLength, packetData.length, 'parsed the correct payload size');
  assert.equal(packets[0].pts, 7, 'correctly parsed the pts value');
});

QUnit.test('aggregates program stream packets from the transport stream', function(assert) {
  var
    events = [],
    packetData = [0x01, 0x02],
    pesHead = pesHeader(false, 7);

  elementaryStream.on('data', function(event) {
    events.push(event);
  });

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHead.slice(0, 4)) // Spread PES Header across packets
  });

  assert.equal(events.length, 0, 'buffers partial packets');

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(pesHead.slice(4).concat(packetData))
  });
  elementaryStream.flush();

  assert.equal(events.length, 1, 'built one packet');
  assert.equal(events[0].type, 'video', 'identified video data');
  assert.equal(events[0].pts, 7, 'correctly parsed the pts');
  assert.equal(events[0].data.byteLength, packetData.length, 'concatenated transport packets');
});

QUnit.test('aggregates program stream packets from the transport stream with no header data', function(assert) {
  var events = []

  elementaryStream.on('data', function(event) {
    events.push(event);
  });

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array([0x1, 0x2, 0x3])
  });

  assert.equal(events.length, 0, 'buffers partial packets');

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array([0x4, 0x5, 0x6])
  });

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array([0x7, 0x8, 0x9])
  });
  elementaryStream.flush();

  assert.equal(events.length, 1, 'built one packet');
  assert.equal(events[0].type, 'video', 'identified video data');
  assert.equal(events[0].data.byteLength, 0, 'empty packet');
});

QUnit.test('parses an elementary stream packet with just a pts', function(assert) {
  var packet;
  elementaryStream.on('data', function(data) {
    packet = data;
  });

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array([
      // pscp:0000 0000 0000 0000 0000 0001
      0x00, 0x00, 0x01,
      // sid:0000 0000 ppl:0000 0000 0000 1001
      0x00, 0x00, 0x09,
      // 10 psc:00 pp:0 dai:1 c:0 ooc:0
      0x84,
      // pdf:10 ef:1 erf:0 dtmf:0 acif:0 pcf:0 pef:0
      0xc0,
      // phdl:0000 0101 '0010' pts:111 mb:1 pts:1111 1111
      0x05, 0xFF, 0xFF,
      // pts:1111 111 mb:1 pts:1111 1111 pts:1111 111 mb:1
      0xFF, 0xFF, 0xFF,
      // "data":0101
      0x11
    ])
  });
  elementaryStream.flush();

  assert.ok(packet, 'parsed a packet');
  assert.equal(packet.data.byteLength, 1, 'parsed a single data byte');
  assert.equal(packet.data[0], 0x11, 'parsed the data');
  // 2^33-1 is the maximum value of a 33-bit unsigned value
  assert.equal(packet.pts, Math.pow(2, 33) - 1, 'parsed the pts');
});

QUnit.test('parses an elementary stream packet with a pts and dts', function(assert) {
  var packet;
  elementaryStream.on('data', function(data) {
    packet = data;
  });

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array([
      // pscp:0000 0000 0000 0000 0000 0001
      0x00, 0x00, 0x01,
      // sid:0000 0000 ppl:0000 0000 0000 1110
      0x00, 0x00, 0x0e,
      // 10 psc:00 pp:0 dai:1 c:0 ooc:0
      0x84,
      // pdf:11 ef:1 erf:0 dtmf:0 acif:0 pcf:0 pef:0
      0xe0,
      // phdl:0000 1010 '0011' pts:000 mb:1 pts:0000 0000
      0x0a, 0x21, 0x00,
      // pts:0000 000 mb:1 pts:0000 0000 pts:0000 100 mb:1
      0x01, 0x00, 0x09,
      // '0001' dts:000 mb:1 dts:0000 0000 dts:0000 000 mb:1
      0x11, 0x00, 0x01,
      // dts:0000 0000 dts:0000 010 mb:1
      0x00, 0x05,
      // "data":0101
      0x11
    ])
  });
  elementaryStream.flush();

  assert.ok(packet, 'parsed a packet');
  assert.equal(packet.data.byteLength, 1, 'parsed a single data byte');
  assert.equal(packet.data[0], 0x11, 'parsed the data');
  assert.equal(packet.pts, 4, 'parsed the pts');
  assert.equal(packet.dts, 2, 'parsed the dts');
});

QUnit.test('parses an elementary stream packet without a pts or dts', function(assert) {
  var packet;
  elementaryStream.on('data', function(data) {
    packet = data;
  });

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHeader().concat([0xaf, 0x01]))
  });
  elementaryStream.flush();

  assert.ok(packet, 'parsed a packet');
  assert.equal(packet.data.byteLength, 2, 'parsed two data bytes');
  assert.equal(packet.data[0], 0xaf, 'parsed the first data byte');
  assert.equal(packet.data[1], 0x01, 'parsed the second data byte');
  assert.ok(!packet.pts, 'did not parse a pts');
  assert.ok(!packet.dts, 'did not parse a dts');
});

QUnit.test('won\'t emit non-video packets if the PES_packet_length is larger than the contents', function(assert) {
  var events = [];
  var pesHead = pesHeader(false, 1, 5);

  elementaryStream.on('data', function(event) {
    events.push(event);
  });

  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1]))
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: ADTS_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1]))
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: METADATA_STREAM_TYPE,
    // data larger than 5 byte dataLength, should still emit event
    data: new Uint8Array(pesHead.concat([1, 1, 1, 1, 1, 1, 1, 1, 1]))
  });

  assert.equal(0, events.length, 'buffers partial packets');

  elementaryStream.flush();
  assert.equal(events.length, 2, 'emitted 2 packets');
  assert.equal(events[0].type, 'video', 'identified video data');
  assert.equal(events[1].type, 'timed-metadata', 'identified timed-metadata');
});

QUnit.test('buffers audio and video program streams individually', function(assert) {
  var events = [];
  var pesHead = pesHeader(false, 1, 2);

  elementaryStream.on('data', function(event) {
    events.push(event);
  });

  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1]))
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: ADTS_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1]))
  });
  assert.equal(0, events.length, 'buffers partial packets');

  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(1)
  });
  elementaryStream.push({
    type: 'pes',
    streamType: ADTS_STREAM_TYPE,
    data: new Uint8Array(1)
  });
  elementaryStream.flush();
  assert.equal(2, events.length, 'parsed a complete packet');
  assert.equal('video', events[0].type, 'identified video data');
  assert.equal('audio', events[1].type, 'identified audio data');
});

QUnit.test('flushes the buffered packets when a new one of that type is started', function(assert) {
  var packets = [];
  var pesHead = pesHeader(false, 1, 2);

  elementaryStream.on('data', function(packet) {
    packets.push(packet);
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1]))
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: ADTS_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1, 2]))
  });
  elementaryStream.push({
    type: 'pes',
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(1)
  });
  assert.equal(packets.length, 0, 'buffers packets by type');

  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: H264_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([1]))
  });
  assert.equal(packets.length, 1, 'built one packet');
  assert.equal(packets[0].type, 'video', 'identified video data');
  assert.equal(packets[0].data.byteLength, 2, 'concatenated packets');

  elementaryStream.flush();
  assert.equal(packets.length, 3, 'built two more packets');
  assert.equal(packets[1].type, 'video', 'identified video data');
  assert.equal(packets[1].data.byteLength, 1, 'parsed the video payload');
  assert.equal(packets[2].type, 'audio', 'identified audio data');
  assert.equal(packets[2].data.byteLength, 2, 'parsed the audio payload');
});

QUnit.test('buffers and emits timed-metadata', function(assert) {
  var packets = [];
  var pesHead = pesHeader(false, 1, 4);

  elementaryStream.on('data', function(packet) {
    packets.push(packet);
  });

  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: METADATA_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([0, 1]))
  });
  elementaryStream.push({
    type: 'pes',
    streamType: METADATA_STREAM_TYPE,
    data: new Uint8Array([2, 3])
  });
  assert.equal(packets.length, 0, 'buffers metadata until the next start indicator');

  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    streamType: METADATA_STREAM_TYPE,
    data: new Uint8Array(pesHead.concat([4, 5]))
  });
  elementaryStream.push({
    type: 'pes',
    streamType: METADATA_STREAM_TYPE,
    data: new Uint8Array([6, 7])
  });
  assert.equal(packets.length, 1, 'built a packet');
  assert.equal(packets[0].type, 'timed-metadata', 'identified timed-metadata');
  assert.deepEqual(packets[0].data, new Uint8Array([0, 1, 2, 3]), 'concatenated the data');

  elementaryStream.flush();
  assert.equal(packets.length, 2, 'flushed a packet');
  assert.equal(packets[1].type, 'timed-metadata', 'identified timed-metadata');
  assert.deepEqual(packets[1].data, new Uint8Array([4, 5, 6, 7]), 'included the data');
});

QUnit.test('drops packets with unknown stream types', function(assert) {
  var packets = [];
  elementaryStream.on('data', function(packet) {
    packets.push(packet);
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    data: new Uint8Array(1)
  });
  elementaryStream.push({
    type: 'pes',
    payloadUnitStartIndicator: true,
    data: new Uint8Array(1)
  });

  assert.equal(packets.length, 0, 'ignored unknown packets');
});

QUnit.module('MP2T TimestampRolloverStream', {
  beforeEach: function() {
    timestampRolloverStream = new TimestampRolloverStream('audio');
    elementaryStream = new ElementaryStream();
    elementaryStream.pipe(timestampRolloverStream);
  }
});

QUnit.test('Correctly parses rollover PTS', function(assert) {
  var
    maxTS = 8589934592,
    packets = [],
    packetData = [0x01, 0x02],
    pesHeadOne = pesHeader(false, maxTS - 400, 2),
    pesHeadTwo = pesHeader(false, maxTS - 100, 2),
    pesHeadThree = pesHeader(false, maxTS, 2),
    pesHeadFour = pesHeader(false, 50, 2);

  timestampRolloverStream.on('data', function(packet) {
    packets.push(packet);
  });
  elementaryStream.push({
    type: 'pes',
    streamType: ADTS_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHeadOne.concat(packetData))
  });
  elementaryStream.push({
    type: 'pes',
    streamType: ADTS_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHeadTwo.concat(packetData))
  });
  elementaryStream.push({
    type: 'pes',
    streamType: ADTS_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHeadThree.concat(packetData))
  });
  elementaryStream.push({
    type: 'pes',
    streamType: ADTS_STREAM_TYPE,
    payloadUnitStartIndicator: true,
    data: new Uint8Array(pesHeadFour.concat(packetData))
  });
  elementaryStream.flush();

  assert.equal(packets.length, 4, 'built four packets');
  assert.equal(packets[0].type, 'audio', 'identified audio data');
  assert.equal(packets[0].data.byteLength, packetData.length, 'parsed the correct payload size');
  assert.equal(packets[0].pts, maxTS - 400, 'correctly parsed the pts value');
  assert.equal(packets[1].pts, maxTS - 100, 'Does not rollover on minor change');
  assert.equal(packets[2].pts, maxTS, 'correctly parses the max pts value');
  assert.equal(packets[3].pts, maxTS + 50, 'correctly parsed the rollover pts value');
});

QUnit.test('Correctly parses multiple PTS rollovers', function(assert) {
  var
    maxTS = 8589934592,
    packets = [],
    packetData = [0x01, 0x02],
    pesArray = [pesHeader(false, 1, 2),
                pesHeader(false, Math.floor(maxTS * (1 / 3)), 2),
                pesHeader(false, Math.floor(maxTS * (2 / 3)), 2),
                pesHeader(false, 1, 2),
                pesHeader(false, Math.floor(maxTS * (1 / 3)), 2),
                pesHeader(false, Math.floor(maxTS * (2 / 3)), 2),
                pesHeader(false, 1, 2),
                pesHeader(false, Math.floor(maxTS * (1 / 3)), 2),
                pesHeader(false, Math.floor(maxTS * (2 / 3)), 2),
                pesHeader(false, 1, 2)];

  timestampRolloverStream.on('data', function(packet) {
    packets.push(packet);
  });

  while (pesArray.length > 0) {
    elementaryStream.push({
      type: 'pes',
      streamType: ADTS_STREAM_TYPE,
      payloadUnitStartIndicator: true,
      data: new Uint8Array(pesArray.shift().concat(packetData))
    });
    elementaryStream.flush();
  }


  assert.equal(packets.length, 10, 'built ten packets');
  assert.equal(packets[0].pts, 1, 'correctly parsed the pts value');
  assert.equal(packets[1].pts, Math.floor(maxTS * (1 / 3)), 'correctly parsed the pts value');
  assert.equal(packets[2].pts, Math.floor(maxTS * (2 / 3)), 'correctly parsed the pts value');
  assert.equal(packets[3].pts, maxTS + 1, 'correctly parsed the pts value');
  assert.equal(packets[4].pts, maxTS + Math.floor(maxTS * (1 / 3)), 'correctly parsed the pts value');
  assert.equal(packets[5].pts, maxTS + Math.floor(maxTS * (2 / 3)), 'correctly parsed the pts value');
  assert.equal(packets[6].pts, (2 * maxTS) + 1, 'correctly parsed the pts value');
  assert.equal(packets[7].pts, (2 * maxTS) + Math.floor(maxTS * (1 / 3)), 'correctly parsed the pts value');
  assert.equal(packets[8].pts, (2 * maxTS) + Math.floor(maxTS * (2 / 3)), 'correctly parsed the pts value');
  assert.equal(packets[9].pts, (3 * maxTS) + 1, 'correctly parsed the pts value');
});

QUnit.module('H264 Stream', {
  beforeEach: function() {
    h264Stream = new H264Stream();
  }
});

QUnit.test('properly parses seq_parameter_set_rbsp nal units', function(assert) {
  var
    data,
    expectedRBSP = new Uint8Array([
      0x42, 0xc0, 0x1e, 0xd9,
      0x00, 0xb4, 0x35, 0xf9,
      0xe1, 0x00, 0x00, 0x00,
      0x01, 0x00, 0x00, 0x00,
      0x3c, 0x0f, 0x16, 0x2e,
      0x48
    ]),
    expectedConfig = {
      profileIdc: 66,
      levelIdc: 30,
      profileCompatibility: 192,
      width: 720,
      height: 404,
      sarRatio: [1, 1]
    };

  h264Stream.on('data', function(event) {
    data = event;
  });

  // QUnit.test SPS:
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x67, 0x42, 0xc0, 0x1e,
      0xd9, 0x00, 0xb4, 0x35,
      0xf9, 0xe1, 0x00, 0x00,
      0x03, 0x00, 0x01, 0x00,
      0x00, 0x03, 0x00, 0x3c,
      0x0f, 0x16, 0x2e, 0x48,
      0x00, 0x00, 0x01
    ])
  });

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'seq_parameter_set_rbsp', 'identified a sequence parameter set');
  assert.deepEqual(data.escapedRBSP, expectedRBSP, 'properly removed Emulation Prevention Bytes from the RBSP');

  assert.deepEqual(data.config, expectedConfig, 'parsed the sps');
});

QUnit.test('Properly parses seq_parameter_set VUI nal unit', function(assert) {
  var
    data,
    expectedConfig = {
      profileIdc: 66,
      levelIdc: 30,
      profileCompatibility: 192,
      width: 16,
      height: 16,
      sarRatio: [65528, 16384]
    };

  h264Stream.on('data', function(event) {
    data = event;
  });

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x67, 0x42, 0xc0, 0x1e,
      0xd9, 0xff, 0xff, 0xff,
      0xff, 0xe1, 0x00, 0x00,
      0x03, 0x00, 0x01, 0x00,
      0x00, 0x03, 0x00, 0x3c,
      0x0f, 0x16, 0x2e, 0x48,
      0xff, 0x00, 0x00, 0x01
    ])
  });

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'seq_parameter_set_rbsp', 'identified a sequence parameter set');
  assert.deepEqual(data.config, expectedConfig, 'parsed the sps');
});

QUnit.test('Properly parses seq_parameter_set nal unit with defined sarRatio', function(assert) {
  var
    data,
    expectedConfig = {
      profileIdc: 77,
      levelIdc: 21,
      profileCompatibility: 64,
      width: 352,
      height: 480,
      sarRatio: [20, 11]
    };

  h264Stream.on('data', function(event) {
    data = event;
  });

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x67, 0x4d, 0x40, 0x15,
      0xec, 0xa0, 0xb0, 0x7b,
      0x60, 0xe2, 0x00, 0x00,
      0x07, 0xd2, 0x00, 0x01,
      0xd4, 0xc0, 0x1e, 0x2c,
      0x5b, 0x2c, 0x00, 0x00,
      0x01
    ])
  });

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'seq_parameter_set_rbsp', 'identified a sequence parameter set');
  assert.deepEqual(data.config, expectedConfig, 'parsed the sps');
});

QUnit.test('Properly parses seq_parameter_set nal unit with extended sarRatio', function(assert) {
  var
    data,
    expectedConfig = {
      profileIdc: 77,
      levelIdc: 21,
      profileCompatibility: 64,
      width: 352,
      height: 480,
      sarRatio: [8, 7]
    };

  h264Stream.on('data', function(event) {
    data = event;
  });

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x67, 0x4d, 0x40, 0x15,
      0xec, 0xa0, 0xb0, 0x7b,
      0x7F, 0xe0, 0x01, 0x00,
      0x00, 0xf0, 0x00, 0x00,
      0x00, 0x01
    ])
  });

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'seq_parameter_set_rbsp', 'identified a sequence parameter set');
  assert.deepEqual(data.config, expectedConfig, 'parsed the sps');
});

QUnit.test('Properly parses seq_parameter_set nal unit without VUI', function(assert) {
  var
    data,
    expectedConfig = {
      profileIdc: 77,
      levelIdc: 21,
      profileCompatibility: 64,
      width: 352,
      height: 480,
      sarRatio: [1, 1]
    };

  h264Stream.on('data', function(event) {
    data = event;
  });

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x67, 0x4d, 0x40, 0x15,
      0xec, 0xa0, 0xb0, 0x7b,
      0x02, 0x00, 0x00, 0x01
    ])
  });

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'seq_parameter_set_rbsp', 'identified a sequence parameter set');
  assert.deepEqual(data.config, expectedConfig, 'parsed the sps');
});

QUnit.test('unpacks nal units from simple byte stream framing', function(assert) {
  var data;
  h264Stream.on('data', function(event) {
    data = event;
  });

  // the simplest byte stream framing:
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x09, 0x07,
      0x00, 0x00, 0x01
    ])
  });

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'access_unit_delimiter_rbsp', 'identified an access unit delimiter');
  assert.equal(data.data.length, 2, 'calculated nal unit length');
  assert.equal(data.data[1], 7, 'read a payload byte');
});

QUnit.test('unpacks nal units from byte streams split across pushes', function(assert) {
  var data;
  h264Stream.on('data', function(event) {
    data = event;
  });

  // handles byte streams split across pushes
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x09, 0x07, 0x06, 0x05,
      0x04
    ])
  });
  assert.ok(!data, 'buffers NAL units across events');

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x03, 0x02, 0x01,
      0x00, 0x00, 0x01
    ])
  });
  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'access_unit_delimiter_rbsp', 'identified an access unit delimiter');
  assert.equal(data.data.length, 8, 'calculated nal unit length');
  assert.equal(data.data[1], 7, 'read a payload byte');
});

QUnit.test('buffers nal unit trailing zeros across pushes', function(assert) {
  var data = [];
  h264Stream.on('data', function(event) {
    data.push(event);
  });

  // lots of zeros after the nal, stretching into the next push
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x09, 0x07, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
      0x00
    ])
  });
  assert.equal(data.length, 1, 'delivered the first nal');

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00,
      0x00, 0x00, 0x01,
      0x09, 0x06,
      0x00, 0x00, 0x01
    ])
  });
  assert.equal(data.length, 2, 'generated data events');
  assert.equal(data[0].data.length, 2, 'ignored trailing zeros');
  assert.equal(data[0].data[0], 0x09, 'found the first nal start');
  assert.equal(data[1].data.length, 2, 'found the following nal start');
  assert.equal(data[1].data[0], 0x09, 'found the second nal start');
});

QUnit.test('unpacks nal units from byte streams with split sync points', function(assert) {
  var data;
  h264Stream.on('data', function(event) {
    data = event;
  });

  // handles sync points split across pushes
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x09, 0x07,
      0x00])
  });
  assert.ok(!data, 'buffers NAL units across events');

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x01
    ])
  });
  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'access_unit_delimiter_rbsp', 'identified an access unit delimiter');
  assert.equal(data.data.length, 2, 'calculated nal unit length');
  assert.equal(data.data[1], 7, 'read a payload byte');
});

QUnit.test('parses nal unit types', function(assert) {
  var data;
  h264Stream.on('data', function(event) {
    data = event;
  });

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x09
    ])
  });
  h264Stream.flush();

  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'access_unit_delimiter_rbsp', 'identified an access unit delimiter');

  data = null;
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x07,
      0x27, 0x42, 0xe0, 0x0b,
      0xa9, 0x18, 0x60, 0x9d,
      0x80, 0x35, 0x06, 0x01,
      0x06, 0xb6, 0xc2, 0xb5,
      0xef, 0x7c, 0x04
    ])
  });
  h264Stream.flush();
  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'seq_parameter_set_rbsp', 'identified a sequence parameter set');

  data = null;
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x08, 0x01
    ])
  });
  h264Stream.flush();
  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'pic_parameter_set_rbsp', 'identified a picture parameter set');

  data = null;
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x05, 0x01
    ])
  });
  h264Stream.flush();
  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'slice_layer_without_partitioning_rbsp_idr', 'identified a key frame');

  data = null;
  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x06, 0x01
    ])
  });
  h264Stream.flush();
  assert.ok(data, 'generated a data event');
  assert.equal(data.nalUnitType, 'sei_rbsp', 'identified a supplemental enhancement information unit');
});

// MP4 expects H264 (aka AVC) data to be in storage format. Storage
// format is optimized for reliable, random-access media in contrast
// to the byte stream format that retransmits metadata regularly to
// allow decoders to quickly begin operation from wherever in the
// broadcast they begin receiving.
// Details on the byte stream format can be found in Annex B of
// Recommendation ITU-T H.264.
// The storage format is described in ISO/IEC 14496-15
QUnit.test('strips byte stream framing during parsing', function(assert) {
  var data = [];
  h264Stream.on('data', function(event) {
    data.push(event);
  });

  h264Stream.push({
    type: 'video',
    data: new Uint8Array([
      // -- NAL unit start
      // zero_byte
      0x00,
      // start_code_prefix_one_3bytes
      0x00, 0x00, 0x01,
      // nal_unit_type (picture parameter set)
      0x08,
      // fake data
      0x01, 0x02, 0x03, 0x04,
      0x05, 0x06, 0x07,
      // trailing_zero_8bits * 5
      0x00, 0x00, 0x00, 0x00,
      0x00,

      // -- NAL unit start
      // zero_byte
      0x00,
      // start_code_prefix_one_3bytes
      0x00, 0x00, 0x01,
      // nal_unit_type (access_unit_delimiter_rbsp)
      0x09,
      // fake data
      0x06, 0x05, 0x04, 0x03,
      0x02, 0x01, 0x00
    ])
  });
  h264Stream.flush();

  assert.equal(data.length, 2, 'parsed two NAL units');
  assert.deepEqual(new Uint8Array([
    0x08,
    0x01, 0x02, 0x03, 0x04,
    0x05, 0x06, 0x07
  ]), new Uint8Array(data[0].data), 'parsed the first NAL unit');
  assert.deepEqual(new Uint8Array([
    0x09,
    0x06, 0x05, 0x04, 0x03,
    0x02, 0x01, 0x00
  ]), new Uint8Array(data[1].data), 'parsed the second NAL unit');
});

QUnit.test('can be reset', function(assert) {
  var input = {
    type: 'video',
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01,
      0x09, 0x07,
      0x00, 0x00, 0x01
    ])
  }, data = [];
  // only the laQUnit.test event is relevant for this QUnit.test
  h264Stream.on('data', function(event) {
    data.push(event);
  });

  h264Stream.push(input);
  h264Stream.flush();
  h264Stream.push(input);
  h264Stream.flush();

  assert.equal(data.length, 2, 'generated two data events');
  assert.equal(data[1].nalUnitType, 'access_unit_delimiter_rbsp', 'identified an access unit delimiter');
  assert.equal(data[1].data.length, 2, 'calculated nal unit length');
  assert.equal(data[1].data[1], 7, 'read a payload byte');
});

QUnit.module('VideoSegmentStream', {
  beforeEach: function() {
    var track = {};
    var options = {};
    videoSegmentStream = new VideoSegmentStream(track, options);
    videoSegmentStream.track = track;
    videoSegmentStream.options = options;
    videoSegmentStream.track.timelineStartInfo = {
      dts: 10,
      pts: 10,
      baseMediaDecodeTime: 0
    };
  }
});

// see ISO/IEC 14496-15, Section 5 "AVC elementary streams and sample definitions"
QUnit.test('concatenates NAL units into AVC elementary streams', function(assert) {
  var segment, boxes;
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });
  videoSegmentStream.push({
    nalUnitType: 'access_unit_delimiter_rbsp',
    data: new Uint8Array([0x09, 0x01])
  });
  videoSegmentStream.push({
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    data: new Uint8Array([0x05, 0x01])
  });
  videoSegmentStream.push({
    data: new Uint8Array([
      0x08,
      0x01, 0x02, 0x03
    ])
  });
  videoSegmentStream.push({
    data: new Uint8Array([
      0x08,
      0x04, 0x03, 0x02, 0x01, 0x00
    ])
  });
  videoSegmentStream.flush();

  assert.ok(segment, 'generated a data event');
  boxes = mp4.tools.inspect(segment);
  assert.equal(boxes[1].byteLength,
        (2 + 4) + (2 + 4) + (4 + 4) + (4 + 6),
        'wrote the correct number of bytes');
  assert.deepEqual(new Uint8Array(segment.subarray(boxes[0].size + 8)), new Uint8Array([
    0, 0, 0, 2,
    0x09, 0x01,
    0, 0, 0, 2,
    0x05, 0x01,
    0, 0, 0, 4,
    0x08, 0x01, 0x02, 0x03,
    0, 0, 0, 6,
    0x08, 0x04, 0x03, 0x02, 0x01, 0x00
  ]), 'wrote an AVC stream into the mdat');
});

QUnit.test('infers sample durations from DTS values', function(assert) {
   var segment, boxes, samples;
   videoSegmentStream.on('data', function(data) {
     segment = data.boxes;
   });
   videoSegmentStream.push({
     data: new Uint8Array([0x09, 0x01]),
     nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1
   });
   videoSegmentStream.push({
     data: new Uint8Array([0x09, 0x01]),
     nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 1
   });
   videoSegmentStream.push({
     data: new Uint8Array([0x09, 0x01]),
     nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 2
   });
   videoSegmentStream.push({
     data: new Uint8Array([0x09, 0x01]),
     nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 4
   });
   videoSegmentStream.flush();
  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 3, 'generated three samples');
  assert.equal(samples[0].duration, 1, 'set the first sample duration');
  assert.equal(samples[1].duration, 2, 'set the second sample duration');
  assert.equal(samples[2].duration, 2, 'inferred the final sample duration');
});

QUnit.test('filters pre-IDR samples and calculate duration correctly', function(assert) {
  var segment, boxes, samples;
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp',
    dts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 2
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 4
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 2, 'generated two samples, filters out pre-IDR');
  assert.equal(samples[0].duration, 3, 'set the first sample duration');
  assert.equal(samples[1].duration, 3, 'set the second sample duration');
});

QUnit.test('holds onto the last GOP and prepends the subsequent push operation with that GOP', function(assert) {
  var segment, boxes, samples;

  videoSegmentStream.track.timelineStartInfo.dts = 0;

  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x00]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {},
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x00]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x66, 0x66]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 2,
    pts: 2
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x03]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 3,
    pts: 3
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x99, 0x99]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 3,
    pts: 3
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x04]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 4,
    pts: 4
  });
  videoSegmentStream.flush();

  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 5,
    pts: 5
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 6,
    pts: 6
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x00]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {},
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x00]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x11, 0x11]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 6,
    pts: 6
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 4, 'generated four samples, two from previous segment');
  assert.equal(samples[0].size, 12, 'first sample is an AUD + IDR pair');
  assert.equal(samples[1].size, 6, 'second sample is an AUD');
  assert.equal(samples[2].size, 6, 'third sample is an AUD');
  assert.equal(samples[3].size, 24, 'fourth sample is an AUD + PPS + SPS + IDR');
});

QUnit.test('doesn\'t prepend the last GOP if the next segment has earlier PTS', function(assert) {
  var segment, boxes, samples;

  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 10,
    pts: 10
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x66, 0x66]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 10,
    pts: 10
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 11,
    pts: 11
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x03]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 12,
    pts: 12
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x99, 0x99]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 12,
    pts: 12
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x04]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 13,
    pts: 13
  });
  videoSegmentStream.flush();

  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 5,
    pts: 5
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 6,
    pts: 6
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x11, 0x11]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 6,
    pts: 6
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 1, 'generated one sample');
  assert.equal(samples[0].size, 12, 'first sample is an AUD + IDR pair');
});

QUnit.test('doesn\'t prepend the last GOP if the next segment has different PPS or SPS', function(assert) {
  var segment, boxes, samples;

  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x00]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {},
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x00]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x66, 0x66]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 2,
    pts: 2
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x03]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 3,
    pts: 3
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x99, 0x99]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 3,
    pts: 3
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x04]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 4,
    pts: 4
  });
  videoSegmentStream.flush();

  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 5,
    pts: 5
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 6,
    pts: 6
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x01]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {},
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x00, 0x01]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x11, 0x11]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 6,
    pts: 6
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 1, 'generated one sample');
  assert.equal(samples[0].size, 24, 'first sample is an AUD + PPS + SPS + IDR');
});

QUnit.test('doesn\'t prepend the last GOP if the next segment is more than 1 seconds in the future', function(assert) {
  var segment, boxes, samples;

  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x66, 0x66]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 2,
    pts: 2
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x03]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 3,
    pts: 3
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x99, 0x99]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 3,
    pts: 3
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01, 0x04]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 4,
    pts: 4
  });
  videoSegmentStream.flush();

  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1000000,
    pts: 1000000
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x02, 0x02]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1000001,
    pts: 1000001
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x11, 0x11]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 1000001,
    pts: 1000001
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 1, 'generated one sample');
  assert.equal(samples[0].size, 12, 'first sample is an AUD + IDR pair');
});

QUnit.test('track values from seq_parameter_set_rbsp should be cleared by a flush', function(assert) {
  var track;
  videoSegmentStream.on('data', function(data) {
    track = data.track;
  });
  videoSegmentStream.push({
    data: new Uint8Array([0xFF]),
    nalUnitType: 'access_unit_delimiter_rbsp'
  });
  videoSegmentStream.push({
    data: new Uint8Array([0xFF]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr'
  });
  videoSegmentStream.push({
    data: new Uint8Array([0xFF]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {
      width: 123,
      height: 321,
      profileIdc: 1,
      levelIdc: 2,
      profileCompatibility: 3
    },
    dts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x88]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {
      width: 1234,
      height: 4321,
      profileIdc: 4,
      levelIdc: 5,
      profileCompatibility: 6
    },
    dts: 1
  });
  videoSegmentStream.flush();

  assert.equal(track.width, 123, 'width is set by first SPS');
  assert.equal(track.height, 321, 'height is set by first SPS');
  assert.equal(track.sps[0][0], 0xFF, 'first sps is 0xFF');
  assert.equal(track.profileIdc, 1, 'profileIdc is set by first SPS');
  assert.equal(track.levelIdc, 2, 'levelIdc is set by first SPS');
  assert.equal(track.profileCompatibility, 3, 'profileCompatibility is set by first SPS');

  videoSegmentStream.push({
    data: new Uint8Array([0x99]),
    nalUnitType: 'seq_parameter_set_rbsp',
    config: {
      width: 300,
      height: 200,
      profileIdc: 11,
      levelIdc: 12,
      profileCompatibility: 13
    },
    dts: 1
  });
  videoSegmentStream.flush();

  assert.equal(track.width, 300, 'width is set by first SPS after flush');
  assert.equal(track.height, 200, 'height is set by first SPS after flush');
  assert.equal(track.sps.length, 1, 'there is one sps');
  assert.equal(track.sps[0][0], 0x99, 'first sps is 0x99');
  assert.equal(track.profileIdc, 11, 'profileIdc is set by first SPS after flush');
  assert.equal(track.levelIdc, 12, 'levelIdc is set by first SPS after flush');
  assert.equal(track.profileCompatibility, 13, 'profileCompatibility is set by first SPS after flush');
});

QUnit.test('track pps from pic_parameter_set_rbsp should be cleared by a flush', function(assert) {
  var track;
  videoSegmentStream.on('data', function(data) {
    track = data.track;
  });
  videoSegmentStream.push({
    data: new Uint8Array([0xFF]),
    nalUnitType: 'access_unit_delimiter_rbsp'
  });
  videoSegmentStream.push({
    data: new Uint8Array([0xFF]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr'
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x01]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x02]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1
  });
  videoSegmentStream.flush();

  assert.equal(track.pps[0][0], 0x01, 'first pps is 0x01');

  videoSegmentStream.push({
    data: new Uint8Array([0x03]),
    nalUnitType: 'pic_parameter_set_rbsp',
    dts: 1
  });
  videoSegmentStream.flush();

  assert.equal(track.pps[0][0], 0x03, 'first pps is 0x03 after a flush');
});

QUnit.test('calculates compositionTimeOffset values from the PTS/DTS', function(assert) {
  var segment, boxes, samples;
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1,
    pts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 1
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1,
    pts: 2
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 1,
    pts: 4
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  samples = boxes[0].boxes[1].boxes[2].samples;
  assert.equal(samples.length, 3, 'generated three samples');
  assert.equal(samples[0].compositionTimeOffset, 0, 'calculated compositionTimeOffset');
  assert.equal(samples[1].compositionTimeOffset, 1, 'calculated compositionTimeOffset');
  assert.equal(samples[2].compositionTimeOffset, 3, 'calculated compositionTimeOffset');
});

QUnit.test('calculates baseMediaDecodeTime values from the first DTS ever seen and subsequent segments\' lowest DTS', function(assert) {
  var segment, boxes, tfdt;
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 100,
    pts: 100
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 100,
    pts: 100
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 200,
    pts: 200
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 300,
    pts: 300
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  tfdt = boxes[0].boxes[1].boxes[1];
  assert.equal(tfdt.baseMediaDecodeTime, 90, 'calculated baseMediaDecodeTime');
});

QUnit.test('doesn\'t adjust baseMediaDecodeTime when configured to keep original timestamps', function(assert) {
  videoSegmentStream.options.keepOriginalTimestamps = true;

  var segment, boxes, tfdt;
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 100,
    pts: 100
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 100,
    pts: 100
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 200,
    pts: 200
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 300,
    pts: 300
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  tfdt = boxes[0].boxes[1].boxes[1];
  assert.equal(tfdt.baseMediaDecodeTime, 100, 'calculated baseMediaDecodeTime');
});

QUnit.test('calculates baseMediaDecodeTime values relative to a customizable baseMediaDecodeTime', function(assert) {
  var segment, boxes, tfdt, baseMediaDecodeTimeValue;

  // Set the baseMediaDecodeTime to something over 2^32 to ensure
  // that the version 1 TFDT box is being created correctly
  baseMediaDecodeTimeValue = Math.pow(2, 32) + 100;

  videoSegmentStream.track.timelineStartInfo = {
    dts: 10,
    pts: 10,
    baseMediaDecodeTime: baseMediaDecodeTimeValue
  };
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 100,
    pts: 100
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 100,
    pts: 100
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 200,
    pts: 200
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 300,
    pts: 300
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  tfdt = boxes[0].boxes[1].boxes[1];

  // The timeline begins at 10 and the first sample has a dts of
  // 100, so the baseMediaDecodeTime should be equal to (100 - 10)
  assert.equal(tfdt.baseMediaDecodeTime, baseMediaDecodeTimeValue + 90, 'calculated baseMediaDecodeTime');
});

QUnit.test('do not subtract the first frame\'s compositionTimeOffset from baseMediaDecodeTime', function(assert) {
  var segment, boxes, tfdt;
  videoSegmentStream.track.timelineStartInfo = {
    dts: 10,
    pts: 10,
    baseMediaDecodeTime: 100
  };
  videoSegmentStream.on('data', function(data) {
    segment = data.boxes;
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 50,
    pts: 60
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: 50,
    pts: 60
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 100,
    pts: 110
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 150,
    pts: 160
  });
  videoSegmentStream.flush();

  boxes = mp4.tools.inspect(segment);
  tfdt = boxes[0].boxes[1].boxes[1];

  // The timelineStartInfo's bMDT is 100 and that corresponds to a dts/pts of 10
  // The first frame has a dts 50 so the bMDT is calculated as: (50 - 10) + 100 = 140
  assert.equal(tfdt.baseMediaDecodeTime, 140, 'calculated baseMediaDecodeTime');
});

QUnit.test('video segment stream triggers segmentTimingInfo with timing info',
function(assert) {
  var
    segmentTimingInfoArr = [],
    baseMediaDecodeTime = 40,
    startingDts = 50,
    startingPts = 60,
    lastFrameStartDts = 150,
    lastFrameStartPts = 160;

  videoSegmentStream.on('segmentTimingInfo', function(segmentTimingInfo) {
    segmentTimingInfoArr.push(segmentTimingInfo);
  });

  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: startingDts,
    pts: startingPts
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'slice_layer_without_partitioning_rbsp_idr',
    dts: startingDts,
    pts: startingPts
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: 100,
    pts: 110
  });
  videoSegmentStream.push({
    data: new Uint8Array([0x09, 0x01]),
    nalUnitType: 'access_unit_delimiter_rbsp',
    dts: lastFrameStartDts,
    pts: lastFrameStartPts
  });
  videoSegmentStream.flush();

  assert.equal(segmentTimingInfoArr.length, 1, 'triggered segmentTimingInfo once');
  assert.equal(
    baseMediaDecodeTime,
    segmentTimingInfoArr[0].baseMediaDecodeTime,
    'set baseMediaDecodeTime'
  );
  assert.deepEqual(segmentTimingInfoArr[0], {
    start: {
      // baseMediaDecodeTime
      dts: 40,
      // baseMediaDecodeTime + startingPts - startingDts
      pts: 40 + 60 - 50
    },
    end: {
      // because no duration is provided in this test, the duration will instead be based
      // on the previous frame, which will be the start of this frame minus the end of the
      // last frame, or 150 - 100 = 50, which gets added to lastFrameStartDts - startDts =
      // 150 - 50 = 100
      // + baseMediaDecodeTime
      dts: 40 + 100 + 50,
      pts: 40 + 100 + 50
    },
    prependedContentDuration: 0,
    baseMediaDecodeTime: baseMediaDecodeTime
  }, 'triggered correct segment timing info');
});

QUnit.test('aignGopsAtStart_ filters gops appropriately', function(assert) {
  var gopsToAlignWith, gops, actual, expected;

  // atog === arrayToGops
  var atog = function(list) {
    var mapped = list.map(function(item) {
      return {
        pts: item,
        dts: item,
        nalCount: 1,
        duration: 1,
        byteLength: 1
      };
    });

    mapped.byteLength = mapped.length;
    mapped.nalCount = mapped.length;
    mapped.duration = mapped.length;
    mapped.dts = mapped[0].dts;
    mapped.pts = mapped[0].pts;

    return mapped;
  };

  // no gops to trim, all gops start after any alignment candidates
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([10, 12, 13, 14, 16]);
  expected = atog([10, 12, 13, 14, 16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, all gops start after any alignment candidates');

  // no gops to trim, first gop has a match with first alignment candidate
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([0, 2, 4, 6, 8]);
  expected = atog([0, 2, 4, 6, 8]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, first gop has a match with first alignment candidate');

  // no gops to trim, first gop has a match with last alignment candidate
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([8, 10, 12, 13, 14, 16]);
  expected = atog([8, 10, 12, 13, 14, 16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, first gop has a match with last alignment candidate');

  // no gops to trim, first gop has a match with an alignment candidate
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([6, 9, 10, 12, 13, 14, 16]);
  expected = atog([6, 9, 10, 12, 13, 14, 16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, first gop has a match with an alignment candidate');

  // all gops trimmed, all gops come before first alignment candidate
  gopsToAlignWith = atog([10, 12, 13, 14, 16]);
  gops = atog([0, 2, 4, 6, 8]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops come before first alignment candidate');

  // all gops trimmed, all gops come before last alignment candidate, no match found
  gopsToAlignWith = atog([10, 12, 13, 14, 16]);
  gops = atog([0, 2, 4, 6, 8, 11, 15]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops come before last alignment candidate, no match found');

  // all gops trimmed, all gops contained between alignment candidates, no match found
  gopsToAlignWith = atog([6, 10, 12, 13, 14, 16]);
  gops = atog([7, 8, 9, 11, 15]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops contained between alignment candidates, no match found');

  // some gops trimmed, some gops before first alignment candidate
  // match on first alignment candidate
  gopsToAlignWith = atog([9, 10, 13, 16]);
  gops = atog([7, 8, 9, 10, 12]);
  expected = atog([9, 10, 12]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops before first alignment candidate,' +
    'match on first alignment candidate');

  // some gops trimmed, some gops before first alignment candidate
  // match on an alignment candidate
  gopsToAlignWith = atog([9, 10, 13, 16]);
  gops = atog([7, 8, 11, 13, 14]);
  expected = atog([13, 14]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops before first alignment candidate,' +
    'match on an alignment candidate');

  // some gops trimmed, some gops before first alignment candidate
  // match on last alignment candidate
  gopsToAlignWith = atog([9, 10, 13, 16]);
  gops = atog([7, 8, 11, 12, 15, 16]);
  expected = atog([16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops before first alignment candidate,' +
    'match on last alignment candidate');

  // some gops trimmed, some gops after last alignment candidate
  // match on an alignment candidate
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([4, 5, 9, 11, 13]);
  expected = atog([9, 11, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops after last alignment candidate,' +
    'match on an alignment candidate');

  // some gops trimmed, some gops after last alignment candidate
  // match on last alignment candidate
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([4, 5, 7, 10, 13]);
  expected = atog([10, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops after last alignment candidate,' +
    'match on last alignment candidate');

  // some gops trimmed, some gops after last alignment candidate
  // no match found
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([4, 5, 7, 13, 15]);
  expected = atog([13, 15]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops after last alignment candidate,' +
    'no match found');

  // some gops trimmed, gops contained between alignment candidates
  // match with an alignment candidate
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([2, 4, 6, 8]);
  expected = atog([6, 8]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, gops contained between alignment candidates,' +
    'match with an alignment candidate');

  // some gops trimmed, alignment candidates contained between gops
  // no match
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 4, 8, 11, 13]);
  expected = atog([11, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'no match');

  // some gops trimmed, alignment candidates contained between gops
  // match with first alignment candidate
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 3, 4, 5, 9, 10, 11]);
  expected = atog([3, 4, 5, 9, 10, 11]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'match with first alignment candidate');

  // some gops trimmed, alignment candidates contained between gops
  // match with last alignment candidate
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 4, 8, 10, 13, 15]);
  expected = atog([10, 13, 15]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'match with last alignment candidate');

  // some gops trimmed, alignment candidates contained between gops
  // match with an alignment candidate
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 4, 6, 9, 11, 13]);
  expected = atog([6, 9, 11, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtStart_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'match with an alignment candidate');
});

QUnit.test('alignGopsAtEnd_ filters gops appropriately', function(assert) {
  var gopsToAlignWith, gops, actual, expected;

  // atog === arrayToGops
  var atog = function(list) {
    var mapped = list.map(function(item) {
      return {
        pts: item,
        dts: item,
        nalCount: 1,
        duration: 1,
        byteLength: 1
      };
    });

    mapped.byteLength = mapped.length;
    mapped.nalCount = mapped.length;
    mapped.duration = mapped.length;
    mapped.dts = mapped[0].dts;
    mapped.pts = mapped[0].pts;

    return mapped;
  };

  // no gops to trim, all gops start after any alignment candidates
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([10, 12, 13, 14, 16]);
  expected = atog([10, 12, 13, 14, 16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, all gops start after any alignment candidates');

  // no gops to trim, first gop has a match with first alignment candidate
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([0, 1, 3, 5, 7]);
  expected = atog([0, 1, 3, 5, 7]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, first gop has a match with first alignment candidate');

  // no gops to trim, first gop has a match with last alignment candidate
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([8, 10, 12, 13, 14, 16]);
  expected = atog([8, 10, 12, 13, 14, 16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, first gop has a match with last alignment candidate');

  // no gops to trim, first gop has a match with an alignment candidate
  gopsToAlignWith = atog([0, 2, 4, 6, 8]);
  gops = atog([6, 9, 10, 12, 13, 14, 16]);
  expected = atog([6, 9, 10, 12, 13, 14, 16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'no gops to trim, first gop has a match with an alignment candidate');

  // all gops trimmed, all gops come before first alignment candidate
  gopsToAlignWith = atog([10, 12, 13, 14, 16]);
  gops = atog([0, 2, 4, 6, 8]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops come before first alignment candidate');

  // all gops trimmed, all gops come before last alignment candidate, no match found
  gopsToAlignWith = atog([10, 12, 13, 14, 16]);
  gops = atog([0, 2, 4, 6, 8, 11, 15]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops come before last alignment candidate, no match found');

  gopsToAlignWith = atog([10, 12, 13, 14, 16]);
  gops = atog([8, 11, 15]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops come before last alignment candidate, no match found');

  // all gops trimmed, all gops contained between alignment candidates, no match found
  gopsToAlignWith = atog([6, 10, 12, 13, 14, 16]);
  gops = atog([7, 8, 9, 11, 15]);
  expected = null;
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'all gops trimmed, all gops contained between alignment candidates, no match found');

  // some gops trimmed, some gops before first alignment candidate
  // match on first alignment candidate
  gopsToAlignWith = atog([9, 11, 13, 16]);
  gops = atog([7, 8, 9, 10, 12]);
  expected = atog([9, 10, 12]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops before first alignment candidate,' +
    'match on first alignment candidate');

  // some gops trimmed, some gops before first alignment candidate
  // match on an alignment candidate
  gopsToAlignWith = atog([9, 10, 11, 13, 16]);
  gops = atog([7, 8, 11, 13, 14, 15]);
  expected = atog([13, 14, 15]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops before first alignment candidate,' +
    'match on an alignment candidate');

  // some gops trimmed, some gops before first alignment candidate
  // match on last alignment candidate
  gopsToAlignWith = atog([9, 10, 13, 16]);
  gops = atog([7, 8, 11, 12, 15, 16]);
  expected = atog([16]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops before first alignment candidate,' +
    'match on last alignment candidate');

  // some gops trimmed, some gops after last alignment candidate
  // match on an alignment candidate
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([4, 5, 6, 9, 11, 13]);
  expected = atog([9, 11, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops after last alignment candidate,' +
    'match on an alignment candidate');

  // some gops trimmed, some gops after last alignment candidate
  // match on last alignment candidate
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([4, 5, 7, 9, 10, 13]);
  expected = atog([10, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops after last alignment candidate,' +
    'match on last alignment candidate');

  // some gops trimmed, some gops after last alignment candidate
  // no match found
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([4, 5, 7, 13, 15]);
  expected = atog([13, 15]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, some gops after last alignment candidate,' +
    'no match found');

  // some gops trimmed, gops contained between alignment candidates
  // match with an alignment candidate
  gopsToAlignWith = atog([0, 3, 6, 9, 10]);
  gops = atog([2, 4, 6, 8]);
  expected = atog([6, 8]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, gops contained between alignment candidates,' +
    'match with an alignment candidate');

  // some gops trimmed, alignment candidates contained between gops
  // no match
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 4, 8, 11, 13]);
  expected = atog([11, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'no match');

  // some gops trimmed, alignment candidates contained between gops
  // match with first alignment candidate
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 3, 4, 5, 11]);
  expected = atog([3, 4, 5, 11]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'match with first alignment candidate');

  // some gops trimmed, alignment candidates contained between gops
  // match with last alignment candidate
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 4, 8, 10, 13, 15]);
  expected = atog([10, 13, 15]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'match with last alignment candidate');

  // some gops trimmed, alignment candidates contained between gops
  // match with an alignment candidate
  gopsToAlignWith = atog([3, 6, 9, 10]);
  gops = atog([0, 2, 4, 6, 9, 11, 13]);
  expected = atog([9, 11, 13]);
  videoSegmentStream.alignGopsWith(gopsToAlignWith);
  actual = videoSegmentStream.alignGopsAtEnd_(gops);
  assert.deepEqual(actual, expected,
    'some gops trimmed, alignment candidates contained between gops,' +
    'match with an alignment candidate');
});

QUnit.test('generateSegmentTimingInfo generates correct timing info object', function(assert) {
  var
    firstFrame = {
      dts: 12,
      pts: 14,
      duration: 3
    },
    lastFrame = {
      dts: 120,
      pts: 140,
      duration: 4
    },
    baseMediaDecodeTime = 20,
    prependedContentDuration = 0;

  assert.deepEqual(
    generateSegmentTimingInfo(
      baseMediaDecodeTime,
      firstFrame.dts,
      firstFrame.pts,
      lastFrame.dts + lastFrame.duration,
      lastFrame.pts + lastFrame.duration,
      prependedContentDuration
    ), {
      start: {
        // baseMediaDecodeTime,
        dts: 20,
        // baseMediaDecodeTime + firstFrame.pts - firstFrame.dts
        pts: 20 + 14 - 12
      },
      end: {
        // baseMediaDecodeTime + lastFrame.dts + lastFrame.duration - firstFrame.dts,
        dts: 20 + 120 + 4 - 12,
        // baseMediaDecodeTime + lastFrame.pts + lastFrame.duration - firstFrame.pts
        pts: 20 + 140 + 4 - 14
      },
      prependedContentDuration: 0,
      baseMediaDecodeTime: baseMediaDecodeTime
    }, 'generated correct timing info object');
});

QUnit.test('generateSegmentTimingInfo accounts for prepended GOPs', function(assert) {
  var
    firstFrame = {
      dts: 12,
      pts: 14,
      duration: 3
    },
    lastFrame = {
      dts: 120,
      pts: 140,
      duration: 4
    },
    baseMediaDecodeTime = 20,
    prependedContentDuration = 7;

  assert.deepEqual(
    generateSegmentTimingInfo(
      baseMediaDecodeTime,
      firstFrame.dts,
      firstFrame.pts,
      lastFrame.dts + lastFrame.duration,
      lastFrame.pts + lastFrame.duration,
      prependedContentDuration
    ), {
      start: {
        // baseMediaDecodeTime,
        dts: 20,
        // baseMediaDecodeTime + firstFrame.pts - firstFrame.dts
        pts: 20 + 14 - 12
      },
      end: {
        // baseMediaDecodeTime + lastFrame.dts + lastFrame.duration - firstFrame.dts,
        dts: 20 + 120 + 4 - 12,
        // baseMediaDecodeTime + lastFrame.pts + lastFrame.duration - firstFrame.pts
        pts: 20 + 140 + 4 - 14
      },
      prependedContentDuration: 7,
      baseMediaDecodeTime: 20
    },
    'included prepended content duration in timing info');
});

QUnit.test('generateSegmentTimingInfo handles GOPS where pts is < dts', function(assert) {
  var
    firstFrame = {
      dts: 14,
      pts: 12,
      duration: 3
    },
    lastFrame = {
      dts: 140,
      pts: 120,
      duration: 4
    },
    baseMediaDecodeTime = 20,
    prependedContentDuration = 7;

  assert.deepEqual(
    generateSegmentTimingInfo(
      baseMediaDecodeTime,
      firstFrame.dts,
      firstFrame.pts,
      lastFrame.dts + lastFrame.duration,
      lastFrame.pts + lastFrame.duration,
      prependedContentDuration
    ), {
      start: {
        // baseMediaDecodeTime,
        dts: 20,
        // baseMediaDecodeTime + firstFrame.pts - firstFrame.dts
        pts: 20 + 12 - 14
      },
      end: {
        // baseMediaDecodeTime + lastFrame.dts + lastFrame.duration - firstFrame.dts,
        dts: 20 + 140 + 4 - 14,
        // baseMediaDecodeTime + lastFrame.pts + lastFrame.duration - firstFrame.pts
        pts: 20 + 120 + 4 - 12
      },
      prependedContentDuration: 7,
      baseMediaDecodeTime: 20
    },
    'included prepended content duration in timing info');
});

QUnit.module('ADTS Stream', {
  beforeEach: function() {
    adtsStream = new AdtsStream();
  }
});

QUnit.test('generates AAC frame events from ADTS bytes', function(assert) {
  var frames = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x12, 0x34,       // AAC payload
      0x56, 0x78        // extra junk that should be ignored
    ])
  });

  assert.equal(frames.length, 1, 'generated one frame');
  assert.deepEqual(new Uint8Array(frames[0].data),
            new Uint8Array([0x12, 0x34]),
            'extracted AAC frame');
  assert.equal(frames[0].channelcount, 2, 'parsed channelcount');
  assert.equal(frames[0].samplerate, 44100, 'parsed samplerate');

  // Chrome only supports 8, 16, and 32 bit sample sizes. Assuming the
  // default value of 16 in ISO/IEC 14496-12 AudioSampleEntry is
  // acceptable.
  assert.equal(frames[0].samplesize, 16, 'parsed samplesize');
});

QUnit.test('skips garbage data between sync words', function(assert) {
  var frames = [];
  var logs = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });

  adtsStream.on('log', function(log) {
    logs.push(log);
  });

  var frameHeader = [
    0xff, 0xf1,       // no CRC
    0x10,             // AAC Main, 44.1KHz
    0xbc, 0x01, 0x20, // 2 channels, frame length 9 including header
    0x00,             // one AAC per ADTS frame
  ];
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array(
      []
      // garbage
      .concat([0x00, 0x00, 0x00])
      // frame
      .concat(frameHeader)
      .concat([0x00, 0x01])
      // garbage
      .concat([0x00, 0x00, 0x00, 0x00, 0x00])
      .concat(frameHeader)
      .concat([0x00, 0x02])
      // garbage
      .concat([0x00, 0x00, 0x00, 0x00])
      .concat(frameHeader)
      .concat([0x00, 0x03])
      .concat([0x00, 0x00, 0x00, 0x00])
    )
  });

  assert.equal(frames.length, 3, 'generated three frames');
  frames.forEach(function(frame, i) {
    assert.deepEqual(
      new Uint8Array(frame.data),
      new Uint8Array([0x00, i + 1]),
      'extracted AAC frame'
    );

    assert.equal(frame.channelcount, 2, 'parsed channelcount');
    assert.equal(frame.samplerate, 44100, 'parsed samplerate');

    // Chrome only supports 8, 16, and 32 bit sample sizes. Assuming the
    // default value of 16 in ISO/IEC 14496-12 AudioSampleEntry is
    // acceptable.
    assert.equal(frame.samplesize, 16, 'parsed samplesize');
  });
  assert.deepEqual(logs, [
    {level: 'warn', message: 'adts skiping bytes 0 to 3 in frame 0 outside syncword'},
    {level: 'warn', message: 'adts skiping bytes 12 to 17 in frame 1 outside syncword'},
    {level: 'warn', message: 'adts skiping bytes 26 to 30 in frame 2 outside syncword'}
  ], 'logged skipped data');
});

QUnit.test('parses across packets', function(assert) {
  var frames = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x12, 0x34        // AAC payload 1
    ])
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x9a, 0xbc,       // AAC payload 2
      0xde, 0xf0        // extra junk that should be ignored
    ])
  });

  assert.equal(frames.length, 2, 'parsed two frames');
  assert.deepEqual(new Uint8Array(frames[1].data),
            new Uint8Array([0x9a, 0xbc]),
            'extracted the second AAC frame');
});

QUnit.test('parses frames segmented across packet', function(assert) {
  var frames = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x12        // incomplete AAC payload 1
    ])
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0x34,             // remainder of the previous frame's payload
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x9a, 0xbc,       // AAC payload 2
      0xde, 0xf0        // extra junk that should be ignored
    ])
  });

  assert.equal(frames.length, 2, 'parsed two frames');
  assert.deepEqual(new Uint8Array(frames[0].data),
            new Uint8Array([0x12, 0x34]),
            'extracted the first AAC frame');
  assert.deepEqual(new Uint8Array(frames[1].data),
            new Uint8Array([0x9a, 0xbc]),
            'extracted the second AAC frame');
});

QUnit.test('resyncs data in aac frames that contain garbage', function(assert) {
  var frames = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });

  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0x67,             // garbage
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x9a, 0xbc,       // AAC payload 1
      0xde, 0xf0        // extra junk that should be ignored
    ])
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0x67,             // garbage
      0xff, 0xf1,       // no CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x20, // 2 channels, frame length 9 bytes
      0x00,             // one AAC per ADTS frame
      0x12, 0x34        // AAC payload 2
    ])
  });

  assert.equal(frames.length, 2, 'parsed two frames');
  assert.deepEqual(new Uint8Array(frames[0].data),
            new Uint8Array([0x9a, 0xbc]),
            'extracted the first AAC frame');
  assert.deepEqual(new Uint8Array(frames[1].data),
            new Uint8Array([0x12, 0x34]),
            'extracted the second AAC frame');
});

QUnit.test('ignores audio "MPEG version" bit in adts header', function(assert) {
  var frames = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0xff, 0xf8,       // MPEG-2 audio, CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x60, // 2 channels, frame length 11 bytes
      0x00,             // one AAC per ADTS frame
      0xfe, 0xdc,       // "CRC"
      0x12, 0x34        // AAC payload 2
    ])
  });

  assert.equal(frames.length, 1, 'parsed a frame');
  assert.deepEqual(new Uint8Array(frames[0].data),
            new Uint8Array([0x12, 0x34]),
            'skipped the CRC');
});

QUnit.test('skips CRC bytes', function(assert) {
  var frames = [];
  adtsStream.on('data', function(frame) {
    frames.push(frame);
  });
  adtsStream.push({
    type: 'audio',
    data: new Uint8Array([
      0xff, 0xf0,       // with CRC
      0x10,             // AAC Main, 44.1KHz
      0xbc, 0x01, 0x60, // 2 channels, frame length 11 bytes
      0x00,             // one AAC per ADTS frame
      0xfe, 0xdc,       // "CRC"
      0x12, 0x34        // AAC payload 2
    ])
  });

  assert.equal(frames.length, 1, 'parsed a frame');
  assert.deepEqual(new Uint8Array(frames[0].data),
            new Uint8Array([0x12, 0x34]),
            'skipped the CRC');
});

QUnit.module('AudioSegmentStream', {
  beforeEach: function() {
    var track = {
      type: 'audio',
      samplerate: 90e3 // no scaling
    };
    audioSegmentStream = new AudioSegmentStream(track);
    audioSegmentStream.track = track;
    audioSegmentStream.track.timelineStartInfo = {
      dts: 111,
      pts: 111,
      baseMediaDecodeTime: 0
    };
  }
});

QUnit.test('fills audio gaps taking into account audio sample rate', function(assert) {
  var
    events = [],
    boxes,
    numSilentFrames,
    videoGap = 0.29,
    audioGap = 0.49,
    expectedFillSeconds = audioGap - videoGap,
    sampleRate = 44100,
    frameDuration = Math.ceil(90e3 / (sampleRate / 1024)),
    frameSeconds = clock.videoTsToSeconds(frameDuration),
    audioBMDT,
    offsetSeconds = clock.videoTsToSeconds(111),
    startingAudioBMDT = clock.secondsToAudioTs(10 + audioGap - offsetSeconds, sampleRate);

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.setAudioAppendStart(clock.secondsToVideoTs(10));
  audioSegmentStream.setVideoBaseMediaDecodeTime(clock.secondsToVideoTs(10 + videoGap));

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: sampleRate,
    pts: clock.secondsToVideoTs(10 + audioGap),
    dts: clock.secondsToVideoTs(10 + audioGap),
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  numSilentFrames = Math.floor(expectedFillSeconds / frameSeconds);

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1 + numSilentFrames, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 364, 'silent sample');
  assert.equal(events[0].track.samples[7].size, 364, 'silent sample');
  assert.equal(events[0].track.samples[8].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);

  audioBMDT = boxes[0].boxes[1].boxes[1].baseMediaDecodeTime;

  assert.equal(
    audioBMDT,
    // should always be rounded up so as not to overfill
    Math.ceil(startingAudioBMDT -
              clock.secondsToAudioTs(numSilentFrames * frameSeconds, sampleRate)),
    'filled the gap to the nearest frame');
  assert.equal(
    Math.floor(clock.audioTsToVideoTs(audioBMDT, sampleRate) -
               clock.secondsToVideoTs(10 + videoGap)),
    Math.floor(clock.secondsToVideoTs(expectedFillSeconds) % frameDuration -
               clock.secondsToVideoTs(offsetSeconds)),
               'filled all but frame remainder between video start and audio start');
});

QUnit.test('fills audio gaps with existing frame if odd sample rate', function(assert) {
  var
    events = [],
    boxes,
    numSilentFrames,
    videoGap = 0.29,
    audioGap = 0.49,
    expectedFillSeconds = audioGap - videoGap,
    sampleRate = 90e3, // we don't have matching silent frames
    frameDuration = Math.ceil(90e3 / (sampleRate / 1024)),
    frameSeconds = clock.videoTsToSeconds(frameDuration),
    audioBMDT,
    offsetSeconds = clock.videoTsToSeconds(111),
    startingAudioBMDT = clock.secondsToAudioTs(10 + audioGap - offsetSeconds, sampleRate);

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.setAudioAppendStart(clock.secondsToVideoTs(10));
  audioSegmentStream.setVideoBaseMediaDecodeTime(clock.secondsToVideoTs(10 + videoGap));

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: sampleRate,
    pts: clock.secondsToVideoTs(10 + audioGap),
    dts: clock.secondsToVideoTs(10 + audioGap),
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  numSilentFrames = Math.floor(expectedFillSeconds / frameSeconds);

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1 + numSilentFrames, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 1, 'copied sample');
  assert.equal(events[0].track.samples[7].size, 1, 'copied sample');
  assert.equal(events[0].track.samples[8].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);

  audioBMDT = boxes[0].boxes[1].boxes[1].baseMediaDecodeTime;

  assert.equal(
    audioBMDT,
    // should always be rounded up so as not to overfill
    Math.ceil(startingAudioBMDT -
              clock.secondsToAudioTs(numSilentFrames * frameSeconds, sampleRate)),
    'filled the gap to the nearest frame');
  assert.equal(
    Math.floor(clock.audioTsToVideoTs(audioBMDT, sampleRate) -
               clock.secondsToVideoTs(10 + videoGap)),
    Math.floor(clock.secondsToVideoTs(expectedFillSeconds) % frameDuration -
               clock.secondsToVideoTs(offsetSeconds)),
               'filled all but frame remainder between video start and audio start');
});

QUnit.test('fills audio gaps with smaller of audio gap and audio-video gap', function(assert) {
  var
    events = [],
    boxes,
    offsetSeconds = clock.videoTsToSeconds(111),
    videoGap = 0.29,
    sampleRate = 44100,
    frameDuration = Math.ceil(90e3 / (sampleRate / 1024)),
    frameSeconds = clock.videoTsToSeconds(frameDuration),
    // audio gap smaller, should be used as fill
    numSilentFrames = 1,
    // buffer for imprecise numbers
    audioGap = frameSeconds + offsetSeconds + 0.001,
    oldAudioEnd = 10.5,
    audioBMDT;

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.setAudioAppendStart(clock.secondsToVideoTs(oldAudioEnd));
  audioSegmentStream.setVideoBaseMediaDecodeTime(clock.secondsToVideoTs(10 + videoGap));

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: sampleRate,
    pts: clock.secondsToVideoTs(oldAudioEnd + audioGap),
    dts: clock.secondsToVideoTs(oldAudioEnd + audioGap),
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1 + numSilentFrames, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 364, 'silent sample');
  assert.equal(events[0].track.samples[1].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);

  audioBMDT = boxes[0].boxes[1].boxes[1].baseMediaDecodeTime;

  assert.equal(
    Math.floor(clock.secondsToVideoTs(oldAudioEnd + audioGap) -
               clock.audioTsToVideoTs(audioBMDT, sampleRate) -
               clock.secondsToVideoTs(offsetSeconds)),
    Math.floor(frameDuration + 0.001),
    'filled length of audio gap only');
});

QUnit.test('does not fill audio gaps if no audio append start time', function(assert) {
  var
    events = [],
    boxes,
    videoGap = 0.29,
    audioGap = 0.49;

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.setVideoBaseMediaDecodeTime((10 + videoGap) * 90e3);

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: (10 + audioGap) * 90e3,
    dts: (10 + audioGap) * 90e3,
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);
  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime,
              (10 + audioGap) * 90e3 - 111,
              'did not fill gap');
});

QUnit.test('does not fill audio gap if no video base media decode time', function(assert) {
  var
    events = [],
    boxes,
    audioGap = 0.49;

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.setAudioAppendStart(10 * 90e3);

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: (10 + audioGap) * 90e3,
    dts: (10 + audioGap) * 90e3,
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);
  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime,
              (10 + audioGap) * 90e3 - 111,
              'did not fill the gap');
});

QUnit.test('does not fill audio gaps greater than a half second', function(assert) {
  var
    events = [],
    boxes,
    videoGap = 0.01,
    audioGap = videoGap + 0.51;

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.setAudioAppendStart(10 * 90e3);
  audioSegmentStream.setVideoBaseMediaDecodeTime((10 + videoGap) * 90e3);

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: (10 + audioGap) * 90e3,
    dts: (10 + audioGap) * 90e3,
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);
  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime,
              (10 + audioGap) * 90e3 - 111,
              'did not fill gap');
});

QUnit.test('does not fill audio gaps smaller than a frame duration', function(assert) {
  var
    events = [],
    boxes,
    offsetSeconds = clock.videoTsToSeconds(111),
    // audio gap small enough that it shouldn't be filled
    audioGap = 0.001,
    newVideoStart = 10,
    oldAudioEnd = 10.3,
    newAudioStart = oldAudioEnd + audioGap + offsetSeconds;

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  // the real audio gap is tiny, but the gap between the new video and audio segments
  // would be large enough to fill
  audioSegmentStream.setAudioAppendStart(clock.secondsToVideoTs(oldAudioEnd));
  audioSegmentStream.setVideoBaseMediaDecodeTime(clock.secondsToVideoTs(newVideoStart));

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: clock.secondsToVideoTs(newAudioStart),
    dts: clock.secondsToVideoTs(newAudioStart),
    data: new Uint8Array([1])
  });

  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1, 'generated samples');
  assert.equal(events[0].track.samples[0].size, 1, 'normal sample');
  boxes = mp4.tools.inspect(events[0].boxes);
  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime,
              clock.secondsToVideoTs(newAudioStart - offsetSeconds),
              'did not fill gap');
});

QUnit.test('ensures baseMediaDecodeTime for audio is not negative', function(assert) {
  var events = [], boxes;

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });
  audioSegmentStream.track.timelineStartInfo.baseMediaDecodeTime = 10;
  audioSegmentStream.setEarliestDts(101);
  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: 111 - 10 - 1, // before the earliest DTS
    dts: 111 - 10 - 1, // before the earliest DTS
    data: new Uint8Array([0])
  });
  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: 111 - 10 + 2, // after the earliest DTS
    dts: 111 - 10 + 2, // after the earliest DTS
    data: new Uint8Array([1])
  });
  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 1, 'generated only one sample');
  boxes = mp4.tools.inspect(events[0].boxes);
  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime, 2, 'kept the later sample');
});

QUnit.test('audio track metadata takes on the value of the last metadata seen', function(assert) {
  var events = [];

  audioSegmentStream.on('data', function(event) {
    events.push(event);
  });

  audioSegmentStream.push({
    channelcount: 2,
    samplerate: 90e3,
    pts: 100,
    dts: 100,
    data: new Uint8Array([0])
  });
  audioSegmentStream.push({
    channelcount: 4,
    samplerate: 10000,
    pts: 111,
    dts: 111,
    data: new Uint8Array([1])
  });
  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a data event fired');
  assert.equal(events[0].track.samples.length, 2, 'generated two samples');
  assert.equal(events[0].track.samplerate, 10000, 'kept the later samplerate');
  assert.equal(events[0].track.channelcount, 4, 'kept the later channelcount');
});

QUnit.test('audio segment stream triggers segmentTimingInfo with timing info',
function(assert) {
  var
    events = [],
    samplerate = 48000,
    baseMediaDecodeTimeInVideoClock = 30,
    audioFrameDurationInVideoClock = 90000 * 1024 / samplerate,
    firstFrame = {
      channelcount: 2,
      samplerate: samplerate,
      pts: 112,
      dts: 111,
      data: new Uint8Array([0])
    },
    secondFrame = {
      channelcount: 2,
      samplerate: samplerate,
      pts: firstFrame.pts + audioFrameDurationInVideoClock,
      dts: firstFrame.dts + audioFrameDurationInVideoClock,
      data: new Uint8Array([1])
    };

  audioSegmentStream.on('segmentTimingInfo', function(event) {
    events.push(event);
  });
  audioSegmentStream.track.timelineStartInfo.baseMediaDecodeTime =
    baseMediaDecodeTimeInVideoClock;

  audioSegmentStream.push(firstFrame);
  audioSegmentStream.push(secondFrame);
  audioSegmentStream.flush();

  assert.equal(events.length, 1, 'a segmentTimingInfo event was fired');
  assert.deepEqual(
    events[0],
    {
      start: {
        dts: baseMediaDecodeTimeInVideoClock,
        pts: baseMediaDecodeTimeInVideoClock + (firstFrame.pts - firstFrame.dts)
      },
      end: {
        dts: baseMediaDecodeTimeInVideoClock + (secondFrame.dts - firstFrame.dts) +
          audioFrameDurationInVideoClock,
        pts: baseMediaDecodeTimeInVideoClock + (secondFrame.pts - firstFrame.pts) +
          audioFrameDurationInVideoClock
      },
      prependedContentDuration: 0,
      baseMediaDecodeTime: baseMediaDecodeTimeInVideoClock
    },
    'has correct segmentTimingInfo'
  );
});


QUnit.module('Transmuxer - options');

QUnit.test('no options creates combined output', function(assert) {
  var
    segments = [],
    boxes,
    initSegment,
    transmuxer = new Transmuxer();

  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true,
    hasAudio: true
  })));

  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true)));
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated a combined video and audio segment');
  assert.equal(segments[0].type, 'combined', 'combined is the segment type');

  boxes = mp4.tools.inspect(segments[0].data);
  initSegment = mp4.tools.inspect(segments[0].initSegment);
  assert.equal(initSegment.length, 2, 'generated 2 init segment boxes');
  assert.equal('ftyp', initSegment[0].type, 'generated an ftyp box');
  assert.equal('moov', initSegment[1].type, 'generated a single moov box');
  assert.equal(boxes.length, 4, 'generated 4 top-level boxes');
  assert.equal('moof', boxes[0].type, 'generated a first moof box');
  assert.equal('mdat', boxes[1].type, 'generated a first mdat box');
  assert.equal('moof', boxes[2].type, 'generated a second moof box');
  assert.equal('mdat', boxes[3].type, 'generated a second mdat box');
});

QUnit.test('first sequence number option is used in mfhd box', function(assert) {
  var
    segments = [],
    mfhds = [],
    boxes,
    transmuxer = new Transmuxer({ firstSequenceNumber: 10 });

  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true,
    hasAudio: true
  })));

  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true)));
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated a combined video and audio segment');
  assert.equal(segments[0].type, 'combined', 'combined is the segment type');

  boxes = mp4.tools.inspect(segments[0].data);
  boxes.forEach(function(box) {
    if (box.type === 'moof') {
      box.boxes.forEach(function(moofBox) {
        if (moofBox.type === 'mfhd') {
          mfhds.push(moofBox);
        }
      });
    }
  });

  assert.equal(mfhds.length, 2, 'muxed output has two mfhds');

  assert.equal(mfhds[0].sequenceNumber, 10, 'first mfhd sequence starts at 10');
  assert.equal(mfhds[1].sequenceNumber, 10, 'second mfhd sequence starts at 10');
});

QUnit.test('can specify that we want to generate separate audio and video segments', function(assert) {
  var
    segments = [],
    segmentLengthOnDone,
    boxes,
    initSegment,
    transmuxer = new Transmuxer({remux: false});

  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.on('done', function(segment) {
    if (!segmentLengthOnDone) {
      segmentLengthOnDone = segments.length;
    }
  });

  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true,
    hasAudio: true
  })));

  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true)));
  transmuxer.flush();

  assert.equal(segmentLengthOnDone, 2, 'emitted both segments before triggering done');
  assert.equal(segments.length, 2, 'generated a video and an audio segment');
  assert.ok(segments[0].type === 'video' || segments[1].type === 'video', 'one segment is video');
  assert.ok(segments[0].type === 'audio' || segments[1].type === 'audio', 'one segment is audio');

  boxes = mp4.tools.inspect(segments[0].data);
  initSegment = mp4.tools.inspect(segments[0].initSegment);
  assert.equal(initSegment.length, 2, 'generated 2 top-level initSegment boxes');
  assert.equal(boxes.length, 2, 'generated 2 top-level boxes');
  assert.equal('ftyp', initSegment[0].type, 'generated an ftyp box');
  assert.equal('moov', initSegment[1].type, 'generated a moov box');
  assert.equal('moof', boxes[0].type, 'generated a moof box');
  assert.equal('mdat', boxes[1].type, 'generated a mdat box');

  boxes = mp4.tools.inspect(segments[1].data);
  initSegment = mp4.tools.inspect(segments[1].initSegment);
  assert.equal(initSegment.length, 2, 'generated 2 top-level initSegment boxes');
  assert.equal(boxes.length, 2, 'generated 2 top-level boxes');
  assert.equal('ftyp', initSegment[0].type, 'generated an ftyp box');
  assert.equal('moov', initSegment[1].type, 'generated a moov box');
  assert.equal('moof', boxes[0].type, 'generated a moof box');
  assert.equal('mdat', boxes[1].type, 'generated a mdat box');
});

QUnit.test('adjusts caption and ID3 times when configured to adjust timestamps', function(assert) {
  var transmuxer = new Transmuxer({ keepOriginalTimestamps: false });

  var
    segments = [],
    captions = [];

  transmuxer.on('data', function(segment) {
    captions = captions.concat(segment.captions);
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true,
    hasAudio: true
  })));

  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true, 90000)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true, 90000)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true, 90002)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false, 90002)));
  transmuxer.push(packetize(videoPes([
      0x06, // sei_rbsp
      0x04, 0x29, 0xb5, 0x00,
      0x31, 0x47, 0x41, 0x39,
      0x34, 0x03, 0x52, 0xff,
      0xfc, 0x94, 0xae, 0xfc,
      0x94, 0x20, 0xfc, 0x91,
      0x40, 0xfc, 0xb0, 0xb0,
      0xfc, 0xba, 0xb0, 0xfc,
      0xb0, 0xba, 0xfc, 0xb0,
      0xb0, 0xfc, 0x94, 0x2f,
      0xfc, 0x94, 0x2f, 0xfc,
      0x94, 0x2f, 0xff, 0x80,
      0x00 // has an extra End Of Caption, so start and end times will be the same
  ], true, 90002)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true, 90004)));
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated a combined video and audio segment');
  assert.equal(segments[0].type, 'combined', 'combined is the segment type');
  assert.equal(captions.length, 1, 'got one caption');
  assert.equal(captions[0].startPts, 90004, 'original pts value intact');
  assert.equal(captions[0].startTime, (90004 - 90002) / 90e3, 'caption start time are based on original timeline');
  assert.equal(captions[0].endTime, (90004 - 90002) / 90e3, 'caption end time are based on original timeline');
});

[
  {options: {keepOriginalTimestamps: false}},
  {options: {keepOriginalTimestamps: true}},
  {options: {keepOriginalTimestamps: false, baseMediaDecodeTime: 15000}},
  {options: {keepOriginalTimestamps: true, baseMediaDecodeTime: 15000}},
  {options: {keepOriginalTimestamps: false}, baseMediaSetter: 15000},
  {options: {keepOriginalTimestamps: true}, baseMediaSetter: 15000}
].forEach(function(test) {
  var createTransmuxer = function() {
    var transmuxer = new Transmuxer(test.options);

    if (test.baseMediaSetter) {
      transmuxer.setBaseMediaDecodeTime(test.baseMediaSetter);
    }

    return transmuxer;
  };

  var name = '';

  Object.keys(test.options).forEach(function(optionName) {
    name += '' + optionName + ' ' + test.options[optionName] + ' ';
  });

  if (test.baseMediaSetter) {
    name += 'baseMediaDecodeTime setter ' + test.baseMediaSetter;
  }

  QUnit.test('Audio frames after video not trimmed, ' + name, function(assert) {
    var
    segments = [],
      earliestDts = 15000,
      transmuxer = createTransmuxer();

    transmuxer.on('data', function(segment) {
      segments.push(segment);
    });

    // the following transmuxer pushes add tiny video and
    // audio data to the transmuxer. When we add the data
    // we also set the pts/dts time so that audio should
    // not be trimmed.
    transmuxer.push(packetize(PAT));
    transmuxer.push(packetize(generatePMT({
      hasVideo: true,
      hasAudio: true
    })));

    transmuxer.push(packetize(audioPes([
      0x19, 0x47
    ], true, earliestDts + 1)));
    transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x07, // seq_parameter_set_rbsp
      0x27, 0x42, 0xe0, 0x0b,
      0xa9, 0x18, 0x60, 0x9d,
      0x80, 0x53, 0x06, 0x01,
      0x06, 0xb6, 0xc2, 0xb5,
      0xef, 0x7c, 0x04
    ], false, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
    ], true, earliestDts)));
    transmuxer.flush();

    assert.equal(segments.length, 1, 'generated a combined segment');
    // The audio frame is 10 bytes. The full data is 305 bytes without anything
    // trimmed. If the audio frame was trimmed this will be 295 bytes.
    assert.equal(segments[0].data.length, 305, 'trimmed audio frame');
  });

  QUnit.test('Audio frames trimmed before video, ' + name, function(assert) {
    var
      segments = [],
      earliestDts = 15000,
      baseTime = test.options.baseMediaDecodeTime || test.baseMediaSetter || 0,
      transmuxer = createTransmuxer();

    transmuxer.on('data', function(segment) {
      segments.push(segment);
    });

    // the following transmuxer pushes add tiny video and
    // audio data to the transmuxer. When we add the data
    // we also set the pts/dts time so that audio should
    // be trimmed.
    transmuxer.push(packetize(PAT));
    transmuxer.push(packetize(generatePMT({
      hasVideo: true,
      hasAudio: true
    })));

    transmuxer.push(packetize(audioPes([
      0x19, 0x47
    ], true, earliestDts - baseTime - 1)));
    transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
    ], true, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x07, // seq_parameter_set_rbsp
      0x27, 0x42, 0xe0, 0x0b,
      0xa9, 0x18, 0x60, 0x9d,
      0x80, 0x53, 0x06, 0x01,
      0x06, 0xb6, 0xc2, 0xb5,
      0xef, 0x7c, 0x04
    ], false, earliestDts)));
    transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
    ], true, earliestDts)));
    transmuxer.flush();

    assert.equal(segments.length, 1, 'generated a combined segment');
    // The audio frame is 10 bytes. The full data is 305 bytes without anything
    // trimmed. If the audio frame was trimmed this will be 295 bytes.
    if (test.options.keepOriginalTimestamps && !baseTime) {
      assert.equal(segments[0].data.length, 305, 'did not trim audio frame');
    } else {
      assert.equal(segments[0].data.length, 295, 'trimmed audio frame');
    }
  });
});

QUnit.test("doesn't adjust caption and ID3 times when configured to keep original timestamps", function(assert) {
  var transmuxer = new Transmuxer({ keepOriginalTimestamps: true });

  var
    segments = [],
    captions = [];

  transmuxer.on('data', function(segment) {
    captions = captions.concat(segment.captions);
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true,
    hasAudio: true
  })));

  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true, 90000)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true, 90000)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true, 90002)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false, 90002)));
  transmuxer.push(packetize(videoPes([
      0x06, // sei_rbsp
      0x04, 0x29, 0xb5, 0x00,
      0x31, 0x47, 0x41, 0x39,
      0x34, 0x03, 0x52, 0xff,
      0xfc, 0x94, 0xae, 0xfc,
      0x94, 0x20, 0xfc, 0x91,
      0x40, 0xfc, 0xb0, 0xb0,
      0xfc, 0xba, 0xb0, 0xfc,
      0xb0, 0xba, 0xfc, 0xb0,
      0xb0, 0xfc, 0x94, 0x2f,
      0xfc, 0x94, 0x2f, 0xfc,
      0x94, 0x2f, 0xff, 0x80,
      0x00 // has an extra End Of Caption, so start and end times will be the same
  ], true, 90002)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true, 90004)));
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated a combined video and audio segment');
  assert.equal(segments[0].type, 'combined', 'combined is the segment type');
  assert.equal(captions.length, 1, 'got one caption');
  assert.equal(captions[0].startPts, 90004, 'original pts value intact');
  assert.equal(captions[0].startTime, 90004 / 90e3, 'caption start time are based on original timeline');
  assert.equal(captions[0].endTime, 90004 / 90e3, 'caption end time are based on original timeline');
});

QUnit.module('MP4 - Transmuxer', {
  beforeEach: function() {
    transmuxer = new Transmuxer();
  }
});

QUnit.test('generates a video init segment', function(assert) {
  var segments = [], boxes;
  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x87, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true)));
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated a segment');
  assert.ok(segments[0].data, 'wrote data in the init segment');
  assert.equal(segments[0].type, 'video', 'video is the segment type');
  assert.ok(segments[0].info, 'video info is alongside video segments/bytes');

  mp4VideoProperties.forEach(function(prop) {
    assert.ok(segments[0].info[prop], 'video info has ' + prop);
  });

  boxes = mp4.tools.inspect(segments[0].initSegment);
  assert.equal('ftyp', boxes[0].type, 'generated an ftyp box');
  assert.equal('moov', boxes[1].type, 'generated a moov box');
});

QUnit.test('transmuxer triggers video timing info event on flush', function(assert) {
  var videoSegmentTimingInfoArr = [];

  transmuxer.on('videoSegmentTimingInfo', function(videoSegmentTimingInfo) {
    videoSegmentTimingInfoArr.push(videoSegmentTimingInfo);
  });

  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false)));
  transmuxer.push(packetize(videoPes([
      0x05, 0x01 // slice_layer_without_partitioning_rbsp_idr
  ], true)));

  assert.equal(
    videoSegmentTimingInfoArr.length,
    0,
    'has not triggered videoSegmentTimingInfo'
  );

  transmuxer.flush();

  assert.equal(videoSegmentTimingInfoArr.length, 1, 'triggered videoSegmentTimingInfo');
});

QUnit.test('generates an audio init segment', function(assert) {
  var segments = [], boxes;
  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasAudio: true
  })));
  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true)));
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated a segment');
  assert.ok(segments[0].data, 'wrote data in the init segment');
  assert.equal(segments[0].type, 'audio', 'audio is the segment type');
  assert.ok(segments[0].info, 'audio info is alongside audio segments/bytes');
  mp4AudioProperties.forEach(function(prop) {
    assert.ok(segments[0].info[prop], 'audio info has ' + prop);
  });

  boxes = mp4.tools.inspect(segments[0].initSegment);
  assert.equal('ftyp', boxes[0].type, 'generated an ftyp box');
  assert.equal('moov', boxes[1].type, 'generated a moov box');
});

QUnit.test('buffers video samples until flushed', function(assert) {
  var samples = [], offset, boxes, initSegment;
  transmuxer.on('data', function(data) {
    samples.push(data);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  // buffer a NAL
  transmuxer.push(packetize(videoPes([0x09, 0x01], true)));
  transmuxer.push(packetize(videoPes([0x05, 0x02])));

  // add an access_unit_delimiter_rbsp
  transmuxer.push(packetize(videoPes([0x09, 0x03])));
  transmuxer.push(packetize(videoPes([0x00, 0x04])));
  transmuxer.push(packetize(videoPes([0x00, 0x05])));

  // flush everything
  transmuxer.flush();
  assert.equal(samples.length, 1, 'emitted one event');
  boxes = mp4.tools.inspect(samples[0].data);
  initSegment = mp4.tools.inspect(samples[0].initSegment);
  assert.equal(boxes.length, 2, 'generated two boxes');
  assert.equal(initSegment.length, 2, 'generated two init segment boxes');
  assert.equal(boxes[0].type, 'moof', 'the first box is a moof');
  assert.equal(boxes[1].type, 'mdat', 'the second box is a mdat');

  offset = boxes[0].size + 8;
  assert.deepEqual(new Uint8Array(samples[0].data.subarray(offset)),
            new Uint8Array([
              0, 0, 0, 2,
              0x09, 0x01,
              0, 0, 0, 2,
              0x05, 0x02,
              0, 0, 0, 2,
              0x09, 0x03,
              0, 0, 0, 2,
              0x00, 0x04,
              0, 0, 0, 2,
              0x00, 0x05]),
            'concatenated NALs into an mdat');
});

QUnit.test('creates a metadata stream', function(assert) {
  transmuxer.push(packetize(PAT));
  assert.ok(transmuxer.transmuxPipeline_.metadataStream, 'created a metadata stream');
});

QUnit.test('pipes timed metadata to the metadata stream', function(assert) {
  var metadatas = [];
  transmuxer.push(packetize(PAT));
  transmuxer.transmuxPipeline_.metadataStream.on('data', function(data) {
    metadatas.push(data);
  });
  transmuxer.push(packetize(PMT));
  transmuxer.push(packetize(timedMetadataPes([0x03])));

  transmuxer.flush();
  assert.equal(metadatas.length, 1, 'emitted timed metadata');
});

QUnit.test('pipeline dynamically configures itself based on input', function(assert) {
  var id3 = id3Generator;

  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasAudio: true
  })));
  transmuxer.push(packetize(timedMetadataPes([0x03])));
  transmuxer.flush();
  assert.equal(transmuxer.transmuxPipeline_.type, 'ts', 'detected TS file data');

  transmuxer.push(new Uint8Array(id3.id3Tag(id3.id3Frame('PRIV', 0x00, 0x01)).concat([0xFF, 0xF1])));
  transmuxer.flush();
  assert.equal(transmuxer.transmuxPipeline_.type, 'aac', 'detected AAC file data');
});

QUnit.test('pipeline retriggers log events', function(assert) {
  var id3 = id3Generator;
  var logs = [];

  var checkLogs = function() {
    Object.keys(transmuxer.transmuxPipeline_).forEach(function(key) {
      var stream = transmuxer.transmuxPipeline_[key];

      if (!stream.on || key === 'headOfPipeline') {
        return;
      }

      stream.trigger('log', {level: 'foo', message: 'bar'});

      assert.deepEqual(logs, [
        {level: 'foo', message: 'bar', stream: key}
      ], 'retriggers log from ' + key);
      logs.length = 0;
    });
  };

  transmuxer.on('log', function(log) {
    logs.push(log);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasAudio: true
  })));
  transmuxer.push(packetize(timedMetadataPes([0x03])));
  transmuxer.flush();
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasAudio: true
  })));
  transmuxer.push(packetize(timedMetadataPes([0x03])));
  transmuxer.flush();
  assert.equal(transmuxer.transmuxPipeline_.type, 'ts', 'detected TS file data');
  checkLogs();

  transmuxer.push(new Uint8Array(id3.id3Tag(id3.id3Frame('PRIV', 0x00, 0x01)).concat([0xFF, 0xF1])));
  transmuxer.flush();
  transmuxer.push(new Uint8Array(id3.id3Tag(id3.id3Frame('PRIV', 0x00, 0x01)).concat([0xFF, 0xF1])));
  transmuxer.flush();
  assert.equal(transmuxer.transmuxPipeline_.type, 'aac', 'detected AAC file data');
  checkLogs();
});

QUnit.test('reuses audio track object when the pipeline reconfigures itself', function(assert) {
  var boxes, segments = [],
    id3Tag = new Uint8Array(75),
    streamTimestamp = 'com.apple.streaming.transportStreamTimestamp',
    priv = 'PRIV',
    i,
    adtsPayload;

  id3Tag[0] = 73;
  id3Tag[1] = 68;
  id3Tag[2] = 51;
  id3Tag[3] = 4;
  id3Tag[9] = 63;
  id3Tag[17] = 53;
  id3Tag[70] = 13;
  id3Tag[71] = 187;
  id3Tag[72] = 160;
  id3Tag[73] = 0xFF;
  id3Tag[74] = 0xF1;

  for (i = 0; i < priv.length; i++) {
    id3Tag[i + 10] = priv.charCodeAt(i);
  }
  for (i = 0; i < streamTimestamp.length; i++) {
    id3Tag[i + 20] = streamTimestamp.charCodeAt(i);
  }

  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });

  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(packetize(generatePMT({
    hasAudio: true
  }))));
  transmuxer.push(packetize(audioPes([0x19, 0x47], true, 10000)));
  transmuxer.flush();

  boxes = mp4.tools.inspect(segments[0].data);

  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime,
    0,
    'first segment starts at 0 pts');

  adtsPayload = new Uint8Array(adtsFrame(2).concat([0x19, 0x47]));

  transmuxer.push(id3Tag);
  transmuxer.push(adtsPayload);
  transmuxer.flush();

  boxes = mp4.tools.inspect(segments[1].data);

  assert.equal(boxes[0].boxes[1].boxes[1].baseMediaDecodeTime,
    // The first segment had a PTS of 10,000 and the second segment 900,000
    // Audio PTS is specified in a clock equal to samplerate (44.1khz)
    // So you have to take the different between the PTSs (890,000)
    // and transform it from 90khz to 44.1khz clock
    Math.floor((900000 - 10000) / (90000 / 44100)),
    'second segment starts at the right time');
});

validateTrack = function(track, metadata) {
  var mdia;
  QUnit.assert.equal(track.type, 'trak', 'wrote the track type');
  QUnit.assert.equal(track.boxes.length, 2, 'wrote track children');
  QUnit.assert.equal(track.boxes[0].type, 'tkhd', 'wrote the track header');
  if (metadata) {
    if (metadata.trackId) {
      QUnit.assert.equal(track.boxes[0].trackId, metadata.trackId, 'wrote the track id');
    }
    if (metadata.width) {
      QUnit.assert.equal(track.boxes[0].width, metadata.width, 'wrote the width');
    }
    if (metadata.height) {
      QUnit.assert.equal(track.boxes[0].height, metadata.height, 'wrote the height');
    }
  }

  mdia = track.boxes[1];
  QUnit.assert.equal(mdia.type, 'mdia', 'wrote the media');
  QUnit.assert.equal(mdia.boxes.length, 3, 'wrote the mdia children');

  QUnit.assert.equal(mdia.boxes[0].type, 'mdhd', 'wrote the media header');
  QUnit.assert.equal(mdia.boxes[0].language, 'und', 'the language is undefined');
  QUnit.assert.equal(mdia.boxes[0].duration, 0xffffffff, 'the duration is at maximum');

  QUnit.assert.equal(mdia.boxes[1].type, 'hdlr', 'wrote the media handler');

  QUnit.assert.equal(mdia.boxes[2].type, 'minf', 'wrote the media info');
};

validateTrackFragment = function(track, segment, metadata, type) {
  var tfhd, trun, sdtp, i, j, sample, nalUnitType;
  QUnit.assert.equal(track.type, 'traf', 'wrote a track fragment');

  if (type === 'video') {
    QUnit.assert.equal(track.boxes.length, 4, 'wrote four track fragment children');
  } else if (type === 'audio') {
    QUnit.assert.equal(track.boxes.length, 3, 'wrote three track fragment children');
  }

  tfhd = track.boxes[0];
  QUnit.assert.equal(tfhd.type, 'tfhd', 'wrote a track fragment header');
  QUnit.assert.equal(tfhd.trackId, metadata.trackId, 'wrote the track id');

  QUnit.assert.equal(track.boxes[1].type,
        'tfdt',
        'wrote a track fragment decode time box');
  QUnit.assert.ok(track.boxes[1].baseMediaDecodeTime >= 0, 'base decode time is non-negative');

  trun = track.boxes[2];
  QUnit.assert.ok(trun.dataOffset >= 0, 'set data offset');

  QUnit.assert.equal(trun.dataOffset,
        metadata.mdatOffset + 8,
        'trun data offset is the size of the moof');

  QUnit.assert.ok(trun.samples.length > 0, 'generated media samples');
  for (i = 0, j = metadata.baseOffset + trun.dataOffset;
       i < trun.samples.length;
       i++) {
    sample = trun.samples[i];
    QUnit.assert.ok(sample.size > 0, 'wrote a positive size for sample ' + i);
    if (type === 'video') {
      QUnit.assert.ok(sample.duration > 0, 'wrote a positive duration for sample ' + i);
      QUnit.assert.ok(sample.compositionTimeOffset >= 0,
         'wrote a positive composition time offset for sample ' + i);
      QUnit.assert.ok(sample.flags, 'wrote sample flags');
      QUnit.assert.equal(sample.flags.isLeading, 0, 'the leading nature is unknown');

      QUnit.assert.notEqual(sample.flags.dependsOn, 0, 'sample dependency is not unknown');
      QUnit.assert.notEqual(sample.flags.dependsOn, 4, 'sample dependency is valid');
      nalUnitType = segment[j + 4] & 0x1F;
      QUnit.assert.equal(nalUnitType, 9, 'samples begin with an access_unit_delimiter_rbsp');

      QUnit.assert.equal(sample.flags.isDependedOn, 0, 'dependency of other samples is unknown');
      QUnit.assert.equal(sample.flags.hasRedundancy, 0, 'sample redundancy is unknown');
      QUnit.assert.equal(sample.flags.degradationPriority, 0, 'sample degradation priority is zero');
      // If current sample is Key frame
      if (sample.flags.dependsOn === 2) {
        QUnit.assert.equal(sample.flags.isNonSyncSample, 0, 'samples_is_non_sync_sample flag is zero');
      } else {
        QUnit.assert.equal(sample.flags.isNonSyncSample, 1, 'samples_is_non_sync_sample flag is one');
      }
    } else {
      QUnit.assert.equal(sample.duration, 1024,
            'aac sample duration is always 1024');
    }
    j += sample.size; // advance to the next sample in the mdat
  }

  if (type === 'video') {
    sdtp = track.boxes[3];
    QUnit.assert.equal(trun.samples.length,
          sdtp.samples.length,
          'wrote an QUnit.equal number of trun and sdtp samples');
    for (i = 0; i < sdtp.samples.length; i++) {
      sample = sdtp.samples[i];
      QUnit.assert.notEqual(sample.dependsOn, 0, 'sample dependency is not unknown');
      QUnit.assert.equal(trun.samples[i].flags.dependsOn,
            sample.dependsOn,
            'wrote a consistent dependsOn');
      QUnit.assert.equal(trun.samples[i].flags.isDependedOn,
            sample.isDependedOn,
            'wrote a consistent isDependedOn');
      QUnit.assert.equal(trun.samples[i].flags.hasRedundancy,
            sample.hasRedundancy,
            'wrote a consistent hasRedundancy');
    }
  }
};

QUnit.test('parses an example mp2t file and generates combined media segments', function(assert) {
  var
    segments = [],
    i, j, boxes, mfhd, trackType = 'audio', trackId = 257, baseOffset = 0, initSegment;

  transmuxer.on('data', function(segment) {
    if (segment.type === 'combined') {
      segments.push(segment);
    }
  });
  transmuxer.push(testSegment);
  transmuxer.flush();

  assert.equal(segments.length, 1, 'generated one combined segment');

  boxes = mp4.tools.inspect(segments[0].data);
  initSegment = mp4.tools.inspect(segments[0].initSegment);
  assert.equal(boxes.length, 4, 'combined segments are composed of 4 boxes');
  assert.equal(initSegment.length, 2, 'init segment is composed of 2 boxes');
  assert.equal(initSegment[0].type, 'ftyp', 'the first box is an ftyp');
  assert.equal(initSegment[1].type, 'moov', 'the second box is a moov');
  assert.equal(initSegment[1].boxes[0].type, 'mvhd', 'generated an mvhd');
  validateTrack(initSegment[1].boxes[1], {
    trackId: 256
  });
  validateTrack(initSegment[1].boxes[2], {
    trackId: 257
  });

  for (i = 0; i < boxes.length; i += 2) {
    assert.equal(boxes[i].type, 'moof', 'first box is a moof');
    assert.equal(boxes[i].boxes.length, 2, 'the moof has two children');

    mfhd = boxes[i].boxes[0];
    assert.equal(mfhd.type, 'mfhd', 'mfhd is a child of the moof');

    assert.equal(boxes[i + 1].type, 'mdat', 'second box is an mdat');

    // Only do even numbered boxes because the odd-offsets will be mdat
    if (i % 2 === 0) {
      for (j = 0; j < i; j++) {
        baseOffset += boxes[j].size;
      }

      validateTrackFragment(boxes[i].boxes[1], segments[0].data, {
        trackId: trackId,
        width: 388,
        height: 300,
        baseOffset: baseOffset,
        mdatOffset: boxes[i].size
      }, trackType);

      trackId--;
      baseOffset = 0;
      trackType = 'video';
    }
  }
});

QUnit.test('can be reused for multiple TS segments', function(assert) {
  var
    boxes = [],
    initSegments = [];

  transmuxer.on('data', function(segment) {
    if (segment.type === 'combined') {
      boxes.push(mp4.tools.inspect(segment.data));
      initSegments.push(mp4.tools.inspect(segment.initSegment));
    }
  });
  transmuxer.push(testSegment);
  transmuxer.flush();
  transmuxer.push(testSegment);
  transmuxer.flush();

  assert.equal(boxes.length, 2, 'generated two combined segments');
  assert.equal(initSegments.length, 2, 'generated two combined init segments');

  assert.deepEqual(initSegments[0][0], initSegments[1][0], 'generated identical ftyps');
  assert.deepEqual(initSegments[0][1], initSegments[1][1], 'generated identical moovs');

  assert.deepEqual(boxes[0][0].boxes[1],
            boxes[1][0].boxes[1],
            'generated identical video trafs');
  assert.equal(boxes[0][0].boxes[0].sequenceNumber,
        0,
        'set the correct video sequence number');
  assert.equal(boxes[1][0].boxes[0].sequenceNumber,
        1,
        'set the correct video sequence number');
  assert.deepEqual(boxes[0][1],
            boxes[1][1],
            'generated identical video mdats');

  assert.deepEqual(boxes[0][2].boxes[3],
            boxes[1][2].boxes[3],
            'generated identical audio trafs');
  assert.equal(boxes[0][2].boxes[0].sequenceNumber,
        0,
        'set the correct audio sequence number');
  assert.equal(boxes[1][2].boxes[0].sequenceNumber,
        1,
        'set the correct audio sequence number');
  assert.deepEqual(boxes[0][3],
            boxes[1][3],
            'generated identical audio mdats');
});

QUnit.module('NalByteStream', {
  beforeEach: function() {
    nalByteStream = new NalByteStream();
  }
});

QUnit.test('parses nal units with 4-byte start code', function(assert) {
  var nalUnits = [];
  nalByteStream.on('data', function(data) {
    nalUnits.push(data);
  });

  nalByteStream.push({
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01, // start code
      0x09, 0xFF, // Payload
      0x00, 0x00, 0x00 // end code
    ])
  });

  assert.equal(nalUnits.length, 1, 'found one nal');
  assert.deepEqual(nalUnits[0], new Uint8Array([0x09, 0xFF]), 'has the proper payload');
});

QUnit.test('parses nal units with 3-byte start code', function(assert) {
  var nalUnits = [];
  nalByteStream.on('data', function(data) {
    nalUnits.push(data);
  });

  nalByteStream.push({
    data: new Uint8Array([
      0x00, 0x00, 0x01, // start code
      0x09, 0xFF, // Payload
      0x00, 0x00, 0x00 // end code
    ])
  });

  assert.equal(nalUnits.length, 1, 'found one nal');
  assert.deepEqual(nalUnits[0], new Uint8Array([0x09, 0xFF]), 'has the proper payload');
});

QUnit.test('does not emit empty nal units', function(assert) {
  var dataTriggerCount = 0;
  nalByteStream.on('data', function(data) {
    dataTriggerCount++;
  });

  // An empty nal unit is just two start codes:
  nalByteStream.push({
    data: new Uint8Array([
      0x00, 0x00, 0x00, 0x01, // start code
      0x00, 0x00, 0x00, 0x01  // start code
    ])
  });
  assert.equal(dataTriggerCount, 0, 'emmited no nal units');
});

QUnit.test('parses multiple nal units', function(assert) {
  var nalUnits = [];
  nalByteStream.on('data', function(data) {
    nalUnits.push(data);
  });

  nalByteStream.push({
    data: new Uint8Array([
      0x00, 0x00, 0x01, // start code
      0x09, 0xFF, // Payload
      0x00, 0x00, 0x00, // end code
      0x00, 0x00, 0x01, // start code
      0x12, 0xDD, // Payload
      0x00, 0x00, 0x00 // end code
    ])
  });

  assert.equal(nalUnits.length, 2, 'found two nals');
  assert.deepEqual(nalUnits[0], new Uint8Array([0x09, 0xFF]), 'has the proper payload');
  assert.deepEqual(nalUnits[1], new Uint8Array([0x12, 0xDD]), 'has the proper payload');
});

QUnit.test('parses nal units surrounded by an unreasonable amount of zero-bytes', function(assert) {
  var nalUnits = [];
  nalByteStream.on('data', function(data) {
    nalUnits.push(data);
  });

  nalByteStream.push({
    data: new Uint8Array([
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x01, // start code
      0x09, 0xFF, // Payload
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, // end code
      0x00, 0x00, 0x01, // start code
      0x12, 0xDD, // Payload
      0x00, 0x00, 0x00, // end code
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00,
      0x00, 0x00, 0x00
    ])
  });

  assert.equal(nalUnits.length, 2, 'found two nals');
  assert.deepEqual(nalUnits[0], new Uint8Array([0x09, 0xFF]), 'has the proper payload');
  assert.deepEqual(nalUnits[1], new Uint8Array([0x12, 0xDD]), 'has the proper payload');
});

QUnit.test('parses nal units split across multiple packets', function(assert) {
  var nalUnits = [];
  nalByteStream.on('data', function(data) {
    nalUnits.push(data);
  });

  nalByteStream.push({
    data: new Uint8Array([
      0x00, 0x00, 0x01, // start code
      0x09, 0xFF // Partial payload
    ])
  });
  nalByteStream.push({
    data: new Uint8Array([
      0x12, 0xDD, // Partial Payload
      0x00, 0x00, 0x00 // end code
    ])
  });

  assert.equal(nalUnits.length, 1, 'found one nal');
  assert.deepEqual(nalUnits[0], new Uint8Array([0x09, 0xFF, 0x12, 0xDD]), 'has the proper payload');
});

QUnit.module('FLV - Transmuxer', {
  beforeEach: function() {
    transmuxer = new FlvTransmuxer();
  }
});

QUnit.test('generates video tags', function(assert) {
  var segments = [];
  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));

  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 0, 'generated no audio tags');
  assert.equal(segments[0].tags.videoTags.length, 2, 'generated a two video tags');
});

QUnit.test('drops nalUnits at the start of a segment not preceeded by an access_unit_delimiter_rbsp', function(assert) {
  var segments = [];
  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  transmuxer.push(packetize(videoPes([
      0x08, 0x01 // pic_parameter_set_rbsp
  ], true)));
  transmuxer.push(packetize(videoPes([
    0x07, // seq_parameter_set_rbsp
    0x27, 0x42, 0xe0, 0x0b,
    0xa9, 0x18, 0x60, 0x9d,
    0x80, 0x53, 0x06, 0x01,
    0x06, 0xb6, 0xc2, 0xb5,
    0xef, 0x7c, 0x04
  ], false)));
  transmuxer.push(packetize(videoPes([
      0x09, 0x01 // access_unit_delimiter_rbsp
  ], true)));

  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 0, 'generated no audio tags');
  assert.equal(segments[0].tags.videoTags.length, 1, 'generated a single video tag');
});

QUnit.test('generates audio tags', function(assert) {
  var segments = [];
  transmuxer.on('data', function(segment) {
    segments.push(segment);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasAudio: true
  })));
  transmuxer.push(packetize(audioPes([
    0x19, 0x47
  ], true)));

  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 3, 'generated three audio tags');
  assert.equal(segments[0].tags.videoTags.length, 0, 'generated no video tags');
});

QUnit.test('buffers video samples until flushed', function(assert) {
  var segments = [];
  transmuxer.on('data', function(data) {
    segments.push(data);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  // buffer a NAL
  transmuxer.push(packetize(videoPes([0x09, 0x01], true)));
  transmuxer.push(packetize(videoPes([0x00, 0x02])));

  // add an access_unit_delimiter_rbsp
  transmuxer.push(packetize(videoPes([0x09, 0x03])));
  transmuxer.push(packetize(videoPes([0x00, 0x04])));
  transmuxer.push(packetize(videoPes([0x00, 0x05])));

  // flush everything
  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 0, 'generated no audio tags');
  assert.equal(segments[0].tags.videoTags.length, 2, 'generated two video tags');
});

QUnit.test('does not buffer a duplicate video sample on subsequent flushes', function(assert) {
  var segments = [];
  transmuxer.on('data', function(data) {
    segments.push(data);
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  // buffer a NAL
  transmuxer.push(packetize(videoPes([0x09, 0x01], true)));
  transmuxer.push(packetize(videoPes([0x00, 0x02])));

  // add an access_unit_delimiter_rbsp
  transmuxer.push(packetize(videoPes([0x09, 0x03])));
  transmuxer.push(packetize(videoPes([0x00, 0x04])));
  transmuxer.push(packetize(videoPes([0x00, 0x05])));

  // flush everything
  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 0, 'generated no audio tags');
  assert.equal(segments[0].tags.videoTags.length, 2, 'generated two video tags');

  segments = [];

  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true
  })));

  // buffer a NAL
  transmuxer.push(packetize(videoPes([0x09, 0x01], true)));
  transmuxer.push(packetize(videoPes([0x00, 0x02])));

  // add an access_unit_delimiter_rbsp
  transmuxer.push(packetize(videoPes([0x09, 0x03])));
  transmuxer.push(packetize(videoPes([0x00, 0x04])));
  transmuxer.push(packetize(videoPes([0x00, 0x05])));

  // flush everything
  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 0, 'generated no audio tags');
  assert.equal(segments[0].tags.videoTags.length, 2, 'generated two video tags');
});

QUnit.test('emits done event when no audio data is present', function(assert) {
  var segments = [];
  var done = false;

  transmuxer.on('data', function(data) {
    segments.push(data);
  });
  transmuxer.on('done', function() {
    done = true;
  });
  transmuxer.push(packetize(PAT));
  transmuxer.push(packetize(generatePMT({
    hasVideo: true,
    hasAudio: true
  })));

  // buffer a NAL
  transmuxer.push(packetize(videoPes([0x09, 0x01], true)));
  transmuxer.push(packetize(videoPes([0x00, 0x02])));

  // add an access_unit_delimiter_rbsp
  transmuxer.push(packetize(videoPes([0x09, 0x03])));
  transmuxer.push(packetize(videoPes([0x00, 0x04])));
  transmuxer.push(packetize(videoPes([0x00, 0x05])));

  // flush everything
  transmuxer.flush();

  assert.equal(segments[0].tags.audioTags.length, 0, 'generated no audio tags');
  assert.equal(segments[0].tags.videoTags.length, 2, 'generated two video tags');
  assert.ok(done, 'emitted done event even though no audio data was given');
});
