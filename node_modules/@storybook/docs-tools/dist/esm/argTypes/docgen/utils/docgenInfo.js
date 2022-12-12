import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";

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