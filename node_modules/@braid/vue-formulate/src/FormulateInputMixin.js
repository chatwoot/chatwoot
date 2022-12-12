/**
 * Default base for input components.
 */
export default {
  props: {
    context: {
      type: Object,
      required: true
    }
  },
  computed: {
    type () {
      return this.context.type
    },
    attributes () {
      return this.context.attributes || {}
    },
    hasValue () {
      return this.context.hasValue
    }
  }
}
