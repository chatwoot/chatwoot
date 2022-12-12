import QUnit from 'qunit';
import {detectContainerForBytes, isLikelyFmp4MediaSegment} from '../src/containers.js';
import {stringToBytes, concatTypedArrays, toUint8} from '../src/byte-helpers.js';

const filler = (size) => {
  const view = new Uint8Array(size);

  for (let i = 0; i < size; i++) {
    view[i] = 0;
  }

  return view;
};

const otherMp4Data = concatTypedArrays([0x00, 0x00, 0x00, 0x00], stringToBytes('stypiso'));
const id3Data = Array.prototype.slice.call(concatTypedArrays(
  stringToBytes('ID3'),
  // id3 header is 10 bytes without footer
  // 10th byte is length 0x23 or 35 in decimal
  // so a total length of 45
  [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x23],
  // add in the id3 content
  filler(35)
));

const id3DataWithFooter = Array.prototype.slice.call(concatTypedArrays(
  stringToBytes('ID3'),
  // id3 header is 20 bytes with footer
  // "we have a footer" is the sixth byte
  // 10th byte is length of 0x23 or 35 in decimal
  // so a total length of 55
  [0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x23],
  // add in the id3 content
  filler(45)
));

const testData = {
  // EBML tag + dataSize
  // followed by DocType + dataSize and then actual data for that tag
  'mkv': concatTypedArrays([0x1a, 0x45, 0xdf, 0xa3, 0x99, 0x42, 0x82, 0x88], stringToBytes('matroska')),
  'webm': concatTypedArrays([0x1a, 0x45, 0xdf, 0xa3, 0x99, 0x42, 0x82, 0x88], stringToBytes('webm')),
  'flac': stringToBytes('fLaC'),
  'ogg': stringToBytes('OggS'),
  'aac': toUint8([0xFF, 0xF1]),
  'ac3': toUint8([0x0B, 0x77]),
  'mp3': toUint8([0xFF, 0xFB]),
  '3gp': concatTypedArrays([0x00, 0x00, 0x00, 0x00], stringToBytes('ftyp3g')),
  'mp4': concatTypedArrays([0x00, 0x00, 0x00, 0x00], stringToBytes('ftypiso')),
  'mov': concatTypedArrays([0x00, 0x00, 0x00, 0x00], stringToBytes('ftypqt')),
  'avi': toUint8([0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x41, 0x56, 0x49]),
  'wav': toUint8([0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45]),
  'ts': toUint8([0x47]),
  // seq_parameter_set_rbsp
  'h264': toUint8([0x00, 0x00, 0x00, 0x01, 0x67, 0x42, 0xc0, 0x0d, 0xd9, 0x01, 0xa1, 0xfa, 0x10, 0x00, 0x00, 0x03, 0x20, 0x00, 0x00, 0x95, 0xe0, 0xf1, 0x42, 0xa4, 0x80, 0x00, 0x00, 0x00, 0x01]),
  // video_parameter_set_rbsp
  'h265': toUint8([0x00, 0x00, 0x00, 0x01, 0x40, 0x01, 0x0c, 0x01, 0xff, 0xff, 0x24, 0x08, 0x00, 0x00, 0x00, 0x9c, 0x08, 0x00, 0x00, 0x00, 0x00, 0x78, 0x95, 0x98, 0x09, 0x00, 0x00, 0x00, 0x01])
};

// seq_parameter_set_rbsp
const h265seq = toUint8([
  0x00, 0x00, 0x00, 0x01,
  0x42, 0x01, 0x01, 0x21,
  0x60, 0x00, 0x00, 0x00,
  0x90, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x78, 0xa0,
  0x0d, 0x08, 0x0f, 0x16,
  0x59, 0x59, 0xa4, 0x93,
  0x2b, 0x9a, 0x02, 0x00,
  0x00, 0x00, 0x64, 0x00,
  0x00, 0x09, 0x5e, 0x10,
  0x00, 0x00, 0x00, 0x01
]);

const h264shortnal = Array.prototype.slice.call(testData.h264);

// remove 0x00 from the front
h264shortnal.splice(0, 1);
// remove 0x00 from the back
h264shortnal.splice(h264shortnal.length - 2, 1);

const h265shortnal = Array.prototype.slice.call(testData.h265);

// remove 0x00 from the front
h265shortnal.splice(0, 1);
// remove 0x00 from the back
h265shortnal.splice(h265shortnal.length - 2, 1);

const mp4Variants = {
  'start with moov': concatTypedArrays(filler(4), [0x6D, 0x6F, 0x6F, 0x76]),
  'start with moof': concatTypedArrays(filler(4), [0x6D, 0x6F, 0x6F, 0x66]),
  'start with styp': concatTypedArrays(filler(4), [0x73, 0x74, 0x79, 0x70])
};

QUnit.module('detectContainerForBytes');

