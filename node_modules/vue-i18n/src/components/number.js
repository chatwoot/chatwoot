/* @flow */

import { warn, isString, isObject, includes, numberFormatKeys } from '../util'

export default {
  name: 'i18n-n',
  functional: true,
  props: {
    tag: {
      type: [String, Boolean, Object],
      default: 'span'
    },
    value: {
      type: Number,
      required: true
    },
    format: {
      type: [String, Object]
    },
    locale: {
      type: String
    }
  },
  render (h: Function, { props, parent, data }: Object) {
    const i18n = parent.$i18n

    if (!i18n) {
      if (process.env.NODE_ENV !== 'production') {
        warn('Cannot find VueI18n instance!')
      }
      return null
    }

    let key: ?string = null
    let options: ?NumberFormatOptions = null

    if (isString(props.format)) {
      key = props.format
    } else if (isObject(props.format)) {
      if (props.format.key) {
        key = props.format.key
      }

      // Filter out number format options only
      options = Object.keys(props.format).reduce((acc, prop) => {
        if (includes(numberFormatKeys, prop)) {
          return Object.assign({}, acc, { [prop]: props.format[prop] })
        }
        return acc
      }, null)
    }

    const locale: Locale = props.locale || i18n.locale
    const parts: NumberFormatToPartsResult = i18n._ntp(props.value, locale, key, options)

    const values = parts.map((part, index) => {
      const slot: ?Function = data.scopedSlots && data.scopedSlots[part.type]
      return slot ? slot({ [part.type]: part.value, index, parts }) : part.value
    })

    const tag = (!!props.tag && props.tag !== true) || props.tag === false ? props.tag : 'span'
    return tag
      ? h(tag, {
        attrs: data.attrs,
        'class': data['class'],
        staticClass: data.staticClass
      }, values)
      : values
  }
}
