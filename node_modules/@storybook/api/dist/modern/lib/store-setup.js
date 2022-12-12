/* eslint-disable no-underscore-dangle */

/* eslint-disable func-names */
import { parse, stringify } from 'telejson'; // setting up the store, overriding set and get to use telejson

export default (_ => {
  _.fn('set', function (key, data) {
    return _.set(this._area, this._in(key), stringify(data, {
      maxDepth: 50
    }));
  });

  _.fn('get', function (key, alt) {
    const value = _.get(this._area, this._in(key));

    return value !== null ? parse(value) : alt || value;
  });
});