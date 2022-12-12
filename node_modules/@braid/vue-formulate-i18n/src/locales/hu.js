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
const locale = 'hu'

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
    return `Kérlek fogadd el a(z) ${name} mezőt.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} után kell lennie ${args[0]}.`
    }
    return `${s(name)} későbbi dátumnak kell lennie.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} csak ábécé szerinti karaktereket tartalmazhat.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} csak betűket és számokat tartalmazhat.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} előtt kell lennie ${args[0]}.`
    }
    return `${s(name)} korábbi dátumnak kell lennie.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} között kell lennie ${args[0]} és ${args[1]}.`
    }
    return `${s(name)} között kell lennie ${args[0]} és ${args[1]} karakter hosszú.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} nem egyezik.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} nem érvényes dátum, kérlek használd a ${args[0]} formátumot.`
    }
    return `${s(name)} nem érvényes dátum.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Ez a mező érvénytelen.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Kérlek valós e-mail címet adj meg.'
    }
    return `“${value}” nem érvényes e-mail cím.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Ez a mező nem ér véget érvényes értékkel.`
    }
    return `“${value}” nem ér véget érvényes értékkel.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” nem megengedett ${name}.`
    }
    return `Ez nem megengedett ${name}.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} nem megengedett érték.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Csak választható ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} kisebbnek vagy egyenlőnek kell lennie ${args[0]}.`
    }
    return `${s(name)} kisebbnek vagy egyenlőnek kell lennie ${args[0]} karakter hosszú.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} típusúnak kell lennie: ${args[0] || 'Nem engedélyezett fájlformátumok.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Legalább szükséges ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} legalább ${args[0]}.`
    }
    return `${s(name)} legalább ${args[0]} karakter hosszú.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” nem megengedett ${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} számnak kell lennie.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} kötelező.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Ez a mező nem érvényes értékkel kezdődik.`
    }
    return `“${value}” nem érvényes értékkel kezdődik.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Kérlek érvényes ulr-t adj meg.`
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
