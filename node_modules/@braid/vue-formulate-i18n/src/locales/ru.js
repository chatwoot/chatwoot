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
const locale = 'ru'

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
   * Valid accepted value | Действительно допустимое значение.
   */
  accepted: function ({ name }) {
    return `Пожалуйста, подтвердите ${name}.`
  },

  /**
   * The date is not after | Дата не после.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} должна быть после ${args[0]}.`
    }
    return `${s(name)} должна быть дата после.`
  },

  /**
   * The value is not a letter | Значение может содержать только буквы.
   */
  alpha: function ({ name }) {
    return `${s(name)} может содержать только буквы.`
  },

  /**
   * Rule: checks if the value is alpha numeric | Значение может содержать только буквы и цифры.
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} может содержать только буквы и цифры.`
  },

  /**
   * The date is not before | Дата должна быть раньше.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} должно быть раньше ${args[0]}.`
    }
    return `${s(name)} должно быть раньше.`
  },

  /**
   * The value is not between two numbers or lengths | Значение должно быть между.
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} должно быть между ${args[0]} и ${args[1]}.`
    }
    return `${s(name)} должно быть между ${args[0]} и ${args[1]}.`
  },

  /**
   * The confirmation field does not match | Поле подтверждения не совпадает.
   */
  confirm: function ({ name, args }) {
    return `${s(name)} не совпадает.`
  },

  /**
   * Is not a valid date | Не является допустимой датой.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} не является допустимой датой, пожалуйста, используйте формат ${args[0]}`
    }
    return `${s(name)} не является допустимой датой.`
  },

  /**
   * The default render method for error messages | Это поле не является допустимым.
   */
  default: function ({ name }) {
    return `Это поле не является допустимым.`
  },

  /**
   * Is not a valid email address | Недействительный адрес электронной почты.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Пожалуйста, введите действительный адрес электронной почты.'
    }
    return `“${value}” недействительный адрес электронной почты.`
  },

  /**
   * Ends with specified value | Не заканчивается допустимым значением.
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Это поле не заканчивается допустимым значением.`
    }
    return `“${value}” не заканчивается допустимым значением.`
  },

  /**
   * Value is an allowed value | Выбранное значение ошибочно.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” является ошибочным для ${name}.`
    }
    return `Выбранное значение для ${name} ошибочно.`
  },

  /**
   * Value is not a match | Значение не совпадает.
   */
  matches: function ({ name }) {
    return `${s(name)} не совпадает.`
  },

  /**
   * The maximum value allowed | Максимально допустимое значение.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Вы можете выбрать только ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} должно быть меньше или равно ${args[0]}.`
    }
    return `Количество символов ${s(name)} должно быть меньше или равно ${args[0]}.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} должно быть файлом одного из следующих типов: ${args[0] || 'Не допустимые форматы файлов.'}`
  },

  /**
   * The maximum value allowed | Максимально допустимое значение.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Должно быть не менее ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} должно быть не менее ${args[0]}.`
    }
    return `Количество символов ${s(name)} должно быть не менее ${args[0]}.`
  },

  /**
   * The field is not an allowed value | Поле не является допустимым значением.
   */
  not: function ({ name, value }) {
    return `“${value}” не является допустимым ${name}.`
  },

  /**
   * The field is not a number | Поле не является числом.
   */
  number: function ({ name }) {
    return `${s(name)} должны быть числом.`
  },

  /**
   * Required field | Обязательное поле.
   */
  required: function ({ name }) {
    return `${s(name)} обязательное поле.`
  },

  /**
   * Starts with specified value | Поле должно начинаться действительным значением.
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Поле должно начинаться действительным значением.`
    }
    return `“${value}” должно начинаться действительным значением.`
  },

  /**
   * Value is not a url | Действительный URL.
   */
  url: function ({ name }) {
    return `Пожалуйста, укажите действительный URL.`
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
