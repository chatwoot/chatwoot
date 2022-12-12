module.exports = {
  allowCache: true,
  mediaSequence: 0,
  playlistType: 'VOD',
  segments: [
    {
      duration: 10,
      timeline: 0,
      uri: 'http://example.com/00001.ts'
    },
    {
      duration: 10,
      timeline: 0,
      uri: 'https://example.com/00002.ts'
    },
    {
      duration: 10,
      timeline: 0,
      uri: '//example.com/00003.ts'
    },
    {
      duration: 10,
      timeline: 0,
      uri: 'http://example.com/00004.ts'
    }
  ],
  targetDuration: 10,
  endList: true,
  discontinuitySequence: 0,
  discontinuityStarts: []
};
