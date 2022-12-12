import {
  getUniqueTimelineStarts,
  findPlaylistWithName,
  getMediaGroupPlaylists,
  updateMediaSequenceForPlaylist,
  updateSequenceNumbers,
  positionManifestOnTimeline
} from '../src/playlist-merge';
import { merge } from '../src/utils/object';
import QUnit from 'qunit';

QUnit.module('getUniqueTimelineStarts');

QUnit.test('handles multiple playlists', function(assert) {
  const listOfTimelineStartLists = [
    [{ start: 0, timeline: 0 }, { start: 10, timeline: 10 }, { start: 20, timeline: 20 }],
    [{ start: 0, timeline: 0 }, { start: 10, timeline: 10 }, { start: 20, timeline: 20 }],
    [{ start: 10, timeline: 10 }, { start: 20, timeline: 20 }],
    [{ start: 0, timeline: 0 }, { start: 20, timeline: 20 }],
    [{ start: 30, timeline: 30 }]
  ];

  assert.deepEqual(
    getUniqueTimelineStarts(listOfTimelineStartLists),
    [{
      start: 0,
      timeline: 0
    }, {
      start: 10,
      timeline: 10
    }, {
      start: 20,
      timeline: 20
    }, {
      start: 30,
      timeline: 30
    }],
    'handled multiple playlists with differing timeline starts'
  );
});

QUnit.module('findPlaylistWithName');

QUnit.test('returns nothing when no playlists', function(assert) {
  assert.notOk(findPlaylistWithName([], 'A'), 'nothing when no playlists');
});

QUnit.test('returns nothing when no match', function(assert) {
  const playlists = [
    { attributes: { NAME: 'B' } }
  ];

  assert.notOk(findPlaylistWithName(playlists, 'A'), 'nothing when no match');
});

QUnit.test('returns matching playlist', function(assert) {
  const playlists = [
    { attributes: { NAME: 'A' } },
    { attributes: { NAME: 'B' } },
    { attributes: { NAME: 'C' } }
  ];

  assert.deepEqual(
    findPlaylistWithName(playlists, 'B'),
    playlists[1],
    'returns matching playlist'
  );
});

QUnit.module('getMediaGroupPlaylists');

QUnit.test('returns nothing when no media group playlists', function(assert) {
  const manifest = {
    mediaGroups: {
      AUDIO: {}
    }
  };

  assert.deepEqual(
    getMediaGroupPlaylists(manifest),
    [],
    'nothing when no media group playlists'
  );
});

QUnit.test('returns media group playlists', function(assert) {
  const playlistEnA = { attributes: { NAME: 'A' } };
  const playlistEnB = { attributes: { NAME: 'B' } };
  const playlistEnC = { attributes: { NAME: 'C' } };
  const playlistFrA = { attributes: { NAME: 'A' } };
  const playlistFrB = { attributes: { NAME: 'B' } };
  const manifest = {
    mediaGroups: {
      AUDIO: {
        audio: {
          en: {
            playlists: [playlistEnA, playlistEnB, playlistEnC]
          },
          fr: {
            playlists: [playlistFrA, playlistFrB]
          }
        }
      }
    }
  };

  assert.deepEqual(
    getMediaGroupPlaylists(manifest),
    [playlistEnA, playlistEnB, playlistEnC, playlistFrA, playlistFrB],
    'returns media group playlists'
  );
});

QUnit.module('updateMediaSequenceForPlaylist');

QUnit.test('no segments means only top level mediaSequence is updated', function(assert) {
  const playlist = { mediaSequence: 1, segments: [] };

  updateMediaSequenceForPlaylist({ playlist, mediaSequence: 3 });

  assert.deepEqual(
    playlist,
    { mediaSequence: 3, segments: [] },
    'updated only top level mediaSequence'
  );
});

QUnit.test('updates top level mediaSequence and segments', function(assert) {
  const playlist = {
    mediaSequence: 1,
    segments: [{ number: 1 }, { number: 2 }, { number: 3 }]
  };

  updateMediaSequenceForPlaylist({ playlist, mediaSequence: 3 });

  assert.deepEqual(
    playlist,
    { mediaSequence: 3, segments: [{ number: 3 }, { number: 4 }, { number: 5 }] },
    'updated top level mediaSequence and segments'
  );
});

QUnit.module('updateSequenceNumbers');

QUnit.test('no playlists, no update', function(assert) {
  const oldPlaylists = [];
  const newPlaylists = [];
  const timelineStarts = [];

  updateSequenceNumbers({ oldPlaylists, newPlaylists, timelineStarts });

  assert.deepEqual(newPlaylists, [], 'new playlists unchanged');
});

