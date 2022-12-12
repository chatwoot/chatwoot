import { labelVirtual, accessibleText, sanitize } from '../../commons/text';
import { idrefs } from '../../commons/dom';

function helpSameAsLabelEvaluate(node, options, virtualNode) {
  var labelText = labelVirtual(virtualNode),
    check = node.getAttribute('title');

  if (!labelText) {
    return false;
  }

  if (!check) {
    check = '';

    if (node.getAttribute('aria-describedby')) {
      var ref = idrefs(node, 'aria-describedby');
      check = ref
        .map(thing => {
          return thing ? accessibleText(thing) : '';
        })
        .join('');
    }
  }

  return sanitize(check) === sanitize(labelText);
}

export default helpSameAsLabelEvaluate;
