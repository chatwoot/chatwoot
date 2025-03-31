import {LineStream, ParseStream} from '../src';
import QUnit from 'qunit';
import sinon from 'sinon';

QUnit.module('ParseStream', {
  beforeEach() {
    this.lineStream = new LineStream();
    this.parseStream = new ParseStream();
    this.lineStream.pipe(this.parseStream);
  }
});

QUnit.test('parses custom tags', function(assert) {
  const manifest = '#VOD-STARTTIMESTAMP:1501533337573\n';
  let element;

  this.parseStream.addParser({
    expression: /^#VOD-STARTTIMESTAMP/,
    customType: 'startTimestamp'
  });

  this.parseStream.on('data', function(elem) {
    element = elem;
  });

  this.lineStream.push(manifest);
  assert.ok(element, 'element');
  assert.strictEqual(element.type, 'custom', 'the type of the data is custom');
  assert.strictEqual(
    element.customType,
    'startTimestamp',
    'the customType is startTimestamp'
  );
});

QUnit.test('mapper does not conflict with parser', function(assert) {
  const manifest = '#EXAMPLE\n';
  const commentMapper = sinon.spy(line => '#NEW-COMMENT');
  const commentMapper2 = sinon.spy(line => '#SOMETHING-ELSE');
  const dataCallback = sinon.spy();

  this.parseStream.addTagMapper({
    expression: /^#EXAMPLE/,
    map: commentMapper
  });
  this.parseStream.addTagMapper({
    expression: /^#EXAMPLE/,
    map: commentMapper2
  });

  this.parseStream.addParser({
    expression: /^#EXAMPLE/,
    customType: 'test'
  });
  this.parseStream.addParser({
    expression: /^#NEW-COMMENT/,
    customType: 'test2'
  });

  this.parseStream.on('data', dataCallback);
  this.lineStream.push(manifest);

  assert.ok(commentMapper.called);
  assert.ok(commentMapper2.called);
  assert.strictEqual(dataCallback.callCount, 3);

  assert.deepEqual(dataCallback.getCall(0).args[0], {
    data: '#EXAMPLE',
    type: 'custom',
    customType: 'test',
    segment: undefined
  });
  assert.deepEqual(dataCallback.getCall(1).args[0], {
    data: '#NEW-COMMENT',
    type: 'custom',
    customType: 'test2',
    segment: undefined
  });
  assert.deepEqual(dataCallback.getCall(2).args[0], {
    text: 'SOMETHING-ELSE',
    type: 'comment'
  });
});

QUnit.test('maps custom tags', function(assert) {
  const manifest = '#EXAMPLE\n';
  const commentMapper = sinon.spy(line => '#NEW-COMMENT');
  const dataCallback = sinon.spy();

  this.parseStream.addTagMapper({
    expression: /^#EXAMPLE/,
    map: commentMapper
  });

  this.parseStream.on('data', dataCallback);
  this.lineStream.push(manifest);

  assert.ok(commentMapper.called);
  assert.strictEqual(dataCallback.callCount, 2);

  assert.deepEqual(dataCallback.getCall(0).args[0], {
    text: 'EXAMPLE',
    type: 'comment'
  });
  assert.deepEqual(dataCallback.getCall(1).args[0], {
    text: 'NEW-COMMENT',
    type: 'comment'
  });
});

