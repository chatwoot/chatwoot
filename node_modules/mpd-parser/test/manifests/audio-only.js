export const parsedManifest = {
  allowCache: true,
  discontinuityStarts: [],
  segments: [],
  timelineStarts: [{
    start: 0,
    timeline: 0
  }],
  endList: true,
  mediaGroups: {
    'AUDIO': {
      audio: {
        en: {
          language: 'en',
          autoselect: true,
          default: true,
          playlists: [
            {
              attributes: {
                'NAME': '0',
                'BANDWIDTH': 130803,
                'CODECS': 'mp4a.40.2',
                'PROGRAM-ID': 1,
                'AUDIO': 'audio',
                'SUBTITLES': 'subs'
              },
              uri: '',
              endList: true,
              timeline: 0,
              resolvedUri: '',
              targetDuration: 60,
              segments: [],
              mediaSequence: 0,
              discontinuitySequence: 0,
              discontinuityStarts: [],
              timelineStarts: [{
                start: 0,
                timeline: 0
              }],
              sidx: {
                uri: 'http://example.com/audio_en_2c_128k_aac.mp4',
                resolvedUri: 'http://example.com/audio_en_2c_128k_aac.mp4',
                byterange: {
                  length: 224,
                  offset: 786
                },
                map: {
                  uri: '',
                  resolvedUri: 'http://example.com/audio_en_2c_128k_aac.mp4',
                  byterange: {
                    length: 786,
                    offset: 0
                  }
                },
                duration: 60,
                timeline: 0,
                presentationTime: 0,
                number: 0
              }
            }
          ],
          uri: ''
        },
        es: {
          language: 'es',
          autoselect: true,
          default: false,
          playlists: [
            {
              attributes: {
                'NAME': '1',
                'BANDWIDTH': 130405,
                'CODECS': 'mp4a.40.2',
                'PROGRAM-ID': 1,
                'AUDIO': 'audio',
                'SUBTITLES': 'subs'
              },
              uri: '',
              endList: true,
              timeline: 0,
              resolvedUri: '',
              targetDuration: 60,
              segments: [],
              mediaSequence: 0,
              discontinuitySequence: 0,
              discontinuityStarts: [],
              timelineStarts: [{
                start: 0,
                timeline: 0
              }],
              sidx: {
                uri: 'http://example.com/audio_es_2c_128k_aac.mp4',
                resolvedUri: 'http://example.com/audio_es_2c_128k_aac.mp4',
                byterange: {
                  length: 224,
                  offset: 786
                },
                map: {
                  uri: '',
                  resolvedUri: 'http://example.com/audio_es_2c_128k_aac.mp4',
                  byterange: {
                    length: 786,
                    offset: 0
                  }
                },
                duration: 60,
                timeline: 0,
                presentationTime: 0,
                number: 0
              }
            }
          ],
          uri: ''
        }
      }
    },
    'VIDEO': {},
    'CLOSED-CAPTIONS': {},
    'SUBTITLES': {}
  },
  uri: '',
  duration: 60,
  playlists: []
};
