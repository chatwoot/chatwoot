import React from 'react';
import { Title } from './Title';
import { Subtitle } from './Subtitle';
import { Description } from './Description';
import { Primary } from './Primary';
import { PRIMARY_STORY } from './types';
import { ArgsTable } from './ArgsTable';
import { Stories } from './Stories';
export const DocsPage = () => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Title, null), /*#__PURE__*/React.createElement(Subtitle, null), /*#__PURE__*/React.createElement(Description, null), /*#__PURE__*/React.createElement(Primary, null), /*#__PURE__*/React.createElement(ArgsTable, {
  story: PRIMARY_STORY
}), /*#__PURE__*/React.createElement(Stories, null));