QUnit.test('maps multiple custom tags', function(assert) {
  const manifest = '#VOD-STARTTIMESTAMP:1501533337573\n';
  const commentMapper = sinon.spy(line => '#NEW-COMMENT');
  const pdtMapper = sinon.spy((line) => {
    const match = /#VOD-STARTTIMESTAMP:(\d+)/g.exec(line)[1];
    const ISOdate = new Date(Number(match)).toISOString();

    return `#EXT-X-PROGRAM-DATE-TIME:${ISOdate}`;
  });
  const dataCallback = sinon.spy();

  this.parseStream.addTagMapper({
    expression: /^#VOD-STARTTIMESTAMP/,
    map: commentMapper
  });
  this.parseStream.addTagMapper({
    expression: /^#VOD-STARTTIMESTAMP/,
    map: pdtMapper
  });

  this.parseStream.on('data', dataCallback);
  this.lineStream.push(manifest);

  assert.ok(commentMapper.called);
  assert.ok(pdtMapper.called);
  assert.strictEqual(dataCallback.callCount, 3);

  assert.deepEqual(dataCallback.getCall(0).args[0], {
    text: 'VOD-STARTTIMESTAMP:1501533337573',
    type: 'comment'
  });

  assert.deepEqual(dataCallback.getCall(1).args[0], {
    text: 'NEW-COMMENT',
    type: 'comment'
  });

  const dateTag = dataCallback.getCall(2).args[0];

  assert.strictEqual(dateTag.dateTimeString, '2017-07-31T20:35:37.573Z');
  assert.strictEqual(dateTag.tagType, 'program-date-time');
  assert.strictEqual(dateTag.type, 'tag');
});

QUnit.test('mapper ignores tags', function(assert) {
  const manifest = '#TAG\n';
  const dataCallback = sinon.spy();

  this.parseStream.addTagMapper({
    expression: /^#NO-MATCH/,
    map(line) {
      return '#MAPPED';
    }
  });

  this.parseStream.on('data', dataCallback);
  this.lineStream.push(manifest);

  assert.strictEqual(dataCallback.callCount, 1);
  assert.deepEqual(dataCallback.getCall(0).args[0], {
    text: 'TAG',
    type: 'comment'
  });
});

QUnit.test('parses comment lines', function(assert) {
  const manifest = '# a line that starts with a hash mark without "EXT" is a comment\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'comment', 'the type is comment');
  assert.strictEqual(
    element.text,
    manifest.slice(1, manifest.length - 1),
    'the comment text is parsed'
  );
});
QUnit.test('parses uri lines', function(assert) {
  const manifest = 'any non-blank line that does not start with a hash-mark is a URI\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'uri', 'the type is uri');
  assert.strictEqual(
    element.uri,
    manifest.substring(0, manifest.length - 1),
    'the uri text is parsed'
  );
});
QUnit.test('parses unknown tag types', function(assert) {
  const manifest = '#EXT-X-EXAMPLE-TAG:some,additional,stuff\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the type is tag');
  assert.strictEqual(
    element.data,
    manifest.slice(4, manifest.length - 1),
    'unknown tag data is preserved'
  );
});

// #EXTM3U
QUnit.test('parses #EXTM3U tags', function(assert) {
  const manifest = '#EXTM3U\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'm3u', 'the tag type is m3u');
});

// #EXTINF
QUnit.test('parses minimal #EXTINF tags', function(assert) {
  const manifest = '#EXTINF\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'inf', 'the tag type is inf');
});
QUnit.test('parses #EXTINF tags with durations', function(assert) {
  let manifest = '#EXTINF:15\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'inf', 'the tag type is inf');
  assert.strictEqual(element.duration, 15, 'the duration is parsed');
  assert.ok(!('title' in element), 'no title is parsed');

  manifest = '#EXTINF:21,\n';
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'inf', 'the tag type is inf');
  assert.strictEqual(element.duration, 21, 'the duration is parsed');
  assert.ok(!('title' in element), 'no title is parsed');
});
QUnit.test('parses #EXTINF tags with a duration and title', function(assert) {
  const manifest = '#EXTINF:13,Does anyone really use the title attribute?\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'inf', 'the tag type is inf');
  assert.strictEqual(element.duration, 13, 'the duration is parsed');
  assert.strictEqual(
    element.title,
    manifest.substring(manifest.indexOf(',') + 1, manifest.length - 1),
    'the title is parsed'
  );
});
QUnit.test('parses #EXTINF tags with carriage returns', function(assert) {
  const manifest = '#EXTINF:13,Does anyone really use the title attribute?\r\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'inf', 'the tag type is inf');
  assert.strictEqual(element.duration, 13, 'the duration is parsed');
  assert.strictEqual(
    element.title,
    manifest.substring(manifest.indexOf(',') + 1, manifest.length - 2),
    'the title is parsed'
  );
});

