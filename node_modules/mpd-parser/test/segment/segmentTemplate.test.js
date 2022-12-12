import QUnit from 'qunit';
import {
  constructTemplateUrl,
  parseTemplateInfo,
  segmentsFromTemplate
} from '../../src/segment/segmentTemplate';

QUnit.module('segmentTemplate - constructTemplateUrl');

QUnit.test('does not change url with no identifiers', function(assert) {
  const url = 'path/to/segment.mp4';

  assert.equal(constructTemplateUrl(url, {}), url, 'no change');
});

QUnit.test('replaces each identifier individually', function(assert) {
  const values = {
    RepresentationID: 'Rep1',
    Bandwidth: 1000,
    Number: 2,
    Time: 2000
  };

  const cases = [
    {
      url: '/$RepresentationID$/segment.mp4',
      expected: '/Rep1/segment.mp4'
    },
    {
      url: '/$Bandwidth$/segment.mp4',
      expected: '/1000/segment.mp4'
    },
    {
      url: '/$Number$/segment.mp4',
      expected: '/2/segment.mp4'
    },
    {
      url: '/$Time$/segment.mp4',
      expected: '/2000/segment.mp4'
    },
    {
      url: '/$$/segment.mp4',
      expected: '/$/segment.mp4'
    }
  ];

  cases.forEach(test => {
    assert.equal(constructTemplateUrl(test.url, values), test.expected, `constructs ${test.url}`);
  });
});

QUnit.test('replaces multiple identifiers in url', function(assert) {
  assert.equal(
    constructTemplateUrl(
      '$$$Time$$$$$/$RepresentationID$/$Bandwidth$/$Number$-$Time$-segment-$Number$.mp4',
      {
        RepresentationID: 'Rep1',
        Bandwidth: 1000,
        Number: 2,
        Time: 2000
      }
    ),
    '$2000$$/Rep1/1000/2-2000-segment-2.mp4',
    'correctly replaces multiple identifiers in single url'
  );
});

QUnit.test('does not replace unknown identifiers', function(assert) {
  assert.equal(
    constructTemplateUrl(
      '/$UNKNOWN$/$RepresentationID$/$UNKOWN2$/$Number$.mp4',
      {
        RepresentationID: 'Rep1',
        Number: 1
      }
    ),
    '/$UNKNOWN$/Rep1/$UNKOWN2$/1.mp4',
    'ignores unknown identifiers'
  );
});

QUnit.test('honors padding format tag', function(assert) {
  assert.equal(
    constructTemplateUrl(
      '/$Number%03d$/segment.mp4',
      { Number: 7 }
    ),
    '/007/segment.mp4',
    'correctly adds padding when format tag present'
  );
});

QUnit.test('does not add padding when value is longer than width', function(assert) {
  assert.equal(
    constructTemplateUrl(
      '/$Bandwidth%06d$/segment.mp4',
      { Bandwidth: 999999999 }
    ),
    '/999999999/segment.mp4',
    'no padding when value longer than format width'
  );
});

QUnit.test('does not use padding format tag for $RepresentationID$', function(assert) {
  assert.equal(
    constructTemplateUrl(
      '/$RepresentationID%09d$/$Number%03d$/segment.mp4',
      { RepresentationID: 'Rep1', Number: 7 }
    ),
    '/Rep1/007/segment.mp4',
    'ignores format tag for $RepresentationID$'
  );
});

QUnit.module('segmentTemplate - parseTemplateInfo');

QUnit.test(
  'one media segment when no @duration attribute or SegmentTimeline element',
  function(assert) {
    const attributes = {
      startNumber: 3,
      timescale: 1000,
      sourceDuration: 42,
      periodIndex: 1,
      type: 'static',
      periodStart: 0
    };

    assert.deepEqual(
      parseTemplateInfo(attributes, void 0),
      [ { number: 3, duration: 42, time: 0, timeline: 0 }],
      'creates segment list of one media segment when no @duration attribute or timeline'
    );
  }
);

