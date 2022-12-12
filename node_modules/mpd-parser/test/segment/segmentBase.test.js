import QUnit from 'qunit';
import {
  segmentsFromBase,
  addSidxSegmentsToPlaylist
} from '../../src/segment/segmentBase';
import errors from '../../src/errors';
import window from 'global/window';

QUnit.module('segmentBase - segmentsFromBase');

QUnit.test('sets segment to baseUrl', function(assert) {
  const inputAttributes = {
    baseUrl: 'http://www.example.com/i.fmp4',
    initialization: { sourceURL: 'http://www.example.com/init.fmp4' },
    periodStart: 0,
    type: 'static'
  };

  assert.deepEqual(segmentsFromBase(inputAttributes), [{
    map: {
      resolvedUri: 'http://www.example.com/init.fmp4',
      uri: 'http://www.example.com/init.fmp4'
    },
    resolvedUri: 'http://www.example.com/i.fmp4',
    uri: 'http://www.example.com/i.fmp4',
    presentationTime: 0,
    number: 0
  }]);
});

QUnit.test('sets duration based on sourceDuration', function(assert) {
  const inputAttributes = {
    baseUrl: 'http://www.example.com/i.fmp4',
    initialization: { sourceURL: 'http://www.example.com/init.fmp4' },
    sourceDuration: 10,
    periodStart: 0,
    type: 'static'
  };

  assert.deepEqual(segmentsFromBase(inputAttributes), [{
    duration: 10,
    timeline: 0,
    map: {
      resolvedUri: 'http://www.example.com/init.fmp4',
      uri: 'http://www.example.com/init.fmp4'
    },
    resolvedUri: 'http://www.example.com/i.fmp4',
    uri: 'http://www.example.com/i.fmp4',
    presentationTime: 0,
    number: 0
  }]);
});

// sourceDuration comes from mediaPresentationDuration. The DASH spec defines the type of
// mediaPresentationDuration as xs:duration, which follows ISO 8601. It does not need to
// be adjusted based on timescale.
//
// References:
// https://www.w3.org/TR/xmlschema-2/#duration
// https://en.wikipedia.org/wiki/ISO_8601
QUnit.test('sets duration based on sourceDuration and not @timescale', function(assert) {
  const inputAttributes = {
    baseUrl: 'http://www.example.com/i.fmp4',
    initialization: { sourceURL: 'http://www.example.com/init.fmp4' },
    sourceDuration: 10,
    timescale: 2,
    periodStart: 0,
    type: 'static'
  };

  assert.deepEqual(segmentsFromBase(inputAttributes), [{
    duration: 10,
    timeline: 0,
    map: {
      resolvedUri: 'http://www.example.com/init.fmp4',
      uri: 'http://www.example.com/init.fmp4'
    },
    resolvedUri: 'http://www.example.com/i.fmp4',
    uri: 'http://www.example.com/i.fmp4',
    presentationTime: 0,
    number: 0
  }]);
});

QUnit.test('sets duration based on @duration', function(assert) {
  const inputAttributes = {
    duration: 10,
    sourceDuration: 20,
    baseUrl: 'http://www.example.com/i.fmp4',
    initialization: { sourceURL: 'http://www.example.com/init.fmp4' },
    periodStart: 0,
    type: 'static'
  };

  assert.deepEqual(segmentsFromBase(inputAttributes), [{
    duration: 10,
    timeline: 0,
    map: {
      resolvedUri: 'http://www.example.com/init.fmp4',
      uri: 'http://www.example.com/init.fmp4'
    },
    resolvedUri: 'http://www.example.com/i.fmp4',
    uri: 'http://www.example.com/i.fmp4',
    presentationTime: 0,
    number: 0
  }]);
});