// #EXT-X-TARGETDURATION
QUnit.test('parses minimal #EXT-X-TARGETDURATION tags', function(assert) {
  const manifest = '#EXT-X-TARGETDURATION\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'targetduration', 'the tag type is targetduration');
  assert.ok(!('duration' in element), 'no duration is parsed');
});
QUnit.test('parses #EXT-X-TARGETDURATION with duration', function(assert) {
  const manifest = '#EXT-X-TARGETDURATION:47\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'targetduration', 'the tag type is targetduration');
  assert.strictEqual(element.duration, 47, 'the duration is parsed');
});

// #EXT-X-VERSION
QUnit.test('parses minimal #EXT-X-VERSION tags', function(assert) {
  const manifest = '#EXT-X-VERSION:\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'version', 'the tag type is version');
  assert.ok(!('version' in element), 'no version is present');
});
QUnit.test('parses #EXT-X-VERSION with a version', function(assert) {
  const manifest = '#EXT-X-VERSION:99\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'version', 'the tag type is version');
  assert.strictEqual(element.version, 99, 'the version is parsed');
});

// #EXT-X-MEDIA-SEQUENCE
QUnit.test('parses minimal #EXT-X-MEDIA-SEQUENCE tags', function(assert) {
  const manifest = '#EXT-X-MEDIA-SEQUENCE\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'media-sequence', 'the tag type is media-sequence');
  assert.ok(!('number' in element), 'no number is present');
});
QUnit.test('parses #EXT-X-MEDIA-SEQUENCE with sequence numbers', function(assert) {
  const manifest = '#EXT-X-MEDIA-SEQUENCE:109\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'media-sequence', 'the tag type is media-sequence');
  assert.ok(element.number, 109, 'the number is parsed');
});

// #EXT-X-PLAYLIST-TYPE
QUnit.test('parses minimal #EXT-X-PLAYLIST-TYPE tags', function(assert) {
  const manifest = '#EXT-X-PLAYLIST-TYPE:\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'playlist-type', 'the tag type is playlist-type');
  assert.ok(!('playlistType' in element), 'no playlist type is present');
});
QUnit.test('parses #EXT-X-PLAYLIST-TYPE with mutability info', function(assert) {
  let manifest = '#EXT-X-PLAYLIST-TYPE:EVENT\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'playlist-type', 'the tag type is playlist-type');
  assert.strictEqual(element.playlistType, 'EVENT', 'the playlist type is EVENT');

  manifest = '#EXT-X-PLAYLIST-TYPE:VOD\n';
  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'playlist-type', 'the tag type is playlist-type');
  assert.strictEqual(element.playlistType, 'VOD', 'the playlist type is VOD');

  manifest = '#EXT-X-PLAYLIST-TYPE:nonsense\n';
  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'playlist-type', 'the tag type is playlist-type');
  assert.strictEqual(element.playlistType, 'nonsense', 'the playlist type is parsed');
});

// #EXT-X-BYTERANGE
QUnit.test('parses minimal #EXT-X-BYTERANGE tags', function(assert) {
  const manifest = '#EXT-X-BYTERANGE\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'byterange', 'the tag type is byterange');
  assert.ok(!('length' in element), 'no length is present');
  assert.ok(!('offset' in element), 'no offset is present');
});
QUnit.test('parses #EXT-X-BYTERANGE with length and offset', function(assert) {
  let manifest = '#EXT-X-BYTERANGE:45\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'byterange', 'the tag type is byterange');
  assert.strictEqual(element.length, 45, 'length is parsed');
  assert.ok(!('offset' in element), 'no offset is present');

  manifest = '#EXT-X-BYTERANGE:108@16\n';
  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'byterange', 'the tag type is byterange');
  assert.strictEqual(element.length, 108, 'length is parsed');
  assert.strictEqual(element.offset, 16, 'offset is parsed');
});