QUnit.test('uses @duration attribute when present', function(assert) {
  const attributes = {
    startNumber: 0,
    timescale: 1000,
    sourceDuration: 16,
    duration: 6000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };

  assert.deepEqual(
    parseTemplateInfo(attributes, []),
    [
      {
        number: 0,
        duration: 6,
        timeline: 0,
        time: 0
      },
      {
        number: 1,
        duration: 6,
        timeline: 0,
        time: 6000
      },
      {
        number: 2,
        duration: 4,
        timeline: 0,
        time: 12000
      }
    ],
    'correctly parses segment durations and start times with @duration attribute'
  );
});

QUnit.test('parseByDuration allows non zero startNumber', function(assert) {
  const attributes = {
    startNumber: 101,
    timescale: 1000,
    sourceDuration: 16,
    duration: 6000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };

  assert.deepEqual(
    parseTemplateInfo(attributes, []),
    [
      {
        number: 101,
        duration: 6,
        timeline: 0,
        time: 0
      },
      {
        number: 102,
        duration: 6,
        timeline: 0,
        time: 6000
      },
      {
        number: 103,
        duration: 4,
        timeline: 0,
        time: 12000
      }
    ],
    'allows non zero startNumber'
  );
});

QUnit.test('parseByDuration defaults 1 for startNumber and timescale', function(assert) {
  const attributes = {
    sourceDuration: 11,
    duration: '4',
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };

  assert.deepEqual(
    parseTemplateInfo(attributes, []),
    [
      {
        number: 1,
        duration: 4,
        timeline: 0,
        time: 0
      },
      {
        number: 2,
        duration: 4,
        timeline: 0,
        time: 4
      },
      {
        number: 3,
        duration: 3,
        timeline: 0,
        time: 8
      }
    ],
    'uses default startNumber and timescale value of 1'
  );
});

QUnit.test('parseByDuration uses endNumber and has correct duration', function(assert) {
  const attributes = {
    sourceDuration: 11,
    duration: '4',
    periodIndex: 1,
    endNumber: '2',
    type: 'static',
    periodStart: 0
  };

  assert.deepEqual(
    parseTemplateInfo(attributes, []),
    [
      {
        number: 1,
        duration: 4,
        timeline: 0,
        time: 0
      },
      {
        number: 2,
        duration: 7,
        timeline: 0,
        time: 4
      }
    ],
    'uses default startNumber and timescale value of 1'
  );
});

QUnit.test('uses SegmentTimeline info when no @duration attribute', function(assert) {
  const attributes = {
    startNumber: 0,
    sourceDuration: 16,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 0,
      d: 6000
    },
    {
      d: 2000
    },
    {
      d: 3000
    },
    {
      d: 5000
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 0,
        duration: 6,
        time: 0,
        timeline: 0
      },
      {
        number: 1,
        duration: 2,
        time: 6000,
        timeline: 0
      },
      {
        number: 2,
        duration: 3,
        time: 8000,
        timeline: 0
      },
      {
        number: 3,
        duration: 5,
        time: 11000,
        timeline: 0
      }
    ],
    'correctly calculates segment durations and start times with SegmentTimeline'
  );
});

QUnit.test('parseByTimeline allows non zero startNumber', function(assert) {
  const attributes = {
    startNumber: 101,
    sourceDuration: 16,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 0,
      d: 6000
    },
    {
      d: 2000
    },
    {
      d: 3000
    },
    {
      d: 5000
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 101,
        duration: 6,
        time: 0,
        timeline: 0
      },
      {
        number: 102,
        duration: 2,
        time: 6000,
        timeline: 0
      },
      {
        number: 103,
        duration: 3,
        time: 8000,
        timeline: 0
      },
      {
        number: 104,
        duration: 5,
        time: 11000,
        timeline: 0
      }
    ],
    'allows non zero startNumber'
  );
});

