'use strict';
require('../register')('rxjs/Observable', {Observable: require('rxjs/Observable').Observable});
require('rxjs/add/observable/of'); // eslint-disable-line import/no-unassigned-import
require('rxjs/add/observable/from'); // eslint-disable-line import/no-unassigned-import
