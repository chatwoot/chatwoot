var mp2t, metadataStream;

mp2t = require('../lib/m2ts');
metadataStream = new mp2t.MetadataStream();

self.addEventListener('message', function(e) {
  metadataStream.on('data', function(data) {
    self.postMessage(data);
  });
  metadataStream.push(e.data);
});
