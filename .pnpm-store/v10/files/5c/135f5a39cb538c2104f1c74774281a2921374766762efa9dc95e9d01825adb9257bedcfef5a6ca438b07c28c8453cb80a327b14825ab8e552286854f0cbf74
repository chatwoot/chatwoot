export const workerCallback = function(options) {
  const transmuxer = options.transmuxer;
  const endAction = options.endAction || options.action;
  const callback = options.callback;
  const message = Object.assign({}, options, {endAction: null, transmuxer: null, callback: null});

  const listenForEndEvent = (event) => {
    if (event.data.action !== endAction) {
      return;
    }
    transmuxer.removeEventListener('message', listenForEndEvent);

    // transfer ownership of bytes back to us.
    if (event.data.data) {
      event.data.data = new Uint8Array(
        event.data.data,
        options.byteOffset || 0,
        options.byteLength || event.data.data.byteLength
      );
      if (options.data) {
        options.data = event.data.data;
      }
    }

    callback(event.data);
  };

  transmuxer.addEventListener('message', listenForEndEvent);

  if (options.data) {
    const isArrayBuffer = options.data instanceof ArrayBuffer;

    message.byteOffset = isArrayBuffer ? 0 : options.data.byteOffset;
    message.byteLength = options.data.byteLength;

    const transfers = [isArrayBuffer ? options.data : options.data.buffer];

    transmuxer.postMessage(message, transfers);
  } else {
    transmuxer.postMessage(message);
  }
};
