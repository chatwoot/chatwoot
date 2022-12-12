const _excluded = ["type", "control"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import mapValues from 'lodash/mapValues';

const normalizeType = type => {
  return typeof type === 'string' ? {
    name: type
  } : type;
};

const normalizeControl = control => typeof control === 'string' ? {
  type: control
} : control;

export const normalizeInputType = (inputType, key) => {
  const {
    type,
    control
  } = inputType,
        rest = _objectWithoutPropertiesLoose(inputType, _excluded);

  const normalized = Object.assign({
    name: key
  }, rest);
  if (type) normalized.type = normalizeType(type);

  if (control) {
    normalized.control = normalizeControl(control);
  } else if (control === false) {
    normalized.control = {
      disable: true
    };
  }

  return normalized;
};
export const normalizeInputTypes = inputTypes => mapValues(inputTypes, normalizeInputType);