import React from 'react';
var wrapper = {
  fontSize: '14px',
  letterSpacing: '0.2px',
  margin: '10px 0'
};
var main = {
  margin: 'auto',
  padding: 30,
  borderRadius: 10,
  background: 'rgba(0,0,0,0.03)'
};
var heading = {
  textAlign: 'center'
};
export var NoDocs = function NoDocs() {
  return /*#__PURE__*/React.createElement("div", {
    style: wrapper,
    className: "sb-nodocs sb-wrapper"
  }, /*#__PURE__*/React.createElement("div", {
    style: main
  }, /*#__PURE__*/React.createElement("h1", {
    style: heading
  }, "No Docs"), /*#__PURE__*/React.createElement("p", null, "Sorry, but there are no docs for the selected story. To add them, set the story's\xA0", /*#__PURE__*/React.createElement("code", null, "docs"), " parameter. If you think this is an error:"), /*#__PURE__*/React.createElement("ul", null, /*#__PURE__*/React.createElement("li", null, "Please check the story definition."), /*#__PURE__*/React.createElement("li", null, "Please check the Storybook config."), /*#__PURE__*/React.createElement("li", null, "Try reloading the page.")), /*#__PURE__*/React.createElement("p", null, "If the problem persists, check the browser console, or the terminal you've run Storybook from.")));
};
NoDocs.displayName = "NoDocs";