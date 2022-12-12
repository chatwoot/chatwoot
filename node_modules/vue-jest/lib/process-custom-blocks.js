const { getVueJestConfig, getCustomTransformer } = require('./utils')
const vueOptionsNamespace = require('./constants').vueOptionsNamespace

function applyTransformer(
  transformer,
  blocks,
  vueOptionsNamespace,
  filename,
  config
) {
  return transformer.process({ blocks, vueOptionsNamespace, filename, config })
}

function groupByType(acc, block) {
  acc[block.type] = acc[block.type] || []
  acc[block.type].push(block)
  return acc
}

module.exports = function(allBlocks, filename, config) {
  const blocksByType = allBlocks.reduce(groupByType, {})
  const code = []
  for (const [type, blocks] of Object.entries(blocksByType)) {
    const transformer = getCustomTransformer(
      getVueJestConfig(config).transform,
      type
    )
    if (transformer) {
      const codeStr = applyTransformer(
        transformer,
        blocks,
        vueOptionsNamespace,
        filename,
        config
      )
      code.push(codeStr)
    }
  }

  return code.length ? code.join('\n') : ''
}
