function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import { withMeasure } from './withMeasure';
import { PARAM_KEY } from './constants';
export var decorators = [withMeasure];
export var globals = _defineProperty({}, PARAM_KEY, false);