'use strict';
const symbolObservable = require('symbol-observable').default;

module.exports = value => Boolean(value && value[symbolObservable] && value === value[symbolObservable]());
