'use strict'

var allowedModifiers = ['trim', 'number', 'lazy']
var RANGE_TOKEN = '__r'
var CHECKBOX_RADIO_TOKEN = '__c'

var htmlTags = require('html-tags')

var svgTags = require('svg-tags')

var isReservedTag = function isReservedTag(tag) {
  return ~htmlTags.indexOf(tag) || ~svgTags.indexOf(tag)
}

var getExpression = function getExpression(t, path) {
  return t.isStringLiteral(path.node.value) ? path.node.value : path.node.value.expression
}

var genValue = function genValue(t, model) {
  return t.jSXAttribute(t.jSXIdentifier('domPropsValue'), t.jSXExpressionContainer(model))
}

var genAssignmentCode = function genAssignmentCode(t, model, assignment) {
  if (model.computed) {
    var object = model.object,
      property = model.property

    return t.ExpressionStatement(
      t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('$set')), [object, property, assignment])
    )
  } else {
    return t.ExpressionStatement(t.AssignmentExpression('=', model, assignment))
  }
}

var genListener = function genListener(t, event, body) {
  return t.jSXAttribute(
    t.jSXIdentifier('on' + event),
    t.jSXExpressionContainer(t.ArrowFunctionExpression([t.Identifier('$event')], t.BlockStatement(body)))
  )
}

var genSelectModel = function genSelectModel(t, modelAttribute, model, modifier) {
  if (modifier && modifier !== 'number') {
    throw modelAttribute.get('name').get('name').buildCodeFrameError('you can only use number modifier with <select/ >')
  }

  var number = modifier === 'number'

  var valueGetter = t.ConditionalExpression(
    t.BinaryExpression('in', t.StringLiteral('_value'), t.Identifier('o')),
    t.MemberExpression(t.Identifier('o'), t.Identifier('_value')),
    t.MemberExpression(t.Identifier('o'), t.Identifier('value'))
  )

  var selectedVal = t.CallExpression(
    t.MemberExpression(
      t.CallExpression(
        t.MemberExpression(
          t.MemberExpression(
            t.MemberExpression(t.Identifier('Array'), t.Identifier('prototype')),
            t.Identifier('filter')
          ),
          t.Identifier('call')
        ),
        [
          t.MemberExpression(
            t.MemberExpression(t.Identifier('$event'), t.Identifier('target')),
            t.Identifier('options')
          ),
          t.ArrowFunctionExpression(
            [t.Identifier('o')],
            t.MemberExpression(t.Identifier('o'), t.Identifier('selected'))
          )
        ]
      ),
      t.Identifier('map')
    ),
    [
      t.ArrowFunctionExpression(
        [t.Identifier('o')],
        number
          ? t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [valueGetter])
          : valueGetter
      )
    ]
  )

  var assignment = t.ConditionalExpression(
    t.MemberExpression(t.MemberExpression(t.Identifier('$event'), t.Identifier('target')), t.Identifier('multiple')),
    t.Identifier('$$selectedVal'),
    t.MemberExpression(t.Identifier('$$selectedVal'), t.NumericLiteral(0), true)
  )

  var code = t.VariableDeclaration('const', [t.VariableDeclarator(t.Identifier('$$selectedVal'), selectedVal)])

  return [genValue(t, model), genListener(t, 'Change', [code, genAssignmentCode(t, model, assignment)])]
}

