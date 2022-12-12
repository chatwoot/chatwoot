function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.reflect.construct.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

import React, { Component } from 'react';
import deepEqual from 'fast-deep-equal';
import { STORY_CHANGED } from '@storybook/core-events';
import { ActionLogger as ActionLoggerComponent } from '../../components/ActionLogger';
import { EVENT_ID } from '../..';

var safeDeepEqual = function safeDeepEqual(a, b) {
  try {
    return deepEqual(a, b);
  } catch (e) {
    return false;
  }
};

var ActionLogger = /*#__PURE__*/function (_Component) {
  _inherits(ActionLogger, _Component);

  var _super = _createSuper(ActionLogger);

  function ActionLogger(props) {
    var _this;

    _classCallCheck(this, ActionLogger);

    _this = _super.call(this, props);
    _this.mounted = void 0;

    _this.handleStoryChange = function () {
      var actions = _this.state.actions;

      if (actions.length > 0 && actions[0].options.clearOnStoryChange) {
        _this.clearActions();
      }
    };

    _this.addAction = function (action) {
      _this.setState(function (prevState) {
        var actions = _toConsumableArray(prevState.actions);

        var previous = actions.length && actions[0];

        if (previous && safeDeepEqual(previous.data, action.data)) {
          previous.count++; // eslint-disable-line
        } else {
          action.count = 1; // eslint-disable-line

          actions.unshift(action);
        }

        return {
          actions: actions.slice(0, action.options.limit)
        };
      });
    };

    _this.clearActions = function () {
      _this.setState({
        actions: []
      });
    };

    _this.state = {
      actions: []
    };
    return _this;
  }

  _createClass(ActionLogger, [{
    key: "componentDidMount",
    value: function componentDidMount() {
      this.mounted = true;
      var api = this.props.api;
      api.on(EVENT_ID, this.addAction);
      api.on(STORY_CHANGED, this.handleStoryChange);
    }
  }, {
    key: "componentWillUnmount",
    value: function componentWillUnmount() {
      this.mounted = false;
      var api = this.props.api;
      api.off(STORY_CHANGED, this.handleStoryChange);
      api.off(EVENT_ID, this.addAction);
    }
  }, {
    key: "render",
    value: function render() {
      var _this$state$actions = this.state.actions,
          actions = _this$state$actions === void 0 ? [] : _this$state$actions;
      var active = this.props.active;
      var props = {
        actions: actions,
        onClear: this.clearActions
      };
      return active ? /*#__PURE__*/React.createElement(ActionLoggerComponent, props) : null;
    }
  }]);

  return ActionLogger;
}(Component);

export { ActionLogger as default };