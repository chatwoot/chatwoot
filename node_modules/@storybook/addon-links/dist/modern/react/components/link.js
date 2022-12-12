const _excluded = ["kind", "story", "children"];

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import React, { PureComponent } from 'react';
import { navigate, hrefTo } from '../../utils'; // FIXME: copied from Typography.Link. Code is duplicated to
// avoid emotion dependency which breaks React 15.x back-compat
// Cmd/Ctrl/Shift/Alt + Click should trigger default browser behaviour. Same applies to non-left clicks

const LEFT_BUTTON = 0;

const isPlainLeftClick = e => e.button === LEFT_BUTTON && !e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey;

const cancelled = (e, cb = _e => {}) => {
  if (isPlainLeftClick(e)) {
    e.preventDefault();
    cb(e);
  }
};

export default class LinkTo extends PureComponent {
  constructor(...args) {
    super(...args);
    this.state = {
      href: '/'
    };

    this.updateHref = async () => {
      const {
        kind,
        story
      } = this.props;
      const href = await hrefTo(kind, story);
      this.setState({
        href
      });
    };

    this.handleClick = () => {
      navigate(this.props);
    };
  }

  componentDidMount() {
    this.updateHref();
  }

  componentDidUpdate(prevProps) {
    const {
      kind,
      story
    } = this.props;

    if (prevProps.kind !== kind || prevProps.story !== story) {
      this.updateHref();
    }
  }

  render() {
    const _this$props = this.props,
          {
      children
    } = _this$props,
          rest = _objectWithoutPropertiesLoose(_this$props, _excluded);

    const {
      href
    } = this.state;
    return /*#__PURE__*/React.createElement("a", _extends({
      href: href,
      onClick: e => cancelled(e, this.handleClick)
    }, rest), children);
  }

}
LinkTo.defaultProps = {
  kind: null,
  story: null,
  children: undefined
};