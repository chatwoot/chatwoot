import { inputRules, InputRule } from 'prosemirror-inputrules';
import { applyMarkOnRange } from '../commands';
import { createInputRule } from '../utils';
import { TextSelection } from 'prosemirror-state';

const validCombos = {
  '**': ['_', '~~', '^'],
  '*': ['__', '~~', '^'],
  '^': ['*', '_'],
  __: ['*', '~~', '^'],
  _: ['**', '~~', '^'],
  '~~': ['__', '_', '**', '*', '^'],
};

const validRegex = (char, str) => {
  for (let i = 0; i < validCombos[char].length; i++) {
    const ch = validCombos[char][i];
    if (ch === str) {
      return true;
    }
    const matchLength = str.length - ch.length;
    if (str.substr(matchLength, str.length) === ch) {
      return validRegex(ch, str.substr(0, matchLength));
    }
  }
  return false;
};

function addMark(markType, schema, charSize, char) {
  return (state, match, start, end) => {
    const [, prefix, textWithCombo] = match;
    const to = end;
    // in case of *string* pattern it matches the text from beginning of the paragraph,
    // because we want ** to work for strong text
    // that's why "start" argument is wrong and we need to calculate it ourselves
    const from = textWithCombo ? start + prefix.length : start;
    const nodeBefore = state.doc.resolve(start + prefix.length).nodeBefore;

    if (
      prefix &&
      prefix.length > 0 &&
      !validRegex(char, prefix) &&
      !(nodeBefore && nodeBefore.type === state.schema.nodes.hard_break)
    ) {
      return null;
    }
    // fixes the following case: my `*name` is *
    // expected result: should ignore special characters inside "code"
    if (
      state.schema.marks.code &&
      state.schema.marks.code.isInSet(state.doc.resolve(from + 1).marks())
    ) {
      return null;
    }

    // Prevent autoformatting across hardbreaks
    let containsHardBreak;
    state.doc.nodesBetween(from, to, node => {
      if (node.type === schema.nodes.hard_break) {
        containsHardBreak = true;
        return false;
      }
      return !containsHardBreak;
    });
    if (containsHardBreak) {
      return null;
    }

    // fixes autoformatting in heading nodes: # Heading *bold*
    // expected result: should not autoformat *bold*; <h1>Heading *bold*</h1>
    if (state.doc.resolve(from).sameParent(state.doc.resolve(to))) {
      if (!state.doc.resolve(from).parent.type.allowsMarkType(markType)) {
        return null;
      }
    }

    // apply mark to the range (from, to)
    let tr = state.tr.addMark(from, to, markType.create());

    if (charSize > 1) {
      // delete special characters after the text
      // Prosemirror removes the last symbol by itself, so we need to remove "charSize - 1" symbols
      tr = tr.delete(to - (charSize - 1), to);
    }

    return (
      tr
        // delete special characters before the text
        .delete(from, from + charSize)
        .removeStoredMark(markType)
    );
  };
}

function addCodeMark(markType, specialChar) {
  return (state, match, start, end) => {
    if (match[1] && match[1].length > 0) {
      const allowedPrefixConditions = [
        prefix => {
          return prefix === '(';
        },
        prefix => {
          const nodeBefore = state.doc.resolve(
            start + prefix.length
          ).nodeBefore;
          return (
            (nodeBefore && nodeBefore.type === state.schema.nodes.hard_break) ||
            false
          );
        },
      ];

      if (allowedPrefixConditions.every(condition => !condition(match[1]))) {
        return null;
      }
    }
    // fixes autoformatting in heading nodes: # Heading `bold`
    // expected result: should not autoformat *bold*; <h1>Heading `bold`</h1>
    if (state.doc.resolve(start).sameParent(state.doc.resolve(end))) {
      if (!state.doc.resolve(start).parent.type.allowsMarkType(markType)) {
        return null;
      }
    }

    let tr = state.tr;
    // checks if a selection exists and needs to be removed
    if (state.selection.from !== state.selection.to) {
      tr.delete(state.selection.from, state.selection.to);
      end -= state.selection.to - state.selection.from;
    }

    const regexStart = end - match[2].length + 1;
    const codeMark = state.schema.marks.code.create();
    return applyMarkOnRange(regexStart, end, false, codeMark, tr)
      .setStoredMarks([codeMark])
      .delete(regexStart, regexStart + specialChar.length)
      .removeStoredMark(markType);
  };
}

