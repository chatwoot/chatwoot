import QUnit from 'qunit';
import {
  urlTypeToSegment as urlTypeConverter,
  byteRangeToString
} from '../../src/segment/urlType';
import window from 'global/window';

QUnit.module('urlType - urlTypeConverter');

QUnit.test('returns correct object if given baseUrl only', function(assert) {
  assert.deepEqual(urlTypeConverter({ baseUrl: 'http://example.com/' }), {
    resolvedUri: 'http://example.com/',
    uri: ''
  });
});

QUnit.test('returns correct object if given baseUrl and source', function(assert) {
  assert.deepEqual(urlTypeConverter({
    baseUrl: 'http://example.com',
    source: 'init.fmp4'
  }), {
    resolvedUri: 'http://example.com/init.fmp4',
    uri: 'init.fmp4'
  });
});

QUnit.test('returns correct object if given baseUrl, source and range', function(assert) {
  assert.deepEqual(urlTypeConverter({
    baseUrl: 'http://example.com',
    source: 'init.fmp4',
    range: '101-105'
  }), {
    resolvedUri: 'http://example.com/init.fmp4',
    uri: 'init.fmp4',
    byterange: {
      offset: 101,
      length: 5
    }
  });
});

QUnit.test('returns correct object if given baseUrl, source and indexRange', function(assert) {
  assert.deepEqual(urlTypeConverter({
    baseUrl: 'http://example.com',
    source: 'sidx.fmp4',
    indexRange: '101-105'
  }), {
    resolvedUri: 'http://example.com/sidx.fmp4',
    uri: 'sidx.fmp4',
    byterange: {
      offset: 101,
      length: 5
    }
  });
});

QUnit.test('returns correct object if given baseUrl and range', function(assert) {
  assert.deepEqual(urlTypeConverter({
    baseUrl: 'http://example.com/',
    range: '101-105'
  }), {
    resolvedUri: 'http://example.com/',
    uri: '',
    byterange: {
      offset: 101,
      length: 5
    }
  });
});

QUnit.test('returns correct object if given baseUrl and indexRange', function(assert) {
  assert.deepEqual(urlTypeConverter({
    baseUrl: 'http://example.com/',
    indexRange: '101-105'
  }), {
    resolvedUri: 'http://example.com/',
    uri: '',
    byterange: {
      offset: 101,
      length: 5
    }
  });
});

if (window.BigInt) {
  const BigInt = window.BigInt;

  QUnit.test('can use BigInt range', function(assert) {
    const bigNumber = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(10);

    const result = urlTypeConverter({
      baseUrl: 'http://example.com',
      source: 'init.fmp4',
      range: `${bigNumber}-${bigNumber + BigInt(4)}`
    });

    assert.equal(typeof result.byterange.offset, 'bigint', 'is bigint');
    result.byterange.offset = result.byterange.offset.toString();

    assert.deepEqual(result, {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4',
      byterange: {
        offset: bigNumber.toString(),
        length: 5
      }
    });
  });

  QUnit.test('returns number range if bigint not nedeed', function(assert) {
    const bigNumber = BigInt(5);

    const result = urlTypeConverter({
      baseUrl: 'http://example.com',
      source: 'init.fmp4',
      range: `${bigNumber}-${bigNumber + BigInt(4)}`
    });

    assert.deepEqual(result, {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4',
      byterange: {
        offset: 5,
        length: 5
      }
    });
  });
}

QUnit.module('urlType - byteRangeToString');

QUnit.test('returns correct string representing byterange object', function(assert) {
  assert.strictEqual(
    byteRangeToString({
      offset: 0,
      length: 100
    }),
    '0-99'
  );
});

if (window.BigInt) {
  const BigInt = window.BigInt;

  QUnit.test('can handle bigint numbers', function(assert) {
    const offset = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(10);
    const length = BigInt(Number.MAX_SAFE_INTEGER) + BigInt(5);

    assert.strictEqual(
      byteRangeToString({
        offset,
        length
      }),
      `${offset}-${offset + length - BigInt(1)}`
    );
  });
}
