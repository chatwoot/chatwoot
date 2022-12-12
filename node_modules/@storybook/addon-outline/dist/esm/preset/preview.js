function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import { withOutline } from '../withOutline';
import { PARAM_KEY } from '../constants';
export var decorators = [withOutline];
export var globals = _defineProperty({}, PARAM_KEY, false);