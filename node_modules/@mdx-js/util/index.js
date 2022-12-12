const IMPORT_REGEX = /^import\s/
const EXPORT_REGEX = /^export\s/
const EXPORT_DEFAULT_REGEX = /^export default\s/
const STARTS_WITH_CAPITAL_LETTER_REGEX = /^[A-Z]/
const EMPTY_NEWLINE = '\n\n'
const COMMENT_OPEN = '<!--'
const COMMENT_CLOSE = '-->'

const isImport = text => IMPORT_REGEX.test(text)
const isExport = text => EXPORT_REGEX.test(text)
const isExportDefault = text => EXPORT_DEFAULT_REGEX.test(text)
const isImportOrExport = text => isImport(text) || isExport(text)

const isComment = str =>
  str.startsWith(COMMENT_OPEN) && str.endsWith(COMMENT_CLOSE)

const getCommentContents = str =>
  str.slice(COMMENT_OPEN.length, -COMMENT_CLOSE.length)

const startsWithCapitalLetter = str =>
  STARTS_WITH_CAPITAL_LETTER_REGEX.test(str)

const paramCase = string =>
  string
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .replace(/([a-z])([0-9])/g, '$1-$2')
    .toLowerCase()

const toTemplateLiteral = text => {
  const escaped = text
    .replace(/\\(?!\$)/g, '\\\\') // Escape all "\" to avoid unwanted escaping in text nodes
    // and ignore "\$" since it's already escaped and is common
    // with prettier https://github.com/mdx-js/mdx/issues/606
    .replace(/`/g, '\\`') // Escape "`"" since
    .replace(/(\\\$)/g, '\\$1') // Escape \$ so render it as it is
    .replace(/(\\\$)(\{)/g, '\\$1\\$2') // Escape \${} so render it as it is
    .replace(/\$\{/g, '\\${') // Escape ${} in text so that it doesn't eval

  return '{`' + escaped + '`}'
}

module.exports.EMPTY_NEWLINE = EMPTY_NEWLINE
module.exports.isImport = isImport
module.exports.isExport = isExport
module.exports.isExportDefault = isExportDefault
module.exports.isImportOrExport = isImportOrExport
module.exports.startsWithCapitalLetter = startsWithCapitalLetter
module.exports.isComment = isComment
module.exports.getCommentContents = getCommentContents
module.exports.paramCase = paramCase
module.exports.toTemplateLiteral = toTemplateLiteral
