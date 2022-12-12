"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Page = void 0;

var _react = _interopRequireDefault(require("react"));

var _Header = require("./Header");

require("./page.css");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

const Page = () => {
  const [user, setUser] = _react.default.useState();

  return /*#__PURE__*/_react.default.createElement("article", null, /*#__PURE__*/_react.default.createElement(_Header.Header, {
    user: user,
    onLogin: () => setUser({
      name: 'Jane Doe'
    }),
    onLogout: () => setUser(undefined),
    onCreateAccount: () => setUser({
      name: 'Jane Doe'
    })
  }), /*#__PURE__*/_react.default.createElement("section", null, /*#__PURE__*/_react.default.createElement("h2", null, "Pages in Storybook"), /*#__PURE__*/_react.default.createElement("p", null, "We recommend building UIs with a", ' ', /*#__PURE__*/_react.default.createElement("a", {
    href: "https://componentdriven.org",
    target: "_blank",
    rel: "noopener noreferrer"
  }, /*#__PURE__*/_react.default.createElement("strong", null, "component-driven")), ' ', "process starting with atomic components and ending with pages."), /*#__PURE__*/_react.default.createElement("p", null, "Render pages with mock data. This makes it easy to build and review page states without needing to navigate to them in your app. Here are some handy patterns for managing page data in Storybook:"), /*#__PURE__*/_react.default.createElement("ul", null, /*#__PURE__*/_react.default.createElement("li", null, "Use a higher-level connected component. Storybook helps you compose such data from the \"args\" of child component stories"), /*#__PURE__*/_react.default.createElement("li", null, "Assemble data in the page component from your services. You can mock these services out using Storybook.")), /*#__PURE__*/_react.default.createElement("p", null, "Get a guided tutorial on component-driven development at", ' ', /*#__PURE__*/_react.default.createElement("a", {
    href: "https://storybook.js.org/tutorials/",
    target: "_blank",
    rel: "noopener noreferrer"
  }, "Storybook tutorials"), ". Read more in the", ' ', /*#__PURE__*/_react.default.createElement("a", {
    href: "https://storybook.js.org/docs",
    target: "_blank",
    rel: "noopener noreferrer"
  }, "docs"), "."), /*#__PURE__*/_react.default.createElement("div", {
    className: "tip-wrapper"
  }, /*#__PURE__*/_react.default.createElement("span", {
    className: "tip"
  }, "Tip"), " Adjust the width of the canvas with the", ' ', /*#__PURE__*/_react.default.createElement("svg", {
    width: "10",
    height: "10",
    viewBox: "0 0 12 12",
    xmlns: "http://www.w3.org/2000/svg"
  }, /*#__PURE__*/_react.default.createElement("g", {
    fill: "none",
    fillRule: "evenodd"
  }, /*#__PURE__*/_react.default.createElement("path", {
    d: "M1.5 5.2h4.8c.3 0 .5.2.5.4v5.1c-.1.2-.3.3-.4.3H1.4a.5.5 0 01-.5-.4V5.7c0-.3.2-.5.5-.5zm0-2.1h6.9c.3 0 .5.2.5.4v7a.5.5 0 01-1 0V4H1.5a.5.5 0 010-1zm0-2.1h9c.3 0 .5.2.5.4v9.1a.5.5 0 01-1 0V2H1.5a.5.5 0 010-1zm4.3 5.2H2V10h3.8V6.2z",
    id: "a",
    fill: "#999"
  }))), "Viewports addon in the toolbar")));
};

exports.Page = Page;