QUnit.test('no matching playlists only updates discontinuity sequence', function(assert) {
  const oldPlaylists = [{
    discontinuitySequence: 1,
    discontinuityStarts: [],
    timeline: 5,
    attributes: { NAME: 'A' }
  }, {
    discontinuitySequence: 2,
    discontinuityStarts: [],
    timeline: 10,
    attributes: { NAME: 'B' }
  }];
  const newPlaylists = [{
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timeline: 5,
    attributes: { NAME: 'C' }
  }, {
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timeline: 10,
    attributes: { NAME: 'D' }
  }];
  const timelineStarts = [
    { start: 0, timeline: 0 },
    { start: 5, timeline: 5 },
    { start: 10, timeline: 10 }
  ];

  updateSequenceNumbers({ oldPlaylists, newPlaylists, timelineStarts });

  assert.deepEqual(
    newPlaylists,
    [{
      discontinuitySequence: 1,
      discontinuityStarts: [],
      timeline: 5,
      attributes: { NAME: 'C' }
    }, {
      discontinuitySequence: 2,
      discontinuityStarts: [],
      timeline: 10,
      attributes: { NAME: 'D' }
    }],
    'new playlist discontinuity sequence numbers updated'
  );
});

QUnit.test('segment match of matching playlist', function(assert) {
  const oldPlaylists = [{
    discontinuitySequence: 1,
    discontinuityStarts: [],
    mediaSequence: 5,
    timeline: 5,
    attributes: { NAME: 'C' },
    segments: [{
      presentationTime: 10,
      timeline: 5,
      number: 5
    }, {
      presentationTime: 12,
      timeline: 5,
      number: 6
    }, {
      presentationTime: 14,
      timeline: 5,
      number: 7
    }]
  }];
  const newPlaylists = [{
    discontinuitySequence: 0,
    discontinuityStarts: [],
    mediaSequence: 0,
    timeline: 5,
    attributes: { NAME: 'C' },
    segments: [{
      presentationTime: 12,
      timeline: 5,
      number: 0
    }, {
      presentationTime: 14,
      timeline: 5,
      number: 1
    }]
  }];
  const timelineStarts = [
    { start: 0, timeline: 0 },
    { start: 5, timeline: 5 }
  ];

  updateSequenceNumbers({ oldPlaylists, newPlaylists, timelineStarts });

  assert.deepEqual(
    newPlaylists,
    [{
      discontinuitySequence: 1,
      discontinuityStarts: [],
      mediaSequence: 6,
      timeline: 5,
      attributes: { NAME: 'C' },
      segments: [{
        presentationTime: 12,
        timeline: 5,
        number: 6
      }, {
        presentationTime: 14,
        timeline: 5,
        number: 7
      }]
    }],
    'new playlist updated'
  );
});

QUnit.test('complete refresh of matching playlist', function(assert) {
  const oldPlaylists = [{
    discontinuitySequence: 1,
    discontinuityStarts: [],
    mediaSequence: 5,
    timeline: 5,
    attributes: { NAME: 'C' },
    segments: [{
      presentationTime: 10,
      timeline: 5,
      number: 5
    }, {
      presentationTime: 12,
      timeline: 5,
      number: 6
    }, {
      presentationTime: 14,
      timeline: 5,
      number: 7
    }]
  }];
  const newPlaylists = [{
    discontinuitySequence: 0,
    discontinuityStarts: [],
    mediaSequence: 0,
    timeline: 5,
    attributes: { NAME: 'C' },
    segments: [{
      presentationTime: 16,
      timeline: 5,
      number: 0
    }, {
      presentationTime: 18,
      timeline: 5,
      number: 1
    }]
  }];
  const timelineStarts = [
    { start: 0, timeline: 0 },
    { start: 5, timeline: 5 }
  ];

  updateSequenceNumbers({ oldPlaylists, newPlaylists, timelineStarts });

  assert.deepEqual(
    newPlaylists,
    [{
      discontinuitySequence: 1,
      discontinuityStarts: [0],
      mediaSequence: 8,
      timeline: 5,
      attributes: { NAME: 'C' },
      segments: [{
        discontinuity: true,
        presentationTime: 16,
        timeline: 5,
        number: 8
      }, {
        presentationTime: 18,
        timeline: 5,
        number: 9
      }]
    }],
    'new playlist updated after complete refresh'
  );
});

QUnit.module('positionManifestOnTimeline');

