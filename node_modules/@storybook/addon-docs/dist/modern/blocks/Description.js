import React, { useContext } from 'react';
import { Description } from '@storybook/components';
import { str } from '@storybook/docs-tools';
import { DocsContext } from './DocsContext';
import { CURRENT_SELECTION } from './types';
export let DescriptionType;

(function (DescriptionType) {
  DescriptionType["INFO"] = "info";
  DescriptionType["NOTES"] = "notes";
  DescriptionType["DOCGEN"] = "docgen";
  DescriptionType["LEGACY_5_2"] = "legacy-5.2";
  DescriptionType["AUTO"] = "auto";
})(DescriptionType || (DescriptionType = {}));

const getNotes = notes => notes && (typeof notes === 'string' ? notes : str(notes.markdown) || str(notes.text));

const getInfo = info => info && (typeof info === 'string' ? info : str(info.text));

const noDescription = component => null;

export const getDescriptionProps = ({
  of,
  type,
  markdown,
  children
}, {
  id,
  storyById
}) => {
  const {
    component,
    parameters
  } = storyById(id);

  if (children || markdown) {
    return {
      markdown: children || markdown
    };
  }

  const {
    notes,
    info,
    docs
  } = parameters;
  const {
    extractComponentDescription = noDescription,
    description
  } = docs || {};
  const target = of === CURRENT_SELECTION ? component : of; // override component description

  const componentDescriptionParameter = description === null || description === void 0 ? void 0 : description.component;

  if (componentDescriptionParameter) {
    return {
      markdown: componentDescriptionParameter
    };
  }

  switch (type) {
    case DescriptionType.INFO:
      return {
        markdown: getInfo(info)
      };

    case DescriptionType.NOTES:
      return {
        markdown: getNotes(notes)
      };
    // FIXME: remove in 6.0

    case DescriptionType.LEGACY_5_2:
      return {
        markdown: `
${getNotes(notes) || getInfo(info) || ''}

${extractComponentDescription(target) || ''}
`.trim()
      };

    case DescriptionType.DOCGEN:
    case DescriptionType.AUTO:
    default:
      return {
        markdown: extractComponentDescription(target, Object.assign({
          component
        }, parameters))
      };
  }
};

const DescriptionContainer = props => {
  const context = useContext(DocsContext);
  const {
    markdown
  } = getDescriptionProps(props, context);
  return markdown ? /*#__PURE__*/React.createElement(Description, {
    markdown: markdown
  }) : null;
}; // since we are in the docs blocks, assume default description if for primary component story


DescriptionContainer.defaultProps = {
  of: '.'
};
export { DescriptionContainer as Description };