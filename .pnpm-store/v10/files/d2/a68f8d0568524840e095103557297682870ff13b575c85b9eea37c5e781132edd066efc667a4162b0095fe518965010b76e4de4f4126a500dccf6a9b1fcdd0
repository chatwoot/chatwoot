'use strict';

var segments = require('data-files!segments');

var
  window = require('global/window'),
  captionStream,
  m2ts = require('../lib/m2ts'),
  mp4 = require('../lib/mp4'),
  QUnit = require('qunit'),
  seiNalUnitGenerator = require('./utils/sei-nal-unit-generator'),
  makeSeiFromCaptionPacket = seiNalUnitGenerator.makeSeiFromCaptionPacket,
  makeSeiFromMultipleCaptionPackets = seiNalUnitGenerator.makeSeiFromMultipleCaptionPackets,
  characters = seiNalUnitGenerator.characters,
  packetHeader708 = seiNalUnitGenerator.packetHeader708,
  displayWindows708 = seiNalUnitGenerator.displayWindows708,
  cc708PinkUnderscore = require('./utils/cc708-pink-underscore'),
  cc708Korean = require('./utils/cc708-korean'),
  sintelCaptions = segments['sintel-captions.ts'](),
  mixed608708Captions = require('./utils/mixed-608-708-captions.js'),
  multiChannel608Captions = segments['multi-channel-608-captions.ts']();

QUnit.module('Caption Stream', {
  beforeEach: function() {
    captionStream = new m2ts.CaptionStream();
  }
});

QUnit.test('parses SEIs messages larger than 255 bytes', function(assert) {
  var packets = [], data;
  captionStream.ccStreams_[0].push = function(packet) {
    packets.push(packet);
  };
  // set data channel 1 active for field 1
  captionStream.activeCea608Channel_[0] = 0;
  data = new Uint8Array(268);
  data[0] = 0x04; // payload_type === user_data_registered_itu_t_t35
  data[1] = 0xff; // payload_size
  data[2] = 0x0d; // payload_size
  data[3] = 181; // itu_t_t35_country_code
  data[4] = 0x00;
  data[5] = 0x31; // itu_t_t35_provider_code
  data[6] = 0x47;
  data[7] = 0x41;
  data[8] = 0x39;
  data[9] = 0x34; // user_identifier, "GA94"
  data[10] = 0x03; // user_data_type_code, 0x03 is cc_data
  data[11] = 0xc1; // process_cc_data, cc_count
  data[12] = 0xff; // reserved
  data[13] = 0xfc; // cc_valid, cc_type (608, field 1)
  data[14] = 0xff; // cc_data_1 with parity bit set
  data[15] = 0x0e; // cc_data_2 without parity bit set
  data[16] = 0xff; // marker_bits

  captionStream.push({
    nalUnitType: 'sei_rbsp',
    escapedRBSP: data
  });
  captionStream.flush();
  assert.equal(packets.length, 1, 'parsed a caption');
});

QUnit.test('parses SEIs containing multiple messages', function(assert) {
  var packets = [], data;

  captionStream.ccStreams_[0].push = function(packet) {
    packets.push(packet);
  };
  // set data channel 1 active for field 1
  captionStream.activeCea608Channel_[0] = 0;

  data = new Uint8Array(22);
  data[0] = 0x01; // payload_type !== user_data_registered_itu_t_t35
  data[1] = 0x04; // payload_size
  data[6] = 0x04; // payload_type === user_data_registered_itu_t_t35
  data[7] = 0x0d; // payload_size
  data[8] = 181; // itu_t_t35_country_code
  data[9] = 0x00;
  data[10] = 0x31; // itu_t_t35_provider_code
  data[11] = 0x47;
  data[12] = 0x41;
  data[13] = 0x39;
  data[14] = 0x34; // user_identifier, "GA94"
  data[15] = 0x03; // user_data_type_code, 0x03 is cc_data
  data[16] = 0xc1; // process_cc_data, cc_count
  data[17] = 0xff; // reserved
  data[18] = 0xfc; // cc_valid, cc_type (608, field 1)
  data[19] = 0xff; // cc_data_1 with parity bit set
  data[20] = 0x0e; // cc_data_2 without parity bit set
  data[21] = 0xff; // marker_bits

  captionStream.push({
    nalUnitType: 'sei_rbsp',
    escapedRBSP: data
  });
  captionStream.flush();
  assert.equal(packets.length, 1, 'parsed a caption');
});

QUnit.test('parses SEIs containing multiple messages of type user_data_registered_itu_t_t35', function(assert) {
  var packets = [], data;

  captionStream.ccStreams_[0].push = function(packet) {
    packets.push(packet);
  };
  // set data channel 1 active for field 1
  captionStream.activeCea608Channel_[0] = 0;

  data = new Uint8Array(33);
  data[0] = 0x01; // payload_type !== user_data_registered_itu_t_t35
  data[1] = 0x04; // payload_size

  // https://www.etsi.org/deliver/etsi_ts/101100_101199/101154/01.11.01_60/ts_101154v011101p.pdf#page=117
  data[6] = 0x04; // payload_type === user_data_registered_itu_t_t35
  data[7] = 0x09; // payload_size
  data[8] = 181; // itu_t_t35_country_code
  data[9] = 0x00;
  data[10] = 0x31; // itu_t_t35_provider_code
  data[11] = 0x44;
  data[12] = 0x54;
  data[13] = 0x47;
  data[14] = 0x31; // user_identifier, "DTG1"
  data[15] = 0x11; // zero_bit (b7), active_format_flag (b6), reserved (b5-b0)
  data[16] = 0xF0; // reserved (b7-b4), active_format (b3-b0)

  data[17] = 0x04; // payload_type === user_data_registered_itu_t_t35
  data[18] = 0x0d; // payload_size
  data[19] = 181; // itu_t_t35_country_code
  data[20] = 0x00;
  data[21] = 0x31; // itu_t_t35_provider_code
  data[22] = 0x47;
  data[23] = 0x41;
  data[24] = 0x39;
  data[25] = 0x34; // user_identifier, "GA94"
  data[26] = 0x03; // user_data_type_code, 0x03 is cc_data
  data[27] = 0xc1; // process_cc_data, cc_count
  data[28] = 0xff; // reserved
  data[29] = 0xfc; // cc_valid, cc_type (608, field 1)
  data[30] = 0xff; // cc_data_1 with parity bit set
  data[31] = 0x0e; // cc_data_2 without parity bit set
  data[32] = 0xff; // marker_bits

  captionStream.push({
    nalUnitType: 'sei_rbsp',
    escapedRBSP: data
  });
  captionStream.flush();
  assert.equal(packets.length, 1, 'ignored DTG1 payload, parsed a GA94 caption');
});

QUnit.test('does not throw error if only invalid payloads', function(assert) {
  var packets = [], data;

  captionStream.ccStreams_[0].push = function(packet) {
    packets.push(packet);
  };
  // set data channel 1 active for field 1
  captionStream.activeCea608Channel_[0] = 0;

  data = new Uint8Array(33);
  data[0] = 0x01; // payload_type !== user_data_registered_itu_t_t35
  data[1] = 0x04; // payload_size

  // https://www.etsi.org/deliver/etsi_ts/101100_101199/101154/01.11.01_60/ts_101154v011101p.pdf#page=117
  data[6] = 0x04; // payload_type === user_data_registered_itu_t_t35
  data[7] = 0x09; // payload_size
  data[8] = 181; // itu_t_t35_country_code
  data[9] = 0x00;
  data[10] = 0x31; // itu_t_t35_provider_code
  data[11] = 0x44;
  data[12] = 0x54;
  data[13] = 0x47;
  data[14] = 0x31; // user_identifier, "DTG1"
  data[15] = 0x11; // zero_bit (b7), active_format_flag (b6), reserved (b5-b0)
  data[16] = 0xF0; // reserved (b7-b4), active_format (b3-b0)

  data[17] = 0x04; // payload_type === user_data_registered_itu_t_t35
  data[18] = 0x0d; // payload_size
  data[19] = 181; // itu_t_t35_country_code
  data[20] = 0x00;
  data[21] = 0x31; // itu_t_t35_provider_code
  data[22] = 0x47;
  data[23] = 0x41;
  data[24] = 0x39;


  captionStream.push({
    nalUnitType: 'sei_rbsp',
    escapedRBSP: data
  });
  captionStream.flush();
  assert.equal(packets.length, 0, 'ignored DTG1 payload');
});


QUnit.test('ignores SEIs that do not have type user_data_registered_itu_t_t35', function(assert) {
  var captions = [];
  captionStream.on('data', function(caption) {
    captions.push(caption);
  });
  captionStream.push({
    nalUnitType: 'sei_rbsp',
    escapedRBSP: new Uint8Array([
      0x05 // payload_type !== user_data_registered_itu_t_t35
    ])
  });

  assert.equal(captions.length, 0, 'ignored the unknown payload type');
});

QUnit.test('parses a minimal example of caption data', function(assert) {
  var packets = [];
  captionStream.ccStreams_[0].push = function(packet) {
    packets.push(packet);
  };
  // set data channel 1 active for field 1
  captionStream.activeCea608Channel_[0] = 0;
  captionStream.push({
    nalUnitType: 'sei_rbsp',
    escapedRBSP: new Uint8Array([
      0x04, // payload_type === user_data_registered_itu_t_t35

      0x0d, // payload_size

      181, // itu_t_t35_country_code
      0x00, 0x31, // itu_t_t35_provider_code
      0x47, 0x41, 0x39, 0x34, // user_identifier, "GA94"
      0x03, // user_data_type_code, 0x03 is cc_data

      // 110 00001
      0xc1, // process_cc_data, cc_count
      0xff, // reserved
      // 1111 1100
      0xfc, // cc_valid, cc_type (608, field 1)
      0xff, // cc_data_1 with parity bit set
      0x0e, // cc_data_2 without parity bit set

      0xff // marker_bits
    ])
  });
  captionStream.flush();
  assert.equal(packets.length, 1, 'parsed a caption packet');
});

QUnit.test('can be parsed from a segment', function(assert) {
  var transmuxer = new mp4.Transmuxer(),
      captions = [];

  // Setting the BMDT to ensure that captions and id3 tags are not
  // time-shifted by this value when they are output and instead are
  // zero-based
  transmuxer.setBaseMediaDecodeTime(100000);

  transmuxer.on('data', function(data) {
    if (data.captions) {
      captions = captions.concat(data.captions);
    }
  });

  transmuxer.push(sintelCaptions);
  transmuxer.flush();

  assert.equal(captions.length, 2, 'parsed two captions');
  assert.equal(captions[0].text.indexOf('ASUKA'), 0, 'parsed the start of the first caption');
  assert.ok(captions[0].text.indexOf('Japanese') > 0, 'parsed the end of the first caption');
  assert.equal(captions[0].startTime, 1, 'parsed the start time');
  assert.equal(captions[0].endTime, 4, 'parsed the end time');
});

QUnit.test('dispatches caption track information', function(assert) {
  var transmuxer = new mp4.Transmuxer(),
      captions = [],
      captionStreams = {};

  // Setting the BMDT to ensure that captions and id3 tags are not
  // time-shifted by this value when they are output and instead are
  // zero-based
  transmuxer.setBaseMediaDecodeTime(100000);

  transmuxer.on('data', function(data) {
    if (data.captions) {
      captions = captions.concat(data.captions);
      for (var trackId in data.captionStreams) {
        captionStreams[trackId] = true;
      }
    }
  });

  transmuxer.push(multiChannel608Captions);
  transmuxer.flush();

  assert.deepEqual(captionStreams, {CC1: true, CC3: true}, 'found captions in CC1 and CC3');
  assert.equal(captions.length, 4, 'parsed eight captions');
  assert.equal(captions[0].text, 'être une période de questions', 'parsed the text of the first caption in CC3');
  assert.equal(captions[1].text, 'PERIOD, FOLKS.', 'parsed the text of the first caption in CC1');
});