QUnit.test('handles multiple playlists, including added and removed', function(assert) {
  const oldPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 12,
    discontinuitySequence: 2,
    discontinuityStarts: [1],
    timelineStarts: [
      // only this playlist has the 20 timeline
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    timeline: 20,
    segments: [{
      number: 12,
      timeline: 20,
      presentationTime: 31
    }, {
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const oldPlaylistB = {
    attributes: { NAME: 'B' },
    mediaSequence: 13,
    discontinuitySequence: 2,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  // same as A just with a different name
  const oldPlaylistC = merge(oldPlaylistA, {
    attributes: { NAME: 'C' }
  });
  const newPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      // no discontinuity is marked because from the context of the new playlist, it's the
      // first period
      number: 0,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 1,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const newPlaylistB = {
    attributes: { NAME: 'B' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      number: 0,
      timeline: 33,
      presentationTime: 35
    }]
  };
  // same as B but with a different name
  const newPlaylistD = merge(newPlaylistB, {
    attributes: { NAME: 'D' }
  });
  const oldManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    // The manifest's timeline starts will account for all seen timeline starts. Since the
    // lowest playlist discontinuity sequence is 2, that means there are two additional
    // timeline starts here that aren't present in any playlists.
    timelineStarts: [
      { start: 10, timeline: 10 },
      { start: 15, timeline: 15 },
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    playlists: [oldPlaylistA, oldPlaylistB, oldPlaylistC]
  };
  const newManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    timelineStarts: [
      // removed 20 timeline
      { start: 33, timeline: 33 }
    ],
    // removed C, added D
    playlists: [newPlaylistA, newPlaylistB, newPlaylistD]
  };

  assert.deepEqual(
    positionManifestOnTimeline({ oldManifest, newManifest }),
    {
      mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
      timelineStarts: [
        { start: 10, timeline: 10 },
        { start: 15, timeline: 15 },
        { start: 20, timeline: 20 },
        { start: 33, timeline: 33 }
      ],
      playlists: [{
        attributes: { NAME: 'A' },
        // updated mediaSequence
        mediaSequence: 13,
        // updated discontinuitySequence
        discontinuitySequence: 2,
        discontinuityStarts: [0],
        timelineStarts: [
          { start: 33, timeline: 33 }
        ],
        timeline: 33,
        segments: [{
          discontinuity: true,
          // updated sequence number
          number: 13,
          timeline: 33,
          presentationTime: 33
        }, {
          // updated sequence number
          number: 14,
          timeline: 33,
          presentationTime: 35
        }]
      }, {
        attributes: { NAME: 'B' },
        // updated mediaSequence
        mediaSequence: 14,
        // updated discontinuitySequence, note that it's one greater than A
        discontinuitySequence: 3,
        discontinuityStarts: [],
        timelineStarts: [
          { start: 33, timeline: 33 }
        ],
        timeline: 33,
        segments: [{
          // updated sequence number
          number: 14,
          timeline: 33,
          presentationTime: 35
        }]
      }, {
        attributes: { NAME: 'D' },
        // since D is a new playlist, media sequence is 0
        mediaSequence: 0,
        // updated discontinuitySequence, note that it's one greater than A
        discontinuitySequence: 3,
        discontinuityStarts: [],
        timelineStarts: [
          { start: 33, timeline: 33 }
        ],
        timeline: 33,
        segments: [{
          // updated sequence number
          number: 14,
          timeline: 33,
          presentationTime: 35
        }]
      }]
    },
    'handled updated, removed, and added playlists'
  );
});

QUnit.test('handles playlist and media group playlist', function(assert) {
  const oldPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 12,
    discontinuitySequence: 2,
    discontinuityStarts: [1],
    timelineStarts: [
      // only this playlist has the 20 timeline
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    timeline: 20,
    segments: [{
      number: 12,
      timeline: 20,
      presentationTime: 31
    }, {
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const oldPlaylistB = {
    attributes: { NAME: 'B' },
    mediaSequence: 13,
    discontinuitySequence: 2,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const newPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      // no discontinuity is marked because from the context of the new playlist, it's the
      // first period
      number: 0,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 1,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const newPlaylistB = {
    attributes: { NAME: 'B' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      number: 0,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const oldManifest = {
    mediaGroups: {
      AUDIO: {
        audio: {
          en: {
            playlists: [oldPlaylistA]
          }
        }
      },
      VIDEO: {},
      ['CLOSED-CAPTIONS']: {},
      SUBTITLES: {}
    },
    // The manifest's timeline starts will account for all seen timeline starts. Since the
    // lowest playlist discontinuity sequence is 2, that means there are two additional
    // timeline starts here that aren't present in any playlists.
    timelineStarts: [
      { start: 10, timeline: 10 },
      { start: 15, timeline: 15 },
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    playlists: [oldPlaylistB]
  };
  const newManifest = {
    mediaGroups: {
      AUDIO: {
        audio: {
          en: {
            playlists: [newPlaylistA]
          }
        }
      },
      VIDEO: {},
      ['CLOSED-CAPTIONS']: {},
      SUBTITLES: {}
    },
    timelineStarts: [
      // removed 20 timeline
      { start: 33, timeline: 33 }
    ],
    // removed C, added D
    playlists: [newPlaylistB]
  };

  assert.deepEqual(
    positionManifestOnTimeline({ oldManifest, newManifest }),
    {
      mediaGroups: {
        AUDIO: {
          audio: {
            en: {
              playlists: [{
                attributes: { NAME: 'A' },
                // updated mediaSequence
                mediaSequence: 13,
                // updated discontinuitySequence
                discontinuitySequence: 2,
                discontinuityStarts: [0],
                timelineStarts: [
                  { start: 33, timeline: 33 }
                ],
                timeline: 33,
                segments: [{
                  discontinuity: true,
                  // updated sequence number
                  number: 13,
                  timeline: 33,
                  presentationTime: 33
                }, {
                  // updated sequence number
                  number: 14,
                  timeline: 33,
                  presentationTime: 35
                }]
              }]
            }
          }
        },
        VIDEO: {},
        ['CLOSED-CAPTIONS']: {},
        SUBTITLES: {}
      },
      timelineStarts: [
        { start: 10, timeline: 10 },
        { start: 15, timeline: 15 },
        { start: 20, timeline: 20 },
        { start: 33, timeline: 33 }
      ],
      playlists: [{
        attributes: { NAME: 'B' },
        // updated mediaSequence
        mediaSequence: 14,
        // updated discontinuitySequence, note that it's one greater than A
        discontinuitySequence: 3,
        discontinuityStarts: [],
        timelineStarts: [
          { start: 33, timeline: 33 }
        ],
        timeline: 33,
        segments: [{
          // updated sequence number
          number: 14,
          timeline: 33,
          presentationTime: 35
        }]
      }]
    },
    'handled playlist and media group playlist'
  );
});

QUnit.test('complete refresh same timeline', function(assert) {
  const oldPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 12,
    discontinuitySequence: 2,
    discontinuityStarts: [1],
    timelineStarts: [
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    timeline: 20,
    segments: [{
      number: 12,
      timeline: 20,
      presentationTime: 31
    }, {
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const newPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      number: 0,
      timeline: 33,
      // missed a large portion of time, but still within same timeline
      presentationTime: 50
    }, {
      number: 1,
      timeline: 33,
      presentationTime: 52
    }]
  };
  const oldManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    // The manifest's timeline starts will account for all seen timeline starts. Since the
    // lowest playlist discontinuity sequence is 2, that means there are two additional
    // timeline starts here that aren't present in any playlists.
    timelineStarts: [
      { start: 10, timeline: 10 },
      { start: 15, timeline: 15 },
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    playlists: [oldPlaylistA]
  };
  const newManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    timelineStarts: [
      // removed 20 timeline
      { start: 33, timeline: 33 }
    ],
    playlists: [newPlaylistA]
  };

  assert.deepEqual(
    positionManifestOnTimeline({ oldManifest, newManifest }),
    {
      mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
      timelineStarts: [
        { start: 10, timeline: 10 },
        { start: 15, timeline: 15 },
        { start: 20, timeline: 20 },
        { start: 33, timeline: 33 }
      ],
      playlists: [{
        attributes: { NAME: 'A' },
        // updated mediaSequence to one greater than last seen
        mediaSequence: 15,
        // updated discontinuitySequence to account for timeline 33 discontinuity falling
        // off
        discontinuitySequence: 3,
        // added discontinuity to beginning
        discontinuityStarts: [0],
        timelineStarts: [
          { start: 33, timeline: 33 }
        ],
        timeline: 33,
        segments: [{
          discontinuity: true,
          // updated sequence number
          number: 15,
          timeline: 33,
          presentationTime: 50
        }, {
          // updated sequence number
          number: 16,
          timeline: 33,
          presentationTime: 52
        }]
      }]
    },
    'handled complete refresh on same timeline'
  );
});

QUnit.test('complete refresh different timeline', function(assert) {
  const oldPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 12,
    // timeline 10 is the start (thus no disco)
    // removed 1 disco at timeline 15, and another for the start of timeline 20
    discontinuitySequence: 2,
    discontinuityStarts: [1],
    timelineStarts: [
      // only this playlist has the 20 timeline
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    timeline: 20,
    segments: [{
      number: 12,
      timeline: 20,
      presentationTime: 31
    }, {
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const newPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 50, timeline: 50 }
    ],
    timeline: 50,
    segments: [{
      number: 0,
      // new timeline
      timeline: 50,
      presentationTime: 50
    }, {
      number: 1,
      timeline: 50,
      presentationTime: 52
    }]
  };
  const oldManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    // The manifest's timeline starts will account for all seen timeline starts. Since the
    // lowest playlist discontinuity sequence is 2, that means there are two additional
    // timeline starts here that aren't present in any playlists.
    timelineStarts: [
      { start: 10, timeline: 10 },
      { start: 15, timeline: 15 },
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    playlists: [oldPlaylistA]
  };
  const newManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    timelineStarts: [
      // removed 20 and 33 timelines, added 50
      { start: 50, timeline: 50 }
    ],
    playlists: [newPlaylistA]
  };

  assert.deepEqual(
    positionManifestOnTimeline({ oldManifest, newManifest }),
    {
      mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
      timelineStarts: [
        { start: 10, timeline: 10 },
        { start: 15, timeline: 15 },
        { start: 20, timeline: 20 },
        { start: 33, timeline: 33 },
        // added new timeline and retained the ones from before
        { start: 50, timeline: 50 }
      ],
      playlists: [{
        attributes: { NAME: 'A' },
        // updated mediaSequence to one greater than last seen
        mediaSequence: 15,
        // updated discontinuitySequence to account for removed discos (previously the
        // disco at 15 and 20, plus the disco starting timeline 33 on the refresh)
        discontinuitySequence: 3,
        // added discontinuity to beginning
        discontinuityStarts: [0],
        timelineStarts: [
          { start: 50, timeline: 50 }
        ],
        timeline: 50,
        segments: [{
          discontinuity: true,
          // updated sequence number
          number: 15,
          timeline: 50,
          presentationTime: 50
        }, {
          // updated sequence number
          number: 16,
          timeline: 50,
          presentationTime: 52
        }]
      }]
    },
    'handled complete refresh on different timeline'
  );
});

QUnit.test('no change, first segment a discontinuity', function(assert) {
  const oldPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 13,
    discontinuitySequence: 2,
    discontinuityStarts: [0],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      discontinuity: true,
      number: 13,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 14,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const newPlaylistA = {
    attributes: { NAME: 'A' },
    mediaSequence: 0,
    discontinuitySequence: 0,
    discontinuityStarts: [],
    timelineStarts: [
      { start: 33, timeline: 33 }
    ],
    timeline: 33,
    segments: [{
      // no discontinuity marked for the refresh, should be added by merging logic
      number: 0,
      timeline: 33,
      presentationTime: 33
    }, {
      number: 1,
      timeline: 33,
      presentationTime: 35
    }]
  };
  const oldManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    // The manifest's timeline starts will account for all seen timeline starts. Since the
    // lowest playlist discontinuity sequence is 3, that means there are three additional
    // timeline starts here that aren't present in any playlists, plus the original at 0.
    timelineStarts: [
      { start: 10, timeline: 10 },
      { start: 15, timeline: 15 },
      { start: 20, timeline: 20 },
      { start: 33, timeline: 33 }
    ],
    playlists: [oldPlaylistA]
  };
  const newManifest = {
    mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
    timelineStarts: [{ start: 33, timeline: 33 }],
    playlists: [newPlaylistA]
  };

  assert.deepEqual(
    positionManifestOnTimeline({ oldManifest, newManifest }),
    {
      mediaGroups: { AUDIO: {}, VIDEO: {}, ['CLOSED-CAPTIONS']: {}, SUBTITLES: {} },
      timelineStarts: [
        { start: 10, timeline: 10 },
        { start: 15, timeline: 15 },
        { start: 20, timeline: 20 },
        { start: 33, timeline: 33 }
      ],
      playlists: [{
        attributes: { NAME: 'A' },
        mediaSequence: 13,
        discontinuitySequence: 2,
        // discontinuity at beginning
        discontinuityStarts: [0],
        timelineStarts: [
          { start: 33, timeline: 33 }
        ],
        timeline: 33,
        segments: [{
          // discontinuity added to new playlist
          discontinuity: true,
          // updated sequence number
          number: 13,
          timeline: 33,
          presentationTime: 33
        }, {
          // updated sequence number
          number: 14,
          timeline: 33,
          presentationTime: 35
        }]
      }]
    },
    'handled no change with first segment a discontinuity'
  );
});
