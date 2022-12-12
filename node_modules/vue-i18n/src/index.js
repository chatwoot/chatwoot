/* @flow */

import { install, Vue } from './install'
import {
  warn,
  error,
  isNull,
  parseArgs,
  isPlainObject,
  isObject,
  isArray,
  isBoolean,
  isString,
  isFunction,
  looseClone,
  remove,
  includes,
  merge,
  numberFormatKeys,
  escapeParams
} from './util'
import BaseFormatter from './format'
import I18nPath from './path'

import type { PathValue } from './path'

const htmlTagMatcher = /<\/?[\w\s="/.':;#-\/]+>/
const linkKeyMatcher = /(?:@(?:\.[a-z]+)?:(?:[\w\-_|.]+|\([\w\-_|.]+\)))/g
const linkKeyPrefixMatcher = /^@(?:\.([a-z]+))?:/
const bracketsMatcher = /[()]/g
const defaultModifiers = {
  'upper': str => str.toLocaleUpperCase(),
  'lower': str => str.toLocaleLowerCase(),
  'capitalize': str => `${str.charAt(0).toLocaleUpperCase()}${str.substr(1)}`
}

const defaultFormatter = new BaseFormatter()

export default class VueI18n {
  static install: () => void
  static version: string
  static availabilities: IntlAvailability

  _vm: any
  _formatter: Formatter
  _modifiers: Modifiers
  _root: any
  _sync: boolean
  _fallbackRoot: boolean
  _localeChainCache: { [key: string]: Array<Locale>; }
  _missing: ?MissingHandler
  _exist: Function
  _silentTranslationWarn: boolean | RegExp
  _silentFallbackWarn: boolean | RegExp
  _formatFallbackMessages: boolean
  _dateTimeFormatters: Object
  _numberFormatters: Object
  _path: I18nPath
  _dataListeners: Set<any>
  _componentInstanceCreatedListener: ?ComponentInstanceCreatedListener
  _preserveDirectiveContent: boolean
  _warnHtmlInMessage: WarnHtmlInMessageLevel
  _escapeParameterHtml: boolean
  _postTranslation: ?PostTranslationHandler
  pluralizationRules: {
    [lang: string]: (choice: number, choicesLength: number) => number
  }
  getChoiceIndex: GetChoiceIndex

  constructor (options: I18nOptions = {}) {
    // Auto install if it is not done yet and `window` has `Vue`.
    // To allow users to avoid auto-installation in some cases,
    // this code should be placed here. See #290
    /* istanbul ignore if */
    if (!Vue && typeof window !== 'undefined' && window.Vue) {
      install(window.Vue)
    }

    const locale: Locale = options.locale || 'en-US'
    const fallbackLocale: FallbackLocale = options.fallbackLocale === false
      ? false
      : options.fallbackLocale || 'en-US'
    const messages: LocaleMessages = options.messages || {}
    const dateTimeFormats = options.dateTimeFormats || {}
    const numberFormats = options.numberFormats || {}

    this._vm = null
    this._formatter = options.formatter || defaultFormatter
    this._modifiers = options.modifiers || {}
    this._missing = options.missing || null
    this._root = options.root || null
    this._sync = options.sync === undefined ? true : !!options.sync
    this._fallbackRoot = options.fallbackRoot === undefined
      ? true
      : !!options.fallbackRoot
    this._formatFallbackMessages = options.formatFallbackMessages === undefined
      ? false
      : !!options.formatFallbackMessages
    this._silentTranslationWarn = options.silentTranslationWarn === undefined
      ? false
      : options.silentTranslationWarn
    this._silentFallbackWarn = options.silentFallbackWarn === undefined
      ? false
      : !!options.silentFallbackWarn
    this._dateTimeFormatters = {}
    this._numberFormatters = {}
    this._path = new I18nPath()
    this._dataListeners = new Set()
    this._componentInstanceCreatedListener = options.componentInstanceCreatedListener || null
    this._preserveDirectiveContent = options.preserveDirectiveContent === undefined
      ? false
      : !!options.preserveDirectiveContent
    this.pluralizationRules = options.pluralizationRules || {}
    this._warnHtmlInMessage = options.warnHtmlInMessage || 'off'
    this._postTranslation = options.postTranslation || null
    this._escapeParameterHtml = options.escapeParameterHtml || false

    /**
     * @param choice {number} a choice index given by the input to $tc: `$tc('path.to.rule', choiceIndex)`
     * @param choicesLength {number} an overall amount of available choices
     * @returns a final choice index
    */
    this.getChoiceIndex = (choice: number, choicesLength: number): number => {
      const thisPrototype = Object.getPrototypeOf(this)
      if (thisPrototype && thisPrototype.getChoiceIndex) {
        const prototypeGetChoiceIndex = (thisPrototype.getChoiceIndex: any)
        return (prototypeGetChoiceIndex: GetChoiceIndex).call(this, choice, choicesLength)
      }

      // Default (old) getChoiceIndex implementation - english-compatible
      const defaultImpl = (_choice: number, _choicesLength: number) => {
        _choice = Math.abs(_choice)

        if (_choicesLength === 2) {
          return _choice
            ? _choice > 1
              ? 1
              : 0
            : 1
        }

        return _choice ? Math.min(_choice, 2) : 0
      }

      if (this.locale in this.pluralizationRules) {
        return this.pluralizationRules[this.locale].apply(this, [choice, choicesLength])
      } else {
        return defaultImpl(choice, choicesLength)
      }
    }


    this._exist = (message: Object, key: Path): boolean => {
      if (!message || !key) { return false }
      if (!isNull(this._path.getPathValue(message, key))) { return true }
      // fallback for flat key
      if (message[key]) { return true }
      return false
    }

    if (this._warnHtmlInMessage === 'warn' || this._warnHtmlInMessage === 'error') {
      Object.keys(messages).forEach(locale => {
        this._checkLocaleMessage(locale, this._warnHtmlInMessage, messages[locale])
      })
    }

    this._initVM({
      locale,
      fallbackLocale,
      messages,
      dateTimeFormats,
      numberFormats
    })
  }

  _checkLocaleMessage (locale: Locale, level: WarnHtmlInMessageLevel, message: LocaleMessageObject): void {
    const paths: Array<string> = []

    const fn = (level: WarnHtmlInMessageLevel, locale: Locale, message: any, paths: Array<string>) => {
      if (isPlainObject(message)) {
        Object.keys(message).forEach(key => {
          const val = message[key]
          if (isPlainObject(val)) {
            paths.push(key)
            paths.push('.')
            fn(level, locale, val, paths)
            paths.pop()
            paths.pop()
          } else {
            paths.push(key)
            fn(level, locale, val, paths)
            paths.pop()
          }
        })
      } else if (isArray(message)) {
        message.forEach((item, index) => {
          if (isPlainObject(item)) {
            paths.push(`[${index}]`)
            paths.push('.')
            fn(level, locale, item, paths)
            paths.pop()
            paths.pop()
          } else {
            paths.push(`[${index}]`)
            fn(level, locale, item, paths)
            paths.pop()
          }
        })
      } else if (isString(message)) {
        const ret = htmlTagMatcher.test(message)
        if (ret) {
          const msg = `Detected HTML in message '${message}' of keypath '${paths.join('')}' at '${locale}'. Consider component interpolation with '<i18n>' to avoid XSS. See https://bit.ly/2ZqJzkp`
          if (level === 'warn') {
            warn(msg)
          } else if (level === 'error') {
            error(msg)
          }
        }
      }
    }

    fn(level, locale, message, paths)
  }

  _initVM (data: {
    locale: Locale,
    fallbackLocale: FallbackLocale,
    messages: LocaleMessages,
    dateTimeFormats: DateTimeFormats,
    numberFormats: NumberFormats
  }): void {
    const silent = Vue.config.silent
    Vue.config.silent = true
    this._vm = new Vue({ data })
    Vue.config.silent = silent
  }

  destroyVM (): void {
    this._vm.$destroy()
  }

  subscribeDataChanging (vm: any): void {
    this._dataListeners.add(vm)
  }

  unsubscribeDataChanging (vm: any): void {
    remove(this._dataListeners, vm)
  }

  watchI18nData (): Function {
    const self = this
    return this._vm.$watch('$data', () => {
      self._dataListeners.forEach(e => {
        Vue.nextTick(() => {
          e && e.$forceUpdate()
        })
      })
    }, { deep: true })
  }

  watchLocale (): ?Function {
    /* istanbul ignore if */
    if (!this._sync || !this._root) { return null }
    const target: any = this._vm
    return this._root.$i18n.vm.$watch('locale', (val) => {
      target.$set(target, 'locale', val)
      target.$forceUpdate()
    }, { immediate: true })
  }

  onComponentInstanceCreated (newI18n: I18n) {
    if (this._componentInstanceCreatedListener) {
      this._componentInstanceCreatedListener(newI18n, this)
    }
  }

  get vm (): any { return this._vm }

  get messages (): LocaleMessages { return looseClone(this._getMessages()) }
  get dateTimeFormats (): DateTimeFormats { return looseClone(this._getDateTimeFormats()) }
  get numberFormats (): NumberFormats { return looseClone(this._getNumberFormats()) }
  get availableLocales (): Locale[] { return Object.keys(this.messages).sort() }

  get locale (): Locale { return this._vm.locale }
  set locale (locale: Locale): void {
    this._vm.$set(this._vm, 'locale', locale)
  }

  get fallbackLocale (): FallbackLocale { return this._vm.fallbackLocale }
  set fallbackLocale (locale: FallbackLocale): void {
    this._localeChainCache = {}
    this._vm.$set(this._vm, 'fallbackLocale', locale)
  }

  get formatFallbackMessages (): boolean { return this._formatFallbackMessages }
  set formatFallbackMessages (fallback: boolean): void { this._formatFallbackMessages = fallback }

  get missing (): ?MissingHandler { return this._missing }
  set missing (handler: MissingHandler): void { this._missing = handler }

  get formatter (): Formatter { return this._formatter }
  set formatter (formatter: Formatter): void { this._formatter = formatter }

  get silentTranslationWarn (): boolean | RegExp { return this._silentTranslationWarn }
  set silentTranslationWarn (silent: boolean | RegExp): void { this._silentTranslationWarn = silent }

  get silentFallbackWarn (): boolean | RegExp { return this._silentFallbackWarn }
  set silentFallbackWarn (silent: boolean | RegExp): void { this._silentFallbackWarn = silent }

  get preserveDirectiveContent (): boolean { return this._preserveDirectiveContent }
  set preserveDirectiveContent (preserve: boolean): void { this._preserveDirectiveContent = preserve }

  get warnHtmlInMessage (): WarnHtmlInMessageLevel { return this._warnHtmlInMessage }
  set warnHtmlInMessage (level: WarnHtmlInMessageLevel): void {
    const orgLevel = this._warnHtmlInMessage
    this._warnHtmlInMessage = level
    if (orgLevel !== level && (level === 'warn' || level === 'error')) {
      const messages = this._getMessages()
      Object.keys(messages).forEach(locale => {
        this._checkLocaleMessage(locale, this._warnHtmlInMessage, messages[locale])
      })
    }
  }

  get postTranslation (): ?PostTranslationHandler { return this._postTranslation }
  set postTranslation (handler: PostTranslationHandler): void { this._postTranslation = handler }

  _getMessages (): LocaleMessages { return this._vm.messages }
  _getDateTimeFormats (): DateTimeFormats { return this._vm.dateTimeFormats }
  _getNumberFormats (): NumberFormats { return this._vm.numberFormats }

  _warnDefault (locale: Locale, key: Path, result: ?any, vm: ?any, values: any, interpolateMode: string): ?string {
    if (!isNull(result)) { return result }
    if (this._missing) {
      const missingRet = this._missing.apply(null, [locale, key, vm, values])
      if (isString(missingRet)) {
        return missingRet
      }
    } else {
      if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key)) {
        warn(
          `Cannot translate the value of keypath '${key}'. ` +
          'Use the value of keypath as default.'
        )
      }
    }

    if (this._formatFallbackMessages) {
      const parsedArgs = parseArgs(...values)
      return this._render(key, interpolateMode, parsedArgs.params, key)
    } else {
      return key
    }
  }

  _isFallbackRoot (val: any): boolean {
    return !val && !isNull(this._root) && this._fallbackRoot
  }

  _isSilentFallbackWarn (key: Path): boolean {
    return this._silentFallbackWarn instanceof RegExp
      ? this._silentFallbackWarn.test(key)
      : this._silentFallbackWarn
  }

  _isSilentFallback (locale: Locale, key: Path): boolean {
    return this._isSilentFallbackWarn(key) && (this._isFallbackRoot() || locale !== this.fallbackLocale)
  }

  _isSilentTranslationWarn (key: Path): boolean {
    return this._silentTranslationWarn instanceof RegExp
      ? this._silentTranslationWarn.test(key)
      : this._silentTranslationWarn
  }

  _interpolate (
    locale: Locale,
    message: LocaleMessageObject,
    key: Path,
    host: any,
    interpolateMode: string,
    values: any,
    visitedLinkStack: Array<string>
  ): any {
    if (!message) { return null }

    const pathRet: PathValue = this._path.getPathValue(message, key)
    if (isArray(pathRet) || isPlainObject(pathRet)) { return pathRet }

    let ret: mixed
    if (isNull(pathRet)) {
      /* istanbul ignore else */
      if (isPlainObject(message)) {
        ret = message[key]
        if (!(isString(ret) || isFunction(ret))) {
          if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallback(locale, key)) {
            warn(`Value of key '${key}' is not a string or function !`)
          }
          return null
        }
      } else {
        return null
      }
    } else {
      /* istanbul ignore else */
      if (isString(pathRet) || isFunction(pathRet)) {
        ret = pathRet
      } else {
        if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallback(locale, key)) {
          warn(`Value of key '${key}' is not a string or function!`)
        }
        return null
      }
    }

    // Check for the existence of links within the translated string
    if (isString(ret) && (ret.indexOf('@:') >= 0 || ret.indexOf('@.') >= 0)) {
      ret = this._link(locale, message, ret, host, 'raw', values, visitedLinkStack)
    }

    return this._render(ret, interpolateMode, values, key)
  }

  _link (
    locale: Locale,
    message: LocaleMessageObject,
    str: string,
    host: any,
    interpolateMode: string,
    values: any,
    visitedLinkStack: Array<string>
  ): any {
    let ret: string = str

    // Match all the links within the local
    // We are going to replace each of
    // them with its translation
    const matches: any = ret.match(linkKeyMatcher)
    for (let idx in matches) {
      // ie compatible: filter custom array
      // prototype method
      if (!matches.hasOwnProperty(idx)) {
        continue
      }
      const link: string = matches[idx]
      const linkKeyPrefixMatches: any = link.match(linkKeyPrefixMatcher)
      const [linkPrefix, formatterName] = linkKeyPrefixMatches

      // Remove the leading @:, @.case: and the brackets
      const linkPlaceholder: string = link.replace(linkPrefix, '').replace(bracketsMatcher, '')

      if (includes(visitedLinkStack, linkPlaceholder)) {
        if (process.env.NODE_ENV !== 'production') {
          warn(`Circular reference found. "${link}" is already visited in the chain of ${visitedLinkStack.reverse().join(' <- ')}`)
        }
        return ret
      }
      visitedLinkStack.push(linkPlaceholder)

      // Translate the link
      let translated: any = this._interpolate(
        locale, message, linkPlaceholder, host,
        interpolateMode === 'raw' ? 'string' : interpolateMode,
        interpolateMode === 'raw' ? undefined : values,
        visitedLinkStack
      )

      if (this._isFallbackRoot(translated)) {
        if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(linkPlaceholder)) {
          warn(`Fall back to translate the link placeholder '${linkPlaceholder}' with root locale.`)
        }
        /* istanbul ignore if */
        if (!this._root) { throw Error('unexpected error') }
        const root: any = this._root.$i18n
        translated = root._translate(
          root._getMessages(), root.locale, root.fallbackLocale,
          linkPlaceholder, host, interpolateMode, values
        )
      }
      translated = this._warnDefault(
        locale, linkPlaceholder, translated, host,
        isArray(values) ? values : [values],
        interpolateMode
      )

      if (this._modifiers.hasOwnProperty(formatterName)) {
        translated = this._modifiers[formatterName](translated)
      } else if (defaultModifiers.hasOwnProperty(formatterName)) {
        translated = defaultModifiers[formatterName](translated)
      }

      visitedLinkStack.pop()

      // Replace the link with the translated
      ret = !translated ? ret : ret.replace(link, translated)
    }

    return ret
  }

  _createMessageContext (values: any): MessageContext {
    const _list = isArray(values) ? values : []
    const _named = isObject(values) ? values : {}
    const list = (index: number): mixed => _list[index]
    const named = (key: string): mixed => _named[key]
    return {
      list,
      named
    }
  }

  _render (message: string | MessageFunction, interpolateMode: string, values: any, path: string): any {
    if (isFunction(message)) {
      return message(this._createMessageContext(values))
    }

    let ret = this._formatter.interpolate(message, values, path)

    // If the custom formatter refuses to work - apply the default one
    if (!ret) {
      ret = defaultFormatter.interpolate(message, values, path)
    }

    // if interpolateMode is **not** 'string' ('row'),
    // return the compiled data (e.g. ['foo', VNode, 'bar']) with formatter
    return interpolateMode === 'string' && !isString(ret) ? ret.join('') : ret
  }

  _appendItemToChain (chain: Array<Locale>, item: Locale, blocks: any): any {
    let follow = false
    if (!includes(chain, item)) {
      follow = true
      if (item) {
        follow = item[item.length - 1] !== '!'
        item = item.replace(/!/g, '')
        chain.push(item)
        if (blocks && blocks[item]) {
          follow = blocks[item]
        }
      }
    }
    return follow
  }

  _appendLocaleToChain (chain: Array<Locale>, locale: Locale, blocks: any): any {
    let follow
    const tokens = locale.split('-')
    do {
      const item = tokens.join('-')
      follow = this._appendItemToChain(chain, item, blocks)
      tokens.splice(-1, 1)
    } while (tokens.length && (follow === true))
    return follow
  }

  _appendBlockToChain (chain: Array<Locale>, block: Array<Locale> | Object, blocks: any): any {
    let follow = true
    for (let i = 0; (i < block.length) && (isBoolean(follow)); i++) {
      const locale = block[i]
      if (isString(locale)) {
        follow = this._appendLocaleToChain(chain, locale, blocks)
      }
    }
    return follow
  }

  _getLocaleChain (start: Locale, fallbackLocale: FallbackLocale): Array<Locale> {
    if (start === '') { return [] }

    if (!this._localeChainCache) {
      this._localeChainCache = {}
    }

    let chain = this._localeChainCache[start]
    if (!chain) {
      if (!fallbackLocale) {
        fallbackLocale = this.fallbackLocale
      }
      chain = []

      // first block defined by start
      let block = [start]

      // while any intervening block found
      while (isArray(block)) {
        block = this._appendBlockToChain(
          chain,
          block,
          fallbackLocale
        )
      }

      // last block defined by default
      let defaults
      if (isArray(fallbackLocale)) {
        defaults = fallbackLocale
      } else if (isObject(fallbackLocale)) {
        /* $FlowFixMe */
        if (fallbackLocale['default']) {
          defaults = fallbackLocale['default']
        } else {
          defaults = null
        }
      } else {
        defaults = fallbackLocale
      }

      // convert defaults to array
      if (isString(defaults)) {
        block = [defaults]
      } else {
        block = defaults
      }
      if (block) {
        this._appendBlockToChain(
          chain,
          block,
          null
        )
      }
      this._localeChainCache[start] = chain
    }
    return chain
  }

  _translate (
    messages: LocaleMessages,
    locale: Locale,
    fallback: FallbackLocale,
    key: Path,
    host: any,
    interpolateMode: string,
    args: any
  ): any {
    const chain = this._getLocaleChain(locale, fallback)
    let res
    for (let i = 0; i < chain.length; i++) {
      const step = chain[i]
      res =
        this._interpolate(step, messages[step], key, host, interpolateMode, args, [key])
      if (!isNull(res)) {
        if (step !== locale && process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
          warn(("Fall back to translate the keypath '" + key + "' with '" + step + "' locale."))
        }
        return res
      }
    }
    return null
  }

  _t (key: Path, _locale: Locale, messages: LocaleMessages, host: any, ...values: any): any {
    if (!key) { return '' }

    const parsedArgs = parseArgs(...values)
    if(this._escapeParameterHtml) {
      parsedArgs.params = escapeParams(parsedArgs.params)
    }

    const locale: Locale = parsedArgs.locale || _locale

    let ret: any = this._translate(
      messages, locale, this.fallbackLocale, key,
      host, 'string', parsedArgs.params
    )
    if (this._isFallbackRoot(ret)) {
      if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
        warn(`Fall back to translate the keypath '${key}' with root locale.`)
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$t(key, ...values)
    } else {
      ret = this._warnDefault(locale, key, ret, host, values, 'string')
      if (this._postTranslation && ret !== null && ret !== undefined) {
        ret = this._postTranslation(ret, key)
      }
      return ret
    }
  }

  t (key: Path, ...values: any): TranslateResult {
    return this._t(key, this.locale, this._getMessages(), null, ...values)
  }

  _i (key: Path, locale: Locale, messages: LocaleMessages, host: any, values: Object): any {
    const ret: any =
      this._translate(messages, locale, this.fallbackLocale, key, host, 'raw', values)
    if (this._isFallbackRoot(ret)) {
      if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key)) {
        warn(`Fall back to interpolate the keypath '${key}' with root locale.`)
      }
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n.i(key, locale, values)
    } else {
      return this._warnDefault(locale, key, ret, host, [values], 'raw')
    }
  }

  i (key: Path, locale: Locale, values: Object): TranslateResult {
    /* istanbul ignore if */
    if (!key) { return '' }

    if (!isString(locale)) {
      locale = this.locale
    }

    return this._i(key, locale, this._getMessages(), null, values)
  }

  _tc (
    key: Path,
    _locale: Locale,
    messages: LocaleMessages,
    host: any,
    choice?: number,
    ...values: any
  ): any {
    if (!key) { return '' }
    if (choice === undefined) {
      choice = 1
    }

    const predefined = { 'count': choice, 'n': choice }
    const parsedArgs = parseArgs(...values)
    parsedArgs.params = Object.assign(predefined, parsedArgs.params)
    values = parsedArgs.locale === null ? [parsedArgs.params] : [parsedArgs.locale, parsedArgs.params]
    return this.fetchChoice(this._t(key, _locale, messages, host, ...values), choice)
  }

  fetchChoice (message: string, choice: number): ?string {
    /* istanbul ignore if */
    if (!message || !isString(message)) { return null }
    const choices: Array<string> = message.split('|')

    choice = this.getChoiceIndex(choice, choices.length)
    if (!choices[choice]) { return message }
    return choices[choice].trim()
  }

  tc (key: Path, choice?: number, ...values: any): TranslateResult {
    return this._tc(key, this.locale, this._getMessages(), null, choice, ...values)
  }

  _te (key: Path, locale: Locale, messages: LocaleMessages, ...args: any): boolean {
    const _locale: Locale = parseArgs(...args).locale || locale
    return this._exist(messages[_locale], key)
  }

  te (key: Path, locale?: Locale): boolean {
    return this._te(key, this.locale, this._getMessages(), locale)
  }

  getLocaleMessage (locale: Locale): LocaleMessageObject {
    return looseClone(this._vm.messages[locale] || {})
  }

  setLocaleMessage (locale: Locale, message: LocaleMessageObject): void {
    if (this._warnHtmlInMessage === 'warn' || this._warnHtmlInMessage === 'error') {
      this._checkLocaleMessage(locale, this._warnHtmlInMessage, message)
    }
    this._vm.$set(this._vm.messages, locale, message)
  }

  mergeLocaleMessage (locale: Locale, message: LocaleMessageObject): void {
    if (this._warnHtmlInMessage === 'warn' || this._warnHtmlInMessage === 'error') {
      this._checkLocaleMessage(locale, this._warnHtmlInMessage, message)
    }
    this._vm.$set(this._vm.messages, locale, merge(
      typeof this._vm.messages[locale] !== 'undefined' && Object.keys(this._vm.messages[locale]).length
        ? this._vm.messages[locale]
        : {},
      message
    ))
  }

  getDateTimeFormat (locale: Locale): DateTimeFormat {
    return looseClone(this._vm.dateTimeFormats[locale] || {})
  }

  setDateTimeFormat (locale: Locale, format: DateTimeFormat): void {
    this._vm.$set(this._vm.dateTimeFormats, locale, format)
    this._clearDateTimeFormat(locale, format)
  }

  mergeDateTimeFormat (locale: Locale, format: DateTimeFormat): void {
    this._vm.$set(this._vm.dateTimeFormats, locale, merge(this._vm.dateTimeFormats[locale] || {}, format))
    this._clearDateTimeFormat(locale, format)
  }

  _clearDateTimeFormat (locale: Locale, format: DateTimeFormat): void {
    for (let key in format) {
      const id = `${locale}__${key}`

      if (!this._dateTimeFormatters.hasOwnProperty(id)) {
        continue
      }

      delete this._dateTimeFormatters[id]
    }
  }

  _localizeDateTime (
    value: number | Date,
    locale: Locale,
    fallback: FallbackLocale,
    dateTimeFormats: DateTimeFormats,
    key: string
  ): ?DateTimeFormatResult {
    let _locale: Locale = locale
    let formats: DateTimeFormat = dateTimeFormats[_locale]

    const chain = this._getLocaleChain(locale, fallback)
    for (let i = 0; i < chain.length; i++) {
      const current = _locale
      const step = chain[i]
      formats = dateTimeFormats[step]
      _locale = step
      // fallback locale
      if (isNull(formats) || isNull(formats[key])) {
        if (step !== locale && process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
          warn(`Fall back to '${step}' datetime formats from '${current}' datetime formats.`)
        }
      } else {
        break
      }
    }

    if (isNull(formats) || isNull(formats[key])) {
      return null
    } else {
      const format: ?DateTimeFormatOptions = formats[key]
      const id = `${_locale}__${key}`
      let formatter = this._dateTimeFormatters[id]
      if (!formatter) {
        formatter = this._dateTimeFormatters[id] = new Intl.DateTimeFormat(_locale, format)
      }
      return formatter.format(value)
    }
  }

  _d (value: number | Date, locale: Locale, key: ?string): DateTimeFormatResult {
    /* istanbul ignore if */
    if (process.env.NODE_ENV !== 'production' && !VueI18n.availabilities.dateTimeFormat) {
      warn('Cannot format a Date value due to not supported Intl.DateTimeFormat.')
      return ''
    }

    if (!key) {
      return new Intl.DateTimeFormat(locale).format(value)
    }

    const ret: ?DateTimeFormatResult =
      this._localizeDateTime(value, locale, this.fallbackLocale, this._getDateTimeFormats(), key)
    if (this._isFallbackRoot(ret)) {
      if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
        warn(`Fall back to datetime localization of root: key '${key}'.`)
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n.d(value, key, locale)
    } else {
      return ret || ''
    }
  }

  d (value: number | Date, ...args: any): DateTimeFormatResult {
    let locale: Locale = this.locale
    let key: ?string = null

    if (args.length === 1) {
      if (isString(args[0])) {
        key = args[0]
      } else if (isObject(args[0])) {
        if (args[0].locale) {
          locale = args[0].locale
        }
        if (args[0].key) {
          key = args[0].key
        }
      }
    } else if (args.length === 2) {
      if (isString(args[0])) {
        key = args[0]
      }
      if (isString(args[1])) {
        locale = args[1]
      }
    }

    return this._d(value, locale, key)
  }

  getNumberFormat (locale: Locale): NumberFormat {
    return looseClone(this._vm.numberFormats[locale] || {})
  }

  setNumberFormat (locale: Locale, format: NumberFormat): void {
    this._vm.$set(this._vm.numberFormats, locale, format)
    this._clearNumberFormat(locale, format)
  }

  mergeNumberFormat (locale: Locale, format: NumberFormat): void {
    this._vm.$set(this._vm.numberFormats, locale, merge(this._vm.numberFormats[locale] || {}, format))
    this._clearNumberFormat(locale, format)
  }

  _clearNumberFormat (locale: Locale, format: NumberFormat): void {
    for (let key in format) {
      const id = `${locale}__${key}`

      if (!this._numberFormatters.hasOwnProperty(id)) {
        continue
      }

      delete this._numberFormatters[id]
    }
  }

  _getNumberFormatter (
    value: number,
    locale: Locale,
    fallback: FallbackLocale,
    numberFormats: NumberFormats,
    key: string,
    options: ?NumberFormatOptions
  ): ?Object {
    let _locale: Locale = locale
    let formats: NumberFormat = numberFormats[_locale]

    const chain = this._getLocaleChain(locale, fallback)
    for (let i = 0; i < chain.length; i++) {
      const current = _locale
      const step = chain[i]
      formats = numberFormats[step]
      _locale = step
      // fallback locale
      if (isNull(formats) || isNull(formats[key])) {
        if (step !== locale && process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
          warn(`Fall back to '${step}' number formats from '${current}' number formats.`)
        }
      } else {
        break
      }
    }

    if (isNull(formats) || isNull(formats[key])) {
      return null
    } else {
      const format: ?NumberFormatOptions = formats[key]

      let formatter
      if (options) {
        // If options specified - create one time number formatter
        formatter = new Intl.NumberFormat(_locale, Object.assign({}, format, options))
      } else {
        const id = `${_locale}__${key}`
        formatter = this._numberFormatters[id]
        if (!formatter) {
          formatter = this._numberFormatters[id] = new Intl.NumberFormat(_locale, format)
        }
      }
      return formatter
    }
  }

  _n (value: number, locale: Locale, key: ?string, options: ?NumberFormatOptions): NumberFormatResult {
    /* istanbul ignore if */
    if (!VueI18n.availabilities.numberFormat) {
      if (process.env.NODE_ENV !== 'production') {
        warn('Cannot format a Number value due to not supported Intl.NumberFormat.')
      }
      return ''
    }

    if (!key) {
      const nf = !options ? new Intl.NumberFormat(locale) : new Intl.NumberFormat(locale, options)
      return nf.format(value)
    }

    const formatter: ?Object = this._getNumberFormatter(value, locale, this.fallbackLocale, this._getNumberFormats(), key, options)
    const ret: ?NumberFormatResult = formatter && formatter.format(value)
    if (this._isFallbackRoot(ret)) {
      if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key) && !this._isSilentFallbackWarn(key)) {
        warn(`Fall back to number localization of root: key '${key}'.`)
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n.n(value, Object.assign({}, { key, locale }, options))
    } else {
      return ret || ''
    }
  }

  n (value: number, ...args: any): NumberFormatResult {
    let locale: Locale = this.locale
    let key: ?string = null
    let options: ?NumberFormatOptions = null

    if (args.length === 1) {
      if (isString(args[0])) {
        key = args[0]
      } else if (isObject(args[0])) {
        if (args[0].locale) {
          locale = args[0].locale
        }
        if (args[0].key) {
          key = args[0].key
        }

        // Filter out number format options only
        options = Object.keys(args[0]).reduce((acc, key) => {
          if (includes(numberFormatKeys, key)) {
            return Object.assign({}, acc, { [key]: args[0][key] })
          }
          return acc
        }, null)
      }
    } else if (args.length === 2) {
      if (isString(args[0])) {
        key = args[0]
      }
      if (isString(args[1])) {
        locale = args[1]
      }
    }

    return this._n(value, locale, key, options)
  }

  _ntp (value: number, locale: Locale, key: ?string, options: ?NumberFormatOptions): NumberFormatToPartsResult {
    /* istanbul ignore if */
    if (!VueI18n.availabilities.numberFormat) {
      if (process.env.NODE_ENV !== 'production') {
        warn('Cannot format to parts a Number value due to not supported Intl.NumberFormat.')
      }
      return []
    }

    if (!key) {
      const nf = !options ? new Intl.NumberFormat(locale) : new Intl.NumberFormat(locale, options)
      return nf.formatToParts(value)
    }

    const formatter: ?Object = this._getNumberFormatter(value, locale, this.fallbackLocale, this._getNumberFormats(), key, options)
    const ret: ?NumberFormatToPartsResult = formatter && formatter.formatToParts(value)
    if (this._isFallbackRoot(ret)) {
      if (process.env.NODE_ENV !== 'production' && !this._isSilentTranslationWarn(key)) {
        warn(`Fall back to format number to parts of root: key '${key}' .`)
      }
      /* istanbul ignore if */
      if (!this._root) { throw Error('unexpected error') }
      return this._root.$i18n._ntp(value, locale, key, options)
    } else {
      return ret || []
    }
  }
}

let availabilities: IntlAvailability
// $FlowFixMe
Object.defineProperty(VueI18n, 'availabilities', {
  get () {
    if (!availabilities) {
      const intlDefined = typeof Intl !== 'undefined'
      availabilities = {
        dateTimeFormat: intlDefined && typeof Intl.DateTimeFormat !== 'undefined',
        numberFormat: intlDefined && typeof Intl.NumberFormat !== 'undefined'
      }
    }

    return availabilities
  }
})

VueI18n.install = install
VueI18n.version = '__VERSION__'
