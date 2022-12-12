'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var postcss = _interopDefault(require('postcss'));

var cloneRule = ((decl, dir) => {
  const rule = Object(decl.parent).type === 'rule' ? decl.parent.clone({
    raws: {}
  }).removeAll() : postcss.rule({
    selector: '&'
  });
  rule.selectors = rule.selectors.map(selector => `${selector}:dir(${dir})`);
  return rule;
});

const matchLogical = /^\s*logical\s+/i;
const matchLogicalBorder = /^border(-width|-style|-color)?$/i;
const matchLogicalBorderSide = /^border-(block|block-start|block-end|inline|inline-start|inline-end|start|end)(-(width|style|color))?$/i;
var transformBorder = {
  // border
  'border': (decl, values, dir) => {
    const isLogical = matchLogical.test(values[0]);

    if (isLogical) {
      values[0] = values[0].replace(matchLogical, '');
    }

    const ltrDecls = [decl.clone({
      prop: `border-top${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[1] || values[0]
    }), decl.clone({
      prop: `border-bottom${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[2] || values[0]
    }), decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[3] || values[1] || values[0]
    })];
    const rtlDecls = [decl.clone({
      prop: `border-top${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[1] || values[0]
    }), decl.clone({
      prop: `border-bottom${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[2] || values[0]
    }), decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[3] || values[1] || values[0]
    })];
    return isLogical ? 1 === values.length ? decl.clone({
      value: decl.value.replace(matchLogical, '')
    }) : !values[3] || values[3] === values[1] ? [decl.clone({
      prop: `border-top${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[3] || values[1] || values[0]
    }), decl.clone({
      prop: `border-bottom${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[2] || values[0]
    }), decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorder, '$1')}`,
      value: values[1] || values[0]
    })] : 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)] : null;
  },
  // border-block
  'border-block': (decl, values) => [decl.clone({
    prop: `border-top${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
    value: values[0]
  }), decl.clone({
    prop: `border-bottom${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
    value: values[0]
  })],
  // border-block-start
  'border-block-start': decl => {
    decl.prop = 'border-top';
  },
  // border-block-end
  'border-block-end': decl => {
    decl.prop = 'border-bottom';
  },
  // border-inline
  'border-inline': (decl, values, dir) => {
    const ltrDecls = [decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[1] || values[0]
    })];
    const rtlDecls = [decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[1] || values[0]
    })];
    const isLTR = 1 === values.length || 2 === values.length && values[0] === values[1];
    return isLTR ? ltrDecls : 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
  },
  // border-inline-start
  'border-inline-start': (decl, values, dir) => {
    const ltrDecl = decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorderSide, '$2')}`
    });
    const rtlDecl = decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorderSide, '$2')}`
    });
    return 'ltr' === dir ? ltrDecl : 'rtl' === dir ? rtlDecl : [cloneRule(decl, 'ltr').append(ltrDecl), cloneRule(decl, 'rtl').append(rtlDecl)];
  },
  // border-inline-end
  'border-inline-end': (decl, values, dir) => {
    const ltrDecl = decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorderSide, '$2')}`
    });
    const rtlDecl = decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorderSide, '$2')}`
    });
    return 'ltr' === dir ? ltrDecl : 'rtl' === dir ? rtlDecl : [cloneRule(decl, 'ltr').append(ltrDecl), cloneRule(decl, 'rtl').append(rtlDecl)];
  },
  // border-start
  'border-start': (decl, values, dir) => {
    const ltrDecls = [decl.clone({
      prop: `border-top${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[1] || values[0]
    })];
    const rtlDecls = [decl.clone({
      prop: `border-top${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[1] || values[0]
    })];
    return 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
  },
  // border-end
  'border-end': (decl, values, dir) => {
    const ltrDecls = [decl.clone({
      prop: `border-bottom${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-right${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[1] || values[0]
    })];
    const rtlDecls = [decl.clone({
      prop: `border-bottom${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[0]
    }), decl.clone({
      prop: `border-left${decl.prop.replace(matchLogicalBorderSide, '$2')}`,
      value: values[1] || values[0]
    })];
    return 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
  }
};

var transformFloat = ((decl, values, dir) => {
  const lDecl = decl.clone({
    value: 'left'
  });
  const rDecl = decl.clone({
    value: 'right'
  });
  return /^inline-start$/i.test(decl.value) ? 'ltr' === dir ? lDecl : 'rtl' === dir ? rDecl : [cloneRule(decl, 'ltr').append(lDecl), cloneRule(decl, 'rtl').append(rDecl)] : /^inline-end$/i.test(decl.value) ? 'ltr' === dir ? rDecl : 'rtl' === dir ? lDecl : [cloneRule(decl, 'ltr').append(rDecl), cloneRule(decl, 'rtl').append(lDecl)] : null;
});

var transformInset = ((decl, values, dir) => {
  if ('logical' !== values[0]) {
    return [decl.clone({
      prop: 'top',
      value: values[0]
    }), decl.clone({
      prop: 'right',
      value: values[1] || values[0]
    }), decl.clone({
      prop: 'bottom',
      value: values[2] || values[0]
    }), decl.clone({
      prop: 'left',
      value: values[3] || values[1] || values[0]
    })];
  }

  const isLTR = !values[4] || values[4] === values[2];
  const ltrDecls = [decl.clone({
    prop: 'top',
    value: values[1]
  }), decl.clone({
    prop: 'left',
    value: values[2] || values[1]
  }), decl.clone({
    prop: 'bottom',
    value: values[3] || values[1]
  }), decl.clone({
    prop: 'right',
    value: values[4] || values[2] || values[1]
  })];
  const rtlDecls = [decl.clone({
    prop: 'top',
    value: values[1]
  }), decl.clone({
    prop: 'right',
    value: values[2] || values[1]
  }), decl.clone({
    prop: 'bottom',
    value: values[3] || values[1]
  }), decl.clone({
    prop: 'left',
    value: values[4] || values[2] || values[1]
  })];
  return isLTR || 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
});

var transformResize = (decl => /^block$/i.test(decl.value) ? decl.clone({
  value: 'vertical'
}) : /^inline$/i.test(decl.value) ? decl.clone({
  value: 'horizontal'
}) : null);

var matchSide = /^(inset|margin|padding)(?:-(block|block-start|block-end|inline|inline-start|inline-end|start|end))$/i;

var matchInsetPrefix = /^inset-/i;

var cloneDecl = ((decl, suffix, value) => decl.clone({
  prop: `${decl.prop.replace(matchSide, '$1')}${suffix}`.replace(matchInsetPrefix, ''),
  value
}));

var transformSide = {
  // inset-block, margin-block, padding-block
  'block': (decl, values) => [cloneDecl(decl, '-top', values[0]), cloneDecl(decl, '-bottom', values[1] || values[0])],
  // inset-block-start, margin-block-start, padding-block-start
  'block-start': decl => {
    decl.prop = decl.prop.replace(matchSide, '$1-top').replace(matchInsetPrefix, '');
  },
  // inset-block-end, margin-block-end, padding-block-end
  'block-end': decl => {
    decl.prop = decl.prop.replace(matchSide, '$1-bottom').replace(matchInsetPrefix, '');
  },
  // inset-inline, margin-inline, padding-inline
  'inline': (decl, values, dir) => {
    const ltrDecls = [cloneDecl(decl, '-left', values[0]), cloneDecl(decl, '-right', values[1] || values[0])];
    const rtlDecls = [cloneDecl(decl, '-right', values[0]), cloneDecl(decl, '-left', values[1] || values[0])];
    const isLTR = 1 === values.length || 2 === values.length && values[0] === values[1];
    return isLTR ? ltrDecls : 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
  },
  // inset-inline-start, margin-inline-start, padding-inline-start
  'inline-start': (decl, values, dir) => {
    const ltrDecl = cloneDecl(decl, '-left', decl.value);
    const rtlDecl = cloneDecl(decl, '-right', decl.value);
    return 'ltr' === dir ? ltrDecl : 'rtl' === dir ? rtlDecl : [cloneRule(decl, 'ltr').append(ltrDecl), cloneRule(decl, 'rtl').append(rtlDecl)];
  },
  // inset-inline-end, margin-inline-end, padding-inline-end
  'inline-end': (decl, values, dir) => {
    const ltrDecl = cloneDecl(decl, '-right', decl.value);
    const rtlDecl = cloneDecl(decl, '-left', decl.value);
    return 'ltr' === dir ? ltrDecl : 'rtl' === dir ? rtlDecl : [cloneRule(decl, 'ltr').append(ltrDecl), cloneRule(decl, 'rtl').append(rtlDecl)];
  },
  // inset-start, margin-start, padding-start
  'start': (decl, values, dir) => {
    const ltrDecls = [cloneDecl(decl, '-top', values[0]), cloneDecl(decl, '-left', values[1] || values[0])];
    const rtlDecls = [cloneDecl(decl, '-top', values[0]), cloneDecl(decl, '-right', values[1] || values[0])];
    return 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
  },
  // inset-end, margin-end, padding-end
  'end': (decl, values, dir) => {
    const ltrDecls = [cloneDecl(decl, '-bottom', values[0]), cloneDecl(decl, '-right', values[1] || values[0])];
    const rtlDecls = [cloneDecl(decl, '-bottom', values[0]), cloneDecl(decl, '-left', values[1] || values[0])];
    return 'ltr' === dir ? ltrDecls : 'rtl' === dir ? rtlDecls : [cloneRule(decl, 'ltr').append(ltrDecls), cloneRule(decl, 'rtl').append(rtlDecls)];
  }
};

var matchSize = /^(min-|max-)?(block|inline)-(size)$/i;

var transformSize = (decl => {
  decl.prop = decl.prop.replace(matchSize, ($0, minmax, flow) => `${minmax || ''}${'block' === flow ? 'height' : 'width'}`);
});

var transformSpacing = ((decl, values, dir) => {
  if ('logical' !== values[0]) {
    return null;
  }

  const isLTR = !values[4] || values[4] === values[2];
  const ltrDecl = decl.clone({
    value: [values[1], values[4] || values[2] || values[1], values[3] || values[1], values[2] || values[1]].join(' ')
  });
  const rtlDecl = decl.clone({
    value: [values[1], values[2] || values[1], values[3] || values[1], values[4] || values[2] || values[1]].join(' ')
  });
  return isLTR ? decl.clone({
    value: decl.value.replace(/^\s*logical\s+/i, '')
  }) : 'ltr' === dir ? ltrDecl : 'rtl' === dir ? rtlDecl : [cloneRule(decl, 'ltr').append(ltrDecl), cloneRule(decl, 'rtl').append(rtlDecl)];
});

var transformTextAlign = ((decl, values, dir) => {
  const lDecl = decl.clone({
    value: 'left'
  });
  const rDecl = decl.clone({
    value: 'right'
  });
  return /^start$/i.test(decl.value) ? 'ltr' === dir ? lDecl : 'rtl' === dir ? rDecl : [cloneRule(decl, 'ltr').append(lDecl), cloneRule(decl, 'rtl').append(rDecl)] : /^end$/i.test(decl.value) ? 'ltr' === dir ? rDecl : 'rtl' === dir ? lDecl : [cloneRule(decl, 'ltr').append(rDecl), cloneRule(decl, 'rtl').append(lDecl)] : null;
});

function splitByComma(string, isTrimmed) {
  return splitByRegExp(string, /^,$/, isTrimmed);
}
function splitBySpace(string, isTrimmed) {
  return splitByRegExp(string, /^\s$/, isTrimmed);
}
function splitBySlash(string, isTrimmed) {
  return splitByRegExp(string, /^\/$/, isTrimmed);
}

function splitByRegExp(string, re, isTrimmed) {
  const array = [];
  let buffer = '';
  let split = false;
  let func = 0;
  let i = -1;

  while (++i < string.length) {
    const char = string[i];

    if (char === '(') {
      func += 1;
    } else if (char === ')') {
      if (func > 0) {
        func -= 1;
      }
    } else if (func === 0) {
      if (re.test(char)) {
        split = true;
      }
    }

    if (split) {
      if (!isTrimmed || buffer.trim()) {
        array.push(isTrimmed ? buffer.trim() : buffer);
      }

      if (!isTrimmed) {
        array.push(char);
      }

      buffer = '';
      split = false;
    } else {
      buffer += char;
    }
  }

  if (buffer !== '') {
    array.push(isTrimmed ? buffer.trim() : buffer);
  }

  return array;
}

var transformTransition = ((decl, notValues, dir) => {
  const ltrValues = [];
  const rtlValues = [];
  splitByComma(decl.value).forEach(value => {
    let hasBeenSplit = false;
    splitBySpace(value).forEach((word, index, words) => {
      if (word in valueMap) {
        hasBeenSplit = true;
        valueMap[word].ltr.forEach(replacement => {
          const clone = words.slice();
          clone.splice(index, 1, replacement);

          if (ltrValues.length && !/^,$/.test(ltrValues[ltrValues.length - 1])) {
            ltrValues.push(',');
          }

          ltrValues.push(clone.join(''));
        });
        valueMap[word].rtl.forEach(replacement => {
          const clone = words.slice();
          clone.splice(index, 1, replacement);

          if (rtlValues.length && !/^,$/.test(rtlValues[rtlValues.length - 1])) {
            rtlValues.push(',');
          }

          rtlValues.push(clone.join(''));
        });
      }
    });

    if (!hasBeenSplit) {
      ltrValues.push(value);
      rtlValues.push(value);
    }
  });
  const ltrDecl = decl.clone({
    value: ltrValues.join('')
  });
  const rtlDecl = decl.clone({
    value: rtlValues.join('')
  });
  return ltrValues.length && 'ltr' === dir ? ltrDecl : rtlValues.length && 'rtl' === dir ? rtlDecl : ltrDecl.value !== rtlDecl.value ? [cloneRule(decl, 'ltr').append(ltrDecl), cloneRule(decl, 'rtl').append(rtlDecl)] : null;
});
const valueMap = {
  'border-block': {
    ltr: ['border-top', 'border-bottom'],
    rtl: ['border-top', 'border-bottom']
  },
  'border-block-color': {
    ltr: ['border-top-color', 'border-bottom-color'],
    rtl: ['border-top-color', 'border-bottom-color']
  },
  'border-block-end': {
    ltr: ['border-bottom'],
    rtl: ['border-bottom']
  },
  'border-block-end-color': {
    ltr: ['border-bottom-color'],
    rtl: ['border-bottom-color']
  },
  'border-block-end-style': {
    ltr: ['border-bottom-style'],
    rtl: ['border-bottom-style']
  },
  'border-block-end-width': {
    ltr: ['border-bottom-width'],
    rtl: ['border-bottom-width']
  },
  'border-block-start': {
    ltr: ['border-top'],
    rtl: ['border-top']
  },
  'border-block-start-color': {
    ltr: ['border-top-color'],
    rtl: ['border-top-color']
  },
  'border-block-start-style': {
    ltr: ['border-top-style'],
    rtl: ['border-top-style']
  },
  'border-block-start-width': {
    ltr: ['border-top-width'],
    rtl: ['border-top-width']
  },
  'border-block-style': {
    ltr: ['border-top-style', 'border-bottom-style'],
    rtl: ['border-top-style', 'border-bottom-style']
  },
  'border-block-width': {
    ltr: ['border-top-width', 'border-bottom-width'],
    rtl: ['border-top-width', 'border-bottom-width']
  },
  'border-end': {
    ltr: ['border-bottom', 'border-right'],
    rtl: ['border-bottom', 'border-left']
  },
  'border-end-color': {
    ltr: ['border-bottom-color', 'border-right-color'],
    rtl: ['border-bottom-color', 'border-left-color']
  },
  'border-end-style': {
    ltr: ['border-bottom-style', 'border-right-style'],
    rtl: ['border-bottom-style', 'border-left-style']
  },
  'border-end-width': {
    ltr: ['border-bottom-width', 'border-right-width'],
    rtl: ['border-bottom-width', 'border-left-width']
  },
  'border-inline': {
    ltr: ['border-left', 'border-right'],
    rtl: ['border-left', 'border-right']
  },
  'border-inline-color': {
    ltr: ['border-left-color', 'border-right-color'],
    rtl: ['border-left-color', 'border-right-color']
  },
  'border-inline-end': {
    ltr: ['border-right'],
    rtl: ['border-left']
  },
  'border-inline-end-color': {
    ltr: ['border-right-color'],
    rtl: ['border-left-color']
  },
  'border-inline-end-style': {
    ltr: ['border-right-style'],
    rtl: ['border-left-style']
  },
  'border-inline-end-width': {
    ltr: ['border-right-width'],
    rtl: ['border-left-width']
  },
  'border-inline-start': {
    ltr: ['border-left'],
    rtl: ['border-right']
  },
  'border-inline-start-color': {
    ltr: ['border-left-color'],
    rtl: ['border-right-color']
  },
  'border-inline-start-style': {
    ltr: ['border-left-style'],
    rtl: ['border-right-style']
  },
  'border-inline-start-width': {
    ltr: ['border-left-width'],
    rtl: ['border-right-width']
  },
  'border-inline-style': {
    ltr: ['border-left-style', 'border-right-style'],
    rtl: ['border-left-style', 'border-right-style']
  },
  'border-inline-width': {
    ltr: ['border-left-width', 'border-right-width'],
    rtl: ['border-left-width', 'border-right-width']
  },
  'border-start': {
    ltr: ['border-top', 'border-left'],
    rtl: ['border-top', 'border-right']
  },
  'border-start-color': {
    ltr: ['border-top-color', 'border-left-color'],
    rtl: ['border-top-color', 'border-right-color']
  },
  'border-start-style': {
    ltr: ['border-top-style', 'border-left-style'],
    rtl: ['border-top-style', 'border-right-style']
  },
  'border-start-width': {
    ltr: ['border-top-width', 'border-left-width'],
    rtl: ['border-top-width', 'border-right-width']
  },
  'block-size': {
    ltr: ['height'],
    rtl: ['height']
  },
  'inline-size': {
    ltr: ['width'],
    rtl: ['width']
  },
  'inset': {
    ltr: ['top', 'right', 'bottom', 'left'],
    rtl: ['top', 'right', 'bottom', 'left']
  },
  'inset-block': {
    ltr: ['top', 'bottom'],
    rtl: ['top', 'bottom']
  },
  'inset-block-start': {
    ltr: ['top'],
    rtl: ['top']
  },
  'inset-block-end': {
    ltr: ['bottom'],
    rtl: ['bottom']
  },
  'inset-end': {
    ltr: ['bottom', 'right'],
    rtl: ['bottom', 'left']
  },
  'inset-inline': {
    ltr: ['left', 'right'],
    rtl: ['left', 'right']
  },
  'inset-inline-start': {
    ltr: ['left'],
    rtl: ['right']
  },
  'inset-inline-end': {
    ltr: ['right'],
    rtl: ['left']
  },
  'inset-start': {
    ltr: ['top', 'left'],
    rtl: ['top', 'right']
  },
  'margin-block': {
    ltr: ['margin-top', 'margin-bottom'],
    rtl: ['margin-top', 'margin-bottom']
  },
  'margin-block-start': {
    ltr: ['margin-top'],
    rtl: ['margin-top']
  },
  'margin-block-end': {
    ltr: ['margin-bottom'],
    rtl: ['margin-bottom']
  },
  'margin-end': {
    ltr: ['margin-bottom', 'margin-right'],
    rtl: ['margin-bottom', 'margin-left']
  },
  'margin-inline': {
    ltr: ['margin-left', 'margin-right'],
    rtl: ['margin-left', 'margin-right']
  },
  'margin-inline-start': {
    ltr: ['margin-left'],
    rtl: ['margin-right']
  },
  'margin-inline-end': {
    ltr: ['margin-right'],
    rtl: ['margin-left']
  },
  'margin-start': {
    ltr: ['margin-top', 'margin-left'],
    rtl: ['margin-top', 'margin-right']
  },
  'padding-block': {
    ltr: ['padding-top', 'padding-bottom'],
    rtl: ['padding-top', 'padding-bottom']
  },
  'padding-block-start': {
    ltr: ['padding-top'],
    rtl: ['padding-top']
  },
  'padding-block-end': {
    ltr: ['padding-bottom'],
    rtl: ['padding-bottom']
  },
  'padding-end': {
    ltr: ['padding-bottom', 'padding-right'],
    rtl: ['padding-bottom', 'padding-left']
  },
  'padding-inline': {
    ltr: ['padding-left', 'padding-right'],
    rtl: ['padding-left', 'padding-right']
  },
  'padding-inline-start': {
    ltr: ['padding-left'],
    rtl: ['padding-right']
  },
  'padding-inline-end': {
    ltr: ['padding-right'],
    rtl: ['padding-left']
  },
  'padding-start': {
    ltr: ['padding-top', 'padding-left'],
    rtl: ['padding-top', 'padding-right']
  }
};

var matchSupportedProperties = /^(?:(inset|margin|padding)(?:-(block|block-start|block-end|inline|inline-start|inline-end|start|end))|(min-|max-)?(block|inline)-(size))$/i;

// tooling

const transforms = {
  'border': transformBorder['border'],
  'border-width': transformBorder['border'],
  'border-style': transformBorder['border'],
  'border-color': transformBorder['border'],
  'border-block': transformBorder['border-block'],
  'border-block-width': transformBorder['border-block'],
  'border-block-style': transformBorder['border-block'],
  'border-block-color': transformBorder['border-block'],
  'border-block-start': transformBorder['border-block-start'],
  'border-block-start-width': transformBorder['border-block-start'],
  'border-block-start-style': transformBorder['border-block-start'],
  'border-block-start-color': transformBorder['border-block-start'],
  'border-block-end': transformBorder['border-block-end'],
  'border-block-end-width': transformBorder['border-block-end'],
  'border-block-end-style': transformBorder['border-block-end'],
  'border-block-end-color': transformBorder['border-block-end'],
  'border-inline': transformBorder['border-inline'],
  'border-inline-width': transformBorder['border-inline'],
  'border-inline-style': transformBorder['border-inline'],
  'border-inline-color': transformBorder['border-inline'],
  'border-inline-start': transformBorder['border-inline-start'],
  'border-inline-start-width': transformBorder['border-inline-start'],
  'border-inline-start-style': transformBorder['border-inline-start'],
  'border-inline-start-color': transformBorder['border-inline-start'],
  'border-inline-end': transformBorder['border-inline-end'],
  'border-inline-end-width': transformBorder['border-inline-end'],
  'border-inline-end-style': transformBorder['border-inline-end'],
  'border-inline-end-color': transformBorder['border-inline-end'],
  'border-start': transformBorder['border-start'],
  'border-start-width': transformBorder['border-start'],
  'border-start-style': transformBorder['border-start'],
  'border-start-color': transformBorder['border-start'],
  'border-end': transformBorder['border-end'],
  'border-end-width': transformBorder['border-end'],
  'border-end-style': transformBorder['border-end'],
  'border-end-color': transformBorder['border-end'],
  'clear': transformFloat,
  'inset': transformInset,
  'margin': transformSpacing,
  'padding': transformSpacing,
  'block': transformSide['block'],
  'block-start': transformSide['block-start'],
  'block-end': transformSide['block-end'],
  'inline': transformSide['inline'],
  'inline-start': transformSide['inline-start'],
  'inline-end': transformSide['inline-end'],
  'start': transformSide['start'],
  'end': transformSide['end'],
  'float': transformFloat,
  'resize': transformResize,
  'size': transformSize,
  'text-align': transformTextAlign,
  'transition': transformTransition,
  'transition-property': transformTransition
}; // properties that will be split by slash

const splitBySlashPropRegExp = /^border(-block|-inline|-start|-end)?(-width|-style|-color)?$/i; // plugin

var index = postcss.plugin('postcss-logical-properties', opts => {
  const preserve = Boolean(Object(opts).preserve);
  const dir = !preserve && typeof Object(opts).dir === 'string' ? /^rtl$/i.test(opts.dir) ? 'rtl' : 'ltr' : false;
  return root => {
    root.walkDecls(decl => {
      const parent = decl.parent;
      const values = splitBySlashPropRegExp.test(decl.prop) ? splitBySlash(decl.value, true) : splitBySpace(decl.value, true);
      const prop = decl.prop.replace(matchSupportedProperties, '$2$5').toLowerCase();

      if (prop in transforms) {
        const replacer = transforms[prop](decl, values, dir);

        if (replacer) {
          [].concat(replacer).forEach(replacement => {
            if (replacement.type === 'rule') {
              parent.before(replacement);
            } else {
              decl.before(replacement);
            }
          });

          if (!preserve) {
            decl.remove();

            if (!parent.nodes.length) {
              parent.remove();
            }
          }
        }
      }
    });
  };
});

module.exports = index;
//# sourceMappingURL=index.cjs.js.map
