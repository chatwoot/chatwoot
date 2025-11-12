import {getId3Offset} from '@videojs/vhs-utils/es/id3-helpers';
import {detectContainerForBytes} from '@videojs/vhs-utils/es/containers';
import {stringToBytes, concatTypedArrays} from '@videojs/vhs-utils/es/byte-helpers';
import {callbackWrapper} from '../xhr';

// calls back if the request is readyState DONE
// which will only happen if the request is complete.
const callbackOnCompleted = (request, cb) => {
  if (request.readyState === 4) {
    return cb();
  }
  return;
};

const containerRequest = (uri, xhr, cb) => {
  let bytes = [];
  let id3Offset;
  let finished = false;

  const endRequestAndCallback = function(err, req, type, _bytes) {
    req.abort();
    finished = true;
    return cb(err, req, type, _bytes);
  };

  const progressListener = function(error, request) {
    if (finished) {
      return;
    }
    if (error) {
      return endRequestAndCallback(error, request, '', bytes);
    }

    // grap the new part of content that was just downloaded
    const newPart = request.responseText.substring(
      bytes && bytes.byteLength || 0,
      request.responseText.length
    );

    // add that onto bytes
    bytes = concatTypedArrays(bytes, stringToBytes(newPart, true));
    id3Offset = id3Offset || getId3Offset(bytes);

    // we need at least 10 bytes to determine a type
    // or we need at least two bytes after an id3Offset
    if (bytes.length < 10 || (id3Offset && bytes.length < id3Offset + 2)) {
      return callbackOnCompleted(request, () => endRequestAndCallback(error, request, '', bytes));
    }

    const type = detectContainerForBytes(bytes);

    // if this looks like a ts segment but we don't have enough data
    // to see the second sync byte, wait until we have enough data
    // before declaring it ts
    if (type === 'ts' && bytes.length < 188) {
      return callbackOnCompleted(request, () => endRequestAndCallback(error, request, '', bytes));
    }

    // this may be an unsynced ts segment
    // wait for 376 bytes before detecting no container
    if (!type && bytes.length < 376) {
      return callbackOnCompleted(request, () => endRequestAndCallback(error, request, '', bytes));
    }

    return endRequestAndCallback(null, request, type, bytes);
  };

  const options = {
    uri,
    beforeSend(request) {
      // this forces the browser to pass the bytes to us unprocessed
      request.overrideMimeType('text/plain; charset=x-user-defined');
      request.addEventListener('progress', function({total, loaded}) {
        return callbackWrapper(request, null, {statusCode: request.status}, progressListener);
      });
    }
  };

  const request = xhr(options, function(error, response) {
    return callbackWrapper(request, error, response, progressListener);
  });

  return request;
};

export default containerRequest;