QUnit.test('parseByTimeline defaults 1 for startNumber and timescale', function(assert) {
  const attributes = {
    sourceDuration: 11,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 0,
      d: 4
    },
    {
      d: 2
    },
    {
      d: 3
    },
    {
      d: 2
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 1,
        duration: 4,
        time: 0,
        timeline: 0
      },
      {
        number: 2,
        duration: 2,
        time: 4,
        timeline: 0
      },
      {
        number: 3,
        duration: 3,
        time: 6,
        timeline: 0
      },
      {
        number: 4,
        duration: 2,
        time: 9,
        timeline: 0
      }
    ],
    'defaults to 1 for startNumber and timescale'
  );
});

QUnit.test('defaults SegmentTimeline.S@t to 0 for first segment', function(assert) {
  const attributes = {
    startNumber: 0,
    sourceDuration: 16,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      d: 6000
    },
    {
      d: 2000
    },
    {
      d: 3000
    },
    {
      d: 5000
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 0,
        duration: 6,
        time: 0,
        timeline: 0
      },
      {
        number: 1,
        duration: 2,
        time: 6000,
        timeline: 0
      },
      {
        number: 2,
        duration: 3,
        time: 8000,
        timeline: 0
      },
      {
        number: 3,
        duration: 5,
        time: 11000,
        timeline: 0
      }
    ],
    'uses default value of 0'
  );
});

QUnit.test('allows non zero starting SegmentTimeline.S@t value', function(assert) {
  const attributes = {
    startNumber: 0,
    sourceDuration: 16,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 42000,
      d: 6000
    },
    {
      d: 2000
    },
    {
      d: 3000
    },
    {
      d: 5000
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 0,
        duration: 6,
        time: 42000,
        timeline: 0
      },
      {
        number: 1,
        duration: 2,
        time: 48000,
        timeline: 0
      },
      {
        number: 2,
        duration: 3,
        time: 50000,
        timeline: 0
      },
      {
        number: 3,
        duration: 5,
        time: 53000,
        timeline: 0
      }
    ],
    'allows non zero SegmentTimeline.S@t start value'
  );
});

QUnit.test('honors @r repeat attribute for SegmentTimeline.S', function(assert) {
  const attributes = {
    startNumber: 0,
    sourceDuration: 16,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 0,
      d: 6000
    },
    {
      d: 1000,
      r: 3
    },
    {
      d: 5000
    },
    {
      d: 1000
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 0,
        duration: 6,
        time: 0,
        timeline: 0
      },
      {
        number: 1,
        duration: 1,
        time: 6000,
        timeline: 0
      },
      {
        number: 2,
        duration: 1,
        time: 7000,
        timeline: 0
      },
      {
        number: 3,
        duration: 1,
        time: 8000,
        timeline: 0
      },
      {
        number: 4,
        duration: 1,
        time: 9000,
        timeline: 0
      },
      {
        number: 5,
        duration: 5,
        time: 10000,
        timeline: 0
      },
      {
        number: 6,
        duration: 1,
        time: 15000,
        timeline: 0
      }
    ],
    'correctly uses @r repeat attribute'
  );
});

QUnit.test('correctly handles negative @r repeat value', function(assert) {
  const attributes = {
    startNumber: 0,
    sourceDuration: 16,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 0,
      d: 6000
    },
    {
      d: 1000,
      r: -1
    },
    {
      t: 10000,
      d: 5000
    },
    {
      d: 1000
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 0,
        duration: 6,
        time: 0,
        timeline: 0
      },
      {
        number: 1,
        duration: 1,
        time: 6000,
        timeline: 0
      },
      {
        number: 2,
        duration: 1,
        time: 7000,
        timeline: 0
      },
      {
        number: 3,
        duration: 1,
        time: 8000,
        timeline: 0
      },
      {
        number: 4,
        duration: 1,
        time: 9000,
        timeline: 0
      },
      {
        number: 5,
        duration: 5,
        time: 10000,
        timeline: 0
      },
      {
        number: 6,
        duration: 1,
        time: 15000,
        timeline: 0
      }
    ],
    'correctly uses negative @r repeat attribute'
  );
});

