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
const locale = 'fr'

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
    return `Merci d'accepter les ${name}.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} doit être postérieur à ${args[0]}.`
    }
    return `${s(name)} doit être une date ultérieure.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} peut uniquement contenir des lettres.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} peut uniquement contenir des lettres ou des chiffres`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} doit être antérieur à ${args[0]}.`
    }
    return `${s(name)} doit être une date antérieure.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} doit être compris entre ${args[0]} et ${args[1]}.`
    }
    return `${s(name)} doit être compris entre ${args[0]} et ${args[1]} caractères.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} ne correspond pas.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} n'est pas valide.  Merci d'utiliser le format ${args[0]}`
    }
    return `${s(name)} n'est pas une date valide.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Ce champ n'est pas valide.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Merci d\'entrer une adresse email valide.'
    }
    return `“${value}” n'est pas une adresse email valide.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Ce champ ne termine pas par une valeur correcte.`
    }
    return `“${value}” ne termine pas par une valeur correcte.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” n'est pas un(e) ${name} autorisé(e).`
    }
    return `Cette valeur n'est pas un(e) ${name} autorisé(e).`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} n'est pas une valeur autorisée.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Vous pouvez uniquement sélectionner ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} doit être inférieur ou égal à ${args[0]}.`
    }
    return `${s(name)} doit être inférieur ou égal à ${args[0]} caractères.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} doit être de type: ${args[0] || 'Aucun format autorisé.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Vous devez sélectionner au moins ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} doit être supérieur à ${args[0]}.`
    }
    return `${s(name)} doit être plus long que ${args[0]} caractères.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” n'est pas un(e) ${name} autorisé(e).`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} doit être un nombre.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} est obligatoire.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Ce champ ne commence pas par une valeur correcte.`
    }
    return `“${value}” ne commence pas par une valeur correcte.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Merci d'entrer une URL valide.`
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
