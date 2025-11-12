// @TODO remove @ts-ignore

import { VNode, vModelText, vModelCheckbox, vModelSelect, vModelRadio, vModelDynamic, Text } from 'vue'
import { pascalCase, camelCase } from 'change-case'
import { createAutoBuildingObject, indent, serializeJs, voidElements } from '@histoire/shared'
import type { Variant } from '@histoire/shared'

export async function generateSourceCode (variant: Variant) {
  const vnode = variant.slots().default?.({ state: variant.state ?? {} }) ?? []
  const list = Array.isArray(vnode) ? vnode : [vnode]
  const lines: string[] = []
  for (const n in list) {
    const vnode = list[n]
    lines.push(...(await printVNode(vnode, variant.state?._hPropState?.[n])).lines)
  }
  return lines.join('\n')
}

async function printVNode (vnode: VNode, propsOverrides: Record<string, any> = null): Promise<{ lines: string[], isText?: boolean }> {
  if (vnode.type === Text) {
    return {
      // @ts-ignore
      lines: [vnode.children],
      isText: true,
    }
  }

  const lines: string[] = []

  if (typeof vnode.type === 'object' || typeof vnode.type === 'string') {
    // Wait for async component
    // @ts-ignore
    if (vnode.type?.__asyncLoader && !vnode.type.__asyncResolved) {
      // @ts-ignore
      await vnode.type.__asyncLoader()
    }

    const attrs: string[][] = []
    let multilineAttrs = false
    const skipProps: string[] = [
      'key',
    ]

    // Directives
    function genDirective (dirName: string, dir, valueCode: string = null) {
      let modifiers = ''
      for (const key in dir.modifiers) {
        if (dir.modifiers[key]) {
          modifiers += `.${key}`
        }
      }
      let arg = ''
      if (dir.arg) {
        arg = `:${dir.arg}`
      }
      if (valueCode) {
        // Cleanup render code
        valueCode = valueCode.replace(/^\$(setup|props|data)\./g, '')
      }
      const valueLines = valueCode ? [valueCode] : serializeAndCleanJs(dir.value)
      const attr: string[] = []
      const dirAttr = `v-${dirName}${arg}${modifiers}="`
      if (valueLines.length > 1) {
        attr.push(`${dirAttr}${valueLines[0]}`)
        attr.push(...valueLines.slice(1, valueLines.length - 1))
        attr.push(`${valueLines[valueLines.length - 1]}"`)
        multilineAttrs = true
      } else {
        attr.push(`${dirAttr}${valueLines[0] ?? ''}"`)
      }
      attrs.push(attr)
    }
    if (vnode.dirs) {
      for (const dir of vnode.dirs) {
        // Vmodel
        if (dir.dir === vModelText || dir.dir === vModelSelect || dir.dir === vModelRadio || dir.dir === vModelCheckbox || dir.dir === vModelDynamic) {
          const listenerKeys = [`onUpdate:${dir.arg ?? 'modelValue'}`, `onUpdate:${camelCase(dir.arg ?? 'modelValue')}`]
          const listenerKey = listenerKeys.find(key => vnode.props[key])
          const listener = vnode.props[listenerKey]
          let valueCode: string = null
          if (listener) {
            skipProps.push(listenerKey)
            const listenerSource = listener.toString()
            const result = /\(\$event\) => (.*?) = \$event/.exec(listenerSource)
            if (result) {
              valueCode = result[1]
            }
          }
          genDirective('model', dir, valueCode)
          // @ts-ignore
        } else if (dir.instance._ || dir.instance.$) {
          // @ts-ignore
          const target = dir.instance.$ ?? dir.instance._
          let dirName: string
          for (const directives of [target.directives, target.appContext.directives]) {
            for (const key in directives) {
              if (directives[key] === dir.dir) {
                dirName = key
                break
              }
            }
            if (dirName) break
          }
          if (dirName) {
            genDirective(dirName, dir)
          }
        }
      }
    }

    // Attributes
    function addAttr (prop: string, value: any) {
      // @ts-ignore
      if (typeof value !== 'string' || vnode.dynamicProps?.includes(prop)) {
        let directive = ':'
        if (prop.startsWith('on')) {
          directive = '@'
        }
        const arg = directive === '@' ? `${prop[2].toLowerCase()}${prop.slice(3)}` : prop

        // v-model on component
        const vmodelListeners = [`onUpdate:${prop}`, `onUpdate:${camelCase(prop)}`]
        // @ts-ignore
        const vmodelListener = vmodelListeners.find(key => vnode.dynamicProps?.includes(key) || (vnode.props && key in vnode.props))
        if (directive === ':' && vmodelListener) {
          // Listener
          skipProps.push(vmodelListener)
          const listener = vnode.props[vmodelListener]
          const listenerSource = listener.toString()
          let valueCode: string
          const result = /\(\$event\) => (.*?) = \$event/.exec(listenerSource)
          if (result) {
            valueCode = result[1]
          }

          // Modifiers
          const modifiersKey = `${prop === 'modelValue' ? 'model' : prop}Modifiers`
          const modifiers = vnode.props[modifiersKey] ?? {}
          skipProps.push(modifiersKey)

          // Directive
          genDirective('model', {
            arg: prop === 'modelValue' ? null : prop,
            modifiers,
            value,
          }, valueCode)
          return
        }

        if (typeof value === 'undefined') {
          return
        }

        let serialized: string[]
        if (typeof value === 'string' && value.startsWith('{{') && value.endsWith('}}')) {
          // It was formatted from auto building object (slot props)
          serialized = cleanupExpression(value.substring(2, value.length - 2).trim()).split('\n')
        } else if (typeof value === 'function') {
          let code = cleanupExpression(value.toString().replace(/'/g, '\\\'').replace(/"/g, '\''))
          const testResult = /function ([^\s]+)\(/.exec(code)
          if (testResult) {
            // Function name only
            serialized = [testResult[1]]
          } else {
            if (code.startsWith('($event) => ')) {
              // Remove unnecessary `($event) => `
              code = code.substring('($event) => '.length)
            }
            serialized = code.split('\n')
          }
        } else {
          serialized = serializeAndCleanJs(value)
        }
        if (serialized.length > 1) {
          multilineAttrs = true
          const indented: string[] = [`${directive}${arg}="${serialized[0]}`]
          indented.push(...serialized.slice(1, serialized.length - 1))
          indented.push(`${serialized[serialized.length - 1]}"`)
          attrs.push(indented)
        } else {
          attrs.push([`${directive}${arg}="${serialized[0]}"`])
        }
        // @ts-ignore
      } else if (vnode.type?.props?.[prop]?.type === Boolean) {
        attrs.push([prop])
      } else {
        attrs.push([`${prop}="${value}"`])
      }
    }

    for (const prop in vnode.props) {
      if (skipProps.includes(prop) || (propsOverrides && prop in propsOverrides)) {
        continue
      }
      const value = vnode.props[prop]
      addAttr(prop, value)
    }

    if (propsOverrides) {
      for (const prop in propsOverrides) {
        addAttr(prop, propsOverrides[prop])
      }
    }

    if (attrs.length > 1) {
      multilineAttrs = true
    }

    // Tags
    const tagName = getTagName(vnode)

    // Children
    let isChildText = false
    const childLines: string[] = []
    if (typeof vnode.children === 'string') {
      if (tagName === 'pre') {
        childLines.push(vnode.children)
      } else {
        childLines.push(...vnode.children.split('\n'))
      }
      isChildText = true
    } else if (Array.isArray(vnode.children)) {
      let isAllChildText
      for (const child of vnode.children) {
        // @ts-ignore
        const result = await printVNode(child)
        if (result.isText) {
          if (isAllChildText === undefined) {
            isAllChildText = true
          }
          const text = result.lines[0]
          if (!childLines.length || /^\s/.test(text)) {
            childLines.push(text.trim())
          } else {
            childLines[childLines.length - 1] += text
          }
        } else {
          if (isAllChildText === undefined) {
            isAllChildText = false
          }
          childLines.push(...result.lines)
        }
      }
      if (isAllChildText !== undefined) {
        isChildText = isAllChildText
      }
    }

    // Slots
    if (vnode.children && typeof vnode.children === 'object' && !Array.isArray(vnode.children)) {
      for (const key in vnode.children) {
        if (typeof vnode.children[key] === 'function') {
          const autoObject = createAutoBuildingObject(key => `{{ ${key} }}`, (target, p) => {
            // Vue 3
            if (p === '__v_isRef') {
              return () => false
            }
          })
          // @ts-ignore
          const children = vnode.children[key](autoObject.proxy)
          const slotLines: string[] = []
          for (const child of children) {
            slotLines.push(...(await printVNode(child)).lines)
          }
          const slotProps = Object.keys(autoObject.cache)
          if (slotProps.length) {
            childLines.push(`<template #${key}="{ ${slotProps.join(', ')} }">`)
            childLines.push(...indent(slotLines))
            childLines.push('</template>')
          } else if (key === 'default') {
            childLines.push(...slotLines)
          } else {
            childLines.push(`<template #${key}>`)
            childLines.push(...indent(slotLines))
            childLines.push(`</template>`)
          }
        }
      }
    }

    // Template
    const tag = [`<${tagName}`]
    if (multilineAttrs) {
      for (const attrLines of attrs) {
        tag.push(...indent(attrLines))
      }
      if (childLines.length > 0) {
        tag.push('>')
      }
    } else {
      if (attrs.length === 1) {
        tag[0] += ` ${attrs[0]}`
      }
      if (childLines.length > 0) {
        tag[0] += '>'
      }
    }

    const isVoid = voidElements.includes(tagName.toLowerCase())

    if (childLines.length > 0) {
      if (childLines.length === 1 && tag.length === 1 && !attrs.length && isChildText) {
        lines.push(`${tag[0]}${childLines[0]}</${tagName}>`)
      } else {
        lines.push(...tag)
        lines.push(...indent(childLines))
        lines.push(`</${tagName}>`)
      }
    } else if (tag.length > 1) {
      lines.push(...tag)
      lines.push(isVoid ? '>' : '/>')
    } else {
      lines.push(`${tag[0]}${isVoid ? '' : ' /'}>`)
    }
  } else if (vnode?.shapeFlag & 1 << 4) {
    // @ts-ignore
    for (const child of vnode.children) {
      lines.push(...(await printVNode(child)).lines)
    }
  }

  return {
    lines,
  }
}

export function getTagName (vnode: VNode) {
  if (typeof vnode.type === 'string') {
    return vnode.type
    // @ts-ignore
  } else if (vnode.type?.__asyncResolved) {
    // @ts-ignore
    const asyncComp = vnode.type?.__asyncResolved
    return asyncComp.name ?? getNameFromFile(asyncComp.__file)
    // @ts-ignore
  } else if (vnode.type?.name) {
    // @ts-ignore
    return vnode.type.name
    // @ts-ignore
  } else if (vnode.type?.__file) {
    // @ts-ignore
    return getNameFromFile(vnode.type.__file)
  }
  return 'Anonymous'
}

function getNameFromFile (file: string) {
  const parts = /([^/]+)\.vue$/.exec(file)
  if (parts) {
    return pascalCase(parts[1])
  }
  return 'Anonymous'
}

function serializeAndCleanJs (value: any) {
  const isAutoBuildingObject = !!value?.__autoBuildingObject
  const result = serializeJs(value)
  if (isAutoBuildingObject) {
    // @ts-ignore
    return [cleanupExpression(result.__autoBuildingObjectGetKey)]
  } else {
    return cleanupExpression(result).split('\n')
  }
}

function cleanupExpression (expr: string) {
  return expr.replace(/\$setup\./g, '')
}
