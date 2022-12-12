import { merge, values } from '../src/utils/object';
import { parseDuration } from '../src/utils/time';
import {
  flatten,
  range,
  from,
  findIndexes,
  findIndex,
  includes
} from '../src/utils/list';
import { findChildren, getContent } from '../src/utils/xml';
import {DOMParser} from '@xmldom/xmldom';
import {JSDOM} from 'jsdom';
import QUnit from 'qunit';

const document = new JSDOM().window.document;

QUnit.module('utils');

QUnit.module('merge');
QUnit.test('empty', function(assert) {
  assert.deepEqual(merge({}, { a: 1 }), { a: 1 });
  assert.deepEqual(merge({ a: 1 }, { a: 1 }), { a: 1 });
  assert.deepEqual(merge({ a: 1 }, {}), { a: 1 });
});

QUnit.test('append', function(assert) {
  assert.deepEqual(merge({ a: 1 }, { b: 3 }), { a: 1, b: 3 });
});

QUnit.test('overwrite', function(assert) {
  assert.deepEqual(merge({ a: 1 }, { a: 2 }), { a: 2 });
});

QUnit.test('empty', function(assert) {
  assert.deepEqual(merge({}, {}), {});
  assert.deepEqual(merge({}, 1), {});
  assert.deepEqual(merge(1, {}), {});
});

QUnit.test('Test for checking the merge when multiple segment Information are present', function(assert) {

  const adaptationSetInfo = {

    base: { duration: '10'}
  };

  const representationInfo = {

    base: { duration: '25', indexRange: '230-252'}
  };

  const expected = {

    base: { duration: '25', indexRange: '230-252'}
  };

  assert.deepEqual(
    merge(adaptationSetInfo, representationInfo), expected,
    'Merged SegmentBase info'
  );

});

QUnit.test('Test for checking the merge when segment Information is present at a level and is undefined at another', function(assert) {
  const periodInfo = {
    base: {
      initialization: {
        range: '0-8888'

      }
    }
  };

  const adaptationSetInfo = {

    base: { duration: '10', indexRange: '230-252'}
  };

  const representationInfo = {};

  const expected = {

    base: { duration: '10', indexRange: '230-252', initialization: {range: '0-8888'}}
  };

  assert.deepEqual(
    merge(periodInfo, adaptationSetInfo, representationInfo), expected,
    'Merged SegmentBase info'
  );

});

QUnit.module('values');

QUnit.test('empty', function(assert) {
  assert.deepEqual(values({}), []);
});

QUnit.test('mixed', function(assert) {
  assert.deepEqual(values({ a: 1, b: true, c: 'foo'}), [1, true, 'foo']);
});

QUnit.module('flatten');
QUnit.test('empty', function(assert) {
  assert.deepEqual(flatten([]), []);
});

QUnit.test('one item', function(assert) {
  assert.deepEqual(flatten([[1]]), [1]);
});

QUnit.test('multiple items', function(assert) {
  assert.deepEqual(flatten([[1], [2], [3]]), [1, 2, 3]);
});

QUnit.test('multiple multiple items', function(assert) {
  assert.deepEqual(flatten([[1], [2, 3], [4]]), [1, 2, 3, 4]);
});

QUnit.test('nested nests', function(assert) {
  assert.deepEqual(flatten([[1], [[2]]]), [1, [2]]);
});

QUnit.test('not a list of lists', function(assert) {
  assert.deepEqual(flatten([1, 2]), [1, 2]);
  assert.deepEqual(flatten([[1], 2]), [1, 2]);
});

QUnit.module('parseDuration');
QUnit.test('full date', function(assert) {
  assert.deepEqual(parseDuration('P10Y10M10DT10H10M10.1S'), 342180610.1);
});

QUnit.test('time only', function(assert) {
  assert.deepEqual(parseDuration('PT10H10M10.1S'), 36610.1);
});

QUnit.test('empty', function(assert) {
  assert.deepEqual(parseDuration(''), 0);
});

QUnit.test('invalid', function(assert) {
  assert.deepEqual(parseDuration('foo'), 0);
});

QUnit.module('range');
QUnit.test('simple', function(assert) {
  assert.deepEqual(range(1, 4), [1, 2, 3]);
});

QUnit.test('single number range', function(assert) {
  assert.deepEqual(range(1, 1), []);
});

QUnit.test('negative', function(assert) {
  assert.deepEqual(range(-1, 2), [-1, 0, 1]);
});

QUnit.module('from');

QUnit.test('simple array', function(assert) {
  assert.deepEqual(from([1]), [1]);
});

QUnit.test('empty array', function(assert) {
  assert.deepEqual(from([]), []);
});

QUnit.test('non-array', function(assert) {
  assert.deepEqual(from(1), []);
});

QUnit.test('array-like', function(assert) {
  const fixture = document.createElement('div');

  fixture.innerHTML = '<div></div><div></div>';

  const result = from(fixture.getElementsByTagName('div'));

  assert.ok(result.map);
  assert.deepEqual(result.length, 2);
});

QUnit.module('findIndexes');

QUnit.test('index not found', function(assert) {
  assert.deepEqual(findIndexes([], 'a'), []);
  assert.deepEqual(findIndexes([], ''), []);
  assert.deepEqual(findIndexes([{ a: true}], 'b'), []);
});

QUnit.test('indexes found', function(assert) {
  assert.deepEqual(findIndexes([{ a: true}], 'a'), [0]);
  assert.deepEqual(findIndexes([
    { a: true },
    { b: true },
    { b: true, c: true }
  ], 'b'), [1, 2]);
});

QUnit.module('findIndex');

QUnit.test('match', function(assert) {
  assert.equal(findIndex([2, 'b', 'a'], (el) => el === 'a'), 2, 'returned index');
});

QUnit.test('no match', function(assert) {
  assert.equal(findIndex([], (el) => el === 'a'), -1, 'no match');
});

QUnit.module('includes');

QUnit.test('match', function(assert) {
  assert.ok(includes([2, 'b', 'a'], 'a'), 'match found');
});

QUnit.test('no match', function(assert) {
  assert.notOk(includes([], 'a'), 'no match');
});

QUnit.module('xml', {
  beforeEach() {
    const parser = new DOMParser();
    const xmlString = `
    <fix>
      <test>foo </test>
      <div>bar</div>
      <div>baz</div>
    </fix>`;

    this.fixture = parser.parseFromString(xmlString, 'text/xml').documentElement;
  }
});

QUnit.test('findChildren', function(assert) {
  assert.deepEqual(findChildren(this.fixture, 'test').length, 1, 'single');
  assert.deepEqual(findChildren(this.fixture, 'div').length, 2, 'multiple');
  assert.deepEqual(findChildren(this.fixture, 'el').length, 0, 'none');
});

QUnit.test('getContent', function(assert) {
  const result = findChildren(this.fixture, 'test')[0];

  assert.deepEqual(getContent(result), 'foo', 'gets text and trims');
});
