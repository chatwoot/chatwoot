import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.find.js";
import mergeWith from 'lodash/mergeWith';
import isEqual from 'lodash/isEqual';
import { logger } from '@storybook/client-logger';
export default (function (a, b) {
  return mergeWith({}, a, b, function (objValue, srcValue) {
    if (Array.isArray(srcValue) && Array.isArray(objValue)) {
      srcValue.forEach(function (s) {
        var existing = objValue.find(function (o) {
          return o === s || isEqual(o, s);
        });

        if (!existing) {
          objValue.push(s);
        }
      });
      return objValue;
    }

    if (Array.isArray(objValue)) {
      logger.log(['the types mismatch, picking', objValue]);
      return objValue;
    }

    return undefined;
  });
});