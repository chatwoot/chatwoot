/**
 * Here we can import additional helper functions to assist in formatting our
 * language. Feel free to add additional helper methods to libs/formats if it
 * assists in creating good validation messages for your locale.
 */
import { sentence as s } from '../libs/formats'

/**
 * This is the ISO 639-1 and (optionally) ISO 639-2 language 'tag'.
 * Some valid examples:
 * zh
 * zh-CN
 * zh-HK
 * en
 * en-GB
 */
const locale = 'nl'

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
    return `Sta ${name} toe.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} moet na ${args[0]} zijn.`
    }
    return `${s(name)} moet een latere datum zijn.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} mag enkel letters bevatten.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} mag enkel letters en cijfers bevatten.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} moet voor ${args[0]} zijn.`
    }
    return `${s(name)} moet een eerdere datum zijn.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} moet tussen ${args[0]} en ${args[1]} zitten.`
    }
    return `${s(name)} moet tussen ${args[0]} en ${
      args[1]
    } lang zijn.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} komt niet overeen.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} is geen geldige datum, het juiste format is ${args[0]}`
    }
    return `${s(name)} is geen geldige datum.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `De invoer voor dit veld is niet geldig`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Voer een geldig e-mailadres in.'
    }
    return `“${value}” is geen geldig e-mailadres.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Dit veld eindigt niet op een geldige waarde.`
    }
    return `“${value}” eindigt niet op een geldige waarde.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” is niet toegestaan als ${name}.`
    }
    return `Deze ${name} is niet toegestaan.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} is niet toegestaan.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Je kunt maximaal ${args[0]} selecteren als ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} moet kleiner of gelijk zijn aan ${args[0]}.`
    }
    return `${s(name)} mag maximaal ${
      args[0]
    } karakters bevatten.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} moet van dit type zijn: ${
      args[0] || 'Bestanden zijn niet toegestaan'
    }`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Je moet tenminste ${args[0]} selecteren als ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} moet groter zijn dan ${args[0]}.`
    }
    return `${s(name)} moet tenminste ${args[0]} karakters bevatten.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” is geen geldige ${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} moet een getal zijn.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} is verplicht.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Dit veld begint niet met een geldige waarde.`
    }
    return `“${value}” begint niet met een geldige waarde.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Voer een geldige URL in.`
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
