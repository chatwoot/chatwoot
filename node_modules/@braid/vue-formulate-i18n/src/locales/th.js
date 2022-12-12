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
const locale = 'th'

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
    return `กรุณายอมรับ ${s(name)}`
  },

  /**
   * The date is not after.
   */
  after: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ต้องเป็นวันที่หลังจาก ${args[0]}`
    }
    return `${s(name)} ต้องเป็นวันที่ยังไม่มาถึง`
  },

  /**
   * The value is not a letter.
   */
  alpha: function ({ name }) {
    return `${s(name)} มีได้เฉพาะตัวอักษรเท่านั้น`
  },

  /**
   * Rule: checks if the value is alpha numeric
   */
  alphanumeric: function ({ name }) {
    return `${s(name)} มีได้เฉพาะตัวอักษรและตัวเลขเท่านั้น`
  },

  /**
   * The date is not before.
   */
  before: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ต้องเป็นวันที่ก่อนหน้า ${args[0]}`
    }
    return `${s(name)} ต้องเป็นวันที่ผ่านมาแล้ว`
  },

  /**
   * The value is not between two numbers or lengths
   */
  between: function ({ name, value, args }) {
    const force = Array.isArray(args) && args[2] ? args[2] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ต้องมีค่าระหว่าง ${args[0]} ถึง ${args[1]}`
    }
    return `${s(name)} ต้องมีความยาว ${args[0]} ถึง ${args[1]} ตัว`
  },

  /**
   * The confirmation field does not match
   */
  confirm: function ({ name, args }) {
    return `${s(name)} ไม่ตรงกัน`
  },

  /**
   * Is not a valid date.
   */
  date: function ({ name, args }) {
    if (Array.isArray(args) && args.length) {
      return `${s(name)} ไม่ใช่วันที่ที่ถูกต้อง กรุณาใช้ตามรูปแบบ ${args[0]}`
    }
    return `${s(name)} ไม่ใช่วันที่ที่ถูกต้อง`
  },

  /**
   * The default render method for error messages.
   */
  default: function ({ name }) {
    return `ข้อมูลช่องนี้ไม่ถูกต้อง`
  },

  /**
   * Is not a valid email address.
   */
  email: function ({ name, value }) {
    if (!value) {
      return 'กรุณากรอกที่อยู่อีเมลให้ถูกต้อง'
    }
    return `“${value}” ไม่ใช่ที่อยู่อีเมลที่ถูกต้อง`
  },

  /**
   * Ends with specified value
   */
  endsWith: function ({ name, value }) {
    if (!value) {
      return `ข้อมูลช่องนี้ไม่ได้ลงท้ายด้วยค่าที่ถูกต้อง`
    }
    return `“${value}” ไม่ได้ลงท้ายด้วยค่าที่ถูกต้อง`
  },

  /**
   * Value is an allowed value.
   */
  in: function ({ name, value }) {
    if (typeof value === 'string' && value) {
      return `“${s(value)}” ไม่ใช่ ${name} ที่อนุญาตให้กรอก`
    }
    return `นี่ไม่ใช่ ${name} ที่อนุญาตให้กรอก`
  },

  /**
   * Value is not a match.
   */
  matches: function ({ name }) {
    return `${s(name)} ไม่ใช่ค่าที่อนุญาตให้กรอก`
  },

  /**
   * The maximum value allowed.
   */
  max: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `คุณเลือกได้เพียง ${args[0]} ${name} เท่านั้น`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ต้องมีไม่เกิน ${args[0]}`
    }
    return `${s(name)} ต้องยาวไม่เกิน ${args[0]} ตัว`
  },

  /**
   * The (field-level) error message for mime errors.
   */
  mime: function ({ name, args }) {
    return `${s(name)} ต้องเป็นประเภท: ${args[0] || 'ไม่มีประเภทไฟล์ที่อนุญาต'}`
  },

  /**
   * The maximum value allowed.
   */
  min: function ({ name, value, args }) {
    if (Array.isArray(value)) {
      return `คุณต้องเลือกอย่างน้อย ${args[0]} ${name}`
    }
    const force = Array.isArray(args) && args[1] ? args[1] : false
    if ((!isNaN(value) && force !== 'length') || force === 'value') {
      return `${s(name)} ต้องมีค่าอย่างน้อย ${args[0]}`
    }
    return `${s(name)} ต้องยาวอย่างน้อย ${args[0]} ตัว`
  },

  /**
   * The field is not an allowed value
   */
  not: function ({ name, value }) {
    return `“${value}” ไม่ใช่ค่า ${name} ที่อนุญาตให้กรอก`
  },

  /**
   * The field is not a number
   */
  number: function ({ name }) {
    return `${s(name)} ต้องเป็นตัวเลข`
  },

  /**
   * Required field.
   */
  required: function ({ name }) {
    return `${s(name)} จำเป็นต้องกรอก`
  },

  /**
   * Starts with specified value
   */
  startsWith: function ({ name, value }) {
    if (!value) {
      return `ข้อมูลช่องนี้ไม่ได้ขึ้นต้นด้วยค่าที่ถูกต้อง`
    }
    return `“${value}” ไม่ได้ขึ้นต้นด้วยค่าที่ถูกต้อง`
  },

  /**
   * Value is not a url.
   */
  url: function ({ name }) {
    return `กรุณาแนบลิงก์ให้ถูกต้อง`
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