var genCheckboxModel = function genCheckboxModel(t, modelAttribute, model, modifier, path) {
  if (modifier && modifier !== 'number') {
    throw modelAttribute
      .get('name')
      .get('name')
      .buildCodeFrameError('you can only use number modifier with input[type="checkbox"]')
  }

  var value = t.NullLiteral()
  var trueValue = t.BooleanLiteral(true)
  var falseValue = t.BooleanLiteral(false)

  path.get('attributes').forEach(function(path) {
    if (!path.node.name) {
      return
    }

    if (path.node.name.name === 'value') {
      value = getExpression(t, path)
      path.remove()
    } else if (path.node.name.name === 'true-value') {
      trueValue = getExpression(t, path)
      path.remove()
    } else if (path.node.name.name === 'false-value') {
      falseValue = getExpression(t, path)
      path.remove()
    }
  })

  var checkedProp = t.JSXAttribute(
    t.JSXIdentifier('checked'),
    t.JSXExpressionContainer(
      t.ConditionalExpression(
        t.CallExpression(t.MemberExpression(t.Identifier('Array'), t.Identifier('isArray')), [model]),
        t.BinaryExpression(
          '>',
          t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_i')), [model, value]),
          t.UnaryExpression('-', t.NumericLiteral(1))
        ),
        t.isBooleanLiteral(trueValue) && trueValue.value === true
          ? model
          : t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_q')), [model, trueValue])
      )
    )
  )

  var handlerProp = t.JSXAttribute(
    t.JSXIdentifier('on' + CHECKBOX_RADIO_TOKEN),
    t.JSXExpressionContainer(
      t.ArrowFunctionExpression(
        [t.Identifier('$event')],
        t.BlockStatement([
          t.VariableDeclaration('const', [
            t.VariableDeclarator(t.Identifier('$$a'), model),
            t.VariableDeclarator(
              t.Identifier('$$el'),
              t.MemberExpression(t.Identifier('$event'), t.Identifier('target'))
            ),
            t.VariableDeclarator(
              t.Identifier('$$c'),
              t.ConditionalExpression(
                t.MemberExpression(t.Identifier('$$el'), t.Identifier('checked')),
                trueValue,
                falseValue
              )
            )
          ]),
          t.IfStatement(
            t.CallExpression(t.MemberExpression(t.Identifier('Array'), t.Identifier('isArray')), [t.Identifier('$$a')]),
            t.BlockStatement([
              t.VariableDeclaration('const', [
                t.VariableDeclarator(
                  t.Identifier('$$v'),
                  modifier === 'number'
                    ? t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [value])
                    : value
                ),
                t.VariableDeclarator(
                  t.Identifier('$$i'),
                  t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_i')), [
                    t.Identifier('$$a'),
                    t.Identifier('$$v')
                  ])
                )
              ]),
              t.IfStatement(
                t.MemberExpression(t.Identifier('$$el'), t.Identifier('checked')),
                t.BlockStatement([
                  t.ExpressionStatement(
                    t.LogicalExpression(
                      '&&',
                      t.BinaryExpression('<', t.Identifier('$$i'), t.NumericLiteral(0)),
                      t.AssignmentExpression(
                        '=',
                        model,
                        t.CallExpression(t.MemberExpression(t.Identifier('$$a'), t.Identifier('concat')), [
                          t.Identifier('$$v')
                        ])
                      )
                    )
                  )
                ]),
                t.BlockStatement([
                  t.ExpressionStatement(
                    t.LogicalExpression(
                      '&&',
                      t.BinaryExpression('>', t.Identifier('$$i'), t.UnaryExpression('-', t.NumericLiteral(1))),
                      t.AssignmentExpression(
                        '=',
                        model,
                        t.CallExpression(
                          t.MemberExpression(
                            t.CallExpression(t.MemberExpression(t.Identifier('$$a'), t.Identifier('slice')), [
                              t.NumericLiteral(0),
                              t.Identifier('$$i')
                            ]),
                            t.Identifier('concat')
                          ),
                          [
                            t.CallExpression(t.MemberExpression(t.Identifier('$$a'), t.Identifier('slice')), [
                              t.BinaryExpression('+', t.Identifier('$$i'), t.NumericLiteral(1))
                            ])
                          ]
                        )
                      )
                    )
                  )
                ])
              )
            ]),
            t.BlockStatement([genAssignmentCode(t, model, t.Identifier('$$c'))])
          )
        ])
      )
    )
  )

  return [checkedProp, handlerProp]
}

var genRadioModel = function genRadioModel(t, modelAttribute, model, modifier, path) {
  if (modifier && modifier !== 'number') {
    throw modelAttribute
      .get('name')
      .get('name')
      .buildCodeFrameError('you can only use number modifier with input[type="radio"]')
  }

  var value = t.BooleanLiteral(true)

  path.get('attributes').forEach(function(path) {
    if (!path.node.name) {
      return
    }

    if (path.node.name.name === 'value') {
      value = getExpression(t, path)
      path.remove()
    }
  })

  var checkedProp = t.JSXAttribute(
    t.JSXIdentifier('checked'),
    t.JSXExpressionContainer(
      t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_q')), [model, value])
    )
  )

  var handlerProp = t.JSXAttribute(
    t.JSXIdentifier('on' + CHECKBOX_RADIO_TOKEN),
    t.JSXExpressionContainer(
      t.ArrowFunctionExpression(
        [t.Identifier('$event')],
        t.BlockStatement([
          genAssignmentCode(
            t,
            model,
            modifier === 'number'
              ? t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [value])
              : value
          )
        ])
      )
    )
  )

  return [checkedProp, handlerProp]
}

var genDefaultModel = function genDefaultModel(t, modelAttribute, model, modifier, path, type) {
  var needCompositionGuard = modifier !== 'lazy' && type !== 'range'

  var event = modifier === 'lazy' ? 'Change' : type === 'range' ? RANGE_TOKEN : 'Input'

  var valueExpression = t.MemberExpression(
    t.MemberExpression(t.Identifier('$event'), t.Identifier('target')),
    t.Identifier('value')
  )

  if (modifier === 'trim') {
    valueExpression = t.CallExpression(t.MemberExpression(valueExpression, t.Identifier('trim')), [])
  } else if (modifier === 'number') {
    valueExpression = t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [valueExpression])
  }

  var code = genAssignmentCode(t, model, valueExpression)

  if (needCompositionGuard) {
    code = t.BlockStatement([
      t.IfStatement(
        t.MemberExpression(
          t.MemberExpression(t.Identifier('$event'), t.Identifier('target')),
          t.Identifier('composing')
        ),
        t.ReturnStatement(null)
      ),
      code
    ])
  } else {
    code = t.BlockStatement([code])
  }

  var valueProp = t.JSXAttribute(t.jSXIdentifier('domPropsValue'), t.JSXExpressionContainer(model))

  var handlerProp = t.JSXAttribute(
    t.JSXIdentifier('on' + event),
    t.JSXExpressionContainer(t.ArrowFunctionExpression([t.Identifier('$event')], code))
  )

  var props = [valueProp, handlerProp]

  if (modifier === 'trim' || modifier === 'number') {
    props.push(
      t.JSXAttribute(
        t.JSXIdentifier('onBlur'),
        t.JSXExpressionContainer(
          t.ArrowFunctionExpression(
            [],
            t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('$forceUpdate')), [])
          )
        )
      )
    )
  }

  return props
}

