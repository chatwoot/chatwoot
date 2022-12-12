/**
 * Returns array of valid input type values
 * @method validInputTypes
 * @memberof axe.utils
 * @return {Array<Sting>}
 */
function validInputTypes() {
  // Reference - https://html.spec.whatwg.org/multipage/input.html#the-input-element
  return [
    'hidden',
    'text',
    'search',
    'tel',
    'url',
    'email',
    'password',
    'date',
    'month',
    'week',
    'time',
    'datetime-local',
    'number',
    'range',
    'color',
    'checkbox',
    'radio',
    'file',
    'submit',
    'image',
    'reset',
    'button'
  ];
}

export default validInputTypes;
