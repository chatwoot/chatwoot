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
const locale = 'pl'

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
    return `Proszę zaakceptować ${name}.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} musi być po ${args[0]}.`
    }
    return `${s(name)} musi być przyszłą datą.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} może zawierać wyłącznie znaki alfabetyczne.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} może zawierać wyłącznie liczby i litery.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} musi być przed ${args[0]}.`
    }
    return `${s(name)} musi być wczesniejszą datą.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} musi być pomiędzy ${args[0]} oraz ${args[1]}.`
    }
    return `${s(name)} musi być pomiędzy ${args[0]} oraz ${args[1]} znaków.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} nie pasuje.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} nie jest poprawną datą, proszę użyć formatu ${args[0]}`
    }
    return `${s(name)} nie jest poprawną datą.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Pole nie jest poprawne.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Proszę podać poprawny adres email.'
    }
    return `“${value}” nie jest poprawnym adresem email.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Pole nie kończy się z poprawną wartością.`
    }
    return `“${value}” nie kończy się z poprawną wartością.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” jest niedozwoloną wartością pola ${name}.`
    }
    return `Wartość jest niedozwolona w polu ${name}.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} nie jest dozwoloną wartością.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Możesz wybrać maksymalnie ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} musi być mniejszy lub równy ${args[0]}.`
    }
    return `${s(name)} musi być mniejszy lub równy ${args[0]} znaków.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} musi być typem: ${args[0] || 'Niedozwolone formaty plików.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Potrzeba przynajmniej ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} musi mieć przynajmniej ${args[0]}.`
    }
    return `${s(name)} musi mieć przynajmniej ${args[0]} znaków.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” jest niedozwoloną wartością ${name}.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} musi być liczbą.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} jest wymagane.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Pole nie zaczyna się z poprawną wartością.`
    }
    return `“${value}” nie zaczyna się z poprawną wartością.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Proszę wprowadzić poprawny adres URL.`
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
