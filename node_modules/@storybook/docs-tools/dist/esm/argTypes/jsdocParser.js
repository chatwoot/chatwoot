import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.join.js";
import doctrine from 'doctrine';

function containsJsDoc(value) {
  return value != null && value.includes('@');
}

function parse(content, tags) {
  var ast;

  try {
    ast = doctrine.parse(content, {
      tags: tags,
      sloppy: true
    });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    throw new Error('Cannot parse JSDoc tags.');
  }

  return ast;
}

var DEFAULT_OPTIONS = {
  tags: ['param', 'arg', 'argument', 'returns', 'ignore']
};
export var parseJsDoc = function parseJsDoc(value) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : DEFAULT_OPTIONS;

  if (!containsJsDoc(value)) {
    return {
      includesJsDoc: false,
      ignore: false
    };
  }

  var jsDocAst = parse(value, options.tags);
  var extractedTags = extractJsDocTags(jsDocAst);

  if (extractedTags.ignore) {
    // There is no point in doing other stuff since this prop will not be rendered.
    return {
      includesJsDoc: true,
      ignore: true
    };
  }

  return {
    includesJsDoc: true,
    ignore: false,
    // Always use the parsed description to ensure JSDoc is removed from the description.
    description: jsDocAst.description,
    extractedTags: extractedTags
  };
};

function extractJsDocTags(ast) {
  var extractedTags = {
    params: null,
    returns: null,
    ignore: false
  };

  for (var i = 0; i < ast.tags.length; i += 1) {
    var tag = ast.tags[i];

    if (tag.title === 'ignore') {
      extractedTags.ignore = true; // Once we reach an @ignore tag, there is no point in parsing the other tags since we will not render the prop.

      break;
    } else {
      switch (tag.title) {
        // arg & argument are aliases for param.
        case 'param':
        case 'arg':
        case 'argument':
          {
            var paramTag = extractParam(tag);

            if (paramTag != null) {
              if (extractedTags.params == null) {
                extractedTags.params = [];
              }

              extractedTags.params.push(paramTag);
            }

            break;
          }

        case 'returns':
          {
            var returnsTag = extractReturns(tag);

            if (returnsTag != null) {
              extractedTags.returns = returnsTag;
            }

            break;
          }

        default:
          break;
      }
    }
  }

  return extractedTags;
}

function extractParam(tag) {
  var paramName = tag.name; // When the @param doesn't have a name but have a type and a description, "null-null" is returned.

  if (paramName != null && paramName !== 'null-null') {
    return {
      name: tag.name,
      type: tag.type,
      description: tag.description,
      getPrettyName: function getPrettyName() {
        if (paramName.includes('null')) {
          // There is a few cases in which the returned param name contains "null".
          // - @param {SyntheticEvent} event- Original SyntheticEvent
          // - @param {SyntheticEvent} event.\n@returns {string}
          return paramName.replace('-null', '').replace('.null', '');
        }

        return tag.name;
      },
      getTypeName: function getTypeName() {
        return tag.type != null ? extractTypeName(tag.type) : null;
      }
    };
  }

  return null;
}

function extractReturns(tag) {
  if (tag.type != null) {
    return {
      type: tag.type,
      description: tag.description,
      getTypeName: function getTypeName() {
        return extractTypeName(tag.type);
      }
    };
  }

  return null;
}

function extractTypeName(type) {
  if (type.type === 'NameExpression') {
    return type.name;
  }

  if (type.type === 'RecordType') {
    var recordFields = type.fields.map(function (field) {
      if (field.value != null) {
        var valueTypeName = extractTypeName(field.value);
        return "".concat(field.key, ": ").concat(valueTypeName);
      }

      return field.key;
    });
    return "({".concat(recordFields.join(', '), "})");
  }

  if (type.type === 'UnionType') {
    var unionElements = type.elements.map(extractTypeName);
    return "(".concat(unionElements.join('|'), ")");
  } // Only support untyped array: []. Might add more support later if required.


  if (type.type === 'ArrayType') {
    return '[]';
  }

  if (type.type === 'TypeApplication') {
    if (type.expression != null) {
      if (type.expression.name === 'Array') {
        var arrayType = extractTypeName(type.applications[0]);
        return "".concat(arrayType, "[]");
      }
    }
  }

  if (type.type === 'NullableType' || type.type === 'NonNullableType' || type.type === 'OptionalType') {
    return extractTypeName(type.expression);
  }

  if (type.type === 'AllLiteral') {
    return 'any';
  }

  return null;
}