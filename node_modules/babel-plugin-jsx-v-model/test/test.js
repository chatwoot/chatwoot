import test from 'ava'
import { transform } from 'babel-core'

const transpile = src => {
  return transform(src, {
    plugins: './index'
  }).code.trim()
}

const testTranspile = (title, code) => {
  test(title, t => {
    const compiled = transpile(code)

    t.snapshot(code, 'Initial code')
    t.snapshot(compiled, 'Compiled code')
  })
}

const testError = (title, code) => {
  test(title, t => {
    const error = t.throws(() => transpile(code), SyntaxError)

    t.snapshot(code, 'Initial code')
    t.snapshot(error.message, 'Error mesage')
  })
}

testError(
  'Error: input[type={dynamic}, v-model]',
  `
  <input
    type={e}
    v-model={a.b}
  />
`
)
testError(
  'Error: input[v-model:invalidModifier]',
  `
  <input
    v-model:invalidModifier={a.b}
  />
`
)
testError(
  'Error: input[v-model, v-model]',
  `
  <input
    v-model={a.b}
    v-model={a.b}
  />
`
)
testError(
  'Error: input[v-model="string literal"]',
  `
  <input
    v-model="string literal"
  />
`
)
testError(
  'Error: input[v-model={identifier}]',
  `
  <input
    v-model={identifier}
  />
`
)
testError(
  'Error: h3',
  `
  <h3
    v-model={a.b}
  />
`
)
testError(
  'Error: select[v-model:trim]',
  `
  <select
    v-model:trim={a.b}
  />
`
)
testError(
  'Error: input[type="checkbox",v-model:trim]',
  `
  <input
    type="checkbox"
    v-model:trim={a.b}
  />
`
)
testError(
  'Error: input[type="radio",v-model:trim]',
  `
  <input
    type="radio"
    v-model:trim={a.b}
  />
`
)
testError(
  'Error: input[type="file",v-model]',
  `
  <input
    type="file"
    v-model={a.b}
  />
`
)

testTranspile(
  'Ignores namespaced attributes',
  `
  <input
    onClick:prevent={hey}
  />
`
)
testTranspile(
  'textarea[v-model]',
  `
  <textarea
    v-model={a.b}
  />
`
)
testTranspile(
  'input[v-model]',
  `
  <input
    v-model={a.b}
  />
`
)
testTranspile(
  'input[v-model={a.b[c.d[e]]}]',
  `
  <input
    v-model={a.b[c.d[e]]}
  />
`
)
testTranspile(
  'input[type="range", v-model]',
  `
  <input
    type="range"
    v-model={a.b}
  />
`
)
testTranspile(
  'input[v-model:lazy]',
  `
  <input
    v-model:lazy={a.b}
  />
`
)
testTranspile(
  'input[v-model:number]',
  `
  <input
    v-model:number={a.b}
  />
`
)
testTranspile(
  'input[v-model:trim]',
  `
  <input
    v-model:trim={a.b}
  />
`
)
testTranspile(
  'input[type="checkbox", v-model]',
  `
  <input
    type="checkbox"
    v-model={a.b}
    {...spreadForCoverage}
  />
`
)
testTranspile(
  'input[type="checkbox", value="forArray", true-value={{hello: true}}, false-value={{hello: false}}, v-model:number]',
  `
  <input
    type="checkbox"
    v-model:number={a.b}
    value="forArray"
    true-value={{hello: true}}
    false-value={{hello: false}}
    {...spreadForCoverage}
  />
`
)
testTranspile(
  'input[type="radio", v-model]',
  `
  <input
    type="radio"
    v-model={a.b}
    {...spreadForCoverage}
  />
`
)
testTranspile(
  'input[type="radio", value="101", v-model:number]',
  `
  <input
    type="radio"
    value="101"
    v-model:number={a.b}
    {...spreadForCoverage}
  />
`
)
testTranspile(
  'select',
  `
  <select
    v-model={a.b}
  />
`
)
testTranspile(
  'select[v-model:number]',
  `
  <select
    v-model:number={a.b}
  />
`
)
testTranspile(
  'custom-element[v-model]',
  `
  <custom-element
    v-model={a.b}
  />
`
)
testTranspile(
  'custom-element[v-model:trim]',
  `
  <custom-element
    v-model:trim={a.b}
  />
`
)
testTranspile(
  'custom-element[v-model:number]',
  `
  <custom-element
    v-model:number={a.b}
  />
`
)
