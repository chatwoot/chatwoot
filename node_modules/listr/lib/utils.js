'use strict';
const isStream = require('is-stream');

// RxJS@6 symbol (https://github.com/sindresorhus/is-observable/issues/1#issuecomment-387843191)
const symbolObservable = typeof Symbol === 'function' && Symbol.observable || '@@observable';		// eslint-disable-line no-mixed-operators

const isObservable = obj => Boolean(obj && obj[symbolObservable] && obj === obj[symbolObservable]()) || require('is-observable')(obj);

exports.isListr = obj => Boolean(obj && obj.setRenderer && obj.add && obj.run);
exports.isObservable = obj => isObservable(obj);
exports.isStream = obj => isStream(obj) && !isObservable(obj);
