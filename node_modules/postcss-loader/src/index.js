const path = require('path')

const { getOptions } = require('loader-utils')
const validateOptions = require('schema-utils')

const postcss = require('postcss')
const postcssrc = require('postcss-load-config')

const Warning = require('./Warning.js')
const SyntaxError = require('./Error.js')
const parseOptions = require('./options.js')

/**
 * **PostCSS Loader**
 *
 * Loads && processes CSS with [PostCSS](https://github.com/postcss/postcss)
 *
 * @method loader
 *
 * @param {String} css Source
 * @param {Object} map Source Map
 *
 * @return {cb} cb Result
 */
function loader (css, map, meta) {
  const options = Object.assign({}, getOptions(this))

  validateOptions(require('./options.json'), options, 'PostCSS Loader')

  const cb = this.async()
  const file = this.resourcePath

  const sourceMap = options.sourceMap

  Promise.resolve().then(() => {
    const length = Object.keys(options)
      .filter((option) => {
        switch (option) {
          // case 'exec':
          case 'ident':
          case 'config':
          case 'sourceMap':
            return
          default:
            return option
        }
      })
      .length

    if (length) {
      return parseOptions.call(this, options)
    }

    const rc = {
      path: path.dirname(file),
      ctx: {
        file: {
          extname: path.extname(file),
          dirname: path.dirname(file),
          basename: path.basename(file)
        },
        options: {}
      }
    }

    if (options.config) {
      if (options.config.path) {
        rc.path = path.resolve(options.config.path)
      }

      if (options.config.ctx) {
        rc.ctx.options = options.config.ctx
      }
    }

    rc.ctx.webpack = this

    return postcssrc(rc.ctx, rc.path)
  }).then((config) => {
    if (!config) {
      config = {}
    }

    if (config.file) {
      this.addDependency(config.file)
    }

    // Disable override `to` option from `postcss.config.js`
    if (config.options.to) {
      delete config.options.to
    }
    // Disable override `from` option from `postcss.config.js`
    if (config.options.from) {
      delete config.options.from
    }

    let plugins = config.plugins || []

    let options = Object.assign({
      from: file,
      map: sourceMap
        ? sourceMap === 'inline'
          ? { inline: true, annotation: false }
          : { inline: false, annotation: false }
        : false
    }, config.options)

    // Loader Exec (Deprecated)
    // https://webpack.js.org/api/loaders/#deprecated-context-properties
    if (options.parser === 'postcss-js') {
      css = this.exec(css, this.resource)
    }

    if (typeof options.parser === 'string') {
      options.parser = require(options.parser)
    }

    if (typeof options.syntax === 'string') {
      options.syntax = require(options.syntax)
    }

    if (typeof options.stringifier === 'string') {
      options.stringifier = require(options.stringifier)
    }

    // Loader API Exec (Deprecated)
    // https://webpack.js.org/api/loaders/#deprecated-context-properties
    if (config.exec) {
      css = this.exec(css, this.resource)
    }

    if (sourceMap && typeof map === 'string') {
      map = JSON.parse(map)
    }

    if (sourceMap && map) {
      options.map.prev = map
    }

    return postcss(plugins)
      .process(css, options)
      .then((result) => {
        let { css, map, root, processor, messages } = result

        result.warnings().forEach((warning) => {
          this.emitWarning(new Warning(warning))
        })

        messages.forEach((msg) => {
          if (msg.type === 'dependency') {
            this.addDependency(msg.file)
          }
        })

        map = map ? map.toJSON() : null

        if (map) {
          map.file = path.resolve(map.file)
          map.sources = map.sources.map((src) => path.resolve(src))
        }

        if (!meta) {
          meta = {}
        }

        const ast = {
          type: 'postcss',
          version: processor.version,
          root
        }

        meta.ast = ast
        meta.messages = messages

        if (this.loaderIndex === 0) {
          /**
           * @memberof loader
           * @callback cb
           *
           * @param {Object} null Error
           * @param {String} css  Result (JS Module)
           * @param {Object} map  Source Map
           */
          cb(null, `module.exports = ${JSON.stringify(css)}`, map)

          return null
        }

        /**
         * @memberof loader
         * @callback cb
         *
         * @param {Object} null Error
         * @param {String} css  Result (Raw Module)
         * @param {Object} map  Source Map
         */
        cb(null, css, map, meta)

        return null
      })
  }).catch((err) => {
    if (err.file) {
      this.addDependency(err.file)
    }

    return err.name === 'CssSyntaxError'
      ? cb(new SyntaxError(err))
      : cb(err)
  })
}

/**
 * @author Andrey Sitnik (@ai) <andrey@sitnik.ru>
 *
 * @license MIT
 * @version 3.0.0
 *
 * @module postcss-loader
 *
 * @requires path
 *
 * @requires loader-utils
 * @requires schema-utils
 *
 * @requires postcss
 * @requires postcss-load-config
 *
 * @requires ./options.js
 * @requires ./Warning.js
 * @requires ./SyntaxError.js
 */
module.exports = loader
