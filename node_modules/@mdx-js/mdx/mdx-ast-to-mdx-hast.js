const toHAST = require('mdast-util-to-hast')
const detab = require('detab')
const u = require('unist-builder')

function mdxAstToMdxHast() {
  return (tree, _file) => {
    const handlers = {
      // `inlineCode` gets passed as `code` by the HAST transform.
      // This makes sure it ends up being `inlineCode`
      inlineCode(h, node) {
        return Object.assign({}, node, {
          type: 'element',
          tagName: 'inlineCode',
          properties: {},
          children: [
            {
              type: 'text',
              value: node.value
            }
          ]
        })
      },
      code(h, node) {
        const value = node.value ? detab(node.value + '\n') : ''
        const lang = node.lang
        const props = {}

        if (lang) {
          props.className = ['language-' + lang]
        }

        // MDAST sets `node.meta` to `null` instead of `undefined` if
        // not present, which React doesn't like.
        props.metastring = node.meta || undefined

        const meta =
          node.meta &&
          node.meta.split(' ').reduce((acc, cur) => {
            if (cur.split('=').length > 1) {
              const t = cur.split('=')
              acc[t[0]] = t[1]
              return acc
            }

            acc[cur] = true
            return acc
          }, {})

        if (meta) {
          Object.keys(meta).forEach(key => {
            const isClassKey = key === 'class' || key === 'className'
            if (props.className && isClassKey) {
              props.className.push(meta[key])
            } else {
              props[key] = meta[key]
            }
          })
        }

        return h(node.position, 'pre', [
          h(node, 'code', props, [u('text', value)])
        ])
      },
      import(h, node) {
        return Object.assign({}, node, {
          type: 'import'
        })
      },
      export(h, node) {
        return Object.assign({}, node, {
          type: 'export'
        })
      },
      comment(h, node) {
        return Object.assign({}, node, {
          type: 'comment'
        })
      },
      jsx(h, node) {
        return Object.assign({}, node, {
          type: 'jsx'
        })
      }
    }

    const hast = toHAST(tree, {
      handlers,
      // Enable passing of HTML nodes to HAST as raw nodes
      allowDangerousHtml: true
    })

    return hast
  }
}

module.exports = mdxAstToMdxHast