QUnit.test('correctly handles negative @r repeat value for last S', function(assert) {
  const attributes = {
    startNumber: 0,
    sourceDuration: 15,
    timescale: 1000,
    periodIndex: 1,
    type: 'static',
    periodStart: 0
  };
  const segmentTimeline = [
    {
      t: 0,
      d: 6000
    },
    {
      d: 3000,
      r: -1
    }
  ];

  assert.deepEqual(
    parseTemplateInfo(attributes, segmentTimeline),
    [
      {
        number: 0,
        duration: 6,
        time: 0,
        timeline: 0
      },
      {
        number: 1,
        duration: 3,
        time: 6000,
        timeline: 0
      },
      {
        number: 2,
        duration: 3,
        time: 9000,
        timeline: 0
      },
      {
        number: 3,
        duration: 3,
        time: 12000,
        timeline: 0
      }
    ],
    'correctly uses negative @r repeat attribute for last S'
  );
});

QUnit.skip(
  'detects discontinuity when @t time is greater than expected start time',
  function(assert) {

  }
);

QUnit.module('segmentTemplate - type ="dynamic"');

QUnit.test('correctly handles duration', function(assert) {
  const basicAttributes = {
    baseUrl: 'http://www.example.com/',
    type: 'dynamic',
    media: 'n-$Number$.m4s',
    minimumUpdatePeriod: 0,
    timescale: 1,
    NOW: 10000,
    clientOffset: 0,
    availabilityStartTime: 0,
    startNumber: 1,
    duration: 2,
    periodIndex: 1,
    periodStart: 0
  };

  assert.deepEqual(
    segmentsFromTemplate(basicAttributes, []),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 6
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 5,
      resolvedUri: 'http://www.example.com/n-5.m4s',
      timeline: 0,
      uri: 'n-5.m4s',
      presentationTime: 8
    }],
    'segments correctly with basic settings'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign({}, basicAttributes, { startNumber: 10 }), []),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 10,
      resolvedUri: 'http://www.example.com/n-10.m4s',
      timeline: 0,
      uri: 'n-10.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 11,
      resolvedUri: 'http://www.example.com/n-11.m4s',
      timeline: 0,
      uri: 'n-11.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 12,
      resolvedUri: 'http://www.example.com/n-12.m4s',
      timeline: 0,
      uri: 'n-12.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 13,
      resolvedUri: 'http://www.example.com/n-13.m4s',
      timeline: 0,
      uri: 'n-13.m4s',
      presentationTime: 6
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 14,
      resolvedUri: 'http://www.example.com/n-14.m4s',
      timeline: 0,
      uri: 'n-14.m4s',
      presentationTime: 8
    }],
    'segments adjusted correctly based on @startNumber'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign(
      {}, basicAttributes,
      { availabilityStartTime: 4 }
    ), []),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 4
    }],
    'segments correct with @availabilityStartTime set'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign(
      {}, basicAttributes,
      { availabilityStartTime: 2, periodStart: 4 }
    ), []),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 4,
      uri: 'n-1.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 4,
      uri: 'n-2.m4s',
      presentationTime: 6
    }],
    'segments correct with @availabilityStartTime and @start set'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign(
      {}, basicAttributes,
      { timeShiftBufferDepth: 4 }, []
    )),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 6
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 5,
      resolvedUri: 'http://www.example.com/n-5.m4s',
      timeline: 0,
      uri: 'n-5.m4s',
      presentationTime: 8
    }],
    'segments correct with @timeShiftBufferDepth set'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign(
      {}, basicAttributes,
      { clientOffset: -2000 }, []
    )),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 6
    }],
    'segments correct with given clientOffset'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign(
      {}, basicAttributes,
      { endNumber: '4' }, []
    )),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 6
    }],
    'segments correct with endNumber'
  );
});