QUnit.test('sorting is fun', function(assert) {
  var packets, captions, seiNals;
  packets = [
    // Send another command so that the second EOC isn't ignored
    { pts: 10 * 1000, ccData: 0x1420, type: 0 },
    // RCL, resume caption loading
    { pts: 1000, ccData: 0x1420, type: 0 },
    // 'test string #1'
    { pts: 1000, ccData: characters('te'), type: 0 },
    { pts: 1000, ccData: characters('st'), type: 0 },
    { pts: 1000, ccData: characters(' s'), type: 0 },
    // 'test string #2'
    { pts: 10 * 1000, ccData: characters('te'), type: 0 },
    { pts: 10 * 1000, ccData: characters('st'), type: 0 },
    { pts: 10 * 1000, ccData: characters(' s'), type: 0 },
    // 'test string #1' continued
    { pts: 1000, ccData: characters('tr'), type: 0 },
    { pts: 1000, ccData: characters('in'), type: 0 },
    { pts: 1000, ccData: characters('g '), type: 0 },
    { pts: 1000, ccData: characters('#1'), type: 0 },
    // 'test string #2' continued
    { pts: 10 * 1000, ccData: characters('tr'), type: 0 },
    { pts: 10 * 1000, ccData: characters('in'), type: 0 },
    { pts: 10 * 1000, ccData: characters('g '), type: 0 },
    { pts: 10 * 1000, ccData: characters('#2'), type: 0 },
    // EOC, End of Caption. End display
    { pts: 10 * 1000, ccData: 0x142f, type: 0 },
    // EOC, End of Caption. Finished transmitting, begin display
    { pts: 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { pts: 20 * 1000, ccData: 0x1420, type: 0 },
    // EOC, End of Caption. End display
    { pts: 20 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];

  seiNals = packets.map(makeSeiFromCaptionPacket);

  captionStream.on('data', function(caption) {
     captions.push(caption);
  });

  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 2, 'detected two captions');
  assert.equal(captions[0].text, 'test string #1', 'parsed caption 1');
  assert.equal(captions[1].text, 'test string #2', 'parsed caption 2');
});

QUnit.test('drops duplicate segments', function(assert) {
  var packets, captions, seiNals;
  packets = [
    {
      pts: 1000, dts: 1000, captions: [
        {ccData: 0x1420, type: 0 }, // RCL (resume caption loading)
        {ccData: 0x1420, type: 0 }, // RCL, duplicate as per spec
        {ccData: characters('te'), type: 0 },
        {ccData: characters('st'), type: 0 }
      ]
    },
    {
      pts: 2000, dts: 2000, captions: [
        {ccData: characters(' s'), type: 0 },
        {ccData: characters('tr'), type: 0 },
        {ccData: characters('in'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters('g '), type: 0 },
        {ccData: characters('da'), type: 0 },
        {ccData: characters('ta'), type: 0 }
      ]
    },
    {
      pts: 2000, dts: 2000, captions: [
        {ccData: characters(' s'), type: 0 },
        {ccData: characters('tr'), type: 0 },
        {ccData: characters('in'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters('g '), type: 0 },
        {ccData: characters('da'), type: 0 },
        {ccData: characters('ta'), type: 0 }
      ]
    },
    {
      pts: 4000, dts: 4000, captions: [
        {ccData: 0x142f, type: 0 }, // EOC (end of caption), mark display start
        {ccData: 0x142f, type: 0 }, // EOC, duplicate as per spec
        {ccData: 0x142f, type: 0 }, // EOC, mark display end and flush
        {ccData: 0x142f, type: 0 } // EOC, duplicate as per spec
      ]
    }
  ];
  captions = [];

  seiNals = packets.map(makeSeiFromMultipleCaptionPackets);

  captionStream.on('data', function(caption) {
     captions.push(caption);
  });

  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 1, 'detected one caption');
  assert.equal(captions[0].text, 'test string data', 'parsed caption properly');
});

QUnit.test('drops duplicate segments with multi-segment DTS values', function(assert) {
  var packets, captions, seiNals;
  packets = [
    {
      pts: 1000, dts: 1000, captions: [
        {ccData: 0x1420, type: 0 }, // RCL (resume caption loading)
        {ccData: 0x1420, type: 0 }, // RCL, duplicate as per spec
        {ccData: characters('te'), type: 0 }
      ]
    },
    {
      pts: 2000, dts: 2000, captions: [
        {ccData: characters('st'), type: 0 },
        {ccData: characters(' s'), type: 0 }
      ]
    },
    {
      pts: 2000, dts: 2000, captions: [
        {ccData: characters('tr'), type: 0 },
        {ccData: characters('in'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters('g '), type: 0 },
        {ccData: characters('da'), type: 0 },
        {ccData: characters('ta'), type: 0 }
      ]
    },
    {
      pts: 2000, dts: 2000, captions: [
        {ccData: characters(' s'), type: 0 },
        {ccData: characters('tr'), type: 0 },
        {ccData: characters('in'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters('g '), type: 0 },
        {ccData: characters('da'), type: 0 },
        {ccData: characters('ta'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters(' s'), type: 0 },
        {ccData: characters('tu'), type: 0 },
        {ccData: characters('ff'), type: 0 }
      ]
    },
    {
      pts: 4000, dts: 4000, captions: [
        {ccData: 0x142f, type: 0 }, // EOC (end of caption)
        // EOC not duplicated for robustness testing
        {ccData: 0x1420, type: 0 } // RCL (resume caption loading)
      ]
    },
    {
      pts: 5000, dts: 5000, captions: [
        {ccData: 0x1420, type: 0 }, // RCL, duplicated as per spec
        {ccData: characters(' a'), type: 0 },
        {ccData: characters('nd'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters(' e'), type: 0 },
        {ccData: characters('ve'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters('n '), type: 0 },
        {ccData: characters('mo'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters('re'), type: 0 },
        {ccData: characters(' t'), type: 0 }
      ]
    },
    {
      pts: 5000, dts: 5000, captions: [
        {ccData: 0x1420, type: 0 }, // RCL, duplicated as per spec
        {ccData: characters(' a'), type: 0 },
        {ccData: characters('nd'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters(' e'), type: 0 },
        {ccData: characters('ve'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters('n '), type: 0 },
        {ccData: characters('mo'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters('re'), type: 0 },
        {ccData: characters(' t'), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters('ex'), type: 0 },
        {ccData: characters('t '), type: 0 }
      ]
    },
    {
      pts: 6000, dts: 6000, captions: [
        {ccData: characters('da'), type: 0 },
        {ccData: characters('ta'), type: 0 }
      ]
    },
    {
      pts: 7000, dts: 7000, captions: [
        {ccData: characters(' h'), type: 0 },
        {ccData: characters('er'), type: 0 }
      ]
    },
    {
      pts: 8000, dts: 8000, captions: [
        {ccData: characters('e!'), type: 0 },
        {ccData: 0x142f, type: 0 }, // EOC (end of caption), mark display start
        {ccData: 0x142f, type: 0 }, // EOC, duplicated as per spec
        {ccData: 0x142f, type: 0 } // EOC, mark display end and flush
        // EOC not duplicated for robustness testing
      ]
    }
  ];
  captions = [];

  seiNals = packets.map(makeSeiFromMultipleCaptionPackets);

  captionStream.on('data', function(caption) {
     captions.push(caption);
  });

  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 2, 'detected two captions');
  assert.equal(captions[0].text, 'test string data stuff', 'parsed caption properly');
  assert.equal(captions[1].text, 'and even more text data here!', 'parsed caption properly');
});

QUnit.test('doesn\'t ignore older segments if reset', function(assert) {
  var firstPackets, secondPackets, captions, seiNals1, seiNals2;
  firstPackets = [
    {
      pts: 11000, dts: 11000, captions: [
        {ccData: 0x1420, type: 0 }, // RCL (resume caption loading)
        {ccData: 0x1420, type: 0 }, // RCL, duplicated as per spec
        {ccData: characters('te'), type: 0 }
      ]
    },
    {
      pts: 12000, dts: 12000, captions: [
        {ccData: characters('st'), type: 0 },
        {ccData: characters(' s'), type: 0 }
      ]
    },
    {
      pts: 12000, dts: 12000, captions: [
        {ccData: characters('tr'), type: 0 },
        {ccData: characters('in'), type: 0 }
      ]
    },
    {
      pts: 13000, dts: 13000, captions: [
        {ccData: characters('g '), type: 0 },
        {ccData: characters('da'), type: 0 },
        {ccData: characters('ta'), type: 0 }
      ]
    }
  ];
  secondPackets = [
    {
      pts: 1000, dts: 1000, captions: [
        {ccData: 0x1420, type: 0 }, // RCL (resume caption loading)
        {ccData: 0x1420, type: 0 }, // RCL, duplicated as per spec
        {ccData: characters('af'), type: 0 }
      ]
    },
    {
      pts: 2000, dts: 2000, captions: [
        {ccData: characters('te'), type: 0 },
        {ccData: characters('r '), type: 0 },
        {ccData: characters('re'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters('se'), type: 0 },
        {ccData: characters('t '), type: 0 },
        {ccData: characters('da'), type: 0 }
      ]
    },
    {
      pts: 3000, dts: 3000, captions: [
        {ccData: characters('ta'), type: 0 },
        {ccData: characters('!!'), type: 0 }
      ]
    },
    {
      pts: 4000, dts: 4000, captions: [
        {ccData: 0x142f, type: 0 }, // EOC (end of caption), mark display start
        {ccData: 0x142f, type: 0 }, // EOC, duplicated as per spec
        {ccData: 0x142f, type: 0 } // EOC, mark display end and flush
        // EOC not duplicated for robustness testing
      ]
    }
  ];
  captions = [];

  seiNals1 = firstPackets.map(makeSeiFromMultipleCaptionPackets);
  seiNals2 = secondPackets.map(makeSeiFromMultipleCaptionPackets);

  captionStream.on('data', function(caption) {
     captions.push(caption);
  });

  seiNals1.forEach(captionStream.push, captionStream);
  captionStream.flush();
  assert.equal(captionStream.latestDts_, 13000, 'DTS is tracked correctly');

  captionStream.reset();
  assert.equal(captionStream.latestDts_, null, 'DTS tracking was reset');

  seiNals2.forEach(captionStream.push, captionStream);
  captionStream.flush();
  assert.equal(captionStream.latestDts_, 4000, 'DTS is tracked correctly');

  assert.equal(captions.length, 1, 'detected one caption');
  assert.equal(captions[0].text, 'after reset data!!', 'parsed caption properly');
});

QUnit.test('extracts all theoretical caption channels', function(assert) {
  var captions = [];
  captionStream.ccStreams_.forEach(function(cc) {
    cc.on('data', function(caption) {
      captions.push(caption);
    });
  });

  // RU2 = roll-up, 2 rows
  // CR = carriage return
  var packets = [
    { pts: 1000, type: 0, ccData: 0x1425 }, // RU2 (sets CC1)
    { pts: 2000, type: 0, ccData: characters('1a') }, // CC1
    { pts: 3000, type: 0, ccData: 0x1c25 }, // RU2 (sets CC2)
    { pts: 4000, type: 1, ccData: 0x1525 }, // RU2 (sets CC3)
    { pts: 5000, type: 1, ccData: characters('3a') }, // CC3
    // this next one tests if active channel is tracked per-field
    // instead of globally
    { pts: 6000, type: 0, ccData: characters('2a') }, // CC2
    { pts: 7000, type: 1, ccData: 0x1d25 }, // RU2 (sets CC4)
    { pts: 8000, type: 1, ccData: characters('4a') }, // CC4
    { pts: 9000, type: 1, ccData: characters('4b') }, // CC4
    { pts: 10000, type: 0, ccData: 0x142d }, // CR (sets + flushes CC1)
    { pts: 11000, type: 0, ccData: 0x1c2d }, // CR (sets + flushes CC2)
    { pts: 12000, type: 0, ccData: 0x1425 }, // RU2 (sets CC1)
    { pts: 13000, type: 0, ccData: characters('1b') }, // CC1
    { pts: 14000, type: 0, ccData: characters('1c') }, // CC1
    { pts: 15000, type: 0, ccData: 0x142d }, // CR (sets + flushes CC1)
    { pts: 16000, type: 1, ccData: 0x152d }, // CR (sets + flushes CC3)
    { pts: 17000, type: 1, ccData: 0x1d2d }, // CR (sets + flushes CC4)
    { pts: 18000, type: 0, ccData: 0x1c25 }, // RU2 (sets CC2)
    { pts: 19000, type: 0, ccData: characters('2b') }, // CC2
    { pts: 20000, type: 0, ccData: 0x1c2d } // CR (sets + flushes CC2)
  ];

  var seiNals = packets.map(makeSeiFromCaptionPacket);
  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 6, 'got all captions');
  assert.equal(captions[0].text, '1a', 'cc1 first row');
  assert.equal(captions[1].text, '2a', 'cc2 first row');
  assert.equal(captions[2].text, '1a\n1b1c', 'cc1 first and second row');
  assert.equal(captions[3].text, '3a', 'cc3 first row');
  assert.equal(captions[4].text, '4a4b', 'cc4 first row');
  assert.equal(captions[5].text, '2a\n2b', 'cc2 first and second row');

});

QUnit.test('drops data until first command that sets activeChannel for a field', function(assert) {
  var captions = [];
  captionStream.ccStreams_.forEach(function(cc) {
    cc.on('data', function(caption) {
      captions.push(caption);
    });
  });

  var packets = [
    // test that packets in same field and same data channel are dropped
    // before a control code that sets the data channel
    { pts: 0 * 1000, ccData: characters('no'), type: 0 },
    { pts: 0 * 1000, ccData: characters('t '), type: 0 },
    { pts: 0 * 1000, ccData: characters('th'), type: 0 },
    { pts: 0 * 1000, ccData: characters('is'), type: 0 },
    // EOC (end of caption), sets CC1
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // RCL (resume caption loading)
    { pts: 1 * 1000, ccData: 0x1420, type: 0 },
    // EOC, if data wasn't dropped this would dispatch a caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 },
    // RCL
    { pts: 3 * 1000, ccData: 0x1420, type: 0 },
    { pts: 4 * 1000, ccData: characters('fi'), type: 0 },
    { pts: 4 * 1000, ccData: characters('el'), type: 0 },
    { pts: 4 * 1000, ccData: characters('d0'), type: 0 },
    // EOC, mark display start
    { pts: 5 * 1000, ccData: 0x142f, type: 0 },
    // EOC, duplicated as per spec
    { pts: 5 * 1000, ccData: 0x142f, type: 0 },
    // EOC, mark display end and flush
    { pts: 6 * 1000, ccData: 0x142f, type: 0 },
    // EOC not duplicated cuz not necessary
    // now switch to field 1 and test that packets in the same field
    // but DIFFERENT data channel are dropped
    { pts: 7 * 1000, ccData: characters('or'), type: 1 },
    { pts: 7 * 1000, ccData: characters(' t'), type: 1 },
    { pts: 7 * 1000, ccData: characters('hi'), type: 1 },
    { pts: 7 * 1000, ccData: characters('s.'), type: 1 },
    // EOC (end of caption, sets CC4)
    { pts: 8 * 1000, ccData: 0x1d2f, type: 1 },
    // RCL (resume caption loading)
    { pts: 8 * 1000, ccData: 0x1d20, type: 1 },
    // EOC, if data wasn't dropped this would dispatch a caption
    { pts: 9 * 1000, ccData: 0x1d2f, type: 1 },
    // RCL
    { pts: 10 * 1000, ccData: 0x1d20, type: 1 },
    { pts: 11 * 1000, ccData: characters('fi'), type: 1 },
    { pts: 11 * 1000, ccData: characters('el'), type: 1 },
    { pts: 11 * 1000, ccData: characters('d1'), type: 1 },
    // EOC, mark display start
    { pts: 12 * 1000, ccData: 0x1d2f, type: 1 },
    // EOC, duplicated as per spec
    { pts: 12 * 1000, ccData: 0x1d2f, type: 1 },
    // EOC, mark display end and flush
    { pts: 13 * 1000, ccData: 0x1d2f, type: 1 }
    // EOC not duplicated cuz not necessary
  ];

  var seiNals = packets.map(makeSeiFromCaptionPacket);
  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 2, 'received 2 captions');
  assert.equal(captions[0].text, 'field0', 'received only confirmed field0 data');
  assert.equal(captions[0].stream, 'CC1', 'caption went to right channel');
  assert.equal(captions[1].text, 'field1', 'received only confirmed field1 data');
  assert.equal(captions[1].stream, 'CC4', 'caption went to right channel');
});

QUnit.test('clears buffer and drops data until first command that sets activeChannel after reset', function(assert) {
  var firstPackets, secondPackets, captions, seiNals1, seiNals2;
  captions = [];

  firstPackets = [
    // RCL (resume caption loading), CC1
    { pts: 1 * 1000, ccData: 0x1420, type: 0 },
    { pts: 2 * 1000, ccData: characters('fi'), type: 0 },
    { pts: 2 * 1000, ccData: characters('el'), type: 0 },
    { pts: 2 * 1000, ccData: characters('d0'), type: 0 },
    // EOC (end of caption), swap text to displayed memory
    { pts: 3 * 1000, ccData: 0x142f, type: 0 },
    { pts: 4 * 1000, ccData: characters('fi'), type: 0 },
    { pts: 4 * 1000, ccData: characters('el'), type: 0 },
    { pts: 4 * 1000, ccData: characters('d0'), type: 0 },
    // RCL (resume caption loading), CC4
    { pts: 5 * 1000, ccData: 0x1d20, type: 1 },
    { pts: 6 * 1000, ccData: characters('fi'), type: 1 },
    { pts: 6 * 1000, ccData: characters('el'), type: 1 },
    { pts: 6 * 1000, ccData: characters('d1'), type: 1 },
    // EOC (end of caption), swap text to displayed memory
    { pts: 7 * 1000, ccData: 0x1d2f, type: 1 },
    { pts: 8 * 1000, ccData: characters('fi'), type: 1 },
    { pts: 8 * 1000, ccData: characters('el'), type: 1 },
    { pts: 8 * 1000, ccData: characters('d1'), type: 1 }
  ];
  secondPackets = [
    // following packets are dropped
    { pts: 9 * 1000, ccData: characters('no'), type: 0 },
    { pts: 9 * 1000, ccData: characters('t '), type: 0 },
    { pts: 9 * 1000, ccData: characters('th'), type: 0 },
    { pts: 9 * 1000, ccData: characters('is'), type: 0 },
    { pts: 10 * 1000, ccData: characters('or'), type: 1 },
    { pts: 10 * 1000, ccData: characters(' t'), type: 1 },
    { pts: 10 * 1000, ccData: characters('hi'), type: 1 },
    { pts: 10 * 1000, ccData: characters('s.'), type: 1 },
    // EOC (end of caption), sets CC1
    { pts: 11 * 1000, ccData: 0x142f, type: 0 },
    // RCL (resume caption loading), CC1
    { pts: 11 * 1000, ccData: 0x1420, type: 0 },
    // EOC, sets CC4
    { pts: 12 * 1000, ccData: 0x1d2f, type: 1 },
    // RCL, CC4
    { pts: 12 * 1000, ccData: 0x1d20, type: 1 },
    // EOC, CC1, would dispatch caption if packets weren't ignored
    { pts: 13 * 1000, ccData: 0x142f, type: 0 },
    // RCL, CC1
    { pts: 13 * 1000, ccData: 0x1420, type: 0 },
    // EOC, CC4, would dispatch caption if packets weren't ignored
    { pts: 14 * 1000, ccData: 0x1d2f, type: 1 },
    // RCL, CC4
    { pts: 14 * 1000, ccData: 0x1d20, type: 1 },
    { pts: 18 * 1000, ccData: characters('bu'), type: 0 },
    { pts: 18 * 1000, ccData: characters('t '), type: 0 },
    { pts: 18 * 1000, ccData: characters('th'), type: 0 },
    { pts: 18 * 1000, ccData: characters('is'), type: 0 },
    { pts: 19 * 1000, ccData: characters('an'), type: 1 },
    { pts: 19 * 1000, ccData: characters('d '), type: 1 },
    { pts: 19 * 1000, ccData: characters('th'), type: 1 },
    { pts: 19 * 1000, ccData: characters('is'), type: 1 },
    // EOC (end of caption), CC1, mark caption 1 start
    { pts: 20 * 1000, ccData: 0x142f, type: 0 },
    // EOC, CC1, duplicated as per spec
    { pts: 20 * 1000, ccData: 0x142f, type: 0 },
    // EOC, CC1, mark caption 1 end and dispatch
    { pts: 21 * 1000, ccData: 0x142f, type: 0 },
    // No duplicate EOC cuz not necessary
    // EOC, CC4, mark caption 2 start
    { pts: 22 * 1000, ccData: 0x1d2f, type: 1 },
    // EOC, CC4, duplicated as per spec
    { pts: 22 * 1000, ccData: 0x1d2f, type: 1 },
    // EOC, CC4, mark caption 2 end and dispatch
    { pts: 23 * 1000, ccData: 0x1d2f, type: 1 }
    // No duplicate EOC cuz not necessary
  ];

  seiNals1 = firstPackets.map(makeSeiFromCaptionPacket);
  seiNals2 = secondPackets.map(makeSeiFromCaptionPacket);

  captionStream.on('data', function(caption) {
    captions.push(caption);
  });

  seiNals1.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captionStream.ccStreams_[0].nonDisplayed_[14], 'field0',
    'there is data in non-displayed memory for field 0 before reset');
  assert.equal(captionStream.ccStreams_[3].nonDisplayed_[14], 'field1',
    'there is data in non-displayed memory for field 1 before reset');
  assert.equal(captionStream.ccStreams_[0].displayed_[14], 'field0',
    'there is data in displayed memory for field 0 before reset');
  assert.equal(captionStream.ccStreams_[3].displayed_[14], 'field1',
    'there is data in displayed memory for field 1 before reset');

  captionStream.reset();

  assert.equal(captionStream.ccStreams_[0].nonDisplayed_[14], '',
    'there is no data in non-displayed memory for field 0 after reset');
  assert.equal(captionStream.ccStreams_[3].nonDisplayed_[14], '',
    'there is no data in non-displayed memory for field 1 after reset');
  assert.equal(captionStream.ccStreams_[0].displayed_[14], '',
    'there is no data in displayed memory for field 0 after reset');
  assert.equal(captionStream.ccStreams_[3].displayed_[14], '',
    'there is no data in displayed memory for field 1 after reset');

  seiNals2.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 2, 'detected two captions');
  assert.equal(captions[0].text, 'but this', 'parsed caption properly');
  assert.equal(captions[0].stream, 'CC1', 'caption went to right channel');
  assert.equal(captions[1].text, 'and this', 'parsed caption properly');
  assert.equal(captions[1].stream, 'CC4', 'caption went to right channel');
});

QUnit.test("don't mess up 608 captions when 708 are present", function(assert) {
  var captions = [];
  captionStream.ccStreams_.forEach(function(cc) {
    cc.on('data', function(caption) {
      captions.push(caption);
    });
  });

  var seiNals = mixed608708Captions.map(makeSeiFromCaptionPacket);
  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 3, 'parsed three captions');
  assert.equal(captions[0].text, 'BUT IT\'S NOT SUFFERING\nRIGHW.', 'parsed first caption correctly');
  // there is also bad data in the captions, but the null ascii character is removed
  assert.equal(captions[1].text, 'IT\'S NOT A THREAT TO ANYBODY.', 'parsed second caption correctly');
  assert.equal(captions[2].text, 'WE TRY NOT TO PUT AN ANIMAL DOWN\nIF WE DON\'T HAVE TO.', 'parsed third caption correctly');
});

QUnit.test("both 608 and 708 captions are available by default", function(assert) {
  var cc608 = [];
  var cc708 = [];
  captionStream.on('data', function(caption) {
    if (caption.stream === 'CC1') {
      cc608.push(caption);
    } else {
      cc708.push(caption);
    }
  });

  var seiNals = mixed608708Captions.map(makeSeiFromCaptionPacket);
  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(cc608.length, 3, 'parsed three 608 cues');
  assert.equal(cc708.length, 3, 'parsed three 708 cues');
});

QUnit.test("708 parsing can be turned off", function(assert) {
  captionStream.reset();
  captionStream = new m2ts.CaptionStream({
    parse708captions: false
  });
  var cc608 = [];
  var cc708 = [];
  captionStream.on('data', function(caption) {
    if (caption.stream === 'CC1') {
      cc608.push(caption);
    } else {
      cc708.push(caption);
    }
  });

  var seiNals = mixed608708Captions.map(makeSeiFromCaptionPacket);
  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(cc608.length, 3, 'parsed three 608 cues');
  assert.equal(cc708.length, 0, 'did not parse any 708 cues');
});

QUnit.test('ignores XDS and Text packets', function(assert) {
  var captions = [];

  captionStream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RCL, resume caption loading, CC3
    { pts: 1000, ccData: 0x1520, type: 1 },
    { pts: 2000, ccData: characters('hi'), type: 1 },
    // EOC, End of Caption
    { pts: 3000, ccData: 0x152f, type: 1 },
    // Send another command so that the second EOC isn't ignored
    { pts: 3000, ccData: 0x152f, type: 1 },
    // EOC, End of Caption
    { pts: 4000, ccData: 0x152f, type: 1 },
    // ENM, Erase Non-Displayed Memory
    { pts: 4000, ccData: 0x152e, type: 1 },
    // RCL, resume caption loading, CC1
    { pts: 5000, ccData: 0x1420, type: 0 }
  ].map(makeSeiFromCaptionPacket).forEach(captionStream.push, captionStream);
  captionStream.flush();
  assert.equal(captionStream.activeCea608Channel_[0], 0, 'field 1: CC1 is active');
  assert.equal(captionStream.activeCea608Channel_[1], 0, 'field 2: CC3 is active');

  [
    // TR, text restart, CC1
    { pts: 5000, ccData: 0x142a, type: 0 },
    { pts: 6000, ccData: characters('tx'), type: 0 }
  ].map(makeSeiFromCaptionPacket).forEach(captionStream.push, captionStream);
  captionStream.flush();
  assert.equal(captionStream.activeCea608Channel_[0], null, 'field 1: disabled');
  assert.equal(captionStream.activeCea608Channel_[1], 0, 'field 2: CC3 is active');

  [
    // EOC, End of Caption
    { pts: 7000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { pts: 7000, ccData: 0x142f, type: 0 },
    // EOC, End of Caption
    { pts: 8000, ccData: 0x142f, type: 0 },
    // RCL, resume caption loading, CC3
    { pts: 9000, ccData: 0x1520, type: 1 },
    // XDS start, "current" class, program identification number type
    { pts: 10000, ccData: 0x0101, type: 1 },
    { pts: 11000, ccData: characters('oh'), type: 1 },
    // XDS end
    { pts: 12000, ccData: 0x0f00, type: 1 }
  ].map(makeSeiFromCaptionPacket).forEach(captionStream.push, captionStream);
  captionStream.flush();
  assert.equal(captionStream.activeCea608Channel_[0], 0, 'field 1: CC1 is active');
  assert.equal(captionStream.activeCea608Channel_[1], null, 'field 2: disabled');

  [
    // EOC, End of Caption
    { pts: 13000, ccData: 0x152f, type: 1 },
    // Send another command so that the second EOC isn't ignored
    { pts: 13000, ccData: 0x152f, type: 1 }
  ].map(makeSeiFromCaptionPacket).forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.equal(captions.length, 1, 'only parsed real caption');
  assert.equal(captions[0].text, 'hi', 'caption is correct');

});

// Full character translation tests are below for Cea608Stream, they just only
// test support for CC1. See those tests and the source code for more about the
// mechanics of special and extended characters.
QUnit.test('special and extended character codes work regardless of field and data channel', function(assert) {
  var packets, seiNals, captions = [];
  packets = [
    // RU2 (roll-up, 2 rows), CC2
    { ccData: 0x1c25, type: 0 },
    // ®
    { ccData: 0x1930, type: 0 },
    // CR (carriage return), CC2, flush caption
    { ccData: 0x1c2d, type: 0 },
    // RU2, CC3
    { ccData: 0x1525, type: 1 },
    // "
    { ccData: 0x2200, type: 1 },
    // «
    { ccData: 0x123e, type: 1 },
    // CR, CC3, flush caption
    { ccData: 0x152d, type: 1 },
    // RU2, CC4
    { ccData: 0x1d25, type: 1 },
    // "
    { ccData: 0x2200, type: 1 },
    // »
    { ccData: 0x1a3f, type: 1 },
    // CR, CC4, flush caption
    { ccData: 0x1d2d, type: 1 }
  ];

  captionStream.on('data', function(caption) {
    captions.push(caption);
  });

  seiNals = packets.map(makeSeiFromCaptionPacket);
  seiNals.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.deepEqual(captions[0].text, String.fromCharCode(0xae), 'CC2 special character correct');
  assert.deepEqual(captions[1].text, String.fromCharCode(0xab), 'CC3 extended character correct');
  assert.deepEqual(captions[2].text, String.fromCharCode(0xbb), 'CC4 extended character correct');
});

QUnit.test('number of roll up rows takes precedence over base row command', function(assert) {
  var captions = [];
  var packets = [

    // RU2 (roll-up, 2 rows), CC1
    { type: 0, ccData: 0x1425 },
    // RU2, CC1
    { type: 0, ccData: 0x1425 },
    // PAC: row 1 (sets base row to row 1)
    { type: 0, ccData: 0x1170 },
    // PAC: row 1
    { type: 0, ccData: 0x1170 },
    // -
    { type: 0, ccData: 0x2d00 },
    // CR
    { type: 0, ccData: 0x14ad },
    // CR
    { type: 0, ccData: 0x14ad },
    // RU3 (roll-up, 3 rows), CC1
    { type: 0, ccData: 0x1426 },
    // RU3, CC1
    { type: 0, ccData: 0x1426 },
    // PAC, row 11
    { type: 0, ccData: 0x13d0 },
    // PAC, row 11
    { type: 0, ccData: 0x13d0 },
    // so
    { type: 0, ccData: 0x736f },
    // CR
    { type: 0, ccData: 0x14ad },
    // CR
    { type: 0, ccData: 0x14ad }
  ];
  var seis;

  captionStream.on('data', function(caption) {
    captions.push(caption);
  });

  seis = packets.map(makeSeiFromCaptionPacket);

  seis.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.deepEqual(captions[0].text, '-', 'RU2 caption is correct');
  assert.deepEqual(captions[1].text, '-\nso', 'RU3 caption is correct');

  packets = [
    // switching from row 11 to 0
    // PAC: row 0 (sets base row to row 0)
    { type: 0, ccData: 0x1140 },
    // PAC: row 0
    { type: 0, ccData: 0x1140 },
    // CR
    { type: 0, ccData: 0x14ad },
    // CR
    { type: 0, ccData: 0x14ad }
  ];

  seis = packets.map(makeSeiFromCaptionPacket);
  seis.forEach(captionStream.push, captionStream);
  captionStream.flush();

  assert.deepEqual(captions[2].text, '-\nso', 'RU3 caption is correct');
});

var cea608Stream;

QUnit.module('CEA 608 Stream', {
  beforeEach: function() {
    cea608Stream = new m2ts.Cea608Stream();
  }
});

QUnit.skip('filters null data', function(assert) {
  assert.ok(false, 'not implemented');
});

QUnit.skip('removes parity bits', function(assert) {
  assert.ok(false, 'not implemented');
});

QUnit.test('converts non-ASCII character codes to ASCII', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // ASCII exceptions
    { ccData: 0x2a5c, type: 0 },
    { ccData: 0x5e5f, type: 0 },
    { ccData: 0x607b, type: 0 },
    { ccData: 0x7c7d, type: 0 },
    { ccData: 0x7e7f, type: 0 },
    // EOC, End of Caption
    { pts: 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption, clear the display
    { pts: 10 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text,
        String.fromCharCode(0xe1, 0xe9, 0xed, 0xf3, 0xfa, 0xe7, 0xf7, 0xd1, 0xf1, 0x2588),
        'translated non-standard characters');
});

QUnit.test('properly handles special character codes', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // Special characters as defined by CEA-608
    // see the CHARACTER_TRANSLATION hash in lib/m2ts/caption-stream for the
    // mapping table
    { ccData: 0x1130, type: 0 },
    { ccData: 0x1131, type: 0 },
    { ccData: 0x1132, type: 0 },
    { ccData: 0x1133, type: 0 },
    { ccData: 0x1134, type: 0 },
    { ccData: 0x1135, type: 0 },
    { ccData: 0x1136, type: 0 },
    { ccData: 0x1137, type: 0 },
    { ccData: 0x1138, type: 0 },
    { ccData: 0x1139, type: 0 },
    { ccData: 0x113a, type: 0 },
    { ccData: 0x113b, type: 0 },
    { ccData: 0x113c, type: 0 },
    { ccData: 0x113d, type: 0 },
    { ccData: 0x113e, type: 0 },
    { ccData: 0x113f, type: 0 },
    // EOC, End of Caption
    { pts: 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption, CC1, clear the display
    { pts: 10 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions[0].text,
        String.fromCharCode(0xae, 0xb0, 0xbd, 0xbf, 0x2122, 0xa2, 0xa3, 0x266a,
            0xe0, 0xa0, 0xe8, 0xe2, 0xea, 0xee, 0xf4, 0xfb),
        'translated special characters');
});

QUnit.test('properly handles extended character codes', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // Extended characters are defined in CEA-608 as a standard character,
    // which is followed by an extended character, and the standard character
    // gets deleted.
    // see the CHARACTER_TRANSLATION hash in lib/m2ts/caption-stream for the
    // mapping table
    { ccData: 0x2200, type: 0 },
    { ccData: 0x123e, type: 0 },
    { ccData: 0x4c41, type: 0 },
    { ccData: 0x1230, type: 0 },
    { ccData: 0x2d4c, type: 0 },
    { ccData: 0x4100, type: 0 },
    { ccData: 0x1338, type: 0 },
    { ccData: 0x204c, type: 0 },
    { ccData: 0x417d, type: 0 },
    { ccData: 0x4400, type: 0 },
    { ccData: 0x1137, type: 0 },
    { ccData: 0x2200, type: 0 },
    { ccData: 0x123f, type: 0 },
    // EOC, End of Caption
    { pts: 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption, clear the display
    { pts: 10 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions[0].text, '«LÀ-LÅ LAÑD♪»',
        'translated special characters');
});

QUnit.test('pop-on mode', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // 'hi'
    { ccData: characters('hi'), type: 0 },
    // EOC, End of Caption. Finished transmitting, begin display
    { pts: 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption. End display
    { pts: 10 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];

  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.deepEqual(captions[0], {
    startPts: 1000,
    endPts: 10 * 1000,
    text: 'hi',
    stream: 'CC1'
  }, 'parsed the caption');
});

QUnit.test('ignores null characters', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // 'mu'
    { ccData: characters('mu'), type: 0 },
    // null characters
    { ccData: 0x0000, type: 0 },
    // ' x'
    { ccData: characters(' x'), type: 0 },
    // EOC, End of Caption. Finished transmitting, begin display
    { pts: 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption. End display
    { pts: 10 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];

  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.deepEqual(captions[0], {
    startPts: 1000,
    endPts: 10 * 1000,
    text: 'mu x',
    stream: 'CC1'
  }, 'ignored null characters');
});

QUnit.test('recognizes the Erase Displayed Memory command', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // '01'
    { ccData: characters('01'), type: 0 },
    // EOC, End of Caption. Finished transmitting, display '01'
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // EDM, Erase Displayed Memory
    { pts: 1.5 * 1000, ccData: 0x142c, type: 0 },
    // '23'
    { ccData: characters('23'), type: 0 },
    // EOC, End of Caption. Display '23'
    { pts: 2 * 1000, ccData: 0x142f, type: 0 },
    // '34'
    { ccData: characters('34'), type: 0 },
    // EOC, End of Caption. Display '34'
    { pts: 3 * 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0},
    // EOC, End of Caption
    { pts: 4 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];

  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 3, 'detected three captions');
  assert.deepEqual(captions[0], {
    startPts: 1 * 1000,
    endPts: 1.5 * 1000,
    text: '01',
    stream: 'CC1'
  }, 'parsed the first caption');
  assert.deepEqual(captions[1], {
    startPts: 2 * 1000,
    endPts: 3 * 1000,
    text: '23',
    stream: 'CC1'
  }, 'parsed the second caption');
  assert.deepEqual(captions[2], {
    startPts: 3 * 1000,
    endPts: 4 * 1000,
    text: '34',
    stream: 'CC1'
  }, 'parsed the third caption');
});

QUnit.test('backspaces are applied to non-displayed memory for pop-on mode', function(assert) {
  var captions = [], packets;
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // '01'
    { ccData: characters('01'), type: 0 },
    // backspace
    { ccData: 0x1421, type: 0 },
    { ccData: characters('23'), type: 0 },
    // PAC: row 13, no indent
    { pts: 1 * 1000, ccData: 0x1370, type: 0 },
    { pts: 1 * 1000, ccData: characters('32'), type: 0 },
    // backspace
    { pts: 2 * 1000, ccData: 0x1421, type: 0 },
    { pts: 3 * 1000, ccData: characters('10'), type: 0 },
    // EOC, End of Caption
    { pts: 4 * 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption, flush caption
    { pts: 5 * 1000, ccData: 0x142f, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.equal(captions[0].text, '310\n\n023', 'applied the backspaces');
});

QUnit.test('backspaces on cleared memory are no-ops', function(assert) {
  var captions = [], packets;
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420 },
    // backspace
    { ccData: 0x1421 },
    // EOC, End of Caption. Finished transmitting, display '01'
    { pts: 1 * 1000, ccData: 0x142f }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 0, 'no captions detected');
});

QUnit.test('recognizes the Erase Non-Displayed Memory command', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // '01'
    { ccData: characters('01'), type: 0 },
    // ENM, Erase Non-Displayed Memory
    { ccData: 0x142e, type: 0 },
    { ccData: characters('23'), type: 0 },
    // EOC, End of Caption. Finished transmitting, display '23'
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];

  packets.forEach(cea608Stream.push, cea608Stream);

  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected one caption');
  assert.deepEqual(captions[0], {
    startPts: 1 * 1000,
    endPts: 2 * 1000,
    text: '23',
    stream: 'CC1'
  }, 'cleared the non-displayed memory');
});

QUnit.test('ignores unrecognized commands', function(assert) {
  var packets, captions;
  packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // a row-9 magenta command, which is not supported
    { ccData: 0x1f4c, type: 0 },
    // '01'
    { ccData: characters('01'), type: 0 },
    // EOC, End of Caption
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 }
  ];
  captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions[0].text, '01', 'skipped the unrecognized commands');
});

