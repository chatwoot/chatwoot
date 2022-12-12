const _excluded = ["argTypes", "globalTypes", "argTypesEnhancers"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import { inferArgTypes } from '../inferArgTypes';
import { inferControls } from '../inferControls';
import { normalizeInputTypes } from './normalizeInputTypes';
export function normalizeProjectAnnotations(_ref) {
  let {
    argTypes,
    globalTypes,
    argTypesEnhancers
  } = _ref,
      annotations = _objectWithoutPropertiesLoose(_ref, _excluded);

  return Object.assign({}, argTypes && {
    argTypes: normalizeInputTypes(argTypes)
  }, globalTypes && {
    globalTypes: normalizeInputTypes(globalTypes)
  }, {
    argTypesEnhancers: [...(argTypesEnhancers || []), inferArgTypes, // inferControls technically should only run if the user is using the controls addon,
    // and so should be added by a preset there. However, as it seems some code relies on controls
    // annotations (in particular the angular implementation's `cleanArgsDecorator`), for backwards
    // compatibility reasons, we will leave this in the store until 7.0
    inferControls]
  }, annotations);
}