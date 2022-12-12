<template>
  <component
    :is="slotComponent"
    :visible-errors="visibleErrors"
    :item-class="itemClass"
    :outer-class="outerClass"
    :role="role"
    :aria-live="ariaLive"
    :type="type"
  />
</template>

<script>
import { arrayify } from './libs/utils'

export default {
  inject: {
    observeErrors: {
      default: false
    },
    removeErrorObserver: {
      default: false
    },
    observeContext: {
      default: false
    },
    removeContextObserver: {
      default: false
    }
  },
  props: {
    context: {
      type: Object,
      default: () => ({})
    },
    type: {
      type: String,
      default: 'form'
    }
  },
  data () {
    return {
      boundSetErrors: this.setErrors.bind(this),
      boundSetFormContext: this.setFormContext.bind(this),
      localErrors: [],
      formContext: {
        classes: {
          formErrors: 'formulate-form-errors',
          formError: 'formulate-form-error'
        }
      }
    }
  },
  computed: {
    visibleValidationErrors () {
      return Array.isArray(this.context.visibleValidationErrors) ? this.context.visibleValidationErrors : []
    },
    errors () {
      return Array.isArray(this.context.errors) ? this.context.errors : []
    },
    mergedErrors () {
      return this.errors.concat(this.localErrors)
    },
    visibleErrors () {
      return Array.from(new Set(this.mergedErrors.concat(this.visibleValidationErrors)))
        .filter(message => typeof message === 'string')
    },
    outerClass () {
      if (this.type === 'input' && this.context.classes) {
        return this.context.classes.errors
      }
      return this.formContext.classes.formErrors
    },
    itemClass () {
      if (this.type === 'input' && this.context.classes) {
        return this.context.classes.error
      }
      return this.formContext.classes.formError
    },
    role () {
      return this.type === 'form' ? 'alert' : 'status'
    },
    ariaLive () {
      return this.type === 'form' ? 'assertive' : 'polite'
    },
    slotComponent () {
      return this.$formulate.slotComponent(null, 'errorList')
    }
  },
  created () {
    // This registration is for <FormulateErrors /> that are used for displaying
    // Form errors in an override position.
    if (this.type === 'form' && typeof this.observeErrors === 'function') {
      if (!Array.isArray(this.context.errors)) {
        this.observeErrors({ callback: this.boundSetErrors, type: 'form' })
      }
      this.observeContext(this.boundSetFormContext)
    }
  },
  destroyed () {
    if (this.type === 'form' && typeof this.removeErrorObserver === 'function') {
      if (!Array.isArray(this.context.errors)) {
        this.removeErrorObserver(this.boundSetErrors)
      }
      this.removeContextObserver(this.boundSetFormContext)
    }
  },
  methods: {
    setErrors (errors) {
      this.localErrors = arrayify(errors)
    },
    setFormContext (context) {
      this.formContext = context
    }
  }
}
</script>
