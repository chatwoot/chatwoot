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
const locale = 'he'

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
    return `אנא קבל את ה${name}.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} חייב להיות אחרי ${args[0]}.`
    }
    return `${s(name)} חייב להיות תאריך יותר מאוחר.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} יכול להכיל אותיות בלבד.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} יכול להכיל אותיות ומספרים בלבד.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} חייב להיות לפני ${args[0]}.`
    }
    return `${s(name)} חייב להיות תאריך יותר מוקדם.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} חייב להיות בין ${args[0]} ו-${args[1]}.`
    }
    return `${s(name)} חייב להיות בין ${args[0]} ו-${args[1]} אותיות.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} אינו תואם.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} אינו תאריך תקין, אנא השתמש בפורמט ${args[0]}`
    }
    return `${s(name)} אינו תאריך תקין.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `השדה אינו תקין.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'אנא הכנס כתובת אימייל תקין.'
    }
    return `“${value}” אינו כתובת אימייל תקין.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `שדה זו אינו מסתיים בערך תקין.`
    }
    return `“${value}” אינו מסתיים בערך תקין.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” אינו ${name} מורשה.`
    }
    return `ערך זו איננו ${name} מורשה.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} אינו ערך מורשה.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `אתה יכול לבחור רק ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} חייב להיות פחות או שוה ל-${args[0]}.`
    }
    return `${s(name)} חייב להיות פחות או שוה ל-${args[0]} אותיות.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} חייב להיות מסוג של: ${args[0] || 'סוגי קבצים לא מורשים.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `אתה צריך לפחות ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} חייב להיות לפחות ${args[0]}.`
    }
    return `${s(name)} חייב להיות לפחות ${args[0]} אותיות.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” אינו ${name} מורשה.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} חייב להיות מספר.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} נדרש.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `שדה זה אינו מתחיל בערך תקף.`
    }
    return `“${value}” אינו מתחיל בערך תקף.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `אנא כלול כתובת אתר חוקית.`
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
