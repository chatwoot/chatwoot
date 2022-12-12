import { getRole, arialabelText, arialabelledbyText } from '../commons/aria';
import {
  getAriaRolesSupportingNameFromContent,
  getAriaRolesByType
} from '../commons/standards';
import { sanitize, visibleVirtual } from '../commons/text';

function labelContentNameMismatchMatches(node, virtualNode) {
  /**
   * Applicability:
   * Rule applies to any element that has
   * a) a semantic role that is `widget` that supports name from content
   * b) has visible text content
   * c) has accessible name (eg: `aria-label`)
   */
  const role = getRole(node);
  if (!role) {
    return false;
  }

  const widgetRoles = getAriaRolesByType('widget');
  const isWidgetType = widgetRoles.includes(role);
  if (!isWidgetType) {
    return false;
  }

  const rolesWithNameFromContents = getAriaRolesSupportingNameFromContent();
  if (!rolesWithNameFromContents.includes(role)) {
    return false;
  }

  /**
   * if no `aria-label` or `aria-labelledby` attribute - ignore `node`
   */
  if (
    !sanitize(arialabelText(virtualNode)) &&
    !sanitize(arialabelledbyText(node))
  ) {
    return false;
  }

  /**
   * if no `contentText` - ignore `node`
   */
  if (!sanitize(visibleVirtual(virtualNode))) {
    return false;
  }

  return true;
}

export default labelContentNameMismatchMatches;
