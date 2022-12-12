import React from 'react';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { ArgsTable } from './ArgsTable';
import { CURRENT_SELECTION } from './types';
export const Props = deprecate(props => /*#__PURE__*/React.createElement(ArgsTable, props), dedent`
    Props doc block has been renamed to ArgsTable.

    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#previewprops-renamed
  `); // @ts-ignore

Props.defaultProps = {
  of: CURRENT_SELECTION
};