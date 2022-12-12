/* global commons */
/*eslint no-unused-vars: 0*/

/**
 * Namespace for axe common methods.
 * @namespace commons
 * @memberof axe
 */
import * as aria from './aria';
import * as color from './color';
import * as dom from './dom';
import * as forms from './forms';
import matches from './matches';
import * as standards from './standards';
import * as table from './table';
import * as text from './text';
import * as utils from '../core/utils';

var commons = {
  aria,
  color,
  dom,
  forms,
  matches,
  standards,
  table,
  text,
  utils
};

export { aria, color, dom, forms, matches, standards, table, text, utils };
