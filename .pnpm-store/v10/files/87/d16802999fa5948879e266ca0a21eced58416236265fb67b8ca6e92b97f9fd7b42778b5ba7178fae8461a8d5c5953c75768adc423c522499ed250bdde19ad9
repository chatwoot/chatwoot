import { parse, VERSION } from '../src';
import QUnit from 'qunit';

QUnit.dump.maxDepth = Infinity;

// manifests
import vttCodecsTemplate from './manifests/vtt_codecs.mpd';
import maatVttSegmentTemplate from './manifests/maat_vtt_segmentTemplate.mpd';
import segmentBaseTemplate from './manifests/segmentBase.mpd';
import segmentListTemplate from './manifests/segmentList.mpd';
import cc608CaptionsTemplate from './manifests/608-captions.mpd';
import cc708CaptionsTemplate from './manifests/708-captions.mpd';
import locationTemplate from './manifests/location.mpd';
import locationsTemplate from './manifests/locations.mpd';
import multiperiod from './manifests/multiperiod.mpd';
import webmsegments from './manifests/webmsegments.mpd';
import multiperiodSegmentTemplate from './manifests/multiperiod-segment-template.mpd';
import multiperiodSegmentList from './manifests/multiperiod-segment-list.mpd';
import multiperiodDynamic from './manifests/multiperiod-dynamic.mpd';
import audioOnly from './manifests/audio-only.mpd';
import multiperiodStartnumber from './manifests/multiperiod-startnumber.mpd';
import multiperiodStartnumberRemovedPeriods from
  './manifests/multiperiod-startnumber-removed-periods.mpd';
import {
  parsedManifest as maatVttSegmentTemplateManifest
} from './manifests/maat_vtt_segmentTemplate.js';
import {
  parsedManifest as segmentBaseManifest
} from './manifests/segmentBase.js';
import {
  parsedManifest as segmentListManifest
} from './manifests/segmentList.js';
import {
  parsedManifest as cc608CaptionsManifest
} from './manifests/608-captions.js';
import {
  parsedManifest as cc708CaptionsManifest
} from './manifests/708-captions.js';
import {
  parsedManifest as multiperiodManifest
} from './manifests/multiperiod.js';
import {
  parsedManifest as webmsegmentsManifest
} from './manifests/webmsegments.js';
import {
  parsedManifest as multiperiodSegmentTemplateManifest
} from './manifests/multiperiod-segment-template.js';
import {
  parsedManifest as multiperiodSegmentListManifest
} from './manifests/multiperiod-segment-list.js';
import {
  parsedManifest as multiperiodDynamicManifest
} from './manifests/multiperiod-dynamic.js';
import {
  parsedManifest as locationManifest
} from './manifests/location.js';
import {
  parsedManifest as locationsManifest
} from './manifests/locations.js';

import {
  parsedManifest as vttCodecsManifest
} from './manifests/vtt_codecs.js';

import {
  parsedManifest as audioOnlyManifest
} from './manifests/audio-only.js';
import {
  parsedManifest as multiperiodStartnumberManifest
} from './manifests/multiperiod-startnumber.js';
import {
  parsedManifest as multiperiodStartnumberRemovedPeriodsManifest
} from './manifests/multiperiod-startnumber-removed-periods.js';

QUnit.module('mpd-parser');

QUnit.test('has VERSION', function(assert) {
  assert.ok(VERSION);
});

QUnit.test('has parse', function(assert) {
  assert.ok(parse);
});

[{
  name: 'maat_vtt_segmentTemplate',
  input: maatVttSegmentTemplate,
  expected: maatVttSegmentTemplateManifest
}, {
  name: 'segmentBase',
  input: segmentBaseTemplate,
  expected: segmentBaseManifest
}, {
  name: 'segmentList',
  input: segmentListTemplate,
  expected: segmentListManifest
}, {
  name: '608-captions',
  input: cc608CaptionsTemplate,
  expected: cc608CaptionsManifest
}, {
  name: '708-captions',
  input: cc708CaptionsTemplate,
  expected: cc708CaptionsManifest
}, {
  name: 'multiperiod',
  input: multiperiod,
  expected: multiperiodManifest
}, {
  name: 'webmsegments',
  input: webmsegments,
  expected: webmsegmentsManifest
}, {
  name: 'multiperiod_segment_template',
  input: multiperiodSegmentTemplate,
  expected: multiperiodSegmentTemplateManifest
}, {
  name: 'multiperiod_segment_list',
  input: multiperiodSegmentList,
  expected: multiperiodSegmentListManifest
}, {
  name: 'multiperiod_dynamic',
  input: multiperiodDynamic,
  expected: multiperiodDynamicManifest
}, {
  name: 'location',
  input: locationTemplate,
  expected: locationManifest
}, {
  name: 'locations',
  input: locationsTemplate,
  expected: locationsManifest
}, {
  name: 'vtt_codecs',
  input: vttCodecsTemplate,
  expected: vttCodecsManifest
}, {
  name: 'audio-only',
  input: audioOnly,
  expected: audioOnlyManifest
}, {
  name: 'multiperiod_startnumber',
  input: multiperiodStartnumber,
  expected: multiperiodStartnumberManifest
}].forEach(({ name, input, expected }) => {
  QUnit.test(`${name} test manifest`, function(assert) {
    const actual = parse(input);

    assert.deepEqual(actual, expected);
  });
});

// this test is handled separately as a `previousManifest` needs to be parsed and provided
QUnit.test('multiperiod_startnumber_removed_periods test manifest', function(assert) {
  const previousManifest = parse(multiperiodStartnumber);
  const actual = parse(multiperiodStartnumberRemovedPeriods, { previousManifest });

  assert.deepEqual(actual, multiperiodStartnumberRemovedPeriodsManifest);
});
