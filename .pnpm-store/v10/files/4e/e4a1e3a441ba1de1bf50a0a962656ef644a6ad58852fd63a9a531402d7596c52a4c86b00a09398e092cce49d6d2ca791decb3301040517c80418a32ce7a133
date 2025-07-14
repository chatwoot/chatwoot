import QUnit from 'qunit';
import {
  segmentsFromList
} from '../../src/segment/segmentList';
import errors from '../../src/errors';

QUnit.module('segmentList - segmentsFromList');

QUnit.test('uses segmentTimeline to set segments', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4'
    }, {
      media: '2.fmp4'
    }, {
      media: '3.fmp4'
    }, {
      media: '4.fmp4'
    }, {
      media: '5.fmp4'
    }],
    initialization: { sourceURL: 'init.fmp4' },
    periodIndex: 0,
    periodStart: 0,
    startNumber: 1,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  const inputTimeline = [{
    t: 1000,
    d: 1000,
    r: 4
  }];

  assert.deepEqual(segmentsFromList(inputAttributes, inputTimeline), [{
    duration: 1000,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 1000,
    uri: '1.fmp4',
    number: 1
  }, {
    duration: 1000,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/2.fmp4',
    timeline: 0,
    presentationTime: 2000,
    uri: '2.fmp4',
    number: 2
  }, {
    duration: 1000,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/3.fmp4',
    timeline: 0,
    presentationTime: 3000,
    uri: '3.fmp4',
    number: 3
  }, {
    duration: 1000,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/4.fmp4',
    timeline: 0,
    presentationTime: 4000,
    uri: '4.fmp4',
    number: 4
  }, {
    duration: 1000,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/5.fmp4',
    timeline: 0,
    presentationTime: 5000,
    uri: '5.fmp4',
    number: 5
  }]);
});

QUnit.test(
  'truncates if segmentTimeline does not apply for all segments',
  function(assert) {
    const inputAttributes = {
      segmentUrls: [{
        media: '1.fmp4'
      }, {
        media: '2.fmp4'
      }, {
        media: '3.fmp4'
      }, {
        media: '4.fmp4'
      }, {
        media: '5.fmp4'
      }],
      initialization: { sourceURL: 'init.fmp4' },
      periodIndex: 0,
      periodStart: 0,
      startNumber: 1,
      baseUrl: 'http://example.com/',
      type: 'static'
    };

    const inputTimeline = [{
      t: 1000,
      d: 1000,
      r: 1
    }];

    assert.deepEqual(segmentsFromList(inputAttributes, inputTimeline), [{
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/1.fmp4',
      timeline: 0,
      presentationTime: 1000,
      uri: '1.fmp4',
      number: 1
    }, {
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/2.fmp4',
      timeline: 0,
      presentationTime: 2000,
      uri: '2.fmp4',
      number: 2
    }]);
  }
);

QUnit.test(
  'if segment timeline is too long does not add extra blank segments',
  function(assert) {
    const inputAttributes = {
      segmentUrls: [{
        media: '1.fmp4'
      }, {
        media: '2.fmp4'
      }, {
        media: '3.fmp4'
      }, {
        media: '4.fmp4'
      }, {
        media: '5.fmp4'
      }],
      initialization: { sourceURL: 'init.fmp4' },
      periodIndex: 0,
      periodStart: 0,
      startNumber: 1,
      baseUrl: 'http://example.com/',
      type: 'static'
    };

    const inputTimeline = [{
      t: 1000,
      d: 1000,
      r: 10
    }];

    assert.deepEqual(segmentsFromList(inputAttributes, inputTimeline), [{
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/1.fmp4',
      timeline: 0,
      presentationTime: 1000,
      uri: '1.fmp4',
      number: 1
    }, {
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/2.fmp4',
      timeline: 0,
      presentationTime: 2000,
      uri: '2.fmp4',
      number: 2
    }, {
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/3.fmp4',
      timeline: 0,
      presentationTime: 3000,
      uri: '3.fmp4',
      number: 3
    }, {
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/4.fmp4',
      timeline: 0,
      presentationTime: 4000,
      uri: '4.fmp4',
      number: 4
    }, {
      duration: 1000,
      map: {
        resolvedUri: 'http://example.com/init.fmp4',
        uri: 'init.fmp4'
      },
      resolvedUri: 'http://example.com/5.fmp4',
      timeline: 0,
      presentationTime: 5000,
      uri: '5.fmp4',
      number: 5
    }]);
  }
);

QUnit.test('uses duration to set segments', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4'
    }, {
      media: '2.fmp4'
    }, {
      media: '3.fmp4'
    }, {
      media: '4.fmp4'
    }, {
      media: '5.fmp4'
    }],
    initialization: { sourceURL: 'init.fmp4' },
    duration: 10,
    periodIndex: 0,
    periodStart: 0,
    startNumber: 1,
    sourceDuration: 50,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  assert.deepEqual(segmentsFromList(inputAttributes), [{
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 0,
    uri: '1.fmp4',
    number: 1
  }, {
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/2.fmp4',
    timeline: 0,
    presentationTime: 10,
    uri: '2.fmp4',
    number: 2
  }, {
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/3.fmp4',
    timeline: 0,
    presentationTime: 20,
    uri: '3.fmp4',
    number: 3
  }, {
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/4.fmp4',
    timeline: 0,
    presentationTime: 30,
    uri: '4.fmp4',
    number: 4
  }, {
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/5.fmp4',
    timeline: 0,
    presentationTime: 40,
    uri: '5.fmp4',
    number: 5
  }]);
});