QUnit.test('sets duration based on @duration and @timescale', function(assert) {
  const inputAttributes = {
    duration: 10,
    sourceDuration: 20,
    timescale: 5,
    baseUrl: 'http://www.example.com/i.fmp4',
    initialization: { sourceURL: 'http://www.example.com/init.fmp4' },
    periodStart: 0,
    type: 'static'
  };

  assert.deepEqual(segmentsFromBase(inputAttributes), [{
    duration: 2,
    timeline: 0,
    map: {
      resolvedUri: 'http://www.example.com/init.fmp4',
      uri: 'http://www.example.com/init.fmp4'
    },
    resolvedUri: 'http://www.example.com/i.fmp4',
    uri: 'http://www.example.com/i.fmp4',
    presentationTime: 0,
    number: 0
  }]);
});

QUnit.test('translates ranges in <Initialization> node', function(assert) {
  const inputAttributes = {
    duration: 10,
    sourceDuration: 20,
    timescale: 5,
    baseUrl: 'http://www.example.com/i.fmp4',
    initialization: {
      sourceURL: 'http://www.example.com/init.fmp4',
      range: '121-125'
    },
    periodStart: 0,
    type: 'static'
  };

  assert.deepEqual(segmentsFromBase(inputAttributes), [{
    duration: 2,
    timeline: 0,
    map: {
      resolvedUri: 'http://www.example.com/init.fmp4',
      uri: 'http://www.example.com/init.fmp4',
      byterange: {
        length: 5,
        offset: 121
      }
    },
    resolvedUri: 'http://www.example.com/i.fmp4',
    uri: 'http://www.example.com/i.fmp4',
    presentationTime: 0,
    number: 0
  }]);
});

QUnit.test('errors if no baseUrl exists', function(assert) {
  assert.throws(() => segmentsFromBase({}), new Error(errors.NO_BASE_URL));
});

QUnit.module('segmentBase - addSidxSegmentsToPlaylist');

QUnit.test('generates playlist from sidx references', function(assert) {
  const baseUrl = 'http://www.example.com/i.fmp4';
  const playlist = {
    sidx: {
      map: {
        byterange: {
          offset: 0,
          length: 10
        }
      },
      duration: 10,
      byterange: {
        offset: 9,
        length: 11
      },
      timeline: 0
    },
    segments: [],
    endList: true
  };
  const sidx = {
    timescale: 1,
    firstOffset: 0,
    references: [{
      referenceType: 0,
      referencedSize: 5,
      subsegmentDuration: 2
    }]
  };

  assert.deepEqual(addSidxSegmentsToPlaylist(playlist, sidx, baseUrl).segments, [{
    map: {
      byterange: {
        offset: 0,
        length: 10
      }
    },
    uri: 'http://www.example.com/i.fmp4',
    resolvedUri: 'http://www.example.com/i.fmp4',
    byterange: {
      offset: 20,
      length: 5
    },
    duration: 2,
    timeline: 0,
    presentationTime: 0,
    number: 0
  }]);
});

if (window.BigInt) {
  const BigInt = window.BigInt;

  QUnit.test('generates playlist from sidx references with BigInt', function(assert) {
    const baseUrl = 'http://www.example.com/i.fmp4';
    const playlist = {
      sidx: {
        map: {
          byterange: {
            offset: 0,
            length: 10
          }
        },
        timeline: 0,
        duration: 10,
        byterange: {
          offset: 9,
          length: 11
        }
      },
      segments: []
    };
    const offset = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(10);
    const sidx = {
      timescale: 1,
      firstOffset: offset,
      references: [{
        referenceType: 0,
        referencedSize: 5,
        subsegmentDuration: 2
      }]
    };

    const segments = addSidxSegmentsToPlaylist(playlist, sidx, baseUrl).segments;

    assert.equal(typeof segments[0].byterange.offset, 'bigint', 'bigint offset');
    segments[0].byterange.offset = segments[0].byterange.offset.toString();

    assert.deepEqual(segments, [{
      map: {
        byterange: {
          offset: 0,
          length: 10
        }
      },
      uri: 'http://www.example.com/i.fmp4',
      resolvedUri: 'http://www.example.com/i.fmp4',
      byterange: {
        // sidx byterange offset + length = 20
        offset: (window.BigInt(20) + offset).toString(),
        length: 5
      },
      number: 0,
      presentationTime: 0
    }]);
  });
}
