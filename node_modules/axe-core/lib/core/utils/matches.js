import cssParser from './css-parser';

function matchesTag(vNode, exp) {
  return (
    vNode.props.nodeType === 1 &&
    (exp.tag === '*' || vNode.props.nodeName === exp.tag)
  );
}

function matchesClasses(vNode, exp) {
  return !exp.classes || exp.classes.every(cl => vNode.hasClass(cl.value));
}

function matchesAttributes(vNode, exp) {
  return (
    !exp.attributes ||
    exp.attributes.every(att => {
      var nodeAtt = vNode.attr(att.key);
      return nodeAtt !== null && (!att.value || att.test(nodeAtt));
    })
  );
}

function matchesId(vNode, exp) {
  return !exp.id || vNode.props.id === exp.id;
}

function matchesPseudos(target, exp) {
  if (
    !exp.pseudos ||
    exp.pseudos.every(pseudo => {
      if (pseudo.name === 'not') {
        return !pseudo.expressions.some(expression => {
          return matchesExpression(target, expression);
        });
      } else if (pseudo.name === 'is') {
        return pseudo.expressions.some(expression => {
          return matchesExpression(target, expression);
        });
      }
      throw new Error(
        'the pseudo selector ' + pseudo.name + ' has not yet been implemented'
      );
    })
  ) {
    return true;
  }
  return false;
}

function matchExpression(vNode, expression) {
  return (
    matchesTag(vNode, expression) &&
    matchesClasses(vNode, expression) &&
    matchesAttributes(vNode, expression) &&
    matchesId(vNode, expression) &&
    matchesPseudos(vNode, expression)
  );
}

var escapeRegExp = (() => {
  /*! Credit: XRegExp 0.6.1 (c) 2007-2008 Steven Levithan <http://stevenlevithan.com/regex/xregexp/> MIT License */
  var from = /(?=[\-\[\]{}()*+?.\\\^$|,#\s])/g;
  var to = '\\';
  return string => {
    return string.replace(from, to);
  };
})();

const reUnescape = /\\/g;
function convertAttributes(atts) {
  /*! Credit Mootools Copyright Mootools, MIT License */
  if (!atts) {
    return;
  }
  return atts.map(att => {
    const attributeKey = att.name.replace(reUnescape, '');
    const attributeValue = (att.value || '').replace(reUnescape, '');
    let test, regexp;

    switch (att.operator) {
      case '^=':
        regexp = new RegExp('^' + escapeRegExp(attributeValue));
        break;
      case '$=':
        regexp = new RegExp(escapeRegExp(attributeValue) + '$');
        break;
      case '~=':
        regexp = new RegExp(
          '(^|\\s)' + escapeRegExp(attributeValue) + '(\\s|$)'
        );
        break;
      case '|=':
        regexp = new RegExp('^' + escapeRegExp(attributeValue) + '(-|$)');
        break;
      case '=':
        test = value => {
          return attributeValue === value;
        };
        break;
      case '*=':
        test = value => {
          return value && value.includes(attributeValue);
        };
        break;
      case '!=':
        test = value => {
          return attributeValue !== value;
        };
        break;
      default:
        test = value => {
          return !!value;
        };
    }

    if (attributeValue === '' && /^[*$^]=$/.test(att.operator)) {
      test = () => {
        return false;
      };
    }

    if (!test) {
      test = value => {
        return value && regexp.test(value);
      };
    }
    return {
      key: attributeKey,
      value: attributeValue,
      test: test
    };
  });
}

function convertClasses(classes) {
  if (!classes) {
    return;
  }
  return classes.map(className => {
    className = className.replace(reUnescape, '');

    return {
      value: className,
      regexp: new RegExp('(^|\\s)' + escapeRegExp(className) + '(\\s|$)')
    };
  });
}

function convertPseudos(pseudos) {
  if (!pseudos) {
    return;
  }
  return pseudos.map(p => {
    var expressions;

    if (['is', 'not'].includes(p.name)) {
      expressions = p.value;
      expressions = expressions.selectors
        ? expressions.selectors
        : [expressions];
      expressions = convertExpressions(expressions);
    }
    return {
      name: p.name,
      expressions: expressions,
      value: p.value
    };
  });
}

/**
 * convert the css-selector-parser format into the Slick format
 * @private
 * @param Array {Object} expressions
 * @return Array {Object}
 *
 */
function convertExpressions(expressions) {
  return expressions.map(exp => {
    var newExp = [];
    var rule = exp.rule;
    while (rule) {
      /* eslint no-restricted-syntax: 0 */
      // `.tagName` is a property coming from the `CSSSelectorParser` library
      newExp.push({
        tag: rule.tagName ? rule.tagName.toLowerCase() : '*',
        combinator: rule.nestingOperator ? rule.nestingOperator : ' ',
        id: rule.id,
        attributes: convertAttributes(rule.attrs),
        classes: convertClasses(rule.classNames),
        pseudos: convertPseudos(rule.pseudos)
      });
      rule = rule.rule;
    }
    return newExp;
  });
}

/**
 * Convert a CSS selector to the Slick format expression
 *
 * @private
 * @param {String} selector CSS selector to convert
 * @returns {Object[]} Array of Slick format expressions
 */
export function convertSelector(selector) {
  var expressions = cssParser.parse(selector);
  expressions = expressions.selectors ? expressions.selectors : [expressions];
  return convertExpressions(expressions);
}

/**
 * Determine if a virtual node matches a Slick format CSS expression
 *
 * @private
 * @method matchesExpression
 * @memberof axe.utils
 * @param {VirtualNode} vNode VirtualNode to match
 * @param {Object|Object[]} expressions CSS selector expression or array of expressions
 * @returns {Boolean}
 */
export function matchesExpression(vNode, expressions, matchAnyParent) {
  const exps = [].concat(expressions);
  const expression = exps.pop();
  let matches = matchExpression(vNode, expression);

  while (!matches && matchAnyParent && vNode.parent) {
    vNode = vNode.parent;
    matches = matchExpression(vNode, expression);
  }

  if (exps.length) {
    if ([' ', '>'].includes(expression.combinator) === false) {
      throw new Error(
        'axe.utils.matchesExpression does not support the combinator: ' +
          expression.combinator
      );
    }

    matches =
      matches &&
      matchesExpression(vNode.parent, exps, expression.combinator === ' ');
  }

  return matches;
}

/**
 * matches implementation that operates on a VirtualNode
 *
 * @method matches
 * @memberof axe.utils
 * @param {VirtualNode} vNode VirtualNode to match
 * @param {String} selector CSS selector string
 * @return {Boolean}
 */
function matches(vNode, selector) {
  const expressions = convertSelector(selector);
  return expressions.some(expression => matchesExpression(vNode, expression));
}

export default matches;
