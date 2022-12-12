/* @flow */

import { warn, isString, isPlainObject, looseEqual } from './util'

export function bind (el: any, binding: Object, vnode: any): void {
  if (!assert(el, vnode)) { return }

  t(el, binding, vnode)
}

export function update (el: any, binding: Object, vnode: any, oldVNode: any): void {
  if (!assert(el, vnode)) { return }

  const i18n: any = vnode.context.$i18n
  if (localeEqual(el, vnode) &&
    (looseEqual(binding.value, binding.oldValue) &&
     looseEqual(el._localeMessage, i18n.getLocaleMessage(i18n.locale)))) { return }

  t(el, binding, vnode)
}

export function unbind (el: any, binding: Object, vnode: any, oldVNode: any): void {
  const vm: any = vnode.context
  if (!vm) {
    warn('Vue instance does not exists in VNode context')
    return
  }

  const i18n: any = vnode.context.$i18n || {}
  if (!binding.modifiers.preserve && !i18n.preserveDirectiveContent) {
    el.textContent = ''
  }
  el._vt = undefined
  delete el['_vt']
  el._locale = undefined
  delete el['_locale']
  el._localeMessage = undefined
  delete el['_localeMessage']
}

function assert (el: any, vnode: any): boolean {
  const vm: any = vnode.context
  if (!vm) {
    warn('Vue instance does not exists in VNode context')
    return false
  }

  if (!vm.$i18n) {
    warn('VueI18n instance does not exists in Vue instance')
    return false
  }

  return true
}

function localeEqual (el: any, vnode: any): boolean {
  const vm: any = vnode.context
  return el._locale === vm.$i18n.locale
}

function t (el: any, binding: Object, vnode: any): void {
  const value: any = binding.value

  const { path, locale, args, choice } = parseValue(value)
  if (!path && !locale && !args) {
    warn('value type not supported')
    return
  }

  if (!path) {
    warn('`path` is required in v-t directive')
    return
  }

  const vm: any = vnode.context
  if (choice != null) {
    el._vt = el.textContent = vm.$i18n.tc(path, choice, ...makeParams(locale, args))
  } else {
    el._vt = el.textContent = vm.$i18n.t(path, ...makeParams(locale, args))
  }
  el._locale = vm.$i18n.locale
  el._localeMessage = vm.$i18n.getLocaleMessage(vm.$i18n.locale)
}

function parseValue (value: any): Object {
  let path: ?string
  let locale: ?Locale
  let args: any
  let choice: ?number

  if (isString(value)) {
    path = value
  } else if (isPlainObject(value)) {
    path = value.path
    locale = value.locale
    args = value.args
    choice = value.choice
  }

  return { path, locale, args, choice }
}

function makeParams (locale: Locale, args: any): Array<any> {
  const params: Array<any> = []

  locale && params.push(locale)
  if (args && (Array.isArray(args) || isPlainObject(args))) {
    params.push(args)
  }

  return params
}
