function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

import React, { useRef, useEffect, useCallback } from 'react';
import { useGlobals, useStorybookApi } from '@storybook/api';
import { createCycleValueArray } from '../utils/create-cycle-value-array';
import { registerShortcuts } from '../utils/register-shortcuts';
export const withKeyboardCycle = Component => {
  const WithKeyboardCycle = props => {
    const {
      id,
      toolbar: {
        items,
        shortcuts
      }
    } = props;
    const api = useStorybookApi();
    const [globals, updateGlobals] = useGlobals();
    const cycleValues = useRef([]);
    const currentValue = globals[id];
    const reset = useCallback(() => {
      updateGlobals({
        [id]: ''
      });
    }, [updateGlobals]);
    const setNext = useCallback(() => {
      const values = cycleValues.current;
      const currentIndex = values.indexOf(currentValue);
      const currentIsLast = currentIndex === values.length - 1;
      const newCurrentIndex = currentIsLast ? 0 : currentIndex + 1;
      const newCurrent = cycleValues.current[newCurrentIndex];
      updateGlobals({
        [id]: newCurrent
      });
    }, [cycleValues, currentValue, updateGlobals]);
    const setPrevious = useCallback(() => {
      const values = cycleValues.current;
      const indexOf = values.indexOf(currentValue);
      const currentIndex = indexOf > -1 ? indexOf : 0;
      const currentIsFirst = currentIndex === 0;
      const newCurrentIndex = currentIsFirst ? values.length - 1 : currentIndex - 1;
      const newCurrent = cycleValues.current[newCurrentIndex];
      updateGlobals({
        [id]: newCurrent
      });
    }, [cycleValues, currentValue, updateGlobals]);
    useEffect(() => {
      if (shortcuts) {
        registerShortcuts(api, id, {
          next: Object.assign({}, shortcuts.next, {
            action: setNext
          }),
          previous: Object.assign({}, shortcuts.previous, {
            action: setPrevious
          }),
          reset: Object.assign({}, shortcuts.reset, {
            action: reset
          })
        });
      }
    }, [api, id, shortcuts, setNext, setPrevious, reset]);
    useEffect(() => {
      cycleValues.current = createCycleValueArray(items);
    }, []);
    return /*#__PURE__*/React.createElement(Component, _extends({
      cycleValues: cycleValues.current
    }, props));
  };

  return WithKeyboardCycle;
};