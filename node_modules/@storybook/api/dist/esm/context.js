import { createContext as ReactCreateContext } from 'react';
export var createContext = function createContext(_ref) {
  var api = _ref.api,
      state = _ref.state;
  return /*#__PURE__*/ReactCreateContext({
    api: api,
    state: state
  });
};