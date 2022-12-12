import QUnit from 'qunit';
import formatFiles from 'create-test-data!formats';
import {parseFormatForBytes} from '../src/format-parser.js';
import {doesCodecMatch, codecsFromFile} from './test-helpers.js';

const modules = {};

// seperate files into modules by extension
Object.keys(formatFiles).forEach((file) => {
  const extension = file.split('.').pop();

  modules[extension] = modules[extension] || [];
  modules[extension].push(file);
});

QUnit.module('parseFormatForBytes', () => Object.keys(modules).forEach(function(module) {
  const files = modules[module];

  QUnit.module(module);

  files.forEach((file) => QUnit.test(`${file} can be identified`, function(assert) {
    const {codecs, container} = parseFormatForBytes(formatFiles[file]());
    const expectedCodecs = codecsFromFile(file);

    assert.equal(container, module, module);
    Object.keys(expectedCodecs).forEach(function(type) {
      const expectedCodec = expectedCodecs[type];
      const codec = codecs[type];

      assert.ok(doesCodecMatch(codec, expectedCodec), `${codec} is ${expectedCodec}`);
    });
  }));
}));
