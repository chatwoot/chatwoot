import { sanitize } from '../commons/text';
import standards from '../standards';
import { isVisible } from '../commons/dom';

function autocompleteMatches(node, virtualNode) {
  const autocomplete = virtualNode.attr('autocomplete');
  if (!autocomplete || sanitize(autocomplete) === '') {
    return false;
  }

  const nodeName = virtualNode.props.nodeName;
  if (['textarea', 'input', 'select'].includes(nodeName) === false) {
    return false;
  }

  // The element is an `input` element a `type` of `hidden`, `button`, `submit` or `reset`
  const excludedInputTypes = ['submit', 'reset', 'button', 'hidden'];
  if (
    nodeName === 'input' &&
    excludedInputTypes.includes(virtualNode.props.type)
  ) {
    return false;
  }

  // The element has a `disabled` or `aria-disabled="true"` attribute
  const ariaDisabled = virtualNode.attr('aria-disabled') || 'false';
  if (
    virtualNode.hasAttr('disabled') ||
    ariaDisabled.toLowerCase() === 'true'
  ) {
    return false;
  }

  // The element has `tabindex="-1"` and has a [[semantic role]] that is
  //   not a [widget](https://www.w3.org/TR/wai-aria-1.1/#widget_roles)
  const role = virtualNode.attr('role');
  const tabIndex = virtualNode.attr('tabindex');
  if (tabIndex === '-1' && role) {
    const roleDef = standards.ariaRoles[role];
    if (roleDef === undefined || roleDef.type !== 'widget') {
      return false;
    }
  }

  // The element is **not** visible on the page or exposed to assistive technologies
  if (
    tabIndex === '-1' &&
    virtualNode.actualNode &&
    !isVisible(virtualNode.actualNode, false) &&
    !isVisible(virtualNode.actualNode, true)
  ) {
    return false;
  }

  return true;
}

export default autocompleteMatches;
