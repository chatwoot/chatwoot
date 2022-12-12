import * as VTooltip from './v-tooltip'

jest.mock('../lib/tooltip')

describe('getPlacement', () => {
  test('object notation', () => {
    const value = {
      placement: 'bottom',
    }
    const modifiers = {}
    const result = VTooltip.getPlacement(value, modifiers)
    expect(result).toBe('bottom')
  })

  test('modifier', () => {
    const value = {}
    const modifiers = {
      'top-end': true,
    }
    const result = VTooltip.getPlacement(value, modifiers)
    expect(result).toBe('top-end')
  })

  test('invalid modifier', () => {
    const value = {}
    const modifiers = {
      'top-middle': true,
    }
    const result = VTooltip.getPlacement(value, modifiers)
    expect(typeof result).toBe('undefined')
  })
})

describe('getContent', () => {
  test('string', () => {
    const value = 'foo'
    const result = VTooltip.getContent(value)
    expect(result).toBe('foo')
  })

  test('object', () => {
    const value = { content: 'foo' }
    const result = VTooltip.getContent(value)
    expect(result).toBe('foo')
  })

  test('false', () => {
    const value = false
    const result = VTooltip.getContent(value)
    expect(result).toBe(false)
  })

  test('null', () => {
    const value = null
    const result = VTooltip.getContent(value)
    expect(result).toBe(false)
  })

  test('false content attribute', () => {
    const value = { content: false }
    const result = VTooltip.getContent(value)
    expect(result).toBe(false)
  })

  test('no content attribute', () => {
    const value = {}
    const result = VTooltip.getContent(value)
    expect(typeof result).toBe('undefined')
  })
})

describe('getOptions', () => {
  test('defaultOptions', () => {
    const options = {}
    const result = VTooltip.getOptions(options)
    expect(result).toEqual({
      placement: VTooltip.defaultOptions.defaultPlacement,
      delay: VTooltip.defaultOptions.defaultDelay,
      html: VTooltip.defaultOptions.defaultHtml,
      template: VTooltip.defaultOptions.defaultTemplate,
      innerSelector: VTooltip.defaultOptions.defaultInnerSelector,
      arrowSelector: VTooltip.defaultOptions.defaultArrowSelector,
      trigger: VTooltip.defaultOptions.defaultTrigger,
      offset: VTooltip.defaultOptions.defaultOffset,
      container: VTooltip.defaultOptions.defaultContainer,
      boundariesElement: VTooltip.defaultOptions.defaultBoundariesElement,
      autoHide: VTooltip.defaultOptions.autoHide,
      hideOnTargetClick: VTooltip.defaultOptions.defaultHideOnTargetClick,
      loadingClass: VTooltip.defaultOptions.defaultLoadingClass,
      loadingContent: VTooltip.defaultOptions.defaultLoadingContent,
      popperOptions: VTooltip.defaultOptions.defaultPopperOptions,
    })
  })
})

describe('destroyTooltip', () => {
  test('is deleted', () => {
    const dispose = jest.fn(x => null)
    const el = {
      _tooltip: {
        dispose: dispose,
      },
      _tooltipOldShow: {},
    }

    VTooltip.destroyTooltip(el)

    expect(dispose.mock.calls.length).toBe(1)
    expect(el._tooltip).toBeUndefined()
    expect(el._tooltipOldShow).toBeUndefined()
  })
})
