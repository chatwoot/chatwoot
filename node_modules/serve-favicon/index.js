/*!
 * serve-favicon
 * Copyright(c) 2010 Sencha Inc.
 * Copyright(c) 2011 TJ Holowaychuk
 * Copyright(c) 2014-2017 Douglas Christopher Wilson
 * MIT Licensed
 */

'use strict'

/**
 * Module dependencies.
 * @private
 */

var Buffer = require('safe-buffer').Buffer
var etag = require('etag')
var fresh = require('fresh')
var fs = require('fs')
var ms = require('ms')
var parseUrl = require('parseurl')
var path = require('path')
var resolve = path.resolve

/**
 * Module exports.
 * @public
 */

module.exports = favicon

/**
 * Module variables.
 * @private
 */

var ONE_YEAR_MS = 60 * 60 * 24 * 365 * 1000 // 1 year

/**
 * Serves the favicon located by the given `path`.
 *
 * @public
 * @param {String|Buffer} path
 * @param {Object} [options]
 * @return {Function} middleware
 */

function favicon (path, options) {
  var opts = options || {}

  var icon // favicon cache
  var maxAge = calcMaxAge(opts.maxAge)

  if (!path) {
    throw new TypeError('path to favicon.ico is required')
  }

  if (Buffer.isBuffer(path)) {
    icon = createIcon(Buffer.from(path), maxAge)
  } else if (typeof path === 'string') {
    path = resolveSync(path)
  } else {
    throw new TypeError('path to favicon.ico must be string or buffer')
  }

  return function favicon (req, res, next) {
    if (getPathname(req) !== '/favicon.ico') {
      next()
      return
    }

    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.statusCode = req.method === 'OPTIONS' ? 200 : 405
      res.setHeader('Allow', 'GET, HEAD, OPTIONS')
      res.setHeader('Content-Length', '0')
      res.end()
      return
    }

    if (icon) {
      send(req, res, icon)
      return
    }

    fs.readFile(path, function (err, buf) {
      if (err) return next(err)
      icon = createIcon(buf, maxAge)
      send(req, res, icon)
    })
  }
}

/**
 * Calculate the max-age from a configured value.
 *
 * @private
 * @param {string|number} val
 * @return {number}
 */

function calcMaxAge (val) {
  var num = typeof val === 'string'
    ? ms(val)
    : val

  return num != null
    ? Math.min(Math.max(0, num), ONE_YEAR_MS)
    : ONE_YEAR_MS
}

/**
 * Create icon data from Buffer and max-age.
 *
 * @private
 * @param {Buffer} buf
 * @param {number} maxAge
 * @return {object}
 */

function createIcon (buf, maxAge) {
  return {
    body: buf,
    headers: {
      'Cache-Control': 'public, max-age=' + Math.floor(maxAge / 1000),
      'ETag': etag(buf)
    }
  }
}

/**
 * Create EISDIR error.
 *
 * @private
 * @param {string} path
 * @return {Error}
 */

function createIsDirError (path) {
  var error = new Error('EISDIR, illegal operation on directory \'' + path + '\'')
  error.code = 'EISDIR'
  error.errno = 28
  error.path = path
  error.syscall = 'open'
  return error
}

/**
 * Get the request pathname.
 *
 * @param {object} req
 * @return {string}
 */

function getPathname (req) {
  try {
    return parseUrl(req).pathname
  } catch (e) {
    return undefined
  }
}

/**
 * Determine if the cached representation is fresh.
 *
 * @param {object} req
 * @param {object} res
 * @return {boolean}
 * @private
 */

function isFresh (req, res) {
  return fresh(req.headers, {
    'etag': res.getHeader('ETag'),
    'last-modified': res.getHeader('Last-Modified')
  })
}

/**
 * Resolve the path to icon.
 *
 * @param {string} iconPath
 * @private
 */

function resolveSync (iconPath) {
  var path = resolve(iconPath)
  var stat = fs.statSync(path)

  if (stat.isDirectory()) {
    throw createIsDirError(path)
  }

  return path
}

/**
 * Send icon data in response to a request.
 *
 * @private
 * @param {IncomingMessage} req
 * @param {OutgoingMessage} res
 * @param {object} icon
 */

function send (req, res, icon) {
  // Set headers
  var headers = icon.headers
  var keys = Object.keys(headers)
  for (var i = 0; i < keys.length; i++) {
    var key = keys[i]
    res.setHeader(key, headers[key])
  }

  // Validate freshness
  if (isFresh(req, res)) {
    res.statusCode = 304
    res.end()
    return
  }

  // Send icon
  res.statusCode = 200
  res.setHeader('Content-Length', icon.body.length)
  res.setHeader('Content-Type', 'image/x-icon')
  res.end(icon.body)
}
