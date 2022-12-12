"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = exports.LoggedOut = exports.LoggedIn = void 0;

var _react = _interopRequireDefault(require("react"));

var _testingLibrary = require("@storybook/testing-library");

var _Page = require("./Page");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = {
  title: 'Example/Page',
  component: _Page.Page,
  parameters: {
    // More on Story layout: https://storybook.js.org/docs/react/configure/story-layout
    layout: 'fullscreen'
  }
};
exports.default = _default;

const Template = args => /*#__PURE__*/_react.default.createElement(_Page.Page, args);

const LoggedOut = Template.bind({});
exports.LoggedOut = LoggedOut;
const LoggedIn = Template.bind({}); // More on interaction testing: https://storybook.js.org/docs/react/writing-tests/interaction-testing

exports.LoggedIn = LoggedIn;

LoggedIn.play = async ({
  canvasElement
}) => {
  const canvas = (0, _testingLibrary.within)(canvasElement);
  const loginButton = await canvas.getByRole('button', {
    name: /Log in/i
  });
  await _testingLibrary.userEvent.click(loginButton);
};