QUnit.test('should identify known types', function(assert) {
  Object.keys(testData).forEach(function(key) {
    const data = new Uint8Array(testData[key]);

    assert.equal(detectContainerForBytes(testData[key]), key, `found ${key} with Array`);
    assert.equal(detectContainerForBytes(data.buffer), key, `found ${key} with ArrayBuffer`);
    assert.equal(detectContainerForBytes(data), key, `found ${key} with Uint8Array`);
  });

  Object.keys(mp4Variants).forEach(function(name) {
    const bytes = mp4Variants[name];

    assert.equal(detectContainerForBytes(bytes), 'mp4', `${name} detected as mp4`);
  });

  // mp3/aac/flac/ac3 audio can have id3 data before the
  // signature for the file, so we need to handle that.
  ['mp3', 'aac', 'flac', 'ac3'].forEach(function(type) {
    const dataWithId3 = concatTypedArrays(id3Data, testData[type]);
    const dataWithId3Footer = concatTypedArrays(id3DataWithFooter, testData[type]);
    const recursiveDataWithId3 = concatTypedArrays(
      id3Data,
      id3Data,
      id3Data,
      testData[type]
    );
    const recursiveDataWithId3Footer = concatTypedArrays(
      id3DataWithFooter,
      id3DataWithFooter,
      id3DataWithFooter,
      testData[type]
    );

    const differentId3Sections = concatTypedArrays(
      id3DataWithFooter,
      id3Data,
      id3DataWithFooter,
      id3Data,
      testData[type]
    );

    assert.equal(detectContainerForBytes(dataWithId3), type, `id3 skipped and ${type} detected`);
    assert.equal(detectContainerForBytes(dataWithId3Footer), type, `id3 + footer skipped and ${type} detected`);

    assert.equal(detectContainerForBytes(recursiveDataWithId3), type, `id3 x3 skipped and ${type} detected`);
    assert.equal(detectContainerForBytes(recursiveDataWithId3Footer), type, `id3 + footer x3 skipped and ${type} detected`);
    assert.equal(detectContainerForBytes(differentId3Sections), type, `id3 with/without footer skipped and ${type} detected`);

  });

  const notTs = concatTypedArrays(testData.ts, filler(188));
  const longTs = concatTypedArrays(testData.ts, filler(187), testData.ts);
  const unsyncTs = concatTypedArrays(filler(187), testData.ts, filler(187), testData.ts);
  const badTs = concatTypedArrays(filler(188), testData.ts, filler(187), testData.ts);

  assert.equal(detectContainerForBytes(longTs), 'ts', 'long ts data is detected');
  assert.equal(detectContainerForBytes(unsyncTs), 'ts', 'unsynced ts is detected');
  assert.equal(detectContainerForBytes(badTs), '', 'ts without a sync byte in 188 bytes is not detected');
  assert.equal(detectContainerForBytes(notTs), '', 'ts missing 0x47 at 188 is not ts at all');
  assert.equal(detectContainerForBytes(otherMp4Data), 'mp4', 'fmp4 detected as mp4');
  assert.equal(detectContainerForBytes(new Uint8Array()), '', 'no type');
  assert.equal(detectContainerForBytes(), '', 'no type');

  assert.equal(detectContainerForBytes(h265seq), 'h265', 'h265 with only seq_parameter_set_rbsp, works');
  assert.equal(detectContainerForBytes(h265shortnal), 'h265', 'h265 with short nals works');
  assert.equal(detectContainerForBytes(h264shortnal), 'h264', 'h265 with short nals works');
});

const createBox = function(type) {
  const size = 0x20;

  return concatTypedArrays(
    // size bytes
    [0x00, 0x00, 0x00, size],
    // box identfier styp
    stringToBytes(type),
    // filler data for size minus identfier and size bytes
    filler(size - 8)
  );
};

QUnit.module('isLikelyFmp4MediaSegment');
QUnit.test('works as expected', function(assert) {
  const fmp4Data = concatTypedArrays(
    createBox('styp'),
    createBox('sidx'),
    createBox('moof')
  );

  const mp4Data = concatTypedArrays(
    createBox('ftyp'),
    createBox('sidx'),
    createBox('moov')
  );

  const fmp4Fake = concatTypedArrays(
    createBox('test'),
    createBox('moof'),
    createBox('fooo'),
    createBox('bar')
  );

  assert.ok(isLikelyFmp4MediaSegment(fmp4Data), 'fmp4 is recognized as fmp4');
  assert.ok(isLikelyFmp4MediaSegment(fmp4Fake), 'fmp4 with moof and unknown boxes is still fmp4');
  assert.ok(isLikelyFmp4MediaSegment(createBox('moof')), 'moof alone is recognized as fmp4');
  assert.notOk(isLikelyFmp4MediaSegment(mp4Data), 'mp4 is not recognized');
  assert.notOk(isLikelyFmp4MediaSegment(concatTypedArrays(id3DataWithFooter, testData.mp3)), 'bad data is not recognized');
  assert.notOk(isLikelyFmp4MediaSegment(new Uint8Array()), 'no errors on empty data');
  assert.notOk(isLikelyFmp4MediaSegment(), 'no errors on empty data');
});