QUnit.test('correctly handles duration with segmentTimeline', function(assert) {
  const basicAttributes = {
    baseUrl: 'http://www.example.com/',
    type: 'dynamic',
    media: 'n-$Number$.m4s',
    minimumUpdatePeriod: 2,
    timescale: 1,
    NOW: 8000,
    clientOffset: 0,
    availabilityStartTime: 0,
    startNumber: 1,
    periodIndex: 1,
    periodStart: 0
  };

  const segmentTimeline = [
    {
      t: 0,
      d: 2,
      r: 1
    },
    {
      d: 2,
      r: -1
    }
  ];

  assert.deepEqual(
    segmentsFromTemplate(basicAttributes, segmentTimeline),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 6
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 5,
      resolvedUri: 'http://www.example.com/n-5.m4s',
      timeline: 0,
      uri: 'n-5.m4s',
      presentationTime: 8
    }],
    'segments should fill until current time when r = -1 and @minimumUpdatePeriod > 0'
  );

  assert.deepEqual(
    segmentsFromTemplate(Object.assign({}, basicAttributes, {clientOffset: -2000}), segmentTimeline),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 0
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 6
    }],
    'segments should fill correctly when taking client offset into account'
  );

  const segmentTimelineShifted = [
    {
      t: 2,
      d: 2,
      r: 1
    },
    {
      d: 2,
      r: -1
    }
  ];

  assert.deepEqual(
    segmentsFromTemplate(basicAttributes, segmentTimelineShifted),
    [{
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 2
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 4
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 6
    }, {
      duration: 2,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 8
    }],
    'segments take into account different time value for first segment'
  );

  assert.deepEqual(
    segmentsFromTemplate(
      Object.assign({}, basicAttributes, {timescale: 2 }),
      segmentTimelineShifted
    ),
    [{
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 1,
      resolvedUri: 'http://www.example.com/n-1.m4s',
      timeline: 0,
      uri: 'n-1.m4s',
      presentationTime: 1
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 2,
      resolvedUri: 'http://www.example.com/n-2.m4s',
      timeline: 0,
      uri: 'n-2.m4s',
      presentationTime: 2
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 3,
      resolvedUri: 'http://www.example.com/n-3.m4s',
      timeline: 0,
      uri: 'n-3.m4s',
      presentationTime: 3
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 4,
      resolvedUri: 'http://www.example.com/n-4.m4s',
      timeline: 0,
      uri: 'n-4.m4s',
      presentationTime: 4
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 5,
      resolvedUri: 'http://www.example.com/n-5.m4s',
      timeline: 0,
      uri: 'n-5.m4s',
      presentationTime: 5
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 6,
      resolvedUri: 'http://www.example.com/n-6.m4s',
      timeline: 0,
      uri: 'n-6.m4s',
      presentationTime: 6
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 7,
      resolvedUri: 'http://www.example.com/n-7.m4s',
      timeline: 0,
      uri: 'n-7.m4s',
      presentationTime: 7
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 8,
      resolvedUri: 'http://www.example.com/n-8.m4s',
      timeline: 0,
      uri: 'n-8.m4s',
      presentationTime: 8
    }, {
      duration: 1,
      map: {
        resolvedUri: 'http://www.example.com/',
        uri: ''
      },
      number: 9,
      resolvedUri: 'http://www.example.com/n-9.m4s',
      timeline: 0,
      uri: 'n-9.m4s',
      presentationTime: 9
    }],
    'segments take into account different time value for first segment with timescale'
  );
});

QUnit.module('segmentTemplate - segmentsFromTemplate');

QUnit.test('constructs simple segment list and resolves uris', function(assert) {
  const attributes = {
    startNumber: 0,
    duration: 6000,
    sourceDuration: 16,
    timescale: 1000,
    bandwidth: 100,
    id: 'Rep1',
    initialization: {
      sourceURL: '$RepresentationID$/$Bandwidth$/init.mp4'
    },
    media: '$RepresentationID$/$Bandwidth$/$Number%03d$-$Time%05d$.mp4',
    periodIndex: 1,
    baseUrl: 'https://example.com/',
    type: 'static',
    periodStart: 0
  };
  const segments = [
    {
      duration: 6,
      map: {
        resolvedUri: 'https://example.com/Rep1/100/init.mp4',
        uri: 'Rep1/100/init.mp4'
      },
      resolvedUri: 'https://example.com/Rep1/100/000-00000.mp4',
      timeline: 0,
      uri: 'Rep1/100/000-00000.mp4',
      number: 0,
      presentationTime: 0
    },
    {
      duration: 6,
      map: {
        resolvedUri: 'https://example.com/Rep1/100/init.mp4',
        uri: 'Rep1/100/init.mp4'
      },
      resolvedUri: 'https://example.com/Rep1/100/001-06000.mp4',
      timeline: 0,
      uri: 'Rep1/100/001-06000.mp4',
      number: 1,
      presentationTime: 6
    },
    {
      duration: 4,
      map: {
        resolvedUri: 'https://example.com/Rep1/100/init.mp4',
        uri: 'Rep1/100/init.mp4'
      },
      resolvedUri: 'https://example.com/Rep1/100/002-12000.mp4',
      timeline: 0,
      uri: 'Rep1/100/002-12000.mp4',
      number: 2,
      presentationTime: 12
    }
  ];

  assert.deepEqual(
    segmentsFromTemplate(attributes, void 0), segments,
    'creates segments from template'
  );
});

