"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseDocblock = void 0;
/**
 * Helper functions to work with docblock comments.
 */
/**
 * Extracts the text from a docblock comment
 * @param {rawDocblock} str
 * @return str stripped from stars and spaces
 */
function parseDocblock(str) {
    var lines = str.split('\n');
    for (var i = 0, l = lines.length; i < l; i++) {
        lines[i] = lines[i].replace(/^\s*\*\s?/, '').replace(/\r$/, '');
    }
    return lines.join('\n').trim();
}
exports.parseDocblock = parseDocblock;
var DOCBLOCK_HEADER = /^\*\s/;
/**
 * Given a path, this function returns the closest preceding docblock if it
 * exists.
 */
function getDocblock(path, _a) {
    var _b = _a === void 0 ? { commentIndex: 1 } : _a, _c = _b.commentIndex, commentIndex = _c === void 0 ? 1 : _c;
    commentIndex = commentIndex || 1;
    var comments = [];
    var allComments = path.node.leadingComments;
    if (allComments) {
        comments = allComments.filter(function (comment) {
            return comment.type === 'CommentBlock' && DOCBLOCK_HEADER.test(comment.value);
        });
    }
    if (comments.length + 1 - commentIndex > 0) {
        return parseDocblock(comments[comments.length - commentIndex].value);
    }
    return null;
}
exports.default = getDocblock;