// #EXT-X-ALLOW-CACHE
QUnit.test('parses minimal #EXT-X-ALLOW-CACHE tags', function(assert) {
  const manifest = '#EXT-X-ALLOW-CACHE:\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'allow-cache', 'the tag type is allow-cache');
  assert.ok(!('allowed' in element), 'no allowed is present');
});
QUnit.test('parses valid #EXT-X-ALLOW-CACHE tags', function(assert) {
  let manifest = '#EXT-X-ALLOW-CACHE:YES\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'allow-cache', 'the tag type is allow-cache');
  assert.ok(element.allowed, 'allowed is parsed');

  manifest = '#EXT-X-ALLOW-CACHE:NO\n';
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'allow-cache', 'the tag type is allow-cache');
  assert.ok(!element.allowed, 'allowed is parsed');
});
// #EXT-X-MAP
QUnit.test('parses minimal #EXT-X-MAP tags', function(assert) {
  const manifest = '#EXT-X-MAP:URI="init.m4s"\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });

  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'map', 'the tag type is map');
  assert.strictEqual(element.uri, 'init.m4s', 'parsed the uri');
});
QUnit.test('parses #EXT-X-MAP tags with a byterange', function(assert) {
  const manifest = '#EXT-X-MAP:URI="0.m4s", BYTERANGE="1000@23"\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });

  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.uri, '0.m4s', 'parsed the uri');
  assert.strictEqual(
    element.byterange.length,
    1000,
    'parsed the byterange length'
  );
  assert.strictEqual(
    element.byterange.offset,
    23,
    'parsed the byterange offset'
  );
});
QUnit.test('parses #EXT-X-MAP tags with arbitrary attributes', function(assert) {
  const manifest = '#EXT-X-MAP:URI="init.mp4", SOMETHING=YES,BYTERANGE="720@0"\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });

  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.uri, 'init.mp4', 'parsed the uri');
  assert.strictEqual(
    element.byterange.length,
    720,
    'parsed the byterange length'
  );
  assert.strictEqual(
    element.byterange.offset,
    0,
    'parsed the byterange offset'
  );
});
// #EXT-X-STREAM-INF
QUnit.test('parses minimal #EXT-X-STREAM-INF tags', function(assert) {
  const manifest = '#EXT-X-STREAM-INF\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'stream-inf', 'the tag type is stream-inf');
  assert.ok(!('attributes' in element), 'no attributes are present');
});
// #EXT-X-PROGRAM-DATE-TIME
QUnit.test('parses minimal EXT-X-PROGRAM-DATE-TIME tags', function(assert) {
  const manifest = '#EXT-X-PROGRAM-DATE-TIME\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'program-date-time', 'the tag type is date-time');
  assert.ok(!('dateTimeString' in element), 'no dateTime is present');
});
QUnit.test(
  'parses EXT-X-PROGRAM-DATE-TIME tags with valid date-time formats',
  function(assert) {
    let manifest = '#EXT-X-PROGRAM-DATE-TIME:2016-06-22T09:20:16.166-04:00\n';
    let element;

    this.parseStream.on('data', function(elem) {
      element = elem;
    });
    this.lineStream.push(manifest);

    assert.ok(element, 'an event was triggered');
    assert.strictEqual(element.type, 'tag', 'the line type is tag');
    assert.strictEqual(element.tagType, 'program-date-time', 'the tag type is date-time');
    assert.strictEqual(
      element.dateTimeString, '2016-06-22T09:20:16.166-04:00',
      'dateTimeString is parsed'
    );
    assert.deepEqual(
      element.dateTimeObject, new Date('2016-06-22T09:20:16.166-04:00'),
      'dateTimeObject is parsed'
    );

    manifest = '#EXT-X-PROGRAM-DATE-TIME:2016-06-22T09:20:16.16389Z\n';
    this.lineStream.push(manifest);

    assert.ok(element, 'an event was triggered');
    assert.strictEqual(element.type, 'tag', 'the line type is tag');
    assert.strictEqual(element.tagType, 'program-date-time', 'the tag type is date-time');
    assert.strictEqual(
      element.dateTimeString, '2016-06-22T09:20:16.16389Z',
      'dateTimeString is parsed'
    );
    assert.deepEqual(
      element.dateTimeObject, new Date('2016-06-22T09:20:16.16389Z'),
      'dateTimeObject is parsed'
    );
  }
);
QUnit.test('parses #EXT-X-STREAM-INF with common attributes', function(assert) {
  let manifest = '#EXT-X-STREAM-INF:BANDWIDTH=14400\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'stream-inf', 'the tag type is stream-inf');
  assert.strictEqual(element.attributes.BANDWIDTH, 14400, 'bandwidth is parsed');

  manifest = '#EXT-X-STREAM-INF:PROGRAM-ID=7\n';
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'stream-inf', 'the tag type is stream-inf');
  assert.strictEqual(element.attributes['PROGRAM-ID'], 7, 'program-id is parsed');

  manifest = '#EXT-X-STREAM-INF:RESOLUTION=396x224\n';
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'stream-inf', 'the tag type is stream-inf');
  assert.strictEqual(element.attributes.RESOLUTION.width, 396, 'width is parsed');
  assert.strictEqual(element.attributes.RESOLUTION.height, 224, 'heigth is parsed');

  manifest = '#EXT-X-STREAM-INF:CODECS="avc1.4d400d, mp4a.40.2"\n';
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'stream-inf', 'the tag type is stream-inf');
  assert.strictEqual(
    element.attributes.CODECS,
    'avc1.4d400d, mp4a.40.2',
    'codecs are parsed'
  );
});
QUnit.test('parses #EXT-X-STREAM-INF with arbitrary attributes', function(assert) {
  const manifest = '#EXT-X-STREAM-INF:NUMERIC=24,ALPHA=Value,MIXED=123abc\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'stream-inf', 'the tag type is stream-inf');
  assert.strictEqual(element.attributes.NUMERIC, '24', 'numeric attributes are parsed');
  assert.strictEqual(
    element.attributes.ALPHA,
    'Value',
    'alphabetic attributes are parsed'
  );
  assert.strictEqual(element.attributes.MIXED, '123abc', 'mixed attributes are parsed');
});
// #EXT-X-ENDLIST
QUnit.test('parses #EXT-X-ENDLIST tags', function(assert) {
  const manifest = '#EXT-X-ENDLIST\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'endlist', 'the tag type is stream-inf');
});

