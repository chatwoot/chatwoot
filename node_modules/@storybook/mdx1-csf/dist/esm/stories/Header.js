import React from 'react';
import { Button } from './Button';
import './header.css';
export const Header = ({
  user,
  onLogin,
  onLogout,
  onCreateAccount
}) => /*#__PURE__*/React.createElement("header", null, /*#__PURE__*/React.createElement("div", {
  className: "wrapper"
}, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("svg", {
  width: "32",
  height: "32",
  viewBox: "0 0 32 32",
  xmlns: "http://www.w3.org/2000/svg"
}, /*#__PURE__*/React.createElement("g", {
  fill: "none",
  fillRule: "evenodd"
}, /*#__PURE__*/React.createElement("path", {
  d: "M10 0h12a10 10 0 0110 10v12a10 10 0 01-10 10H10A10 10 0 010 22V10A10 10 0 0110 0z",
  fill: "#FFF"
}), /*#__PURE__*/React.createElement("path", {
  d: "M5.3 10.6l10.4 6v11.1l-10.4-6v-11zm11.4-6.2l9.7 5.5-9.7 5.6V4.4z",
  fill: "#555AB9"
}), /*#__PURE__*/React.createElement("path", {
  d: "M27.2 10.6v11.2l-10.5 6V16.5l10.5-6zM15.7 4.4v11L6 10l9.7-5.5z",
  fill: "#91BAF8"
}))), /*#__PURE__*/React.createElement("h1", null, "Acme")), /*#__PURE__*/React.createElement("div", null, user ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
  className: "welcome"
}, "Welcome, ", /*#__PURE__*/React.createElement("b", null, user.name), "!"), /*#__PURE__*/React.createElement(Button, {
  size: "small",
  onClick: onLogout,
  label: "Log out"
})) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Button, {
  size: "small",
  onClick: onLogin,
  label: "Log in"
}), /*#__PURE__*/React.createElement(Button, {
  primary: true,
  size: "small",
  onClick: onCreateAccount,
  label: "Sign up"
})))));