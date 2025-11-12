'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var view = require('@codemirror/view');
var language = require('@codemirror/language');
var highlight = require('@lezer/highlight');

// Using https://github.com/one-dark/vscode-one-dark-theme/ as reference for the colors
const chalky = "#e5c07b", coral = "#e06c75", cyan = "#56b6c2", invalid = "#ffffff", ivory = "#abb2bf", stone = "#7d8799", // Brightened compared to original to increase contrast
malibu = "#61afef", sage = "#98c379", whiskey = "#d19a66", violet = "#c678dd", darkBackground = "#21252b", highlightBackground = "#2c313a", background = "#282c34", tooltipBackground = "#353a42", selection = "#3E4451", cursor = "#528bff";
/**
The colors used in the theme, as CSS color strings.
*/
const color = {
    chalky,
    coral,
    cyan,
    invalid,
    ivory,
    stone,
    malibu,
    sage,
    whiskey,
    violet,
    darkBackground,
    highlightBackground,
    background,
    tooltipBackground,
    selection,
    cursor
};
/**
The editor theme styles for One Dark.
*/
const oneDarkTheme = view.EditorView.theme({
    "&": {
        color: ivory,
        backgroundColor: background
    },
    ".cm-content": {
        caretColor: cursor
    },
    ".cm-cursor, .cm-dropCursor": { borderLeftColor: cursor },
    "&.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection": { backgroundColor: selection },
    ".cm-panels": { backgroundColor: darkBackground, color: ivory },
    ".cm-panels.cm-panels-top": { borderBottom: "2px solid black" },
    ".cm-panels.cm-panels-bottom": { borderTop: "2px solid black" },
    ".cm-searchMatch": {
        backgroundColor: "#72a1ff59",
        outline: "1px solid #457dff"
    },
    ".cm-searchMatch.cm-searchMatch-selected": {
        backgroundColor: "#6199ff2f"
    },
    ".cm-activeLine": { backgroundColor: "#6699ff0b" },
    ".cm-selectionMatch": { backgroundColor: "#aafe661a" },
    "&.cm-focused .cm-matchingBracket, &.cm-focused .cm-nonmatchingBracket": {
        backgroundColor: "#bad0f847"
    },
    ".cm-gutters": {
        backgroundColor: background,
        color: stone,
        border: "none"
    },
    ".cm-activeLineGutter": {
        backgroundColor: highlightBackground
    },
    ".cm-foldPlaceholder": {
        backgroundColor: "transparent",
        border: "none",
        color: "#ddd"
    },
    ".cm-tooltip": {
        border: "none",
        backgroundColor: tooltipBackground
    },
    ".cm-tooltip .cm-tooltip-arrow:before": {
        borderTopColor: "transparent",
        borderBottomColor: "transparent"
    },
    ".cm-tooltip .cm-tooltip-arrow:after": {
        borderTopColor: tooltipBackground,
        borderBottomColor: tooltipBackground
    },
    ".cm-tooltip-autocomplete": {
        "& > ul > li[aria-selected]": {
            backgroundColor: highlightBackground,
            color: ivory
        }
    }
}, { dark: true });
/**
The highlighting style for code in the One Dark theme.
*/
const oneDarkHighlightStyle = language.HighlightStyle.define([
    { tag: highlight.tags.keyword,
        color: violet },
    { tag: [highlight.tags.name, highlight.tags.deleted, highlight.tags.character, highlight.tags.propertyName, highlight.tags.macroName],
        color: coral },
    { tag: [highlight.tags.function(highlight.tags.variableName), highlight.tags.labelName],
        color: malibu },
    { tag: [highlight.tags.color, highlight.tags.constant(highlight.tags.name), highlight.tags.standard(highlight.tags.name)],
        color: whiskey },
    { tag: [highlight.tags.definition(highlight.tags.name), highlight.tags.separator],
        color: ivory },
    { tag: [highlight.tags.typeName, highlight.tags.className, highlight.tags.number, highlight.tags.changed, highlight.tags.annotation, highlight.tags.modifier, highlight.tags.self, highlight.tags.namespace],
        color: chalky },
    { tag: [highlight.tags.operator, highlight.tags.operatorKeyword, highlight.tags.url, highlight.tags.escape, highlight.tags.regexp, highlight.tags.link, highlight.tags.special(highlight.tags.string)],
        color: cyan },
    { tag: [highlight.tags.meta, highlight.tags.comment],
        color: stone },
    { tag: highlight.tags.strong,
        fontWeight: "bold" },
    { tag: highlight.tags.emphasis,
        fontStyle: "italic" },
    { tag: highlight.tags.strikethrough,
        textDecoration: "line-through" },
    { tag: highlight.tags.link,
        color: stone,
        textDecoration: "underline" },
    { tag: highlight.tags.heading,
        fontWeight: "bold",
        color: coral },
    { tag: [highlight.tags.atom, highlight.tags.bool, highlight.tags.special(highlight.tags.variableName)],
        color: whiskey },
    { tag: [highlight.tags.processingInstruction, highlight.tags.string, highlight.tags.inserted],
        color: sage },
    { tag: highlight.tags.invalid,
        color: invalid },
]);
/**
Extension to enable the One Dark theme (both the editor theme and
the highlight style).
*/
const oneDark = [oneDarkTheme, language.syntaxHighlighting(oneDarkHighlightStyle)];

exports.color = color;
exports.oneDark = oneDark;
exports.oneDarkHighlightStyle = oneDarkHighlightStyle;
exports.oneDarkTheme = oneDarkTheme;
