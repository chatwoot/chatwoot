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
const locale = 'da'

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
    return `Accepter venligst ${name}.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} skal være efter ${args[0]}.`
    }
    return `${s(name)} skal være en senere dato.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} kan kun indeholde bogstaver.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} kan kun indeholde bogstaver og tal.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} skal være før ${args[0]}.`
    }
    return `${s(name)} skal være en tidligere dato.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} skal være mellem ${args[0]} og ${args[1]}.`
    }
    return `${s(name)} skal være mellem ${args[0]} og ${args[1]} tegn.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} matcher ikke.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} er ikke gyldig, brug venligst formatet ${args[0]}`
    }
    return `${s(name)} er ikke en gyldig dato.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Dette felt er ikke gyldigt.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Indtast venligst en gyldig email-adresse.'
    }
    return `“${value}” er ikke en gyldig email-adresse.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Dette felt slutter ikke med en gyldig værdi.`
    }
    return `“${value}” slutter ikke med en gyldig værdi.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” er ikke en tilladt ${name}.`
    }
    return `Dette er ikke en tilladt ${name}.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} er ikke en gyldig værdi.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Du kan kun vælge ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} skal være mindre end eller lig ${args[0]}.`
    }
    return `${s(name)} skal være mindre end eller lig ${args[0]} tegn.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} skal være af typen: ${args[0] || 'Ingen tilladte filformater.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Du skal vælge mindst ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} skal være mere end ${args[0]}.`
    }
    return `${s(name)} skal være mere end ${args[0]} tegn.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” er ikke en gyldig ${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} skal være et tal.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} er påkrævet.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Dette felt starter ikke med en gyldig værdi.`
    }
    return `“${value}” starter ikke med en gyldig værdi.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Indtast venligst en gyldig URL.`
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
