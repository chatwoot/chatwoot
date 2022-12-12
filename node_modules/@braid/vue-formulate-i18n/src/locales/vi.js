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
const locale = 'vi'

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
    return `${name} phải được chấp nhận.`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} phải sau ngày ${args[0]}.`
    }
    return `${s(name)} phải sau ngày hôm nay.`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} chỉ có thể chứa các kí tự chữ.`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} chỉ có thể chứa các kí tự chữ và số.`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} phải trước ngày ngày ${args[0]}.`
    }
    return `${s(name)} phải trước ngày hôm nay.`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} phải có giá trị nằm trong khoảng giữa ${args[0]} and ${args[1]}.`
    }
    return `${s(name)} phải có giá trị dài từ ${args[0]} đến ${args[1]} ký tự.`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} không khớp.`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} không phải là định dạng của ngày, vui lòng sử dụng định dạng ${args[0]}`
    }
    return `${s(name)} không phải là định dạng của ngày.`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `Trường này không hợp lệ.`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'Vui lòng nhập địa chỉ email hợp lệ.'
    }
    return `“${value}” phải là một địa chỉ email hợp lệ.`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `Trường này phải kết thúc bằng giá trị hợp lệ.`
    }
    return `“${value}” phải kết thúc bằng giá trị hợp lệ.`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” phải khớp với ${name}.`
    }
    return `${name} phải khớp với giá trị cho phép.`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} phải khớp với giá trị cho phép.`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Bạn chỉ có thể chọn ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} phải nhỏ hơn hoặc bằng ${args[0]}.`
    }
    return `${s(name)} phải nhỏ hơn hoặc bằng ${args[0]} ký tự.`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} phải chứa kiểu tệp phù hợp: ${args[0] || 'Không có định dạng tệp nào được cho phép.'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `Phải chứa ít nhất ${args[0]} ${name}.`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} phải chứa ít nhất ${args[0]}.`
    }
    return `${s(name)} phải chứa ít nhất ${args[0]} ký tự.`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” phải là ${name} hợp lệ.`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} phải là số.`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} là bắt buộc.`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `Trường này phải bắt đầu bằng giá trị hợp lệ.`
    }
    return `“${value}” phải bắt đầu bằng giá trị hợp lệ.`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `Vui lòng nhập đúng định dạng url.`
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