export const strongRegex1 =
  /(\S*)(\_\_([^\_\s](\_(?!\_)|[^\_])*[^\_\s]|[^\_\s])\_\_)$/;
export const strongRegex2 =
  /(\S*)(\*\*([^\*\s](\*(?!\*)|[^\*])*[^\*\s]|[^\*\s])\*\*)$/;
export const italicRegex1 =
  /(\S*[^\s\_]*)(\_([^\s\_][^\_]*[^\s\_]|[^\s\_])\_)$/;
export const italicRegex2 =
  /(\S*[^\s\*]*)(\*([^\s\*][^\*]*[^\s\*]|[^\s\*])\*)$/;
export const strikeRegex =
  /(\S*)(\~\~([^\s\~](\~(?!\~)|[^\~])*[^\s\~]|[^\s\~])\~\~)$/;
export const codeRegex = /(\S*)(`[^\s][^`]*`)$/;
export const supertextRegex = /(\S*[^\s^]*)(\^([^\s^][^^]*[^\s^]|[^\s^])\^)$/;

/**
 * Create input rules for strong mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getStrongInputRules(schema) {
  // **string** or __strong__ should bold the text

  const markLength = 2;
  const doubleUnderscoreRule = createInputRule(
    strongRegex1,
    addMark(schema.marks.strong, schema, markLength, '__')
  );

  const doubleAsterixRule = createInputRule(
    strongRegex2,
    addMark(schema.marks.strong, schema, markLength, '**')
  );

  return [doubleUnderscoreRule, doubleAsterixRule];
}

/**
 * Create input rules for em mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getItalicInputRules(schema) {
  // *string* or _string_ should italic the text
  const markLength = 1;

  const underscoreRule = createInputRule(
    italicRegex1,
    addMark(schema.marks.em, schema, markLength, '_')
  );

  const asterixRule = createInputRule(
    italicRegex2,
    addMark(schema.marks.em, schema, markLength, '*')
  );

  return [underscoreRule, asterixRule];
}

/**
 * Create input rules for strike mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getStrikeInputRules(schema) {
  const markLength = 2;
  const doubleTildeRule = createInputRule(
    strikeRegex,
    addMark(schema.marks.strike, schema, markLength, '~~')
  );

  return [doubleTildeRule];
}

function getSuperscriptInputRules(schema) {
  const markLength = 1;
  // const doubleTildeRule = addMark(schema.marks.superscript);
  const doubleTildeRule = createInputRule(
    supertextRegex,
    addMark(schema.marks.superscript, schema, markLength, '^')
  );

  return [doubleTildeRule];
}

/**
 * Create input rules for code mark
 *
 * @param {Schema} schema
 * @returns {InputRule[]}
 */
function getCodeInputRules(schema) {
  const backTickRule = createInputRule(
    codeRegex,
    addCodeMark(schema.marks.code, '`')
  );

  return [backTickRule];
}

export function textFormattingInputRules(schema) {
  const rules = [];

  if (schema.marks.strong) {
    rules.push(...getStrongInputRules(schema));
  }

  if (schema.marks.em) {
    rules.push(...getItalicInputRules(schema));
  }

  if (schema.marks.superscript) {
    rules.push(...getSuperscriptInputRules(schema));
  }

  if (schema.marks.strike) {
    rules.push(...getStrikeInputRules(schema));
  }

  if (schema.marks.code) {
    rules.push(...getCodeInputRules(schema));
  }

  if (rules.length !== 0) {
    return inputRules({ rules });
  }
  return;
}

export default textFormattingInputRules;
