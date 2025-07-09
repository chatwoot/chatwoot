"use strict"

const path = require("path")
const extract = require("./extract")
const utils = require("./utils")
const splatSet = utils.splatSet
const getSettings = require("./settings").getSettings
const getFileMode = require("./getFileMode")

const PREPARE_RULE_NAME = "__eslint-plugin-html-prepare"
const LINTER_ISPATCHED_PROPERTY_NAME =
  "__eslint-plugin-html-verify-function-is-patched"

// Disclaimer:
//
// This is not a long term viable solution. ESLint needs to improve its processor API to
// provide access to the configuration before actually preprocess files, but it's not
// planed yet. This solution is quite ugly but shouldn't alter eslint process.
//
// Related github issues:
// https://github.com/eslint/eslint/issues/3422
// https://github.com/eslint/eslint/issues/4153

const needles = [
  path.join("lib", "linter", "linter.js"), // ESLint 6+
  path.join("lib", "linter.js"), // ESLint 5-
]

iterateESLintModules(patch)

function getLinterFromModule(moduleExports) {
  return moduleExports.Linter
    ? moduleExports.Linter // ESLint 6+
    : moduleExports // ESLint 5-
}

function getModuleFromRequire() {
  return getLinterFromModule(require("eslint/lib/linter"))
}

function getModuleFromCache(key) {
  if (!needles.some((needle) => key.endsWith(needle))) return

  const module = require.cache[key]
  if (!module || !module.exports) return

  const Linter = getLinterFromModule(module.exports)
  if (
    typeof Linter === "function" &&
    typeof Linter.prototype.verify === "function"
  ) {
    return Linter
  }
}

function iterateESLintModules(fn) {
  if (!require.cache || Object.keys(require.cache).length === 0) {
    // Jest is replacing the node "require" function, and "require.cache" isn't available here.
    fn(getModuleFromRequire())
    return
  }

  let found = false

  for (const key in require.cache) {
    const Linter = getModuleFromCache(key)
    if (Linter) {
      fn(Linter)
      found = true
    }
  }

  if (!found) {
    let eslintPath, eslintVersion
    try {
      eslintPath = require.resolve("eslint")
    } catch (e) {
      eslintPath = "(not found)"
    }
    try {
      eslintVersion = require("eslint/package.json").version
    } catch (e) {
      eslintVersion = "n/a"
    }

    const parentPaths = (module) =>
      module ? [module.filename].concat(parentPaths(module.parent)) : []

    throw new Error(
      `eslint-plugin-html error: It seems that eslint is not loaded.
If you think this is a bug, please file a report at https://github.com/BenoitZugmeyer/eslint-plugin-html/issues

In the report, please include *all* those informations:

* ESLint version: ${eslintVersion}
* ESLint path: ${eslintPath}
* Plugin version: ${require("../package.json").version}
* Plugin inclusion paths: ${parentPaths(module).join(", ")}
* NodeJS version: ${process.version}
* CLI arguments: ${JSON.stringify(process.argv)}
* Content of your lock file (package-lock.json or yarn.lock) or the output of \`npm list\`
* How did you run ESLint (via the command line? an editor plugin?)
* The following stack trace:
    ${new Error().stack.slice(10)}


      `
    )
  }
}

function patch(Linter) {
  const verifyMethodName = Linter.prototype._verifyWithoutProcessors
    ? "_verifyWithoutProcessors" // ESLint 6+
    : "verify" // ESLint 5-
  const verify = Linter.prototype[verifyMethodName]

  // ignore if verify function is already been patched sometime before
  if (Linter[LINTER_ISPATCHED_PROPERTY_NAME] === true) {
    return
  }
  Linter[LINTER_ISPATCHED_PROPERTY_NAME] = true
  Linter.prototype[verifyMethodName] = function (
    textOrSourceCode,
    config,
    filenameOrOptions,
    saveState
  ) {
    const callOriginalVerify = () =>
      verify.call(this, textOrSourceCode, config, filenameOrOptions, saveState)

    if (typeof config.extractConfig === "function") {
      return callOriginalVerify()
    }

    const pluginSettings = getSettings(config.settings || {})
    const mode = getFileMode(pluginSettings, filenameOrOptions)

    if (!mode || typeof textOrSourceCode !== "string") {
      return callOriginalVerify()
    }

    let messages
    ;[messages, config] = verifyExternalHtmlPlugin(config, callOriginalVerify)

    if (config.parser && config.parser.id === "@html-eslint/parser") {
      messages.push(...callOriginalVerify())
      const rules = {}
      for (const name in config.rules) {
        if (!name.startsWith("@html-eslint/")) {
          rules[name] = config.rules[name]
        }
      }
      config = editConfig(config, {
        parser: null,
        rules,
      })
    }

    const extractResult = extract(
      textOrSourceCode,
      pluginSettings.indent,
      mode === "xml",
      pluginSettings.javaScriptTagNames,
      pluginSettings.isJavaScriptMIMEType
    )

    if (pluginSettings.reportBadIndent) {
      messages.push(
        ...extractResult.badIndentationLines.map((line) => ({
          message: "Bad line indentation.",
          line,
          column: 1,
          ruleId: "(html plugin)",
          severity: pluginSettings.reportBadIndent,
        }))
      )
    }

    // Save code parts parsed source code so we don't have to parse it twice
    const sourceCodes = new WeakMap()
    const verifyCodePart = (codePart, { prepare, ignoreRules } = {}) => {
      this.defineRule(PREPARE_RULE_NAME, (context) => {
        sourceCodes.set(codePart, context.getSourceCode())
        return {
          Program() {
            if (prepare) {
              prepare(context)
            }
          },
        }
      })

      const localMessages = verify.call(
        this,
        sourceCodes.get(codePart) || String(codePart),
        editConfig(config, {
          rules: Object.assign(
            { [PREPARE_RULE_NAME]: "error" },
            !ignoreRules && config.rules
          ),
        }),
        ignoreRules && typeof filenameOrOptions === "object"
          ? Object.assign({}, filenameOrOptions, {
              reportUnusedDisableDirectives: false,
            })
          : filenameOrOptions,
        saveState
      )

      messages.push(
        ...remapMessages(localMessages, extractResult.hasBOM, codePart)
      )
    }

    const parserOptions = config.parserOptions || {}
    if (parserOptions.sourceType === "module") {
      for (const codePart of extractResult.code) {
        verifyCodePart(codePart)
      }
    } else {
      verifyWithSharedScopes(extractResult.code, verifyCodePart, parserOptions)
    }

    messages.sort((ma, mb) => ma.line - mb.line || ma.column - mb.column)

    return messages
  }
}

