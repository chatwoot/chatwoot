const openBracket = '{'.charCodeAt(0);
const closeBracket = '}'.charCodeAt(0);
const openParen = '('.charCodeAt(0);
const closeParen = ')'.charCodeAt(0);
const singleQuote = "'".charCodeAt(0);
const doubleQuote = '"'.charCodeAt(0);
const backslash = '\\'.charCodeAt(0);
const slash = '/'.charCodeAt(0);
const period = '.'.charCodeAt(0);
const comma = ','.charCodeAt(0);
const colon = ':'.charCodeAt(0);
const asterisk = '*'.charCodeAt(0);
const minus = '-'.charCodeAt(0);
const plus = '+'.charCodeAt(0);
const pound = '#'.charCodeAt(0);
const newline = '\n'.charCodeAt(0);
const space = ' '.charCodeAt(0);
const feed = '\f'.charCodeAt(0);
const tab = '\t'.charCodeAt(0);
const cr = '\r'.charCodeAt(0);
const at = '@'.charCodeAt(0);
const lowerE = 'e'.charCodeAt(0);
const upperE = 'E'.charCodeAt(0);
const digit0 = '0'.charCodeAt(0);
const digit9 = '9'.charCodeAt(0);
const lowerU = 'u'.charCodeAt(0);
const upperU = 'U'.charCodeAt(0);
const atEnd = /[ \n\t\r\{\(\)'"\\;,/]/g;
const wordEnd = /[ \n\t\r\(\)\{\}\*:;@!&'"\+\|~>,\[\]\\]|\/(?=\*)/g;
const wordEndNum = /[ \n\t\r\(\)\{\}\*:;@!&'"\-\+\|~>,\[\]\\]|\//g;
const alphaNum = /^[a-z0-9]/i;
const unicodeRange = /^[a-f0-9?\-]/i;

const util = require('util');

const TokenizeError = require('./errors/TokenizeError');

module.exports = function tokenize(input, options) {
  options = options || {};

  const tokens = [];

  const css = input.valueOf();

  const length = css.length;

  let offset = -1;

  let line = 1;

  let pos = 0;

  let parentCount = 0;

  let isURLArg = null;

  let code;
  let next;
  let quote;
  let lines;
  let last;
  let content;
  let escape;
  let nextLine;
  let nextOffset;

  let escaped;
  let escapePos;
  let nextChar;

  function unclosed(what) {
    const message = util.format(
      'Unclosed %s at line: %d, column: %d, token: %d',
      what,
      line,
      pos - offset,
      pos
    );
    throw new TokenizeError(message);
  }

  function tokenizeError() {
    const message = util.format(
      'Syntax error at line: %d, column: %d, token: %d',
      line,
      pos - offset,
      pos
    );
    throw new TokenizeError(message);
  }

  while (pos < length) {
    code = css.charCodeAt(pos);

    if (code === newline) {
      offset = pos;
      line += 1;
    }

    switch (code) {
      case newline:
      case space:
      case tab:
      case cr:
      case feed:
        next = pos;
        do {
          next += 1;
          code = css.charCodeAt(next);
          if (code === newline) {
            offset = next;
            line += 1;
          }
        } while (
          code === space ||
          code === newline ||
          code === tab ||
          code === cr ||
          code === feed
        );

        tokens.push(['space', css.slice(pos, next), line, pos - offset, line, next - offset, pos]);

        pos = next - 1;
        break;

      case colon:
        next = pos + 1;
        tokens.push(['colon', css.slice(pos, next), line, pos - offset, line, next - offset, pos]);

        pos = next - 1;
        break;

      case comma:
        next = pos + 1;
        tokens.push(['comma', css.slice(pos, next), line, pos - offset, line, next - offset, pos]);

        pos = next - 1;
        break;

      case openBracket:
        tokens.push(['{', '{', line, pos - offset, line, next - offset, pos]);
        break;

      case closeBracket:
        tokens.push(['}', '}', line, pos - offset, line, next - offset, pos]);
        break;

      case openParen:
        parentCount++;
        isURLArg =
          !isURLArg &&
          parentCount === 1 &&
          tokens.length > 0 &&
          tokens[tokens.length - 1][0] === 'word' &&
          tokens[tokens.length - 1][1] === 'url';
        tokens.push(['(', '(', line, pos - offset, line, next - offset, pos]);
        break;

      case closeParen:
        parentCount--;
        isURLArg = !isURLArg && parentCount === 1;
        tokens.push([')', ')', line, pos - offset, line, next - offset, pos]);
        break;

      case singleQuote:
      case doubleQuote:
        quote = code === singleQuote ? "'" : '"';
        next = pos;
        do {
          escaped = false;
          next = css.indexOf(quote, next + 1);
          if (next === -1) {
            unclosed('quote', quote);
          }
          escapePos = next;
          while (css.charCodeAt(escapePos - 1) === backslash) {
            escapePos -= 1;
            escaped = !escaped;
          }
        } while (escaped);

        tokens.push([
          'string',
          css.slice(pos, next + 1),
          line,
          pos - offset,
          line,
          next - offset,
          pos
        ]);
        pos = next;
        break;

      case at:
        atEnd.lastIndex = pos + 1;
        atEnd.test(css);

        if (atEnd.lastIndex === 0) {
          next = css.length - 1;
        } else {
          next = atEnd.lastIndex - 2;
        }

        tokens.push([
          'atword',
          css.slice(pos, next + 1),
          line,
          pos - offset,
          line,
          next - offset,
          pos
        ]);
        pos = next;
        break;

      case backslash:
        next = pos;
        code = css.charCodeAt(next + 1);

        if (
          escape &&
          (code !== slash &&
            code !== space &&
            code !== newline &&
            code !== tab &&
            code !== cr &&
            code !== feed)
        ) {
          next += 1;
        }

        tokens.push([
          'word',
          css.slice(pos, next + 1),
          line,
          pos - offset,
          line,
          next - offset,
          pos
        ]);

        pos = next;
        break;

      case plus:
      case minus:
      case asterisk:
        next = pos + 1;
        nextChar = css.slice(pos + 1, next + 1);

        const prevChar = css.slice(pos - 1, pos);

        // if the operator is immediately followed by a word character, then we
        // have a prefix of some kind, and should fall-through. eg. -webkit

        // look for --* for custom variables
        if (code === minus && nextChar.charCodeAt(0) === minus) {
          next++;

          tokens.push(['word', css.slice(pos, next), line, pos - offset, line, next - offset, pos]);

          pos = next - 1;
          break;
        }

        tokens.push([
          'operator',
          css.slice(pos, next),
          line,
          pos - offset,
          line,
          next - offset,
          pos
        ]);

        pos = next - 1;
        break;

      default:
        if (
          code === slash &&
          (css.charCodeAt(pos + 1) === asterisk ||
            (options.loose && !isURLArg && css.charCodeAt(pos + 1) === slash))
        ) {
          const isStandardComment = css.charCodeAt(pos + 1) === asterisk;

          if (isStandardComment) {
            next = css.indexOf('*/', pos + 2) + 1;
            if (next === 0) {
              unclosed('comment', '*/');
            }
          } else {
            const newlinePos = css.indexOf('\n', pos + 2);

            next = newlinePos !== -1 ? newlinePos - 1 : length;
          }

          content = css.slice(pos, next + 1);
          lines = content.split('\n');
          last = lines.length - 1;

          if (last > 0) {
            nextLine = line + last;
            nextOffset = next - lines[last].length;
          } else {
            nextLine = line;
            nextOffset = offset;
          }

          tokens.push(['comment', content, line, pos - offset, nextLine, next - nextOffset, pos]);

          offset = nextOffset;
          line = nextLine;
          pos = next;
        } else if (code === pound && !alphaNum.test(css.slice(pos + 1, pos + 2))) {
          next = pos + 1;

          tokens.push(['#', css.slice(pos, next), line, pos - offset, line, next - offset, pos]);

          pos = next - 1;
        } else if ((code === lowerU || code === upperU) && css.charCodeAt(pos + 1) === plus) {
          next = pos + 2;

          do {
            next += 1;
            code = css.charCodeAt(next);
          } while (next < length && unicodeRange.test(css.slice(next, next + 1)));

          tokens.push([
            'unicoderange',
            css.slice(pos, next),
            line,
            pos - offset,
            line,
            next - offset,
            pos
          ]);
          pos = next - 1;
        }
        // catch a regular slash, that isn't a comment
        else if (code === slash) {
          next = pos + 1;

          tokens.push([
            'operator',
            css.slice(pos, next),
            line,
            pos - offset,
            line,
            next - offset,
            pos
          ]);

          pos = next - 1;
        } else {
          let regex = wordEnd;

          // we're dealing with a word that starts with a number
          // those get treated differently
          if (code >= digit0 && code <= digit9) {
            regex = wordEndNum;
          }

          regex.lastIndex = pos + 1;
          regex.test(css);

          if (regex.lastIndex === 0) {
            next = css.length - 1;
          } else {
            next = regex.lastIndex - 2;
          }

          // Exponential number notation with minus or plus: 1e-10, 1e+10
          if (regex === wordEndNum || code === period) {
            const ncode = css.charCodeAt(next);

            const ncode1 = css.charCodeAt(next + 1);

            const ncode2 = css.charCodeAt(next + 2);

            if (
              (ncode === lowerE || ncode === upperE) &&
              (ncode1 === minus || ncode1 === plus) &&
              (ncode2 >= digit0 && ncode2 <= digit9)
            ) {
              wordEndNum.lastIndex = next + 2;
              wordEndNum.test(css);

              if (wordEndNum.lastIndex === 0) {
                next = css.length - 1;
              } else {
                next = wordEndNum.lastIndex - 2;
              }
            }
          }

          tokens.push([
            'word',
            css.slice(pos, next + 1),
            line,
            pos - offset,
            line,
            next - offset,
            pos
          ]);
          pos = next;
        }
        break;
    }

    pos++;
  }

  return tokens;
};
