import QUnit from 'qunit';
import formatFiles from 'create-test-data!formats';
import parsingFiles from 'create-test-data!parsing';
import {parseData} from '../src/ebml-helpers.js';
import {doesCodecMatch, codecsFromFile} from './test-helpers.js';

const files = [];

// seperate files into modules by extension
Object.keys(formatFiles).forEach((file) => {
  const extension = file.split('.').pop();

  if (extension === 'webm' || extension === 'mkv') {
    files.push(file);
  }

});

QUnit.module('parseData');

files.forEach((file) => QUnit.test(`${file} can be parsed for tracks and blocks`, function(assert) {
  const {blocks, tracks} = parseData(formatFiles[file]());
  const codecs = codecsFromFile(file);

  assert.equal(tracks.length, Object.keys(codecs).length, 'tracks as expected');

  tracks.forEach(function(track) {
    assert.ok(doesCodecMatch(track.codec, codecs[track.type]), `${track.codec} is ${codecs[track.type]}`);
  });

  assert.ok(blocks.length, `has ${blocks.length} blocks`);
  assert.notOk(blocks.filter((b) => !b.frames.length).length, 'all blocks have frame data');
}));

QUnit.test('xiph and ebml lacing', function(assert) {
  const {blocks} = parseData(parsingFiles['xiph-ebml-lacing.mkv']());

  assert.ok(blocks.length, `has ${blocks.length} blocks`);
  assert.notOk(blocks.filter((b) => !b.frames.length).length, 'all blocks have frame data');
  assert.equal(blocks[1].lacing, 1, 'xiph lacing');
  assert.equal(blocks[2].lacing, 3, 'ebml lacing');
});

QUnit.test('fixed lacing', function(assert) {
  const {blocks} = parseData(parsingFiles['fixed-lacing.mkv']());

  assert.ok(blocks.length, `has ${blocks.length} blocks`);
  assert.notOk(blocks.filter((b) => !b.frames.length).length, 'all blocks have frame data');
  assert.equal(blocks[12].lacing, 2, 'fixed lacing');
});

QUnit.test('live data', function(assert) {
  const {blocks} = parseData(parsingFiles['live.mkv']());

  assert.ok(blocks.length, 6, 'has 6 blocks, even with "infinite" cluster dataSize');
  assert.notOk(blocks.filter((b) => !b.frames.length).length, 'all blocks have frame data');
});