var genComponentModel = function genComponentModel(t, modelAttribute, model, modifier, path, type) {
  var baseValueExpression = t.Identifier('$$v')
  var valueExpression = baseValueExpression

  if (modifier === 'trim') {
    valueExpression = t.CallExpression(t.MemberExpression(valueExpression, t.Identifier('trim')), [])
  } else if (modifier === 'number') {
    valueExpression = t.CallExpression(t.MemberExpression(t.ThisExpression(), t.Identifier('_n')), [valueExpression])
  }

  var assignment = genAssignmentCode(t, model, valueExpression)

  var valueProp = t.JSXAttribute(t.jSXIdentifier('value'), t.JSXExpressionContainer(model))

  var handlerProp = t.JSXAttribute(
    t.JSXIdentifier('onInput'),
    t.JSXExpressionContainer(t.ArrowFunctionExpression([baseValueExpression], t.BlockStatement([assignment])))
  )

  return [valueProp, handlerProp]
}

module.exports = function(babel) {
  var t = babel.types

  return {
    inherits: require('babel-plugin-syntax-jsx'),
    visitor: {
      JSXOpeningElement: function JSXOpeningElement(path) {
        var model = null
        var modifier = null
        var modelAttribute = null
        var type = null
        var typePath = null

        path.get('attributes').forEach(function(path) {
          if (!path.node.name) {
            return
          }

          if (path.node.name.name === 'type') {
            type = path.node.value.value
            typePath = path.get('value')
          }
          /* istanbul ignore else */
          if (t.isJSXIdentifier(path.node.name)) {
            if (path.node.name.name !== 'v-model') {
              return
            }
          } else if (t.isJSXNamespacedName(path.node.name)) {
            if (path.node.name.namespace.name !== 'v-model') {
              return
            }

            if (!~allowedModifiers.indexOf(path.node.name.name.name)) {
              throw path
                .get('name')
                .get('name')
                .buildCodeFrameError('v-model does not support "' + path.node.name.name.name + '" modifier')
            }

            modifier = path.node.name.name.name
          } else {
            return
          }

          modelAttribute = path

          if (model) {
            throw path.buildCodeFrameError('you can not have multiple v-model directives on a single element')
          }

          if (!t.isJSXExpressionContainer(path.node.value)) {
            throw path.get('value').buildCodeFrameError('you should use JSX Expression with v-model')
          }

          if (!t.isMemberExpression(path.node.value.expression)) {
            throw path
              .get('value')
              .get('expression')
              .buildCodeFrameError('you should use MemberExpression with v-model')
          }

          model = path.node.value.expression
        })

        if (!model) {
          return
        }

        var tag = path.node.name.name

        if (tag === 'input' && typePath && t.isJSXExpressionContainer(typePath.node)) {
          throw typePath.buildCodeFrameError('you can not use dynamic type with v-model')
        }
        if (tag === 'input' && type === 'file') {
          throw typePath.buildCodeFrameError('you can not use "file" type with v-model')
        }

        var replacement = null

        if (tag === 'select') {
          replacement = genSelectModel(t, modelAttribute, model, modifier)
        } else if (tag === 'input' && type === 'checkbox') {
          replacement = genCheckboxModel(t, modelAttribute, model, modifier, path)
        } else if (tag === 'input' && type === 'radio') {
          replacement = genRadioModel(t, modelAttribute, model, modifier, path)
        } else if (tag === 'input' || tag === 'textarea') {
          replacement = genDefaultModel(t, modelAttribute, model, modifier, path, type)
        } else if (!isReservedTag(tag)) {
          replacement = genComponentModel(t, modelAttribute, model, modifier, path)
        } else {
          throw path.buildCodeFrameError('you can not use "' + tag + '" with v-model')
        }

        modelAttribute.replaceWithMultiple([
          ...replacement,
          t.JSXSpreadAttribute(
            t.ObjectExpression([
              t.ObjectProperty(
                t.Identifier('directives'),
                t.ArrayExpression([
                  t.ObjectExpression([
                    t.ObjectProperty(t.Identifier('name'), t.StringLiteral('model')),
                    t.ObjectProperty(t.Identifier('value'), model)
                  ])
                ])
              )
            ])
          )
        ])
      }
    }
  }
}
