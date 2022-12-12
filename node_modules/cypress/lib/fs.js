"use strict";

var Promise = require('bluebird');

module.exports = Promise.promisifyAll(require('fs-extra'));