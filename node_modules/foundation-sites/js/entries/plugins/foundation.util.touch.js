import $ from 'jquery';

import { Touch } from '../../foundation.util.touch';

Touch.init($);

window.Foundation.Touch = Touch;

export { Foundation } from './foundation.core';
export { Touch };
