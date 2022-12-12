const {types: t} = require('@babel/core')
const {declare} = require('@babel/helper-plugin-utils')
const {startsWithCapitalLetter} = require('@mdx-js/util')

class BabelPluginApplyMdxTypeProp {
  constructor() {
    const names = []
    this.state = {names}

    this.plugin = declare(api => {
      api.assertVersion(7)

      return {
        visitor: {
          JSXOpeningElement(path) {
            const jsxName = path.node.name.name

            if (startsWithCapitalLetter(jsxName)) {
              names.push(jsxName)

              path.node.attributes.push(
                t.jSXAttribute(
                  t.jSXIdentifier(`mdxType`),
                  t.stringLiteral(jsxName)
                )
              )
            }
          }
        }
      }
    })
  }
}

module.exports = BabelPluginApplyMdxTypeProp
