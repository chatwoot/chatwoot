/**
 * Here we can import additional helper functions to assist in formatting our
 * language. Feel free to add additional helper methods to libs/formats if it
 * assists in creating good validation messages for your locale.
 */
import { sentence as s } from '../libs/formats'

/**
 * This is the ISO 639-1 and (optionally) ISO 639-2 language "tag".
 * Some valid examples:
 * zh
 * zh-CN
 * zh-HK
 * en
 * en-GB
 */
const locale = 'ja'

/**
 * This is an object of functions that each produce valid responses. There's no
 * need for these to be 1-1 with english, feel free to change the wording or
 * use/not use any of the variables available in the object or the
 * arguments for the message to make the most sense in your language and culture.
 *
 * The validation context object includes the following properties:
 * {
 *   args        // Array of rule arguments: between:5,10 (args are ['5', '10'])
 *   name:       // The validation name to be used
 *   value:      // The value of the field (do not mutate!),
 *   vm: the     // FormulateInput instance this belongs to,
 *   formValues: // If wrapped in a FormulateForm, the value of other form fields.
 * }
 */
const localizedValidationMessages = {

  /**
   * Valid accepted value.
   */
  accepted: function ({ name }) {
    return `${name}を承認してください。`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)}は ${args[0]} 以降にしてください。`
    }
    return `${s(name)}はより後にしてください。`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)}にはアルファベットのみ使用できます。`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)}には英数字のみ使用できます。`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)}は ${args[0]} 以前にしてください。`
    }
    return `${s(name)}はより前にしてください。`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)}は${args[0]}から${args[1]}の間でなければなりません。`
    }
    return `${s(name)}は${args[0]}文字から${args[1]}文字でなければなりません。`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)}が一致しません。`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)}は有効な形式ではありません。次のフォーマットで入力してください: ${args[0]}`
    }
    return `${s(name)}は有効な形式ではありません。`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `有効な値ではありません。`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return '有効なメールアドレスを入力してください。'
    }
    return `“${value}” は有効なメールアドレスではありません。`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `有効な値で終わっていません。`
    }
    return `“${value}” は有効な値で終わっていません。`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” は許可された${name}ではありません。`
    }
    return `許可された${name}ではありません。`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)}は許可された値ではありません。`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `${name}は${args[0]}項目しか選択できません。`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)}は${args[0]}以下でなければなりません。`
    }
    return `${s(name)}は${args[0]}文字以下でなければなりません。`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)}は次のファイル形式でなければなりません: ${args[0] || '許可されたファイル形式がありません'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `${name}は${args[0]}項目以上選択してください。`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)}は${args[0]}以上でなければなりません。`
    }
    return `${s(name)}は${args[0]}文字以上でなければなりません。`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” は許可された${name}ではありません。`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)}には数字のみ使用できます。`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)}は必須項目です。`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `有効な値で始まっていません。`
    }
    return `“${value}” は有効な値で始まっていません。`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `有効なURLを入力してください。`
  }
}

/**
 * This creates a vue-formulate plugin that can be imported and used on each
 * project.
 */
export default function (instance) {
  instance.extend({
    locales: {
      [locale]: localizedValidationMessages
    }
  })
}
