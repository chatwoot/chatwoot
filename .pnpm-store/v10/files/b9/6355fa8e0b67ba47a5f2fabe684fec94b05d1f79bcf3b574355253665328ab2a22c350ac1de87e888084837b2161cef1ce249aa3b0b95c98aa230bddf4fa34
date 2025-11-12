const {
  isTypeNode,
  extractRuntimeProps,
  isTSTypeLiteral,
  isTSTypeLiteralOrTSFunctionType,
  extractRuntimeEmits,
  flattenTypeNodes,
  isTSInterfaceBody
} = require('./ts-ast')
const {
  getComponentPropsFromTypeDefineTypes,
  getComponentEmitsFromTypeDefineTypes
} = require('./ts-types')

/**
 * @typedef {import('@typescript-eslint/types').TSESTree.TypeNode} TSESTreeTypeNode
 */
/**
 * @typedef {import('../index').ComponentTypeProp} ComponentTypeProp
 * @typedef {import('../index').ComponentInferTypeProp} ComponentInferTypeProp
 * @typedef {import('../index').ComponentUnknownProp} ComponentUnknownProp
 * @typedef {import('../index').ComponentTypeEmit} ComponentTypeEmit
 * @typedef {import('../index').ComponentInferTypeEmit} ComponentInferTypeEmit
 * @typedef {import('../index').ComponentUnknownEmit} ComponentUnknownEmit
 */

module.exports = {
  isTypeNode,
  getComponentPropsFromTypeDefine,
  getComponentEmitsFromTypeDefine
}

/**
 * Get all props by looking at all component's properties
 * @param {RuleContext} context The ESLint rule context object.
 * @param {TypeNode} propsNode Type with props definition
 * @return {(ComponentTypeProp|ComponentInferTypeProp|ComponentUnknownProp)[]} Array of component props
 */
function getComponentPropsFromTypeDefine(context, propsNode) {
  /** @type {(ComponentTypeProp|ComponentInferTypeProp|ComponentUnknownProp)[]} */
  const result = []
  for (const defNode of flattenTypeNodes(
    context,
    /** @type {TSESTreeTypeNode} */ (propsNode)
  )) {
    if (isTSInterfaceBody(defNode) || isTSTypeLiteral(defNode)) {
      result.push(...extractRuntimeProps(context, defNode))
    } else {
      result.push(
        ...getComponentPropsFromTypeDefineTypes(
          context,
          /** @type {TypeNode} */ (defNode)
        )
      )
    }
  }
  return result
}

/**
 * Get all emits by looking at all component's properties
 * @param {RuleContext} context The ESLint rule context object.
 * @param {TypeNode} emitsNode Type with emits definition
 * @return {(ComponentTypeEmit|ComponentInferTypeEmit|ComponentUnknownEmit)[]} Array of component emits
 */
function getComponentEmitsFromTypeDefine(context, emitsNode) {
  /** @type {(ComponentTypeEmit|ComponentInferTypeEmit|ComponentUnknownEmit)[]} */
  const result = []
  for (const defNode of flattenTypeNodes(
    context,
    /** @type {TSESTreeTypeNode} */ (emitsNode)
  )) {
    if (
      isTSInterfaceBody(defNode) ||
      isTSTypeLiteralOrTSFunctionType(defNode)
    ) {
      result.push(...extractRuntimeEmits(defNode))
    } else {
      result.push(
        ...getComponentEmitsFromTypeDefineTypes(
          context,
          /** @type {TypeNode} */ (defNode)
        )
      )
    }
  }
  return result
}