// #EXT-X-KEY
QUnit.test('parses valid #EXT-X-KEY tags', function(assert) {
  let manifest =
    '#EXT-X-KEY:METHOD=AES-128,URI="https://priv.example.com/key.php?r=52"\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.deepEqual(element, {
    type: 'tag',
    tagType: 'key',
    attributes: {
      METHOD: 'AES-128',
      URI: 'https://priv.example.com/key.php?r=52'
    }
  }, 'parsed a valid key');

  manifest = '#EXT-X-KEY:URI="https://example.com/key#1",METHOD=FutureType-1024\n';
  this.lineStream.push(manifest);
  assert.ok(element, 'an event was triggered');
  assert.deepEqual(element, {
    type: 'tag',
    tagType: 'key',
    attributes: {
      METHOD: 'FutureType-1024',
      URI: 'https://example.com/key#1'
    }
  }, 'parsed the attribute list independent of order');

  manifest = '#EXT-X-KEY:IV=1234567890abcdef1234567890abcdef\n';
  this.lineStream.push(manifest);
  assert.ok(element.attributes.IV, 'detected an IV attribute');
  assert.deepEqual(element.attributes.IV, new Uint32Array([
    0x12345678,
    0x90abcdef,
    0x12345678,
    0x90abcdef
  ]), 'parsed an IV value');
});

