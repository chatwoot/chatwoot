import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.string.trim.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.object.assign.js";
import React, { useContext } from 'react';
import { Description } from '@storybook/components';
import { str } from '@storybook/docs-tools';
import { DocsContext } from './DocsContext';
import { CURRENT_SELECTION } from './types';
export var DescriptionType;

(function (DescriptionType) {
  DescriptionType["INFO"] = "info";
  DescriptionType["NOTES"] = "notes";
  DescriptionType["DOCGEN"] = "docgen";
  DescriptionType["LEGACY_5_2"] = "legacy-5.2";
  DescriptionType["AUTO"] = "auto";
})(DescriptionType || (DescriptionType = {}));

var getNotes = function getNotes(notes) {
  return notes && (typeof notes === 'string' ? notes : str(notes.markdown) || str(notes.text));
};

var getInfo = function getInfo(info) {
  return info && (typeof info === 'string' ? info : str(info.text));
};

var noDescription = function noDescription(component) {
  return null;
};

export var getDescriptionProps = function getDescriptionProps(_ref, _ref2) {
  var of = _ref.of,
      type = _ref.type,
      markdown = _ref.markdown,
      children = _ref.children;
  var id = _ref2.id,
      storyById = _ref2.storyById;

  var _storyById = storyById(id),
      component = _storyById.component,
      parameters = _storyById.parameters;

  if (children || markdown) {
    return {
      markdown: children || markdown
    };
  }

  var notes = parameters.notes,
      info = parameters.info,
      docs = parameters.docs;

  var _ref3 = docs || {},
      _ref3$extractComponen = _ref3.extractComponentDescription,
      extractComponentDescription = _ref3$extractComponen === void 0 ? noDescription : _ref3$extractComponen,
      description = _ref3.description;

  var target = of === CURRENT_SELECTION ? component : of; // override component description

  var componentDescriptionParameter = description === null || description === void 0 ? void 0 : description.component;

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
        markdown: "\n".concat(getNotes(notes) || getInfo(info) || '', "\n\n").concat(extractComponentDescription(target) || '', "\n").trim()
      };

    case DescriptionType.DOCGEN:
    case DescriptionType.AUTO:
    default:
      return {
        markdown: extractComponentDescription(target, Object.assign({
          component: component
        }, parameters))
      };
  }
};

var DescriptionContainer = function DescriptionContainer(props) {
  var context = useContext(DocsContext);

  var _getDescriptionProps = getDescriptionProps(props, context),
      markdown = _getDescriptionProps.markdown;

  return markdown ? /*#__PURE__*/React.createElement(Description, {
    markdown: markdown
  }) : null;
}; // since we are in the docs blocks, assume default description if for primary component story


DescriptionContainer.defaultProps = {
  of: '.'
};
export { DescriptionContainer as Description };