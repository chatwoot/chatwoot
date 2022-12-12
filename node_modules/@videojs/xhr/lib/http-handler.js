"use strict";

var window = require('global/window');

var httpResponseHandler = function httpResponseHandler(callback, decodeResponseBody) {
  if (decodeResponseBody === void 0) {
    decodeResponseBody = false;
  }

  return function (err, response, responseBody) {
    // if the XHR failed, return that error
    if (err) {
      callback(err);
      return;
    } // if the HTTP status code is 4xx or 5xx, the request also failed


    if (response.statusCode >= 400 && response.statusCode <= 599) {
      var cause = responseBody;

      if (decodeResponseBody) {
        if (window.TextDecoder) {
          var charset = getCharset(response.headers && response.headers['content-type']);

          try {
            cause = new TextDecoder(charset).decode(responseBody);
          } catch (e) {}
        } else {
          cause = String.fromCharCode.apply(null, new Uint8Array(responseBody));
        }
      }

      callback({
        cause: cause
      });
      return;
    } // otherwise, request succeeded


    callback(null, responseBody);
  };
};

function getCharset(contentTypeHeader) {
  if (contentTypeHeader === void 0) {
    contentTypeHeader = '';
  }

  return contentTypeHeader.toLowerCase().split(';').reduce(function (charset, contentType) {
    var _contentType$split = contentType.split('='),
        type = _contentType$split[0],
        value = _contentType$split[1];

    if (type.trim() === 'charset') {
      return value.trim();
    }

    return charset;
  }, 'utf-8');
}

module.exports = httpResponseHandler;