QUnit.test('uses timescale to set segment duration', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4'
    }, {
      media: '2.fmp4'
    }, {
      media: '3.fmp4'
    }, {
      media: '4.fmp4'
    }, {
      media: '5.fmp4'
    }],
    initialization: { sourceURL: 'init.fmp4' },
    duration: 10,
    timescale: 2,
    periodIndex: 0,
    periodStart: 0,
    startNumber: 1,
    sourceDuration: 25,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  assert.deepEqual(segmentsFromList(inputAttributes), [{
    duration: 5,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 0,
    uri: '1.fmp4',
    number: 1
  }, {
    duration: 5,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/2.fmp4',
    timeline: 0,
    presentationTime: 5,
    uri: '2.fmp4',
    number: 2
  }, {
    duration: 5,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/3.fmp4',
    timeline: 0,
    presentationTime: 10,
    uri: '3.fmp4',
    number: 3
  }, {
    duration: 5,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/4.fmp4',
    timeline: 0,
    presentationTime: 15,
    uri: '4.fmp4',
    number: 4
  }, {
    duration: 5,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/5.fmp4',
    timeline: 0,
    presentationTime: 20,
    uri: '5.fmp4',
    number: 5
  }]);
});

QUnit.test('timescale sets duration of last segment correctly', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4'
    }, {
      media: '2.fmp4'
    }],
    initialization: { sourceURL: 'init.fmp4' },
    duration: 10,
    timescale: 1,
    periodIndex: 0,
    periodStart: 0,
    startNumber: 1,
    sourceDuration: 15,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  assert.deepEqual(segmentsFromList(inputAttributes), [{
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 0,
    uri: '1.fmp4',
    number: 1
  }, {
    duration: 5,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/2.fmp4',
    timeline: 0,
    presentationTime: 10,
    uri: '2.fmp4',
    number: 2
  }]);
});

QUnit.test('segmentUrl translates ranges correctly', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4',
      mediaRange: '0-200'
    }, {
      media: '1.fmp4',
      mediaRange: '201-400'
    }],
    initialization: { sourceURL: 'init.fmp4' },
    duration: 10,
    timescale: 1,
    periodIndex: 0,
    periodStart: 0,
    startNumber: 1,
    sourceDuration: 20,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  assert.deepEqual(segmentsFromList(inputAttributes), [{
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    byterange: {
      length: 201,
      offset: 0
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 0,
    uri: '1.fmp4',
    number: 1
  }, {
    duration: 10,
    byterange: {
      length: 200,
      offset: 201
    },
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4'
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 10,
    uri: '1.fmp4',
    number: 2
  }]);
});

QUnit.test(
  'throws error if more than 1 segment and no duration or timeline',
  function(assert) {
    const inputAttributes = {
      segmentUrls: [{
        media: '1.fmp4'
      }, {
        media: '2.fmp4'
      }],
      duration: 10,
      initialization: { sourceURL: 'init.fmp4' },
      timescale: 1,
      periodIndex: 0,
      startNumber: 1,
      sourceDuration: 20,
      baseUrl: 'http://example.com/',
      type: 'static'
    };

    const inputTimeline = [{
      t: 1000,
      d: 1000,
      r: 4
    }];

    assert.throws(
      () => segmentsFromList(inputAttributes, inputTimeline),
      new Error(errors.SEGMENT_TIME_UNSPECIFIED)
    );
  }
);

QUnit.test('throws error if timeline and duration are both defined', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4'
    }, {
      media: '2.fmp4'
    }],
    initialization: { sourceURL: 'init.fmp4' },
    timescale: 1,
    periodIndex: 0,
    startNumber: 1,
    sourceDuration: 20,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  assert.throws(
    () => segmentsFromList(inputAttributes),
    new Error(errors.SEGMENT_TIME_UNSPECIFIED)
  );
});

QUnit.test('translates ranges in <Initialization> node', function(assert) {
  const inputAttributes = {
    segmentUrls: [{
      media: '1.fmp4'
    }, {
      media: '1.fmp4'
    }],
    initialization: { sourceURL: 'init.fmp4', range: '121-125' },
    duration: 10,
    timescale: 1,
    periodIndex: 0,
    periodStart: 0,
    startNumber: 1,
    sourceDuration: 20,
    baseUrl: 'http://example.com/',
    type: 'static'
  };

  assert.deepEqual(segmentsFromList(inputAttributes), [{
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4',
      byterange: {
        length: 5,
        offset: 121
      }
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 0,
    uri: '1.fmp4',
    number: 1
  }, {
    duration: 10,
    map: {
      resolvedUri: 'http://example.com/init.fmp4',
      uri: 'init.fmp4',
      byterange: {
        length: 5,
        offset: 121
      }
    },
    resolvedUri: 'http://example.com/1.fmp4',
    timeline: 0,
    presentationTime: 10,
    uri: '1.fmp4',
    number: 2
  }]);
});
