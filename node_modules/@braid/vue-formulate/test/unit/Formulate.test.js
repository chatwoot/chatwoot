import Formulate from '@/Formulate.js'

describe('Formulate', () => {
  it('can merge simple object', () => {
    let a = {
      optionA: true,
      optionB: '1234'
    }
    let b = {
      optionA: false
    }
    expect(Formulate.merge(a, b)).toEqual({
      optionA: false,
      optionB: '1234'
    })
  })

  it('can add to simple array', () => {
    let a = {
      optionA: true,
      optionB: ['first', 'second']
    }
    let b = {
      optionB: ['third']
    }
    expect(Formulate.merge(a, b, true)).toEqual({
      optionA: true,
      optionB: ['first', 'second', 'third']
    })
  })

  it('can merge recursively', () => {
    let a = {
      optionA: true,
      optionC: {
        first: '123',
        third: {
          a: 'b'
        }
      },
      optionB: '1234'
    }
    let b = {
      optionB: '567',
      optionC: {
        first: '1234',
        second: '789',
      }
    }
    expect(Formulate.merge(a, b)).toEqual({
      optionA: true,
      optionC: {
        first: '1234',
        third: {
          a: 'b'
        },
        second: '789'
      },
      optionB: '567'
    })
  })

  it('installs on vue instance', () => {
    const components = [
      'FormulateSlot',
      'FormulateForm',
      'FormulateFile',
      'FormulateHelp',
      'FormulateLabel',
      'FormulateInput',
      'FormulateErrors',
      'FormulateSchema',
      'FormulateAddMore',
      'FormulateGrouping',
      'FormulateInputBox',
      'FormulateInputText',
      'FormulateInputFile',
      'FormulateErrorList',
      'FormulateRepeatable',
      'FormulateInputGroup',
      'FormulateInputButton',
      'FormulateInputSelect',
      'FormulateInputSlider',
      'FormulateButtonContent',
      'FormulateInputTextArea',
      'FormulateRepeatableRemove',
      'FormulateRepeatableProvider'
    ]
    const registry = []
    function Vue () {}
    Vue.component = function (name, instance) {
      registry.push(name)
    }
    Formulate.install(Vue, { extended: true })
    expect(Vue.prototype.$formulate).toBe(Formulate)
    expect(registry).toEqual(components)
  })

  it('can extend instance in a plugin', () => {
    function Vue () {}
    Vue.component = function (name, instance) {}
    const plugin = function (i) {
      i.extend({
        rules: {
          testRule: () => false
        }
      })
    }
    Formulate.install(Vue, {
      plugins: [ plugin ]
    })

    expect(typeof Vue.prototype.$formulate.options.rules.testRule).toBe('function')
  })

  it('locale default to en', () => {
    Formulate.selectedLocale = false // reset the memoization
    function Vue () {}
    Vue.component = function (name, instance) {}
    const vm = {}
    Formulate.install(Vue, {
      locales: {
        de: {},
        fr: {},
        cn: {},
        en: {}
      }
    })
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('en')
  })

  it('explicitly selects language', () => {
    Formulate.selectedLocale = false // reset the memoization
    function Vue () {}
    Vue.component = function (name, instance) {}
    const vm = {}
    Formulate.install(Vue, {
      locale: 'fr-CH',
      locales: {
        de: {},
        fr: {},
        cn: {},
        en: {}
      }
    })
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('fr')
  })

  it('can select a specific language tag', () => {
    Formulate.selectedLocale = false // reset the memoization
    function Vue () {}
    Vue.component = function (name, instance) {}
    const vm = {}
    Formulate.install(Vue, {
      locale: 'nl-BE',
      locales: {
        de: {},
        fr: {},
        'nl-BE': {},
        nl: {},
        cn: {},
        en: {}
      }
    })
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('nl-BE')
  })

  it('can select a matching locale using i18n locale string', () => {
    Formulate.selectedLocale = false // reset the memoization
    function Vue () {}
    Vue.component = function (name, instance) {}
    const vm = { $i18n: {locale: 'cn-ET' } }
    Formulate.install(Vue, {
      locales: {
        cn: {},
        em: {}
      }
    })
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('cn')
  })

  it('can select a matching locale using i18n locale function', () => {
    Formulate.selectedLocale = false // reset the memoization
    function Vue () {}
    Vue.component = function (name, instance) {}
    const vm = { $i18n: {locale: () => 'en-US' } }
    Formulate.install(Vue, {
      locales: {
        cn: {},
        em: {},
        en: {}
      }
    })
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('en')
  })

  it('throws an error improperly extending', async () => {
    expect(() => Formulate.extend('pizza')).toThrow()
  })

  it('can select a locale after memoization with setLocale', () => {
    Formulate.selectedLocale = false // reset the memoization
    function Vue () {}
    Vue.component = function (name, instance) {}
    const vm = { $i18n: {locale: 'em' } }
    Formulate.install(Vue, {
      locales: {
        cn: {},
        em: {}
      }
    })
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('em')
    Vue.prototype.$formulate.setLocale('cn')
    expect(Vue.prototype.$formulate.getLocale(vm)).toBe('cn')
  })
})
