/* eslint-disable no-underscore-dangle */
import { str } from './string';
export function hasDocgen(component) {
  return !!component.__docgenInfo;
}
export function isValidDocgenSection(docgenSection) {
  return docgenSection != null && Object.keys(docgenSection).length > 0;
}
export function getDocgenSection(component, section) {
  return hasDocgen(component) ? component.__docgenInfo[section] : null;
}
export function getDocgenDescription(component) {
  return hasDocgen(component) && str(component.__docgenInfo.description);
}