const { chdirTestApp, chdirCwd } = require('../helpers')

chdirTestApp()

const getStyleRule = require('../get_style_rule')

describe('getStyleRule', () => {
  afterAll(chdirCwd)

  test('excludes modules by default', () => {
    const cssRule = getStyleRule(/\.(css)$/i)
    const expectation = {
      test: /\.(css)$/i,
      exclude: /\.module\.[a-z]+$/
    }

    expect(cssRule).toMatchObject(expectation)
  })

  test('includes modules if set to true', () => {
    const cssRule = getStyleRule(/\.(scss)$/i, true)
    const expectation = {
      test: /\.(scss)$/i,
      include: /\.module\.[a-z]+$/
    }

    expect(cssRule).toMatchObject(expectation)
  })

  test('adds extra preprocessors if supplied', () => {
    const expectation = [{ foo: 'bar' }]
    const cssRule = getStyleRule(/\.(css)$/i, true, expectation)

    expect(cssRule.use).toMatchObject(expect.arrayContaining(expectation))
  })

  test('adds mini-css-extract-plugin when extract_css is true', () => {
    const MiniCssExtractPlugin = require('mini-css-extract-plugin')
    const expectation = [MiniCssExtractPlugin.loader]

    require('../../config').extract_css = true
    const cssRule = getStyleRule(/\.(css)$/i)

    expect(cssRule.use).toMatchObject(expect.arrayContaining(expectation))
  })

  test('adds style-loader when extract_css is true', () => {
    const expectation = [{loader: 'style-loader'}]

    require('../../config').extract_css = false
    const cssRule = getStyleRule(/\.(css)$/i)

    expect(cssRule.use).toMatchObject(expect.objectContaining(expectation))
  })

  test(`doesn't add mini-css-extract-plugin when extract_css is false`, () => {
    const MiniCssExtractPlugin = require('mini-css-extract-plugin')
    const expectation = [MiniCssExtractPlugin.loader]

    require('../../config').extract_css = false
    const cssRule = getStyleRule(/\.(css)$/i)

    expect(cssRule.use).toMatchObject(expect.not.arrayContaining(expectation))
  })
})