QUnit.test('constructs simple segment list and with <Initialization> node', function(assert) {
  const attributes = {
    startNumber: 0,
    duration: 6000,
    sourceDuration: 16,
    timescale: 1000,
    bandwidth: 100,
    id: 'Rep1',
    initialization: {
      sourceURL: 'init.mp4',
      range: '121-125'
    },
    media: '$RepresentationID$/$Bandwidth$/$Number%03d$-$Time%05d$.mp4',
    periodIndex: 1,
    baseUrl: 'https://example.com/',
    type: 'static',
    periodStart: 0
  };
  const segments = [
    {
      duration: 6,
      map: {
        resolvedUri: 'https://example.com/init.mp4',
        uri: 'init.mp4',
        byterange: {
          length: 5,
          offset: 121
        }
      },
      resolvedUri: 'https://example.com/Rep1/100/000-00000.mp4',
      timeline: 0,
      uri: 'Rep1/100/000-00000.mp4',
      number: 0,
      presentationTime: 0
    },
    {
      duration: 6,
      map: {
        resolvedUri: 'https://example.com/init.mp4',
        uri: 'init.mp4',
        byterange: {
          length: 5,
          offset: 121
        }
      },
      resolvedUri: 'https://example.com/Rep1/100/001-06000.mp4',
      timeline: 0,
      uri: 'Rep1/100/001-06000.mp4',
      number: 1,
      presentationTime: 6
    },
    {
      duration: 4,
      map: {
        resolvedUri: 'https://example.com/init.mp4',
        uri: 'init.mp4',
        byterange: {
          length: 5,
          offset: 121
        }
      },
      resolvedUri: 'https://example.com/Rep1/100/002-12000.mp4',
      timeline: 0,
      uri: 'Rep1/100/002-12000.mp4',
      number: 2,
      presentationTime: 12
    }
  ];

  assert.deepEqual(
    segmentsFromTemplate(attributes, void 0), segments,
    'creates segments from template'
  );
});

QUnit.test('multiperiod uses periodDuration when available', function(assert) {
  const attributes = {
    startNumber: 0,
    duration: 6000,
    sourceDuration: 12,
    timescale: 1000,
    bandwidth: 100,
    id: 'Rep1',
    initialization: {
      sourceURL: '$RepresentationID$/$Bandwidth$/init.mp4'
    },
    media: '$RepresentationID$/$Bandwidth$/$Number%03d$-$Time%05d$.mp4',
    periodIndex: 1,
    // 6 second period should mean a single 6 second segment
    periodDuration: 6,
    baseUrl: 'https://example.com/',
    type: 'static',
    periodStart: 0
  };
  const segments = [
    {
      duration: 6,
      map: {
        resolvedUri: 'https://example.com/Rep1/100/init.mp4',
        uri: 'Rep1/100/init.mp4'
      },
      resolvedUri: 'https://example.com/Rep1/100/000-00000.mp4',
      timeline: 0,
      uri: 'Rep1/100/000-00000.mp4',
      number: 0,
      presentationTime: 0
    }
  ];

  assert.deepEqual(
    segmentsFromTemplate(attributes, void 0), segments,
    'creates segments from template'
  );
});
