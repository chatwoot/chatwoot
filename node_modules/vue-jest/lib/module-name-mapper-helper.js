const path = require('path')

/**
 * Resolve a Sass @import or @use rule.
 *
 * @param {String} to - The path to the current file
 * @param {String} importPath - The path to resolve
 * @param {String} fileType - The filetype of the current file
 */
function resolveSass(to, importPath, fileType) {
  // Mimic Sass-loader's `~` syntax for bare imports.
  const matchModuleImport = /^~/

  if (path.isAbsolute(importPath)) {
    return importPath
  } else if (matchModuleImport.test(importPath)) {
    const dirname = path.dirname(importPath).replace(matchModuleImport, '')
    const basename = path.basename(importPath)

    const filenames = []

    if (!/\.(sc|sa|c)ss/.test(basename)) {
      const extensions = ['scss', 'sass', 'css'].filter(e => e !== fileType)
      extensions.unshift(fileType)
      extensions.forEach(ext => {
        filenames.push(`${basename}.${ext}`, `_${basename}.${ext}`)
      })
    } else {
      filenames.push(basename, `_${basename}`)
    }

    for (const filename of filenames) {
      try {
        return require.resolve(path.join(dirname, filename))
      } catch (_) {}
    }
  }

  return path.join(path.dirname(to), importPath)
}

/**
 * Applies the moduleNameMapper substitution from the jest config
 *
 * @param {String} source - the original string
 * @param {String} filePath - the path of the current file (where the source originates)
 * @param {Object} jestConfig - the jestConfig holding the moduleNameMapper settings
 * @param {Object} fileType - extn of the file to be resolved
 * @returns {String} path - the final path to import (including replacements via moduleNameMapper)
 */
module.exports = function applyModuleNameMapper(
  source,
  filePath,
  jestConfig = {},
  fileType = ''
) {
  if (!jestConfig.moduleNameMapper) return source
  // Extract the moduleNameMapper settings from the jest config. TODO: In case of development via babel@7, somehow the jestConfig.moduleNameMapper might end up being an Array. After a proper upgrade to babel@7 we should probably fix this.
  const module = Array.isArray(jestConfig.moduleNameMapper)
    ? jestConfig.moduleNameMapper
    : Object.entries(jestConfig.moduleNameMapper)

  const importPath = module.reduce((acc, [regex, replacement]) => {
    const matches = acc.match(regex)

    if (matches === null) {
      return acc
    }

    return replacement.replace(
      /\$([0-9]+)/g,
      (_, index) => matches[parseInt(index, 10)]
    )
  }, source)

  return resolveSass(filePath, importPath, fileType)
}
