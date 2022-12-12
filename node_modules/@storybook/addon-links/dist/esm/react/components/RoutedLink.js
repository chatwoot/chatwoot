import React from 'react'; // NOTE: this is a copy of `lib/components/src/navigation/RoutedLink.tsx`.
// It's duplicated here because that copy has an explicit dependency on
// React 16.3+, which breaks older versions of React running in the preview.
// The proper DRY solution is to create a new package that doesn't depend
// on a specific react version. However, that's a heavy-handed solution for
// one trivial file.

var LEFT_BUTTON = 0; // Cmd/Ctrl/Shift/Alt + Click should trigger default browser behaviour. Same applies to non-left clicks

var isPlainLeftClick = function isPlainLeftClick(e) {
  return e.button === LEFT_BUTTON && !e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey;
};

var RoutedLink = function RoutedLink(_ref) {
  var _ref$href = _ref.href,
      href = _ref$href === void 0 ? '#' : _ref$href,
      children = _ref.children,
      onClick = _ref.onClick,
      className = _ref.className,
      style = _ref.style;

  var handleClick = function handleClick(e) {
    if (isPlainLeftClick(e)) {
      e.preventDefault();
      onClick(e);
    }
  };

  var props = onClick ? {
    href: href,
    className: className,
    style: style,
    onClick: handleClick
  } : {
    href: href,
    className: className,
    style: style
  };
  return /*#__PURE__*/React.createElement("a", props, children);
};

export default RoutedLink;