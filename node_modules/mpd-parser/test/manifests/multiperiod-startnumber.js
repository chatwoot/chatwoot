export const parsedManifest = {
  allowCache: true,
  discontinuityStarts: [],
  timelineStarts: [
    { start: 100, timeline: 100},
    { start: 103, timeline: 103},
    { start: 107, timeline: 107},
    { start: 111, timeline: 111}
  ],
  duration: 0,
  endList: true,
  mediaGroups: {
    'AUDIO': {
      audio: {
        'en (main)': {
          autoselect: true,
          default: true,
          language: 'en',
          playlists: [
            {
              attributes: {
                'BANDWIDTH': 129262,
                'CODECS': 'mp4a.40.5',
                'NAME': 'v0',
                'PROGRAM-ID': 1
              },
              endList: false,
              mediaSequence: 0,
              discontinuitySequence: 0,
              discontinuityStarts: [3, 5, 7],
              timelineStarts: [
                { start: 100, timeline: 100},
                { start: 103, timeline: 103},
                { start: 107, timeline: 107},
                { start: 111, timeline: 111}
              ],
              resolvedUri: '',
              segments: [
                {
                  duration: 1,
                  map: {
                    resolvedUri: 'http://example.com/audio/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 100,
                  number: 0,
                  resolvedUri: 'http://example.com/audio/500.m4f',
                  timeline: 100,
                  uri: '500.m4f'
                },
                {
                  duration: 1,
                  map: {
                    resolvedUri: 'http://example.com/audio/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 101,
                  number: 1,
                  resolvedUri: 'http://example.com/audio/501.m4f',
                  timeline: 100,
                  uri: '501.m4f'
                },
                {
                  duration: 1,
                  map: {
                    resolvedUri: 'http://example.com/audio/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 102,
                  number: 2,
                  resolvedUri: 'http://example.com/audio/502.m4f',
                  timeline: 100,
                  uri: '502.m4f'
                },
                {
                  discontinuity: true,
                  duration: 2,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 103,
                  number: 3,
                  resolvedUri: 'http://example.com/audio/v0/000.m4f',
                  timeline: 103,
                  uri: '000.m4f'
                },
                {
                  duration: 2,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 105,
                  number: 4,
                  resolvedUri: 'http://example.com/audio/v0/001.m4f',
                  timeline: 103,
                  uri: '001.m4f'
                },
                {
                  discontinuity: true,
                  duration: 2,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 107,
                  number: 5,
                  resolvedUri: 'http://example.com/audio/v0/000.m4f',
                  timeline: 107,
                  uri: '000.m4f'
                },
                {
                  duration: 2,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 109,
                  number: 6,
                  resolvedUri: 'http://example.com/audio/v0/001.m4f',
                  timeline: 107,
                  uri: '001.m4f'
                },
                {
                  discontinuity: true,
                  duration: 1,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 111,
                  number: 7,
                  resolvedUri: 'http://example.com/audio/v0/862.m4f',
                  timeline: 111,
                  uri: '862.m4f'
                },
                {
                  duration: 1,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 112,
                  number: 8,
                  resolvedUri: 'http://example.com/audio/v0/863.m4f',
                  timeline: 111,
                  uri: '863.m4f'
                },
                {
                  duration: 1,
                  map: {
                    resolvedUri: 'http://example.com/audio/v0/init.mp4',
                    uri: 'init.mp4'
                  },
                  presentationTime: 113,
                  number: 9,
                  resolvedUri: 'http://example.com/audio/v0/864.m4f',
                  timeline: 111,
                  uri: '864.m4f'
                }
              ],
              targetDuration: 1,
              timeline: 100,
              uri: ''
            }
          ],
          uri: ''
        }
      }
    },
    'CLOSED-CAPTIONS': {},
    'SUBTITLES': {},
    'VIDEO': {}
  },
  minimumUpdatePeriod: 2000,
  playlists: [
    {
      attributes: {
        'AUDIO': 'audio',
        'BANDWIDTH': 2942295,
        'CODECS': 'avc1.4d001f',
        'NAME': 'D',
        'PROGRAM-ID': 1,
        'RESOLUTION': {
          height: 720,
          width: 1280
        },
        'SUBTITLES': 'subs'
      },
      endList: false,
      mediaSequence: 0,
      discontinuitySequence: 0,
      discontinuityStarts: [3, 5, 7],
      timelineStarts: [
        { start: 100, timeline: 100},
        { start: 103, timeline: 103},
        { start: 107, timeline: 107},
        { start: 111, timeline: 111}
      ],
      resolvedUri: '',
      segments: [
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 100,
          number: 0,
          resolvedUri: 'http://example.com/video/D/D500.m4f',
          timeline: 100,
          uri: 'D500.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 101,
          number: 1,
          resolvedUri: 'http://example.com/video/D/D501.m4f',
          timeline: 100,
          uri: 'D501.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 102,
          number: 2,
          resolvedUri: 'http://example.com/video/D/D502.m4f',
          timeline: 100,
          uri: 'D502.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 103,
          number: 3,
          resolvedUri: 'http://example.com/video/D/D000.m4f',
          timeline: 103,
          uri: 'D000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 105,
          number: 4,
          resolvedUri: 'http://example.com/video/D/D001.m4f',
          timeline: 103,
          uri: 'D001.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 107,
          number: 5,
          resolvedUri: 'http://example.com/video/D/D000.m4f',
          timeline: 107,
          uri: 'D000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 109,
          number: 6,
          resolvedUri: 'http://example.com/video/D/D001.m4f',
          timeline: 107,
          uri: 'D001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 111,
          number: 7,
          resolvedUri: 'http://example.com/video/D/D862.m4f',
          timeline: 111,
          uri: 'D862.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 112,
          number: 8,
          resolvedUri: 'http://example.com/video/D/D863.m4f',
          timeline: 111,
          uri: 'D863.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/D/D_init.mp4',
            uri: 'D_init.mp4'
          },
          presentationTime: 113,
          number: 9,
          resolvedUri: 'http://example.com/video/D/D864.m4f',
          timeline: 111,
          uri: 'D864.m4f'
        }
      ],
      targetDuration: 1,
      timeline: 100,
      uri: ''
    },
    {
      attributes: {
        'AUDIO': 'audio',
        'BANDWIDTH': 4267536,
        'CODECS': 'avc1.640020',
        'NAME': 'E',
        'PROGRAM-ID': 1,
        'RESOLUTION': {
          height: 720,
          width: 1280
        },
        'SUBTITLES': 'subs'
      },
      endList: false,
      mediaSequence: 0,
      discontinuitySequence: 0,
      discontinuityStarts: [3, 5, 7],
      timelineStarts: [
        { start: 100, timeline: 100},
        { start: 103, timeline: 103},
        { start: 107, timeline: 107},
        { start: 111, timeline: 111}
      ],
      resolvedUri: '',
      segments: [
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 100,
          number: 0,
          resolvedUri: 'http://example.com/video/E/E500.m4f',
          timeline: 100,
          uri: 'E500.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 101,
          number: 1,
          resolvedUri: 'http://example.com/video/E/E501.m4f',
          timeline: 100,
          uri: 'E501.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 102,
          number: 2,
          resolvedUri: 'http://example.com/video/E/E502.m4f',
          timeline: 100,
          uri: 'E502.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 103,
          number: 3,
          resolvedUri: 'http://example.com/video/E/E000.m4f',
          timeline: 103,
          uri: 'E000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 105,
          number: 4,
          resolvedUri: 'http://example.com/video/E/E001.m4f',
          timeline: 103,
          uri: 'E001.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 107,
          number: 5,
          resolvedUri: 'http://example.com/video/E/E000.m4f',
          timeline: 107,
          uri: 'E000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 109,
          number: 6,
          resolvedUri: 'http://example.com/video/E/E001.m4f',
          timeline: 107,
          uri: 'E001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 111,
          number: 7,
          resolvedUri: 'http://example.com/video/E/E862.m4f',
          timeline: 111,
          uri: 'E862.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 112,
          number: 8,
          resolvedUri: 'http://example.com/video/E/E863.m4f',
          timeline: 111,
          uri: 'E863.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/E_init.mp4',
            uri: 'E_init.mp4'
          },
          presentationTime: 113,
          number: 9,
          resolvedUri: 'http://example.com/video/E/E864.m4f',
          timeline: 111,
          uri: 'E864.m4f'
        }
      ],
      targetDuration: 1,
      timeline: 100,
      uri: ''
    },
    {
      attributes: {
        'AUDIO': 'audio',
        'BANDWIDTH': 5256859,
        'CODECS': 'avc1.640020',
        'NAME': 'F',
        'PROGRAM-ID': 1,
        'RESOLUTION': {
          height: 720,
          width: 1280
        },
        'SUBTITLES': 'subs'
      },
      endList: false,
      mediaSequence: 0,
      discontinuitySequence: 0,
      discontinuityStarts: [3, 5, 7],
      timelineStarts: [
        { start: 100, timeline: 100},
        { start: 103, timeline: 103},
        { start: 107, timeline: 107},
        { start: 111, timeline: 111}
      ],
      resolvedUri: '',
      segments: [
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 100,
          number: 0,
          resolvedUri: 'http://example.com/video/E/F500.m4f',
          timeline: 100,
          uri: 'F500.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 101,
          number: 1,
          resolvedUri: 'http://example.com/video/E/F501.m4f',
          timeline: 100,
          uri: 'F501.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 102,
          number: 2,
          resolvedUri: 'http://example.com/video/E/F502.m4f',
          timeline: 100,
          uri: 'F502.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 103,
          number: 3,
          resolvedUri: 'http://example.com/video/F/F000.m4f',
          timeline: 103,
          uri: 'F000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 105,
          number: 4,
          resolvedUri: 'http://example.com/video/F/F001.m4f',
          timeline: 103,
          uri: 'F001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 107,
          number: 5,
          resolvedUri: 'http://example.com/video/F/F000.m4f',
          timeline: 107,
          uri: 'F000.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 108,
          number: 6,
          resolvedUri: 'http://example.com/video/F/F001.m4f',
          timeline: 107,
          uri: 'F001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 111,
          number: 7,
          resolvedUri: 'http://example.com/video/F/F862.m4f',
          timeline: 111,
          uri: 'F862.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 112,
          number: 8,
          resolvedUri: 'http://example.com/video/F/F863.m4f',
          timeline: 111,
          uri: 'F863.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/F/F_init.mp4',
            uri: 'F_init.mp4'
          },
          presentationTime: 113,
          number: 9,
          resolvedUri: 'http://example.com/video/F/F864.m4f',
          timeline: 111,
          uri: 'F864.m4f'
        }
      ],
      targetDuration: 1,
      timeline: 100,
      uri: ''
    },
    {
      attributes: {
        'AUDIO': 'audio',
        'BANDWIDTH': 240781,
        'CODECS': 'avc1.4d000d',
        'NAME': 'A',
        'PROGRAM-ID': 1,
        'RESOLUTION': {
          height: 234,
          width: 416
        },
        'SUBTITLES': 'subs'
      },
      endList: false,
      mediaSequence: 0,
      discontinuitySequence: 0,
      discontinuityStarts: [3, 5, 7],
      timelineStarts: [
        { start: 100, timeline: 100},
        { start: 103, timeline: 103},
        { start: 107, timeline: 107},
        { start: 111, timeline: 111}
      ],
      resolvedUri: '',
      segments: [
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 100,
          number: 0,
          resolvedUri: 'http://example.com/video/A/A500.m4f',
          timeline: 100,
          uri: 'A500.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 101,
          number: 1,
          resolvedUri: 'http://example.com/video/A/A501.m4f',
          timeline: 100,
          uri: 'A501.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 102,
          number: 2,
          resolvedUri: 'http://example.com/video/A/A502.m4f',
          timeline: 100,
          uri: 'A502.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 103,
          number: 3,
          resolvedUri: 'http://example.com/video/A/A000.m4f',
          timeline: 103,
          uri: 'A000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 105,
          number: 4,
          resolvedUri: 'http://example.com/video/A/A001.m4f',
          timeline: 103,
          uri: 'A001.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 107,
          number: 5,
          resolvedUri: 'http://example.com/video/A/A000.m4f',
          timeline: 107,
          uri: 'A000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 109,
          number: 6,
          resolvedUri: 'http://example.com/video/A/A001.m4f',
          timeline: 107,
          uri: 'A001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 111,
          number: 7,
          resolvedUri: 'http://example.com/video/A/A862.m4f',
          timeline: 111,
          uri: 'A862.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 112,
          number: 8,
          resolvedUri: 'http://example.com/video/A/A863.m4f',
          timeline: 111,
          uri: 'A863.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/A/A_init.mp4',
            uri: 'A_init.mp4'
          },
          presentationTime: 113,
          number: 9,
          resolvedUri: 'http://example.com/video/A/A864.m4f',
          timeline: 111,
          uri: 'A864.m4f'
        }
      ],
      targetDuration: 1,
      timeline: 100,
      uri: ''
    },
    {
      attributes: {
        'AUDIO': 'audio',
        'BANDWIDTH': 494354,
        'CODECS': 'avc1.4d001e',
        'NAME': 'B',
        'PROGRAM-ID': 1,
        'RESOLUTION': {
          height: 360,
          width: 640
        },
        'SUBTITLES': 'subs'
      },
      endList: false,
      mediaSequence: 0,
      discontinuitySequence: 0,
      discontinuityStarts: [3, 5, 7],
      timelineStarts: [
        { start: 100, timeline: 100},
        { start: 103, timeline: 103},
        { start: 107, timeline: 107},
        { start: 111, timeline: 111}
      ],
      resolvedUri: '',
      segments: [
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 100,
          number: 0,
          resolvedUri: 'http://example.com/video/B/B500.m4f',
          timeline: 100,
          uri: 'B500.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 101,
          number: 1,
          resolvedUri: 'http://example.com/video/B/B501.m4f',
          timeline: 100,
          uri: 'B501.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 102,
          number: 2,
          resolvedUri: 'http://example.com/video/B/B502.m4f',
          timeline: 100,
          uri: 'B502.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 103,
          number: 3,
          resolvedUri: 'http://example.com/video/B/B000.m4f',
          timeline: 103,
          uri: 'B000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 105,
          number: 4,
          resolvedUri: 'http://example.com/video/B/B001.m4f',
          timeline: 103,
          uri: 'B001.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 107,
          number: 5,
          resolvedUri: 'http://example.com/video/B/B000.m4f',
          timeline: 107,
          uri: 'B000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 109,
          number: 6,
          resolvedUri: 'http://example.com/video/B/B001.m4f',
          timeline: 107,
          uri: 'B001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 111,
          number: 7,
          resolvedUri: 'http://example.com/video/B/B862.m4f',
          timeline: 111,
          uri: 'B862.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 112,
          number: 8,
          resolvedUri: 'http://example.com/video/B/B863.m4f',
          timeline: 111,
          uri: 'B863.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/B/B_init.mp4',
            uri: 'B_init.mp4'
          },
          presentationTime: 113,
          number: 9,
          resolvedUri: 'http://example.com/video/B/B864.m4f',
          timeline: 111,
          uri: 'B864.m4f'
        }
      ],
      targetDuration: 1,
      timeline: 100,
      uri: ''
    },
    {
      attributes: {
        'AUDIO': 'audio',
        'BANDWIDTH': 1277155,
        'CODECS': 'avc1.4d001e',
        'NAME': 'C',
        'PROGRAM-ID': 1,
        'RESOLUTION': {
          height: 540,
          width: 960
        },
        'SUBTITLES': 'subs'
      },
      endList: false,
      mediaSequence: 0,
      discontinuitySequence: 0,
      discontinuityStarts: [3, 5, 7],
      timelineStarts: [
        { start: 100, timeline: 100},
        { start: 103, timeline: 103},
        { start: 107, timeline: 107},
        { start: 111, timeline: 111}
      ],
      resolvedUri: '',
      segments: [
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 100,
          number: 0,
          resolvedUri: 'http://example.com/video/E/C500.m4f',
          timeline: 100,
          uri: 'C500.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 101,
          number: 1,
          resolvedUri: 'http://example.com/video/E/C501.m4f',
          timeline: 100,
          uri: 'C501.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/E/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 102,
          number: 2,
          resolvedUri: 'http://example.com/video/E/C502.m4f',
          timeline: 100,
          uri: 'C502.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 103,
          number: 3,
          resolvedUri: 'http://example.com/video/C/C000.m4f',
          timeline: 103,
          uri: 'C000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 105,
          number: 4,
          resolvedUri: 'http://example.com/video/C/C001.m4f',
          timeline: 103,
          uri: 'C001.m4f'
        },
        {
          discontinuity: true,
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 107,
          number: 5,
          resolvedUri: 'http://example.com/video/C/C000.m4f',
          timeline: 107,
          uri: 'C000.m4f'
        },
        {
          duration: 2,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 109,
          number: 6,
          resolvedUri: 'http://example.com/video/C/C001.m4f',
          timeline: 107,
          uri: 'C001.m4f'
        },
        {
          discontinuity: true,
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 111,
          number: 7,
          resolvedUri: 'http://example.com/video/C/C862.m4f',
          timeline: 111,
          uri: 'C862.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 112,
          number: 8,
          resolvedUri: 'http://example.com/video/C/C863.m4f',
          timeline: 111,
          uri: 'C863.m4f'
        },
        {
          duration: 1,
          map: {
            resolvedUri: 'http://example.com/video/C/C_init.mp4',
            uri: 'C_init.mp4'
          },
          presentationTime: 113,
          number: 9,
          resolvedUri: 'http://example.com/video/C/C864.m4f',
          timeline: 111,
          uri: 'C864.m4f'
        }
      ],
      targetDuration: 1,
      timeline: 100,
      uri: ''
    }
  ],
  segments: [],
  suggestedPresentationDelay: 6,
  uri: ''
};
