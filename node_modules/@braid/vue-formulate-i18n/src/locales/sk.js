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
const locale = 'sk'

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
    return `Prosím príjmi ${name}.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} musí byť neskôr ako ${args[0]}.`
    }
    return `Pre ${s(name)} je potrebné zvoliť neskorší dátum.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} môže obsahovať len písmená.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} môže obsahovať len písmená a čísla.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} musí byť skôr než ${args[0]}.`
    }
    return `Pre ${s(name)} je potrebné zvoliť skorší dátum.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} musí byť medzi ${args[0]} a ${args[1]}.`
    }
    return `${s(name)} musí mať od ${args[0]} do ${args[1]} znakov.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} sa nezhoduje.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} neobsahuje korektný dátum. Je potrebné použiť formát ${args[0]}`
    }
    return `${s(name)} neobsahuje korektný dátum.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Toto pole obsahuje chybu.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Prosím, uveď platnú emailovú adresu..'
    }
    return `“${value}” nie je platná emailová adresa.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Toto pole nekončí povolenou hodnotou.`
    }
    return `“${value}” nekončí povolenou hodnotou.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” nie je povolená hodnota pre ${name}.`
    }
    return `Toto nie je povolená hodnota pre ${name}.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} nie je povolená hodnota.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Je možné vybrať najviac ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} musí byť nanajvýš ${args[0]}.`
    }
    return `${s(name)} musí obsahovať nanajvýš ${args[0]} znakov.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} musí byť typu: ${args[0] || 'Žiadne formáty nie sú povolené.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Je potrebné vybrať aspoň ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} musí byť aspoň ${args[0]}.`
    }
    return `${s(name)} musí obsahovať aspoň ${args[0]} znakov.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” nie je povolená hodnota pre ${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} musí byť číslo.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} je povinné pole.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Toto pole nezačína povolenou hodnotou.`
    }
    return `“${value}” nezačína povolenou hodnotou.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Prosím, uveď platnú URL adresu.`
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
