import { withMeasure } from './withMeasure';
import { PARAM_KEY } from './constants';
export const decorators = [withMeasure];
export const globals = {
  [PARAM_KEY]: false
};