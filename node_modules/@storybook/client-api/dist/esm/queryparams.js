import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.search.js";
import global from 'global';
import { parse } from 'qs';
var document = global.document;
export var getQueryParams = function getQueryParams() {
  // document.location is not defined in react-native
  if (document && document.location && document.location.search) {
    return parse(document.location.search, {
      ignoreQueryPrefix: true
    });
  }

  return {};
};
export var getQueryParam = function getQueryParam(key) {
  var params = getQueryParams();
  return params[key];
};