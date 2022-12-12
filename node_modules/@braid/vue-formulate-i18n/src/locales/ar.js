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
const locale = 'ar'

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
    return `من فضلك اقبل ال ${name}`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} يجب أن يأتي بعد ${args[0]}.`
    }
    return `${s(name)} يجب أن يكون تاريخ أحدث`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} يجب أن يحتوى على حروف أبجدية فقط.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} يمكن أن يحتوي على حروف أبجدية أو أرقام فقط.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} يجب أن يكون قبل ${args[0]}.`
    }
    return `${s(name)} يجب أن يكون تاريخ أقدم`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} يجب أن يقع بين ${args[0]} و ${args[1]}.`
    }
    return `${s(name)} يجب ان يكون طوله بين ${args[0]} و ${args[1]} حرف.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} غير متطابق.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ليس على الصيغة الصحيحة, من فضلك استخدم هذه الصيغة ${args[0]}`
    }
    return `${s(name)} ليس على الصيغة الصحيحة.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `هذه القيمة غير مناسبة.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'من فضلك أدخل عنوان بريد الكتروني مناسب.'
    }
    return `“${value}” ليس عنوان بريد الكتروني.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `نهاية هذه القيمة ليست صحيحة.`
    }
    return `“${value}” لا تنتهي بنهاية صحيحة.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” ليس ${name} صحيح.`
    }
    return `هذه القيمة ليست ${name} صحيح.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} ليست قيمة مسموح بها.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `يمكنك فقط ان تختار ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} لا يمكن أن يتجاوز ${args[0]}.`
    }
    return `${s(name)} لا يجب ان يزيد طوله عن ${args[0]} حرف.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} يجب ان يكون من نوع ${args[0] || 'لا يسمح بأي نوع.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `يجب أن تختار على الأقل ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} يجب أن يكون أكبر من ${args[0]}.`
    }
    return `${s(name)} يجب أن يكون طوله أكبر من ${args[0]} حرف.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” ليست قيمة مسموح بها ك${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} يجب أن يكون رقم.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} ضروري.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `هذه القيمة لا تبدأ بقيمة صحيحة.`
    }
    return `“${value}” لا تبدأ بقيمة صحيحة.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `من فضلك أدخل رابط صحيح.`
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
