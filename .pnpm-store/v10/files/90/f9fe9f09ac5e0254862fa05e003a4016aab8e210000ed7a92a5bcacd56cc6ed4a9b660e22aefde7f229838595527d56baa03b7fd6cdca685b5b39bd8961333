// https://tonicdev.com/npm/recordrtc

var RecordRTC;

try {
    RecordRTC = require('recordrtc');
}
catch(e) {
    RecordRTC = require('./RecordRTC.js');
}

console.log('RecordRTC => ', Object.keys(RecordRTC));

var recorder = RecordRTC({}, {
    type: 'video',
    recorderType: RecordRTC.WhammyRecorder
});

recorder.startRecording();

process.exit()