QUnit.skip('applies preamble address codes', function(assert) {
  assert.ok(false, 'not implemented');
});

QUnit.skip('applies mid-row colors', function(assert) {
  assert.ok(false, 'not implemented');
});

QUnit.test('applies mid-row underline', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    { ccData: characters('no'), type: 0 },
    // mid-row, white underline
    { ccData: 0x1121, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // CR (carriage return), dispatches caption
    { ccData: 0x142d, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, 'no <u>yes.</u>', 'properly closed by CR');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('applies mid-row italics', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    { ccData: characters('no'), type: 0 },
    // mid-row, italics
    { ccData: 0x112e, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // CR (carriage return), dispatches caption
    { ccData: 0x142d, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, 'no <i>yes.</i>', 'properly closed by CR');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('applies mid-row italics underline', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    { ccData: characters('no'), type: 0 },
    // mid-row, italics underline
    { ccData: 0x112f, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // CR (carriage return), dispatches caption
    { ccData: 0x142d, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, 'no <i><u>yes.</u></i>', 'properly closed by CR');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

// NOTE: With the exception of white italics PACs (the following two test
// cases), PACs only have their underline attribute extracted and used
QUnit.test('applies PAC underline', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    // PAC: row 15, white underline
    { ccData: 0x1461, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // CR (carriage return), dispatches caption
    { ccData: 0x142d, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, '<u>yes.</u>', 'properly closed by CR');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('applies PAC white italics', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    // PAC: row 15, white italics
    { ccData: 0x146e, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // CR (carriage return), dispatches caption
    { ccData: 0x142d, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, '<i>yes.</i>', 'properly closed by CR');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('applies PAC white italics underline', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    // PAC: row 15, white italics underline
    { ccData: 0x146f, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // CR (carriage return), dispatches caption
    { ccData: 0x142d, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, '<u><i>yes.</i></u>', 'properly closed by CR');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('closes formatting at PAC row change', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // PAC: row 14, white italics underlime
    { ccData: 0x144f, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // PAC: row 15, indent 0
    { ccData: 0x1470, type: 0 },
    { ccData: characters('no'), type: 0 },
    // EOC, End of Caption
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, '<u><i>yes.</i></u>\nno', 'properly closed by PAC row change');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('closes formatting at EOC', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // PAC: row 15, white italics underline
    { ccData: 0x146f, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // EOC, End of Caption
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // Send another command so that the second EOC isn't ignored
    { ccData: 0x1420, type: 0 },
    // EOC, End of Caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  assert.equal(captions[0].text, '<u><i>yes.</i></u>', 'properly closed by EOC');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('closes formatting at negating mid-row code', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    // RU2 (roll-up, 2 rows)
    { ccData: 0x1425, type: 0 },
    { ccData: characters('no'), type: 0 },
    // mid-row: italics underline
    { ccData: 0x112f, type: 0 },
    { ccData: characters('ye'), type: 0 },
    { ccData: characters('s.'), type: 0 },
    // mid-row: white
    { ccData: 0x1120, type: 0 },
    { ccData: characters('no'), type: 0 }
  ];

  packets.forEach(cea608Stream.push, cea608Stream);
  cea608Stream.flushDisplayed();
  assert.equal(captions[0].text, 'no <i><u>yes.</u></i> no', 'properly closed by negating mid-row code');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting is empty');
});

QUnit.test('roll-up display mode', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0},
    // '01'
    {
      pts: 1 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // CR, carriage return
    { pts: 3 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected one caption');
  assert.deepEqual(captions[0], {
    startPts: 0 * 1000,
    endPts: 3 * 1000,
    text: '01',
    stream: 'CC1'
  }, 'parsed the caption');
  captions = [];

  [ // RU4, roll-up captions 4 rows
    { ccdata: 0x1427, type: 0 },
    // '23'
    {
      pts: 4 * 1000,
      ccData: characters('23'),
      type: 0,
      stream: 'CC1'
    },
    // CR
    { pts: 5 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected another caption');
  assert.deepEqual(captions[0], {
    startPts: 3 * 1000,
    endPts: 5 * 1000,
    text: '01\n23',
    stream: 'CC1'
  }, 'parsed the new caption and kept the caption up after the new caption');
});

QUnit.test('roll-up displays multiple rows simultaneously', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0,
      stream: 'CC1'
    },
    // CR, carriage return
    { pts: 1 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.deepEqual(captions[0], {
    startPts: 0 * 1000,
    endPts: 1 * 1000,
    text: '01',
    stream: 'CC1'
  }, 'created a caption for the first period');
  captions = [];

  [ // '23'
    {
      pts: 2 * 1000,
      ccData: characters('23'),
      type: 0,
      stream: 'CC1'
    },
    // CR, carriage return
    { pts: 3 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected another caption');
  assert.deepEqual(captions[0], {
    startPts: 1 * 1000,
    endPts: 3 * 1000,
    text: '01\n23',
    stream: 'CC1'
  }, 'created the top and bottom rows after the shift up');
  captions = [];

  [ // '45'
    {
      pts: 4 * 1000,
      ccData: characters('45'),
      type: 0,
      stream: 'CC1'
    },
    // CR, carriage return
    { pts: 5 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected third caption');
  assert.deepEqual(captions[0], {
    startPts: 3 * 1000,
    endPts: 5 * 1000,
    text: '23\n45',
    stream: 'CC1'
  }, 'created the top and bottom rows after the shift up');
});

QUnit.test('the roll-up count can be changed on-the-fly', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0,
      stream: 'CC1'
    },
    // CR, carriage return
    { pts: 1 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  captions = [];

  [ // RU3, roll-up captions 3 rows
    { ccData: 0x1426, type: 0 },
    // CR, carriage return
    { pts: 2 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'still displaying a caption');
  captions = [];

  [ // RU4, roll-up captions 4 rows
    { ccData: 0x1427, type: 0 },
    // CR, carriage return
    { pts: 3 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'still displaying a caption');
  captions = [];

  // RU3, roll-up captions 3 rows
  cea608Stream.push({ ccdata: 0x1426, type: 0 });
  assert.equal(captions.length, 0, 'cleared the caption');
});

QUnit.test('switching to roll-up from pop-on wipes memories and flushes captions', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RCL (resume caption loading)
    { pts: 0 * 1000, ccData: 0x1420, type: 0 },
    { pts: 0 * 1000, ccData: characters('hi'), type: 0 },
    // EOC (end of caption), mark 1st caption start
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // RCL, resume caption loading
    { pts: 1 * 1000, ccData: 0x1420, type: 0 },
    { pts: 2 * 1000, ccData: characters('oh'), type: 0 },
    // EOC, mark 2nd caption start and flush 1st caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 },
    // RU2 (roll-up, 2 rows), flush 2nd caption
    { pts: 3 * 1000, ccData: 0x1425, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  var displayed = cea608Stream.displayed_.reduce(function(acc, val) {
    acc += val;
    return acc;
  });
  var nonDisplayed = cea608Stream.nonDisplayed_.reduce(function(acc, val) {
    acc += val;
    return acc;
  });

  assert.equal(captions.length, 2, 'both captions flushed');
  assert.equal(displayed, '', 'displayed memory is wiped');
  assert.equal(nonDisplayed, '', 'non-displayed memory is wiped');
  assert.deepEqual(captions[0], {
    startPts: 1000,
    endPts: 2000,
    text: 'hi',
    stream: 'CC1'
  }, 'first caption correct');
  assert.deepEqual(captions[1], {
    startPts: 2000,
    endPts: 3000,
    text: 'oh',
    stream: 'CC1'
  }, 'second caption correct');
});

QUnit.test('switching to roll-up from paint-on wipes memories and flushes captions', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RDC (resume direct captioning)
    { pts: 0 * 1000, ccData: 0x1429, type: 0 },
    { pts: 0 * 1000, ccData: characters('hi'), type: 0 },
    // RU2 (roll-up, 2 rows), flush displayed caption
    { pts: 1 * 1000, ccData: 0x1425, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  var displayed = cea608Stream.displayed_.reduce(function(acc, val) {
    acc += val;
    return acc;
  });
  var nonDisplayed = cea608Stream.nonDisplayed_.reduce(function(acc, val) {
    acc += val;
    return acc;
  });

  assert.equal(captions.length, 1, 'flushed caption');
  assert.equal(displayed, '', 'displayed memory is wiped');
  assert.equal(nonDisplayed, '', 'non-displayed memory is wiped');
  assert.deepEqual(captions[0], {
    startPts: 0,
    endPts: 1000,
    text: 'hi',
    stream: 'CC1'
  }, 'caption correct');
});

// NOTE: This should change to not wiping the display when caption
// positioning is properly implemented
QUnit.test('switching to paint-on from pop-on flushes display', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RCL (resume caption loading)
    { pts: 0 * 1000, ccData: 0x1420, type: 0 },
    // PAC: row 14, indent 0
    { pts: 0 * 1000, ccData: 0x1450, type: 0 },
    { pts: 0 * 1000, ccData: characters('hi'), type: 0 },
    // EOC (end of caption), mark caption start
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // RCL
    { pts: 1 * 1000, ccData: 0x1420, type: 0 },
    // RDC (resume direct captioning), flush caption
    { pts: 2 * 1000, ccData: 0x1429, type: 0 },
    // PAC: row 14, indent 0
    { pts: 2 * 1000, ccData: 0x1450, type: 0 },
    // TO1 (tab offset 1 column)
    { pts: 2 * 1000, ccData: 0x1721, type: 0 },
    { pts: 3 * 1000, ccData: characters('io'), type: 0 },
    // EDM (erase displayed memory), flush paint-on caption
    { pts: 4 * 1000, ccData: 0x142c, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 2, 'detected 2 captions');
  assert.equal(captions[0].text, 'hi', 'pop-on caption received');
  assert.equal(captions[0].startPts, 1000, 'proper start pts');
  assert.equal(captions[0].endPts, 2000, 'proper end pts');
  assert.equal(captions[1].text, 'io', 'paint-on caption received');
  assert.equal(captions[1].startPts, 2000, 'proper start pts');
  assert.equal(captions[1].endPts, 4000, 'proper end pts');
});

QUnit.test('backspaces are reflected in the generated captions', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // backspace
    { ccData: 0x1421, type: 0 },
    {
      pts: 1 * 1000,
      ccData: characters('23'),
      type: 0
    },
    // CR, carriage return
    { pts: 1 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.equal(captions[0].text, '023', 'applied the backspace');
});

QUnit.test('backspaces can remove a caption entirely', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // backspace
    { ccData: 0x1421, type: 0 },
    // Send another command so that the backspace isn't
    // ignored as a duplicate command
    { ccData: 0x1425, type: 0 },
    // backspace
    { ccData: 0x1421, type: 0 },
    // CR, carriage return
    { pts: 1 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 0, 'no caption emitted');
});

QUnit.test('a second identical control code immediately following the first is ignored', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // '02'
    {
      pts: 1 * 1000,
      ccData: characters('02'),
      type: 0
    },
    // backspace
    { ccData: 0x1421, type: 0 },
    // backspace
    { ccData: 0x1421, type: 0 }, // duplicate is ignored
    // backspace
    { ccData: 0x1421, type: 0 },
    // CR, carriage return
    { pts: 2 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'caption emitted');
  assert.equal(captions[0].text, '01', 'only two backspaces processed');
});

QUnit.test('a second identical control code separated by only padding from the first is ignored', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // '02'
    {
      pts: 1 * 1000,
      ccData: characters('02'),
      type: 0
    },
    // backspace
    { ccData: 0x1421, type: 0 },
    // padding
    { ccData: 0x0000, type: 0 },
    { ccData: 0x0000, type: 0 },
    { ccData: 0x0000, type: 0 },
    // backspace
    { pts: 2 * 1000, ccData: 0x1421, type: 0 }, // duplicate is ignored
    // CR, carriage return
    { pts: 3 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'caption emitted');
  assert.equal(captions[0].text, '010', 'only one backspace processed');
});

QUnit.test('preamble address codes on same row are NOT converted into spaces', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // PAC: row 15, indent 0
    { ccData: 0x1470, type: 0 },
    // '02'
    {
      pts: 1 * 1000,
      ccData: characters('02'),
      type: 0
    },
    // CR, carriage return
    { pts: 2 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'caption emitted');
  assert.equal(captions[0].text, '0102', 'PACs were NOT converted to space');
});

QUnit.test('preserves newlines from PACs in pop-on mode', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RCL, resume caption loading
    { ccData: 0x1420, type: 0 },
    // ENM, erase non-displayed memory
    { ccData: 0x142e, type: 0 },
    // PAC: row 12, indent 0
    { ccData: 0x1350, type: 0 },
    // text: TEST
    { ccData: 0x5445, type: 0 },
    { ccData: 0x5354, type: 0 },
    // PAC: row 14, indent 0
    { ccData: 0x1450, type: 0 },
    // text: STRING
    { ccData: 0x5354, type: 0 },
    { ccData: 0x5249, type: 0 },
    { ccData: 0x4e47, type: 0 },
    // PAC: row 15, indent 0
    { ccData: 0x1470, type: 0 },
    // text: DATA
    { ccData: 0x4441, type: 0 },
    { ccData: 0x5441, type: 0 },
    // EOC, end of caption
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // EOC, duplicated as per spec
    { pts: 1 * 1000, ccData: 0x142f, type: 0 },
    // EOC, dispatch caption
    { pts: 2 * 1000, ccData: 0x142f, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'caption emitted');
  assert.equal(captions[0].text, 'TEST\n\nSTRING\nDATA', 'Position PACs were converted to newlines');
});

QUnit.test('extracts real-world cc1 and cc3 channels', function(assert) {
  var cea608Stream1 = cea608Stream;
  var cea608Stream3 = new m2ts.Cea608Stream(1, 0);
  var captions = [];
  cea608Stream1.on('data', function(caption) {
    captions.push(caption);
  });
  cea608Stream3.on('data', function(caption) {
    captions.push(caption);
  });

  var packets = [
    { pts: 425316, type: 0, ccData: 5158 }, // RU3
    { pts: 431322, type: 0, ccData: 5165 }, // CR
    { pts: 440331, type: 0, ccData: 4944 }, // position 11,0
    { pts: 443334, type: 0, ccData: 20549 }, // PE
    { pts: 449340, type: 0, ccData: 21065 }, // RI
    { pts: 449340, type: 0, ccData: 0 }, // padding
    { pts: 452343, type: 0, ccData: 20292 }, // OD
    { pts: 458349, type: 0, ccData: 11264 }, // ,
    { pts: 458349, type: 0, ccData: 0 }, // padding
    { pts: 461352, type: 0, ccData: 0 }, // padding
    { pts: 467358, type: 0, ccData: 8192 }, // (space)
    { pts: 467358, type: 0, ccData: 17920 }, // F
    { pts: 470361, type: 0, ccData: 0 }, // padding
    { pts: 476367, type: 0, ccData: 0 }, // padding
    { pts: 476367, type: 0, ccData: 20300 }, // OL
    { pts: 479370, type: 0, ccData: 19283 }, // KS
    { pts: 485376, type: 0, ccData: 0 }, // padding
    { pts: 485376, type: 0, ccData: 11776 }, // .
    { pts: 674565, type: 0, ccData: 5158 }, // RU3
    { pts: 677568, type: 0, ccData: 5165 }, // CR
    { pts: 371262, type: 1, ccData: 5414 }, // RU3
    { pts: 377268, type: 1, ccData: 0 }, // padding
    { pts: 377268, type: 1, ccData: 4944 }, // position 11,0
    { pts: 380271, type: 1, ccData: 0 }, // padding
    { pts: 386277, type: 1, ccData: 4412 }, // ê
    { pts: 386277, type: 1, ccData: 0 }, // padding
    { pts: 389280, type: 1, ccData: 29810 }, // tr
    { pts: 395286, type: 1, ccData: 25888 }, // e(space)
    { pts: 395286, type: 1, ccData: 30062 }, // un
    { pts: 398289, type: 1, ccData: 25888 }, // e(space)
    { pts: 404295, type: 1, ccData: 28764 }, // pé
    { pts: 404295, type: 1, ccData: 29289 }, // ri
    { pts: 407298, type: 1, ccData: 28516 }, // od
    { pts: 413304, type: 1, ccData: 25856 }, // e
    { pts: 413304, type: 1, ccData: 0 }, // padding
    { pts: 443334, type: 1, ccData: 8292 }, // (space)d
    { pts: 449340, type: 1, ccData: 25888 }, // e(space)
    { pts: 449340, type: 1, ccData: 29045 }, // qu
    { pts: 452343, type: 1, ccData: 25971 }, // es
    { pts: 458349, type: 1, ccData: 29801 }, // ti
    { pts: 458349, type: 1, ccData: 28526 }, // on
    { pts: 461352, type: 1, ccData: 29440 }, // s
    { pts: 467358, type: 1, ccData: 5421 }, // CR
    { pts: 467358, type: 1, ccData: 0 }, // padding
    { pts: 470361, type: 1, ccData: 5414 }, // RU3
    { pts: 476367, type: 1, ccData: 0 } // padding
  ];

  packets.forEach(function(packet) {
    cea608Stream1.push(packet);
    cea608Stream3.push(packet);
  });

  var cc1 = {stream: 'CC1', text: 'PERIOD, FOLKS.'};
  var cc3 = {stream: 'CC3', text: 'être une période de questions'};

  assert.equal(captions.length, 2, 'caption emitted');
  assert.equal(captions[0].stream, cc1.stream, 'cc1 stream detected');
  assert.equal(captions[0].text, cc1.text, 'cc1 stream extracted successfully');
  assert.equal(captions[1].stream, cc3.stream, 'cc3 stream detected');
  assert.equal(captions[1].text, cc3.text, 'cc3 stream extracted successfully');
});

QUnit.test('backspaces stop at the beginning of the line', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RU2, roll-up captions 2 rows
    { ccData: 0x1425, type: 0 },
    // '01'
    {
      pts: 0 * 1000,
      ccData: characters('01'),
      type: 0
    },
    // backspace
    { ccData: 0x1421, type: 0 },
    // Send another command so that the backspace isn't
    // ignored as a duplicate command
    { ccData: 0x1425, type: 0 },
    // backspace
    { ccData: 0x1421, type: 0 },
    // Send another command so that the backspace isn't
    // ignored as a duplicate command
    { ccData: 0x1425, type: 0 },
    // backspace
    { ccData: 0x1421, type: 0 },
    // CR, carriage return
    { pts: 1 * 1000, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 0, 'no caption emitted');
});

QUnit.test('reset works', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });
  [ // RU2, roll-up captions 2 rows
    { pts: 0, ccData: 0x1425, type: 0 },
    // mid-row: white underline
    { pts: 0, ccData: 0x1121, type: 0 },
    { pts: 0, ccData: characters('01'), type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);
  var buffer = cea608Stream.displayed_.map(function(row) {
    return row.trim();
  }).join('\n')
  .replace(/^\n+|\n+$/g, '');

  assert.equal(buffer, '<u>01', 'buffer is as expected');

  cea608Stream.reset();
  buffer = cea608Stream.displayed_
    .map(function(row) {
      return row.trim();
    })
    .join('\n')
    .replace(/^\n+|\n+$/g, '');
  assert.equal(buffer, '', 'displayed buffer reset successfully');
  assert.equal(cea608Stream.lastControlCode_, null, 'last control code reset successfully');
  assert.deepEqual(cea608Stream.formatting_, [], 'formatting was reset');

});


QUnit.test('paint-on mode', function(assert) {
  var packets, captions;
  packets = [
    // RDC, resume direct captioning, begin display
    { pts: 1000, ccData: 0x1429, type: 0 },
    { pts: 2000, ccData: characters('hi'), type: 0 },
    // EDM, erase displayed memory. Finish display, flush caption
    { pts: 3000, ccData: 0x142c, type: 0 }
  ];
  captions = [];

  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  packets.forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.deepEqual(captions[0], {
    startPts: 1000,
    endPts: 3000,
    text: 'hi',
    stream: 'CC1'
  }, 'parsed the caption');
});

QUnit.test('preserves newlines from PACs in paint-on mode', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RDC, resume direct captioning
    { pts: 1000, ccData: 0x1429, type: 0 },
    // PAC: row 12, indent 0
    { pts: 1000, ccData: 0x1350, type: 0 },
    // text: TEST
    { pts: 2000, ccData: 0x5445, type: 0 },
    { pts: 2000, ccData: 0x5354, type: 0 },
    // PAC: row 14, indent 0
    { pts: 3000, ccData: 0x1450, type: 0 },
    // text: STRING
    { pts: 3000, ccData: 0x5354, type: 0 },
    { pts: 4000, ccData: 0x5249, type: 0 },
    { pts: 4000, ccData: 0x4e47, type: 0 },
    // PAC: row 15, indent 0
    { pts: 5000, ccData: 0x1470, type: 0 },
    // text: DATA
    { pts: 5000, ccData: 0x4441, type: 0 },
    { pts: 6000, ccData: 0x5441, type: 0 },
    // EDM, erase displayed memory. Finish display, flush caption
    { pts: 6000, ccData: 0x142c, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'caption emitted');
  assert.equal(captions[0].text, 'TEST\n\nSTRING\nDATA', 'Position PACs were converted to newlines');
});

QUnit.test('backspaces are reflected in the generated captions (paint-on)', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [ // RDC, resume direct captioning
    { ccData: 0x1429, type: 0 },
    // '01', default row 15
    { pts: 0 * 1000, ccData: characters('01'), type: 0 },
    // backspace
    { pts: 0 * 1000, ccData: 0x1421, type: 0 },
    { pts: 1 * 1000, ccData: characters('23'), type: 0 },
    // PAC: row 13, indent 0
    { pts: 2 * 1000, ccData: 0x1370, type: 0 },
    { pts: 2 * 1000, ccData: characters('32'), type: 0 },
    // backspace
    { pts: 3 * 1000, ccData: 0x1421, type: 0 },
    { pts: 4 * 1000, ccData: characters('10'), type: 0 },
    // EDM, erase displayed memory, flush caption
    { pts: 5 * 1000, ccData: 0x142c, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 1, 'detected a caption');
  assert.equal(captions[0].text, '310\n\n023', 'applied the backspaces');
});

QUnit.test('mix of all modes (extract from CNN)', function(assert) {
  var captions = [];
  cea608Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // RU2 (roll-up, 2 rows)
    { pts: 6675, ccData: 0x1425, type: 0 },
    // CR (carriange return), flush nothing
    { pts: 6675, ccData: 0x142d, type: 0 },
    // PAC: row 2, indent 0
    { pts: 6675, ccData: 0x1170, type: 0 },
    // text: YEAR.
    { pts: 6676, ccData: 0x5945, type: 0 },
    { pts: 6676, ccData: 0x4152, type: 0 },
    { pts: 6676, ccData: 0x2e00, type: 0 },
    // RU2 (roll-up, 2 rows)
    { pts: 6677, ccData: 0x1425, type: 0 },
    // CR (carriange return), flush 1 row
    { pts: 6677, ccData: 0x142d, type: 0 },
    // PAC: row 2, indent 0
    { pts: 6677, ccData: 0x1170, type: 0 },
    // text: GO TO CNNHEROS.COM.
    { pts: 6677, ccData: 0x474f, type: 0 },
    { pts: 6678, ccData: 0x2054, type: 0 },
    { pts: 6678, ccData: 0x4f00, type: 0 },
    { pts: 6678, ccData: 0x2043, type: 0 },
    { pts: 6679, ccData: 0x4e4e, type: 0 },
    { pts: 6679, ccData: 0x4845, type: 0 },
    { pts: 6679, ccData: 0x524f, type: 0 },
    { pts: 6680, ccData: 0x532e, type: 0 },
    { pts: 6680, ccData: 0x434f, type: 0 },
    { pts: 6680, ccData: 0x4d2e, type: 0 },
    // EDM (erase displayed memory), flush 2 displayed roll-up rows
    { pts: 6697, ccData: 0x142c, type: 0 },
    // RDC (resume direct captioning), wipes memories, flushes nothing
    { pts: 6749, ccData: 0x1429, type: 0 },
    // PAC: row 1, indent 0
    { pts: 6750, ccData: 0x1150, type: 0 },
    // text: Did your Senator or Congressman
    { pts: 6750, ccData: 0x4469, type: 0 },
    { pts: 6750, ccData: 0x6420, type: 0 },
    { pts: 6750, ccData: 0x796f, type: 0 },
    { pts: 6751, ccData: 0x7572, type: 0 },
    { pts: 6751, ccData: 0x2053, type: 0 },
    { pts: 6751, ccData: 0x656e, type: 0 },
    { pts: 6752, ccData: 0x6174, type: 0 },
    { pts: 6752, ccData: 0x6f72, type: 0 },
    { pts: 6752, ccData: 0x206f, type: 0 },
    { pts: 6753, ccData: 0x7220, type: 0 },
    { pts: 6753, ccData: 0x436f, type: 0 },
    { pts: 6753, ccData: 0x6e67, type: 0 },
    { pts: 6753, ccData: 0x7265, type: 0 },
    { pts: 6754, ccData: 0x7373, type: 0 },
    { pts: 6754, ccData: 0x6d61, type: 0 },
    { pts: 6754, ccData: 0x6e00, type: 0 },
    // PAC: row 2, indent 0
    { pts: 6755, ccData: 0x1170, type: 0 },
    // TO2 (tab offset 2 columns)
    { pts: 6755, ccData: 0x1722, type: 0 },
    // text: get elected by talking tough
    { pts: 6755, ccData: 0x6765, type: 0 },
    { pts: 6756, ccData: 0x7420, type: 0 },
    { pts: 6756, ccData: 0x656c, type: 0 },
    { pts: 6756, ccData: 0x6563, type: 0 },
    { pts: 6756, ccData: 0x7465, type: 0 },
    { pts: 6757, ccData: 0x6420, type: 0 },
    { pts: 6757, ccData: 0x6279, type: 0 },
    { pts: 6757, ccData: 0x2074, type: 0 },
    { pts: 6758, ccData: 0x616c, type: 0 },
    { pts: 6758, ccData: 0x6b69, type: 0 },
    { pts: 6758, ccData: 0x6e67, type: 0 },
    { pts: 6759, ccData: 0x2074, type: 0 },
    { pts: 6759, ccData: 0x6f75, type: 0 },
    { pts: 6759, ccData: 0x6768, type: 0 },
    // RCL (resume caption loading)
    { pts: 6759, ccData: 0x1420, type: 0 },
    // PAC: row 1, indent 4
    { pts: 6760, ccData: 0x1152, type: 0 },
    // TO1 (tab offset 1 column)
    { pts: 6760, ccData: 0x1721, type: 0 },
    // text: on the national debt?
    { pts: 6760, ccData: 0x6f6e, type: 0 },
    { pts: 6761, ccData: 0x2074, type: 0 },
    { pts: 6761, ccData: 0x6865, type: 0 },
    { pts: 6761, ccData: 0x206e, type: 0 },
    { pts: 6762, ccData: 0x6174, type: 0 },
    { pts: 6762, ccData: 0x696f, type: 0 },
    { pts: 6762, ccData: 0x6e61, type: 0 },
    { pts: 6762, ccData: 0x6c20, type: 0 },
    { pts: 6763, ccData: 0x6465, type: 0 },
    { pts: 6763, ccData: 0x6274, type: 0 },
    { pts: 6763, ccData: 0x3f00, type: 0 },
    // RCL (resume caption loading)
    { pts: 6781, ccData: 0x1420, type: 0 },
    // EDM (erase displayed memory), flush paint-on caption
    { pts: 6781, ccData: 0x142c, type: 0 },
    // EOC (end of caption), mark pop-on caption 1 start
    { pts: 6782, ccData: 0x142f, type: 0 },
    // RCL (resume caption loading)
    { pts: 6782, ccData: 0x1420, type: 0 },
    // PAC: row 1, indent 4
    { pts: 6782, ccData: 0x1152, type: 0 },
    // TO2 (tab offset 2 columns)
    { pts: 6783, ccData: 0x1722, type: 0 },
    // text: Will they stay true
    { pts: 6783, ccData: 0x5769, type: 0 },
    { pts: 6783, ccData: 0x6c6c, type: 0 },
    { pts: 6783, ccData: 0x2074, type: 0 },
    { pts: 6784, ccData: 0x6865, type: 0 },
    { pts: 6784, ccData: 0x7920, type: 0 },
    { pts: 6784, ccData: 0x7374, type: 0 },
    { pts: 6785, ccData: 0x6179, type: 0 },
    { pts: 6785, ccData: 0x2074, type: 0 },
    { pts: 6785, ccData: 0x7275, type: 0 },
    { pts: 6786, ccData: 0x6500, type: 0 },
    // PAC: row 2, indent 8
    { pts: 6786, ccData: 0x1174, type: 0 },
    // text: to their words?
    { pts: 6786, ccData: 0x746f, type: 0 },
    { pts: 6786, ccData: 0x2074, type: 0 },
    { pts: 6787, ccData: 0x6865, type: 0 },
    { pts: 6787, ccData: 0x6972, type: 0 },
    { pts: 6787, ccData: 0x2077, type: 0 },
    { pts: 6788, ccData: 0x6f72, type: 0 },
    { pts: 6788, ccData: 0x6473, type: 0 },
    { pts: 6788, ccData: 0x3f00, type: 0 },
    // RCL (resume caption loading)
    { pts: 6797, ccData: 0x1420, type: 0 },
    // EDM (erase displayed memory), mark pop-on caption 1 end and flush
    { pts: 6797, ccData: 0x142c, type: 0 },
    // EOC (end of caption), mark pop-on caption 2 start, flush nothing
    { pts: 6798, ccData: 0x142f, type: 0 },
    // RCL
    { pts: 6799, ccData: 0x1420, type: 0 },
    // EOC, mark pop-on caption 2 end and flush
    { pts: 6838, ccData: 0x142f, type: 0 },
    // RU2 (roll-up, 2 rows), wipes memories
    { pts: 6841, ccData: 0x1425, type: 0 },
    // CR (carriage return), flush nothing
    { pts: 6841, ccData: 0x142d, type: 0 },
    // PAC: row 2, indent 0
    { pts: 6841, ccData: 0x1170, type: 0 },
    // text: NO MORE SPECULATION, NO MORE
    { pts: 6841, ccData: 0x3e3e, type: 0 },
    { pts: 6841, ccData: 0x3e00, type: 0 },
    { pts: 6842, ccData: 0x204e, type: 0 },
    { pts: 6842, ccData: 0x4f00, type: 0 },
    { pts: 6842, ccData: 0x204d, type: 0 },
    { pts: 6842, ccData: 0x4f52, type: 0 },
    { pts: 6842, ccData: 0x4500, type: 0 },
    { pts: 6842, ccData: 0x2000, type: 0 },
    { pts: 6842, ccData: 0x5350, type: 0 },
    { pts: 6843, ccData: 0x4543, type: 0 },
    { pts: 6843, ccData: 0x554c, type: 0 },
    { pts: 6843, ccData: 0x4154, type: 0 },
    { pts: 6843, ccData: 0x494f, type: 0 },
    { pts: 6843, ccData: 0x4e2c, type: 0 },
    { pts: 6843, ccData: 0x204e, type: 0 },
    { pts: 6843, ccData: 0x4f00, type: 0 },
    { pts: 6843, ccData: 0x204d, type: 0 },
    { pts: 6844, ccData: 0x4f52, type: 0 },
    { pts: 6844, ccData: 0x4500, type: 0 },
    // RU2 (roll-up, two rows)
    { pts: 6844, ccData: 0x1425, type: 0 },
    // CR (carriage return), flush 1 roll-up row
    { pts: 6844, ccData: 0x142d, type: 0 },
    // PAC: row 2, indent 0
    { pts: 6844, ccData: 0x1170, type: 0 },
    // text: RUMORS OR GUESSING GAMES.
    { pts: 6844, ccData: 0x5255, type: 0 },
    { pts: 6844, ccData: 0x4d4f, type: 0 },
    { pts: 6844, ccData: 0x5253, type: 0 },
    { pts: 6844, ccData: 0x204f, type: 0 },
    { pts: 6845, ccData: 0x5200, type: 0 },
    { pts: 6845, ccData: 0x2047, type: 0 },
    { pts: 6845, ccData: 0x5545, type: 0 },
    { pts: 6845, ccData: 0x5353, type: 0 },
    { pts: 6845, ccData: 0x494e, type: 0 },
    { pts: 6845, ccData: 0x4700, type: 0 },
    { pts: 6845, ccData: 0x2047, type: 0 },
    { pts: 6845, ccData: 0x414d, type: 0 },
    { pts: 6845, ccData: 0x4553, type: 0 },
    { pts: 6845, ccData: 0x2e00, type: 0 },
    // RU2 (roll-up, 2 rows)
    { pts: 6846, ccData: 0x1425, type: 0 },
    // CR (carriage return), flush 2 roll-up rows
    { pts: 6846, ccData: 0x142d, type: 0 }
  ].forEach(cea608Stream.push, cea608Stream);

  assert.equal(captions.length, 7, 'detected 7 captions of varying types');
  assert.deepEqual(captions[0], {
    startPts: 6675,
    endPts: 6677,
    text: 'YEAR.',
    stream: 'CC1'
  }, 'parsed the 1st roll-up caption');
  assert.deepEqual(captions[1], {
    startPts: 6677,
    endPts: 6697,
    text: 'YEAR.\nGO TO CNNHEROS.COM.',
    stream: 'CC1'
  }, 'parsed the 2nd roll-up caption');
  assert.deepEqual(captions[2], {
    startPts: 6749,
    endPts: 6781,
    text: 'Did your Senator or Congressman\nget elected by talking tough',
    stream: 'CC1'
  }, 'parsed the paint-on caption');
  assert.deepEqual(captions[3], {
    startPts: 6782,
    endPts: 6797,
    text: 'on the national debt?',
    stream: 'CC1'
  }, 'parsed the 1st pop-on caption');
  assert.deepEqual(captions[4], {
    startPts: 6798,
    endPts: 6838,
    text: 'Will they stay true\nto their words?',
    stream: 'CC1'
  }, 'parsed the 2nd pop-on caption');
  assert.deepEqual(captions[5], {
    startPts: 6841,
    endPts: 6844,
    text: '>>> NO MORE SPECULATION, NO MORE',
    stream: 'CC1'
  }, 'parsed the 3rd roll-up caption');
  assert.deepEqual(captions[6], {
    startPts: 6844,
    endPts: 6846,
    text: '>>> NO MORE SPECULATION, NO MORE\nRUMORS OR GUESSING GAMES.',
    stream: 'CC1'
  }, 'parsed the 4th roll-up caption');

});

QUnit.test('Cea608Stream will trigger log on malformed captions', function(assert) {
  var result;
  var logs = [];

  cea608Stream.on('log', function(log) {
    logs.push(log);
  })

  // this will force an exception to happen in flushDisplayed
  cea608Stream.displayed_[0] = undefined;

  try {
    cea608Stream.flushDisplayed();
    result = true;
  } catch (e) {
    result = false;
  }

  assert.ok(
    result,
    'the function does not throw an exception'
  );
  assert.deepEqual(
    logs,
    [
      {level: 'warn', message: 'Skipping a malformed 608 caption at index 0.'}
    ],
    'logs were triggered'
  );
});

var cea708Stream;

QUnit.module('CEA 708 Stream', {
  beforeEach: function() {
    cea708Stream = new m2ts.Cea708Stream();
  }
});

QUnit.test('Filters encoding values out of captionServices option block', function(assert) {
  var expectedServiceEncodings = {
    SERVICE1: 'euc-kr',
    SERVICE2: 'utf-8',
  };

  cea708Stream = new m2ts.Cea708Stream({
    captionServices: {
      SERVICE1: {
        language: 'kr',
        label: 'Korean',
        encoding: 'euc-kr'
      },
      SERVICE2: {
        language: 'en',
        label: 'English',
        encoding: 'utf-8'
      }
    }
  });

  assert.deepEqual(cea708Stream.serviceEncodings, expectedServiceEncodings, 'filtered encodings correctly');
});

QUnit.test('parses 708 captions', function(assert) {
  var captions = [];

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  cc708PinkUnderscore.forEach(cea708Stream.push, cea708Stream);

  assert.equal(captions.length, 235, 'parsed 235 captions');
  assert.deepEqual(captions[0], {
    startPts: 6723335478,
    endPts: 6723626769,
    text: '\"Pinkalicious_and_Peterrific\"\nis_made_possible_in_part_by:',
    stream: 'cc708_1'
  }, 'parsed first caption correctly');
  assert.deepEqual(captions[1], {
    startPts: 6723740883,
    endPts: 6723945087,
    text: 'GIRL:\nRead_me_the_tale\nof_a_faraway_land.',
    stream: 'cc708_1'
  }, 'parsed second caption correctly');
  assert.deepEqual(captions[2], {
    startPts: 6723948090,
    endPts: 6724200342,
    text: 'Tell_me_of_planets\nwith_oceans_of_sand.',
    stream: 'cc708_1'
  }, 'parsed third caption correctly');
  assert.deepEqual(captions[33], {
    startPts: 6732617751,
    endPts: 6732876009,
    text: '♪_It\'s_a_Pinkalicious_feeling_♪',
    stream: 'cc708_1'
  }, 'parsed caption 33 correctly with music note');
  assert.deepEqual(captions[38], {
    startPts: 6734218350,
    endPts: 6734425557,
    text: 'PINKALICIOUS:\n\"Dream_Salon.\"',
    stream: 'cc708_1'
  }, 'parsed caption 38 correctly');
  assert.deepEqual(captions[234], {
    startPts: 6778809897,
    endPts: 6779104191,
    text: 'I_guess_I\'ll_just_have\nto_duck_a_little_bit.',
    stream: 'cc708_1'
  }, 'parsed caption 234 correctly');
});

QUnit.test('Decodes multibyte characters if valid encoding option is provided and TextDecoder is supported', function(assert) {
  var captions = [];

  cea708Stream = new m2ts.Cea708Stream({
    captionServices: {
      SERVICE1: {
        encoding: 'euc-kr'
      }
    }
  });

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  cc708Korean.forEach(cea708Stream.push, cea708Stream);

  cea708Stream.flushDisplayed(4721138662, cea708Stream.services[1]);

  assert.equal(captions.length, 1, 'parsed single caption correctly');

  if (window.TextDecoder) {
    assert.ok(cea708Stream.services[1].textDecoder_, 'TextDecoder created when supported');
    assert.equal(
      captions[0].text,
      '니가 ',
      'parsed multibyte characters correctly'
    );
  } else {
    assert.notOk(cea708Stream.services[1].textDecoder_, 'TextDecoder not created when unsupported');
  }
});

QUnit.test('Creates TextDecoder only if valid encoding value is provided', function(assert) {
  var secondCea708Stream;

  cea708Stream = new m2ts.Cea708Stream({
    captionServices: {
      SERVICE1: {
        encoding: 'euc-kr'
      }
    }
  });

  cc708Korean.forEach(cea708Stream.push, cea708Stream);
  cea708Stream.flushDisplayed(4721138662, cea708Stream.services[1]);

  if (window.TextDecoder) {
    assert.ok(cea708Stream.services[1].textDecoder_, 'TextDecoder created successfully when encoding is valid');
  }

  secondCea708Stream = new m2ts.Cea708Stream({
    captionServices: {
      SERVICE1: {
        encoding: 'invalid'
      }
    }
  });

  cc708Korean.forEach(secondCea708Stream.push, secondCea708Stream);
  secondCea708Stream.flushDisplayed(4721138662, secondCea708Stream.services[1]);

  assert.notOk(secondCea708Stream.services[1].textDecoder_, 'TextDecoder not created when encoding is invalid');
});

QUnit.test('reset command', function(assert) {
  var captions = [];

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
      { type: 3, pts: 153315036, ccData: 0x8322 },
      { type: 2, pts: 153315036, ccData: 0x4820 },
      { type: 2, pts: 153315036, ccData: 0x0000 },
      { type: 3, pts: 153318039, ccData: 0xc322 },
      { type: 2, pts: 153318039, ccData: 0x4953 },
      { type: 2, pts: 153318039, ccData: 0x0000 },
      { type: 3, pts: 153387108, ccData: 0x0628 },
      { type: 2, pts: 153387108, ccData: 0x0d90 },
      { type: 2, pts: 153387108, ccData: 0x0503 },
      { type: 2, pts: 153387108, ccData: 0x912a },
      { type: 2, pts: 153387108, ccData: 0x002a },
      { type: 2, pts: 153387108, ccData: 0x0000 },
      { type: 3, pts: 153405126, ccData: 0x4da2 },
      { type: 2, pts: 153405126, ccData: 0x8c0f },
      { type: 2, pts: 153405126, ccData: 0x628c },
      { type: 2, pts: 153405126, ccData: 0x0f31 },
      { type: 2, pts: 153405126, ccData: 0x983b },
      { type: 2, pts: 153405126, ccData: 0x912a },
      { type: 2, pts: 153405126, ccData: 0x8f00 },
      { type: 2, pts: 153405126, ccData: 0x611f },
      { type: 2, pts: 153405126, ccData: 0x002a },
      { type: 2, pts: 153405126, ccData: 0x1090 },
      { type: 2, pts: 153405126, ccData: 0x0503 },
      { type: 3, pts: 153408129, ccData: 0x8a31 },
      { type: 2, pts: 153408129, ccData: 0x9201 },
      { type: 2, pts: 153408129, ccData: 0x983b },
      // RST (Reset command)
      { type: 2, pts: 153408129, ccData: 0x8f00 },
      { type: 2, pts: 153408129, ccData: 0x0000 },
      { type: 2, pts: 153408129, ccData: 0x611f },
      { type: 2, pts: 153408129, ccData: 0x1090 },
      { type: 2, pts: 153408129, ccData: 0x0000 },
      { type: 2, pts: 153408129, ccData: 0x0503 },
      { type: 2, pts: 153408129, ccData: 0x912a },
      { type: 2, pts: 153408129, ccData: 0x0000 },
      { type: 2, pts: 153408129, ccData: 0x9201 },
      { type: 3, pts: 153414135, ccData: 0xc322 },
      { type: 2, pts: 153414135, ccData: 0x434f },
      { type: 2, pts: 153414135, ccData: 0x0000 }
  ].forEach(cea708Stream.push, cea708Stream);

  assert.equal(captions.length, 1, 'parsed 1 caption');
  assert.deepEqual(captions[0], {
    startPts: 153315036,
    endPts: 153408129,
    text: '*\n;',
    stream: 'cc708_1'
  }, 'parsed the caption correctly');
});

QUnit.test('windowing', function(assert) {
  var captions = [];

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    { type: 3, pts: 1000, ccData: packetHeader708(0, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8000 }, // CW0
    { type: 2, pts: 1000, ccData: characters('w0') },

    { type: 3, pts: 1000, ccData: packetHeader708(1, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8100 }, // CW1
    { type: 2, pts: 1000, ccData: characters('w1') },

    { type: 3, pts: 1000, ccData: packetHeader708(2, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8200 }, // CW2
    { type: 2, pts: 1000, ccData: characters('w2') },

    { type: 3, pts: 1000, ccData: packetHeader708(0, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8300 }, // CW3
    { type: 2, pts: 1000, ccData: characters('w3') },

    { type: 3, pts: 1000, ccData: packetHeader708(1, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8400 }, // CW4
    { type: 2, pts: 1000, ccData: characters('w4') },

    { type: 3, pts: 1000, ccData: packetHeader708(2, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8500 }, // CW5
    { type: 2, pts: 1000, ccData: characters('w5') },

    { type: 3, pts: 1000, ccData: packetHeader708(0, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8600 }, // CW6
    { type: 2, pts: 1000, ccData: characters('w6') },

    { type: 3, pts: 1000, ccData: packetHeader708(1, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: 0x8700 }, // CW7
    { type: 2, pts: 1000, ccData: characters('w7') },

    { type: 3, pts: 2000, ccData: packetHeader708(2, 3, 1, 4) },
    { type: 2, pts: 2000, ccData: 0x8aff }, // HDW (Hide all)
    { type: 2, pts: 2000, ccData: displayWindows708([0]) },

    { type: 3, pts: 3000, ccData: packetHeader708(0, 3, 1, 4) },
    { type: 2, pts: 3000, ccData: 0x8aff }, // HDW (Hide all)
    { type: 2, pts: 3000, ccData: displayWindows708([1]) },

    { type: 3, pts: 4000, ccData: packetHeader708(1, 3, 1, 4) },
    { type: 2, pts: 4000, ccData: 0x8aff }, // HDW (Hide all)
    { type: 2, pts: 4000, ccData: displayWindows708([2, 3]) },

    { type: 3, pts: 5000, ccData: packetHeader708(2, 3, 1, 4) },
    { type: 2, pts: 5000, ccData: 0x8aff }, // HDW (Hide all)
    { type: 2, pts: 5000, ccData: displayWindows708([3, 4]) },

    { type: 3, pts: 6000, ccData: packetHeader708(0, 3, 1, 4) },
    { type: 2, pts: 6000, ccData: 0x8aff }, // HDW (Hide all)
    { type: 2, pts: 6000, ccData: displayWindows708([5, 6, 7]) },

    { type: 3, pts: 7000, ccData: packetHeader708(1, 2, 1, 2) },
    { type: 2, pts: 7000, ccData: 0x8aff }, // HDW (Hide all)

    // Indicate end of last packet
    { type: 3, pts: 8000, ccData: packetHeader708(2, 1, 1, 0) }
  ].forEach(cea708Stream.push, cea708Stream);

  assert.equal(captions.length, 5, 'parsed 5 captions');
  assert.deepEqual(captions[0], {
    startPts: 2000,
    endPts: 3000,
    text: 'w0',
    stream: 'cc708_1'
  }, 'parsed caption 0 correctly');
  assert.deepEqual(captions[1], {
    startPts: 3000,
    endPts: 4000,
    text: 'w1',
    stream: 'cc708_1'
  }, 'parsed caption 1 correctly');
  assert.deepEqual(captions[2], {
    startPts: 4000,
    endPts: 5000,
    text: 'w2\n\nw3',
    stream: 'cc708_1'
  }, 'parsed caption 2 correctly');
  assert.deepEqual(captions[3], {
    startPts: 5000,
    endPts: 6000,
    text: 'w3\n\nw4',
    stream: 'cc708_1'
  }, 'parsed caption 3 correctly');
  assert.deepEqual(captions[4], {
    startPts: 6000,
    endPts: 7000,
    text: 'w5\n\nw6\n\nw7',
    stream: 'cc708_1'
  }, 'parsed caption 4 correctly');
});

QUnit.test('backspace', function(assert) {
  var captions = [];

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    { type: 3, pts: 1000, ccData: packetHeader708(0, 7, 1, 12) },
    { type: 2, pts: 1000, ccData: 0x8000 }, // CW0
    { type: 2, pts: 1000, ccData: characters('ty') },
    { type: 2, pts: 1000, ccData: characters('op') },
    { type: 2, pts: 1000, ccData: 0x0808 }, // BS BS: Backspace twice
    { type: 2, pts: 1000, ccData: characters('po') },
    { type: 2, pts: 1000, ccData: displayWindows708([0]) },

    { type: 3, pts: 2000, ccData: packetHeader708(1, 2, 1, 2) },
    { type: 2, pts: 2000, ccData: 0x8aff },

    // Indicate end of last packet
    { type: 3, pts: 3000, ccData: packetHeader708(2, 1, 1, 0) }
  ].forEach(cea708Stream.push, cea708Stream);

  assert.equal(captions.length, 1, 'parsed 1 caption');
  assert.equal(captions[0].text, 'typo', 'parsed caption with backspaces correctly');
});

QUnit.test('extended character set', function(assert) {
  var captions = [];

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    { type: 3, pts: 1000, ccData: packetHeader708(0, 7, 1, 12) },
    { type: 2, pts: 1000, ccData: displayWindows708([0]) },
    { type: 2, pts: 1000, ccData: 0x8000 }, // CW0
    { type: 2, pts: 1000, ccData: 0x103f }, // Ÿ
    { type: 2, pts: 1000, ccData: 0x1035 }, // •
    { type: 2, pts: 1000, ccData: 0x103f }, // Ÿ
    { type: 2, pts: 1000, ccData: 0x0020 },

    { type: 3, pts: 1000, ccData: packetHeader708(1, 7, 1, 12) },
    { type: 2, pts: 1000, ccData: 0x103c }, // œ
    { type: 2, pts: 1000, ccData: 0x102a }, // Š
    { type: 2, pts: 1000, ccData: 0x1025 }, // …
    { type: 2, pts: 1000, ccData: 0x102a }, // Š
    { type: 2, pts: 1000, ccData: 0x103c }, // œ
    { type: 2, pts: 1000, ccData: 0x0020 },

    { type: 3, pts: 1000, ccData: packetHeader708(2, 5, 1, 8) },
    { type: 2, pts: 1000, ccData: 0x1033 }, // “
    { type: 2, pts: 1000, ccData: 0x103d }, // ℠
    { type: 2, pts: 1000, ccData: 0x1034 }, // ”
    { type: 2, pts: 1000, ccData: 0x1039 }, // ™

    { type: 3, pts: 2000, ccData: packetHeader708(0, 2, 1, 2) },
    { type: 2, pts: 2000, ccData: 0x8aff },

    // Indicate end of last packet
    { type: 3, pts: 3000, ccData: packetHeader708(1, 1, 1, 0) }
  ].forEach(cea708Stream.push, cea708Stream);

  assert.equal(captions.length, 1, 'parsed 1 caption');
  assert.equal(captions[0].text, 'Ÿ•Ÿ œŠ…Šœ “℠”™', 'parsed extended characters correctly');
});

QUnit.test('roll up', function(assert) {
  var captions = [];

  cea708Stream.on('data', function(caption) {
    captions.push(caption);
  });

  [
    // Define window with two virtual rows (rowCount = 1)
    { type: 3, pts: 1000, ccData: packetHeader708(0, 4, 1, 6) },
    { type: 2, pts: 1000, ccData: 0x983b },
    { type: 2, pts: 1000, ccData: 0x8f00 },
    { type: 2, pts: 1000, ccData: 0x611f },

    { type: 3, pts: 1000, ccData: packetHeader708(1, 3, 1, 4) },
    { type: 2, pts: 1000, ccData: characters('L1') },
    { type: 2, pts: 1000, ccData: 0x0d00 }, // CR

    { type: 3, pts: 2000, ccData: packetHeader708(2, 3, 1, 4) },
    { type: 2, pts: 2000, ccData: characters('L2') },
    { type: 2, pts: 2000, ccData: 0x0d00 }, // CR

    { type: 3, pts: 3000, ccData: packetHeader708(0, 3, 1, 4) },
    { type: 2, pts: 3000, ccData: characters('L3') },
    { type: 2, pts: 3000, ccData: 0x0d00 }, // CR

    { type: 3, pts: 4000, ccData: packetHeader708(1, 3, 1, 4) },
    { type: 2, pts: 4000, ccData: characters('L4') },
    { type: 2, pts: 4000, ccData: 0x0d00 }, // CR

    { type: 3, pts: 5000, ccData: packetHeader708(2, 2, 1, 2) },
    { type: 2, pts: 5000, ccData: 0x8aff },

    // Indicate end of last packet
    { type: 3, pts: 6000, ccData: packetHeader708(0, 1, 1, 0) }
  ].forEach(cea708Stream.push, cea708Stream);

  assert.equal(captions.length, 3, 'parsed 3 captions');
  assert.equal(captions[0].text, 'L1\nL2', 'parsed caption 1 correctly');
  assert.equal(captions[1].text, 'L2\nL3', 'parsed caption 2 correctly');
  assert.equal(captions[2].text, 'L3\nL4', 'parsed caption 3 correctly');
});
