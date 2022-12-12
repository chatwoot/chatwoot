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
const locale = 'ca'

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
    return `Si us plau accepta els ${name}.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ha de ser després de ${args[0]}.`
    }
    return `${s(name)} ha de ser una data posterior.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} només pot contenir lletres.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} només pot contenir lletres i números.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ha de ser abans de ${args[0]}.`
    }
    return `${s(name)} ha de ser una data anterior`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ha d'estar entre ${args[0]} i ${args[1]}.`
    }
    return `${s(name)} ha de tenir entre ${args[0]} i ${args[1]} caràcters.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} no coincideix.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} no és una data vàlida, si us plau usi el format ${args[0]}`
    }
    return `${s(name)} no és una data vàlida.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Aquest camp no és vàlid.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Si us plau introdueixi un correu electrònic vàlid.'
    }
    return `“${value}” no és un correu electrònic vàlid.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Aquest camp no acaba en un valor vàlid.`
    }
    return `“${value}” no acaba en un valor vàlid.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” no és un ${name} permès.`
    }
    return `Això no és un ${name} permès.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} no és un valor permès.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Només pots seleccionar ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ha de ser menor o igual que ${args[0]}.`
    }
    return `${s(name)} ha de ser menor o igual que ${args[0]} caràcters.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} ha de ser de tipus: ${args[0] || 'No es permet el format d\'arxius.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Necessites almenys ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ha de contenir almenys ${args[0]}.`
    }
    return `${s(name)} ha de contenir almenys ${args[0]} caràcters.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” no és un ${name} permès.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} ha de ser un número.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} és requerit.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Aquest camp no comença amb un valor vàlid.`
    }
    return `“${value}” no comença amb un valor vàlid.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Si us plau introdueixi una url vàlida.`
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
