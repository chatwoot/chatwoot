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
const locale = 'ko'

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
    return `${name} 승인해 주세요.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ${args[0]} 이후이어야 합니다.`
    }
    return `${s(name)} 미래의 날짜이어야 합니다.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} 알파벳만 사용할 수 있습니다.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} 문자와 숫자만 사용할 수 있습니다.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ${args[0]} 이전이어야 합니다.`
    }
    return `${s(name)}이전이어야 합니다.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ${args[0]}와 ${args[1]}사이이어야 합니다.`
    }
    return `${s(name)} ${args[0]}자애서 ${args[1]}자 사이이어야 합니다.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} 일치하지 않습니다.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} 유효한 날짜 형식이 아닙니다. 다음과 같은 형식으로 입력해 주세요: ${args[0]}`
    }
    return `${s(name)}올바른 날짜 형식이 아닙니다.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `유효하지 않은 값입니다.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return '유효한 이메일 주소를 입력해 주세요.'
    }
    return `“${value}” 유효한 이메일 주소가 아닙니다.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `유효한 값으로 끝나지 않습니다.`
    }
    return `“${value}”으로 끝내야합니다.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” 허용된 ${name} 아닙니다.`
    }
    return `${name} 허용된 값이 아닙니다.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} 허용 된 값이 아닙니다.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `${name} ${args[0]}개의 항목만 선택 가능합니다.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ${args[0]}이하이어야 합니다.`
    }
    return `${s(name)} ${args[0]}자 이하이어야 합니다.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} 다음과 같은 파일 형식이어야 합니다: ${args[0] || '허용되는 파일 형식이 아닙니다.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `${name} ${args[0]} 이상 선택해 주세요.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ${args[0]}이상이어야 합니다.`
    }
    return `${s(name)} ${args[0]}자 이상이어야 합니다.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” 허용된 ${name} 아닙니다.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} 숫자만 사용 가능합니다.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} 필수 항목입니다.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `유효한 값으로 시작하지 않습니다.`
    }
    return `“${value}” 유효한 값으로 시작하지 않습니다.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `유효한 URL을 입력해 주세요.`
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
