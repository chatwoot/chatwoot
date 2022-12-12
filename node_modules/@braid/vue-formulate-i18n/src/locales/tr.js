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
const locale = 'tr'

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
    return `Lütfen ${name}'i kabul edin..`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)}, ${args[0]} sonrasında olmalıdır.`
    }
    return `${s(name)} daha sonraki bir tarih olmalıdır.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} yalnızca alfabetik karakterler içerebilir.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} yalnızca harf ve rakam içerebilir.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)}, ${args[0]} tarihinden önce olmalıdır.`
    }
    return `${s(name)} daha erken bir tarih olmalıdır.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)}, ${args[0]} ile ${args[1]} arasında olmalıdır.`
    }
    return `${s(name)}, ${args[0]} ile ${args[1]} karakter uzunluğunda olmalıdır.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} eşleşmiyor.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} geçerli bir tarih değil, lütfen ${args[0]} biçimini kullanın`
    }
    return `${s(name)} geçerli bir tarih değil.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Bu alan geçerli değil.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Lütfen geçerli bir e-posta adresi giriniz.'
    }
    return `“${value}” geçerli bir e-posta adresi değil.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Bu alan geçerli bir değerle bitmiyor.`
    }
    return `“${value}” geçerli bir değerle bitmiyor.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” izin verilen bir ${name} değil.`
    }
    return `Bu izin verilen bir ${name} değil.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} izin verilen bir değer değil.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Yalnızca ${args[0]} ${name} seçebilirsiniz.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)}, ${args[0]} değerinden küçük veya ona eşit olmalıdır.`
    }
    return `${s(name)}, ${args[0]} karakterden küçük veya ona eşit olmalıdır.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} şu türde olmalıdır: ${args[0] || 'Dosya formatına izin verilmez.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `En az ${args[0]} ${name} gerekiyor.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} en az ${args[0]} olmalıdır.`
    }
    return `${s(name)} en az ${args[0]} karakter uzunluğunda olmalıdır.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” izin verilen bir ${name} değil.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} bir sayı olmalıdır.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} gerekli.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Bu alan geçerli bir değerle başlamıyor.`
    }
    return `“${value}” geçerli bir değerle başlamıyor.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Lütfen geçerli bir url ekleyin.`
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