function editConfig(config, { parser = config.parser, rules = config.rules }) {
  return {
    ...config,
    parser,
    rules,
  }
}

const externalHtmlPluginPrefixes = [
  "@html-eslint/",
  "@angular-eslint/template-",
]

function getParserId(config) {
  if (!config.parser) {
    return
  }

  if (typeof config.parser === "string") {
    // old versions of ESLint (ex: 4.7)
    return config.parser
  }

  return config.parser.id
}

function verifyExternalHtmlPlugin(config, callOriginalVerify) {
  const parserId = getParserId(config)
  const externalHtmlPluginPrefix =
    parserId &&
    externalHtmlPluginPrefixes.find((prefix) => parserId.startsWith(prefix))
  if (!externalHtmlPluginPrefix) {
    return [[], config]
  }

  const rules = {}
  for (const name in config.rules) {
    if (!name.startsWith(externalHtmlPluginPrefix)) {
      rules[name] = config.rules[name]
    }
  }

  return [
    callOriginalVerify(),
    editConfig(config, {
      parser: null,
      rules,
    }),
  ]
}

function verifyWithSharedScopes(codeParts, verifyCodePart, parserOptions) {
  // First pass: collect needed globals and declared globals for each script tags.
  const firstPassValues = []

  for (const codePart of codeParts) {
    verifyCodePart(codePart, {
      prepare(context) {
        const globalScope = context.getScope()
        // See https://github.com/eslint/eslint/blob/4b267a5c8a42477bb2384f33b20083ff17ad578c/lib/rules/no-redeclare.js#L67-L78
        let scopeForDeclaredGlobals
        if (
          parserOptions.ecmaFeatures &&
          parserOptions.ecmaFeatures.globalReturn
        ) {
          scopeForDeclaredGlobals = globalScope.childScopes[0]
        } else {
          scopeForDeclaredGlobals = globalScope
        }

        firstPassValues.push({
          codePart,
          exportedGlobals: globalScope.through.map(
            (node) => node.identifier.name
          ),
          declaredGlobals: scopeForDeclaredGlobals.variables.map(
            (variable) => variable.name
          ),
        })
      },
      ignoreRules: true,
    })
  }

  // Second pass: declare variables for each script scope, then run eslint.
  for (let i = 0; i < firstPassValues.length; i += 1) {
    verifyCodePart(firstPassValues[i].codePart, {
      prepare(context) {
        const exportedGlobals = splatSet(
          firstPassValues
            .slice(i + 1)
            .map((nextValues) => nextValues.exportedGlobals)
        )
        for (const name of exportedGlobals) context.markVariableAsUsed(name)

        const declaredGlobals = splatSet(
          firstPassValues
            .slice(0, i)
            .map((previousValues) => previousValues.declaredGlobals)
        )
        const scope = context.getScope()
        scope.through = scope.through.filter((variable) => {
          return !declaredGlobals.has(variable.identifier.name)
        })
      },
    })
  }
}

function remapMessages(messages, hasBOM, codePart) {
  const newMessages = []

  for (const message of messages) {
    if (remapMessage(message, hasBOM, codePart)) {
      newMessages.push(message)
    }
  }

  return newMessages
}

function remapMessage(message, hasBOM, codePart) {
  if (!message.line || !message.column) {
    // Some messages apply to the whole file instead of a particular code location. In particular:
    // * @typescript-eslint/parser may send messages with no line/column
    // * eslint-plugin-eslint-comments send messages with column=0 to bypass ESLint ignore comments.
    //   See https://github.com/BenoitZugmeyer/eslint-plugin-html/issues/70
    // For now, just include them in the output. In the future, we should make sure those messages
    // are not print twice.
    return true
  }

  const location = codePart.originalLocation({
    line: message.line,
    column: message.column,
  })

  // Ignore messages if they were in transformed code
  if (!location) {
    return false
  }

  Object.assign(message, location)
  message.source = codePart.getOriginalLine(location.line)

  // Map fix range
  if (message.fix && message.fix.range) {
    const bomOffset = hasBOM ? -1 : 0
    message.fix.range = [
      codePart.originalIndex(message.fix.range[0]) + bomOffset,
      // The range end is exclusive, meaning it should replace all characters  with indexes from
      // start to end - 1. We have to get the original index of the last targeted character.
      codePart.originalIndex(message.fix.range[1] - 1) + 1 + bomOffset,
    ]
  }

  // Map end location
  if (message.endLine && message.endColumn) {
    const endLocation = codePart.originalLocation({
      line: message.endLine,
      column: message.endColumn,
    })
    if (endLocation) {
      message.endLine = endLocation.line
      message.endColumn = endLocation.column
    }
  }

  return true
}
