import { stringToMpdXml } from '../src/stringToMpdXml';
import errors from '../src/errors';
import QUnit from 'qunit';

QUnit.module('stringToMpdXml');

QUnit.test('simple mpd', function(assert) {
  assert.deepEqual(stringToMpdXml('<MPD></MPD>').tagName, 'MPD');
});

QUnit.test('invalid xml', function(assert) {
  assert.throws(() => stringToMpdXml('<test'), new RegExp(errors.DASH_INVALID_XML));
});

QUnit.test('invalid manifest', function(assert) {
  assert.throws(() => stringToMpdXml('<test>'), new RegExp(errors.DASH_INVALID_XML));
});

QUnit.test('empty manifest', function(assert) {
  assert.throws(() => stringToMpdXml(''), new RegExp(errors.DASH_EMPTY_MANIFEST));
});
