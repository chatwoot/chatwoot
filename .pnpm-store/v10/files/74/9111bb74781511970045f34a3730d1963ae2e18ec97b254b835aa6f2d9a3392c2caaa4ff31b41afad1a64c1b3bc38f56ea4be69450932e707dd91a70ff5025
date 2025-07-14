import path from 'node:path'

import debug from 'debug'

import { normalizePath } from './normalizePath.js'

const debugLog = debug('lint-staged:chunkFiles')

/**
 * Chunk array into sub-arrays
 * @param {Array} arr
 * @param {Number} chunkCount
 * @retuns {Array<Array>}
 */
const chunkArray = (arr, chunkCount) => {
  if (chunkCount === 1) return [arr]
  const chunked = []
  let position = 0
  for (let i = 0; i < chunkCount; i++) {
    const chunkLength = Math.ceil((arr.length - position) / (chunkCount - i))
    chunked.push([])
    chunked[i] = arr.slice(position, chunkLength + position)
    position += chunkLength
  }
  return chunked
}

/**
 * Chunk files into sub-arrays based on the length of the resulting argument string
 * @param {Object} opts
 * @param {Array<String>} opts.files
 * @param {String} [opts.baseDir] The optional base directory to resolve relative paths.
 * @param {number} [opts.maxArgLength] the maximum argument string length
 * @param {Boolean} [opts.relative] whether files are relative to `gitDir` or should be resolved as absolute
 * @returns {Array<Array<String>>}
 */
export const chunkFiles = ({ files, baseDir, maxArgLength = null, relative = false }) => {
  const normalizedFiles = files.map((file) =>
    normalizePath(relative || !baseDir ? file : path.resolve(baseDir, file))
  )

  if (!maxArgLength) {
    debugLog('Skip chunking files because of undefined maxArgLength')
    return [normalizedFiles] // wrap in an array to return a single chunk
  }

  const fileListLength = normalizedFiles.join(' ').length
  debugLog(
    `Resolved an argument string length of ${fileListLength} characters from ${normalizedFiles.length} files`
  )
  const chunkCount = Math.min(Math.ceil(fileListLength / maxArgLength), normalizedFiles.length)
  debugLog(`Creating ${chunkCount} chunks for maxArgLength of ${maxArgLength}`)
  return chunkArray(normalizedFiles, chunkCount)
}