QUnit.test('parses minimal #EXT-X-KEY tags', function(assert) {
  const manifest = '#EXT-X-KEY:\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.deepEqual(element, {
    type: 'tag',
    tagType: 'key'
  }, 'parsed a minimal key tag');
});

QUnit.test('parses lightly-broken #EXT-X-KEY tags', function(assert) {
  let manifest = '#EXT-X-KEY:URI=\'https://example.com/single-quote\',METHOD=AES-128\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.strictEqual(
    element.attributes.URI,
    'https://example.com/single-quote',
    'parsed a single-quoted uri'
  );

  element = null;
  manifest = '#EXT-X-KEYURI="https://example.com/key",METHOD=AES-128\n';
  this.lineStream.push(manifest);
  assert.strictEqual(element.tagType, 'key', 'parsed the tag type');
  assert.strictEqual(
    element.attributes.URI,
    'https://example.com/key',
    'inferred a colon after the tag type'
  );

  element = null;
  manifest = '#EXT-X-KEY:  URI =  "https://example.com/key",METHOD=AES-128\n';
  this.lineStream.push(manifest);
  assert.strictEqual(
    element.attributes.URI,
    'https://example.com/key',
    'trims and removes quotes around the URI'
  );
});

QUnit.test('parses prefixed with 0x or 0X #EXT-X-KEY:IV tags', function(assert) {
  let manifest;
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });

  manifest = '#EXT-X-KEY:IV=0x1234567890abcdef1234567890abcdef\n';
  this.lineStream.push(manifest);
  assert.ok(element.attributes.IV, 'detected an IV attribute');
  assert.deepEqual(element.attributes.IV, new Uint32Array([
    0x12345678,
    0x90abcdef,
    0x12345678,
    0x90abcdef
  ]), 'parsed an IV value with 0x');

  manifest = '#EXT-X-KEY:IV=0X1234567890abcdef1234567890abcdef\n';
  this.lineStream.push(manifest);
  assert.ok(element.attributes.IV, 'detected an IV attribute');
  assert.deepEqual(element.attributes.IV, new Uint32Array([
    0x12345678,
    0x90abcdef,
    0x12345678,
    0x90abcdef
  ]), 'parsed an IV value with 0X');
});

// #EXT-X-START
QUnit.test('parses EXT-X-START tags', function(assert) {
  const manifest = '#EXT-X-START:TIME-OFFSET=1.1\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'start', 'the tag type is start');
  assert.strictEqual(element.attributes['TIME-OFFSET'], 1.1, 'parses time offset');
  assert.strictEqual(element.attributes.PRECISE, false, 'precise defaults to false');
});
QUnit.test('parses EXT-X-START PRECISE attribute', function(assert) {
  const manifest = '#EXT-X-START:TIME-OFFSET=1.4,PRECISE=YES\n';
  let element;

  this.parseStream.on('data', function(elem) {
    element = elem;
  });
  this.lineStream.push(manifest);

  assert.ok(element, 'an event was triggered');
  assert.strictEqual(element.type, 'tag', 'the line type is tag');
  assert.strictEqual(element.tagType, 'start', 'the tag type is start');
  assert.strictEqual(element.attributes['TIME-OFFSET'], 1.4, 'parses time offset');
  assert.strictEqual(element.attributes.PRECISE, true, 'parses precise attribute');
});

QUnit.test('ignores empty lines', function(assert) {
  const manifest = '\n';
  let event = false;

  this.parseStream.on('data', function() {
    event = true;
  });
  this.lineStream.push(manifest);

  assert.ok(!event, 'no event is triggered');
});
