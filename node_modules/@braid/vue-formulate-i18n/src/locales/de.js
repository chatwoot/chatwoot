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
const locale = 'de'

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
    return `${name} erfordert Zustimmung.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} muss auf ${args[0]} folgen.`
    }
    return `${s(name)} muss ein späteres Datum sein.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} darf nur Buchstaben enthalten.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} darf nur Buchstaben und Zahlen enthalten.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} muss vor ${args[0]} sein.`
    }
    return `${s(name)} muss ein früheres Datum sein.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} muss zwischen ${args[0]} und ${args[1]}.`
    }
    return `${s(name)} muss zwischen ${args[0]} und ${args[1]} Zeichen lang sein.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} stimmt nicht überein.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ist nicht korrekt, bitte das Format ${args[0]} benutzen.`
    }
    return `${s(name)} ist kein gültiges Datum.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Das Feld hat einen Fehler.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Bitte eine gültige E-Mail-Adresse eingeben.'
    }
    return `„${value}“ ist keine gültige E-Mail-Adresse.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Dieses Feld endet nicht mit einem gültigen Wert`
    }
    return `„${value}” endet nicht mit einem gültigen Wert.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `„${s(value)}“ ist kein gültiger Wert für ${name}.`
    }
    return `Dies ist kein gültiger Wert für ${name}.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} ist kein gültiger Wert.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Es dürfen nur ${args[0]} ${name} ausgewählt werden.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} muss kleiner oder gleich ${args[0]} sein.`
    }
    return `${s(name)} muss ${args[0]} oder weniger Zeichen lang sein.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} muss den Typ ${args[0] || 'Keine Dateien erlaubt'} haben.`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Es müssen mindestens ${args[0]} ${name} ausgewählt werden.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} muss größer als ${args[0]} sein.`
    }
    return `${s(name)} muss ${args[0]} oder mehr Zeichen lang sein.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `„${value}“ ist kein erlaubter Wert für ${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} muss eine Zahl sein.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} ist ein Pflichtfeld.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Dieses Feld beginnt nicht mit einem gültigen Wert`
    }
    return `„${value}” beginnt nicht mit einem gültigen Wert`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `${s(name)} muss eine gültige URL sein.`
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
