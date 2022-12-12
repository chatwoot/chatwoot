const {declare} = require('@babel/helper-plugin-utils')

class BabelPluginExtractImportNames {
  constructor() {
    const names = []
    this.state = {names}

    this.plugin = declare(api => {
      api.assertVersion(7)

      return {
        visitor: {
          ImportDeclaration(path) {
            path.traverse({
              Identifier(path) {
                if (path.key === 'local') {
                  names.push(path.node.name)
                }
              }
            })
          }
        }
      }
    })
  }
}

module.exports = BabelPluginExtractImportNames
