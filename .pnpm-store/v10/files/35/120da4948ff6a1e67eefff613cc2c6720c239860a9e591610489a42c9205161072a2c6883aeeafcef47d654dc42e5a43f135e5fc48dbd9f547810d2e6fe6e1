import {JSDOM} from 'jsdom';
import QUnit from 'qunit';
import { parseAttributes } from '../src/parseAttributes';

const document = new JSDOM().window.document;

QUnit.module('parseAttributes');

QUnit.test('simple', function(assert) {
  const el = document.createElement('el');

  el.setAttribute('foo', 1);

  assert.deepEqual(parseAttributes(el), { foo: '1' });
});

QUnit.test('empty', function(assert) {
  const el = document.createElement('el');

  assert.deepEqual(parseAttributes(el), {});
});
