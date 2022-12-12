import library from './libs/library'
import rules from './libs/rules'
import mimes from './libs/mimes'
import FileUpload from './FileUpload'
import coreClasses, { applyClasses, applyStates } from './libs/classes'
import { arrayify, parseLocale, has } from './libs/utils'
import isPlainObject from 'is-plain-object'
import { en } from '@braid/vue-formulate-i18n'
import fauxUploader from './libs/faux-uploader'
import FormulateSlot from './FormulateSlot'
import FormulateSchema from './FormulateSchema'
import FormulateForm from './FormulateForm.vue'
import FormulateInput from './FormulateInput.vue'
import FormulateErrors from './FormulateErrors.vue'
import FormulateHelp from './slots/FormulateHelp.vue'
import FormulateFile from './slots/FormulateFile.vue'
import FormulateGrouping from './FormulateGrouping.vue'
import FormulateLabel from './slots/FormulateLabel.vue'
import FormulateAddMore from './slots/FormulateAddMore.vue'
import FormulateInputBox from './inputs/FormulateInputBox.vue'
import FormulateErrorList from './slots/FormulateErrorList.vue'
import FormulateInputText from './inputs/FormulateInputText.vue'
import FormulateInputFile from './inputs/FormulateInputFile.vue'
import FormulateRepeatable from './slots/FormulateRepeatable.vue'
import FormulateInputGroup from './inputs/FormulateInputGroup.vue'
import FormulateInputButton from './inputs/FormulateInputButton.vue'
import FormulateInputSelect from './inputs/FormulateInputSelect.vue'
import FormulateInputSlider from './inputs/FormulateInputSlider.vue'
import FormulateButtonContent from './slots/FormulateButtonContent.vue'
import FormulateInputTextArea from './inputs/FormulateInputTextArea.vue'
import FormulateRepeatableProvider from './FormulateRepeatableProvider.vue'
import FormulateRepeatableRemove from './slots/FormulateRepeatableRemove.vue'

/**
 * The base formulate library.
 */
class Formulate {
  /**
   * Instantiate our base options.
   */
  constructor () {
    this.options = {}
    this.defaults = {
      components: {
        FormulateSlot,
        FormulateForm,
        FormulateFile,
        FormulateHelp,
        FormulateLabel,
        FormulateInput,
        FormulateErrors,
        FormulateSchema,
        FormulateAddMore,
        FormulateGrouping,
        FormulateInputBox,
        FormulateInputText,
        FormulateInputFile,
        FormulateErrorList,
        FormulateRepeatable,
        FormulateInputGroup,
        FormulateInputButton,
        FormulateInputSelect,
        FormulateInputSlider,
        FormulateButtonContent,
        FormulateInputTextArea,
        FormulateRepeatableRemove,
        FormulateRepeatableProvider
      },
      slotComponents: {
        addMore: 'FormulateAddMore',
        buttonContent: 'FormulateButtonContent',
        errorList: 'FormulateErrorList',
        errors: 'FormulateErrors',
        file: 'FormulateFile',
        help: 'FormulateHelp',
        label: 'FormulateLabel',
        prefix: false,
        remove: 'FormulateRepeatableRemove',
        repeatable: 'FormulateRepeatable',
        suffix: false,
        uploadAreaMask: 'div'
      },
      slotProps: {},
      library,
      rules,
      mimes,
      locale: false,
      uploader: fauxUploader,
      uploadUrl: false,
      fileUrlKey: 'url',
      uploadJustCompleteDuration: 1000,
      errorHandler: (err) => err,
      plugins: [ en ],
      locales: {},
      failedValidation: () => false,
      idPrefix: 'formulate-',
      baseClasses: b => b,
      coreClasses,
      classes: {},
      useInputDecorators: true,
      validationNameStrategy: false
    }
    this.registry = new Map()
    this.idRegistry = {}
  }

  /**
   * Install vue formulate, and register it’s components.
   */
  install (Vue, options) {
    Vue.prototype.$formulate = this
    this.options = this.defaults
    var plugins = this.defaults.plugins
    if (options && Array.isArray(options.plugins) && options.plugins.length) {
      plugins = plugins.concat(options.plugins)
    }
    plugins.forEach(plugin => (typeof plugin === 'function') ? plugin(this) : null)
    this.extend(options || {})
    for (var componentName in this.options.components) {
      Vue.component(componentName, this.options.components[componentName])
    }
  }

  /**
   * Produce a deterministically generated id based on the sequence by which it
   * was requested. This should be *theoretically* the same SSR as client side.
   * However, SSR and deterministic ids can be very challenging, so this
   * implementation is open to community review.
   */
  nextId (vm) {
    const path = vm.$route && vm.$route.path ? vm.$route.path : false
    const pathPrefix = path ? vm.$route.path.replace(/[/\\.\s]/g, '-') : 'global'
    if (!Object.prototype.hasOwnProperty.call(this.idRegistry, pathPrefix)) {
      this.idRegistry[pathPrefix] = 0
    }
    return `${this.options.idPrefix}${pathPrefix}-${++this.idRegistry[pathPrefix]}`
  }

  /**
   * Given a set of options, apply them to the pre-existing options.
   * @param {Object} extendWith
   */
  extend (extendWith) {
    if (typeof extendWith === 'object') {
      this.options = this.merge(this.options, extendWith)
      return this
    }
    throw new Error(`Formulate.extend expects an object, was ${typeof extendWith}`)
  }

  /**
   * Create a new object by copying properties of base and mergeWith.
   * Note: arrays don't overwrite - they push
   *
   * @param {Object} base
   * @param {Object} mergeWith
   * @param {boolean} concatArrays
   */
  merge (base, mergeWith, concatArrays = true) {
    var merged = {}
    for (var key in base) {
      if (mergeWith.hasOwnProperty(key)) {
        if (isPlainObject(mergeWith[key]) && isPlainObject(base[key])) {
          merged[key] = this.merge(base[key], mergeWith[key], concatArrays)
        } else if (concatArrays && Array.isArray(base[key]) && Array.isArray(mergeWith[key])) {
          merged[key] = base[key].concat(mergeWith[key])
        } else {
          merged[key] = mergeWith[key]
        }
      } else {
        merged[key] = base[key]
      }
    }
    for (var prop in mergeWith) {
      if (!merged.hasOwnProperty(prop)) {
        merged[prop] = mergeWith[prop]
      }
    }
    return merged
  }

  /**
   * Determine what "class" of input this element is given the "type".
   * @param {string} type
   */
  classify (type) {
    if (this.options.library.hasOwnProperty(type)) {
      return this.options.library[type].classification
    }
    return 'unknown'
  }

  /**
   * Generate all classes for a particular context.
   * @param {Object} context
   */
  classes (classContext) {
    // Step 1: We get the global classes for all keys.
    const coreClasses = this.options.coreClasses(classContext)
    // Step 2: We extend those classes with a user defined baseClasses.
    const baseClasses = this.options.baseClasses(coreClasses, classContext)
    return Object.keys(baseClasses).reduce((classMap, key) => {
      // Step 3: For each key, apply any global overrides for that key.
      let classesForKey = applyClasses(baseClasses[key], this.options.classes[key], classContext)
      // Step 4: Apply any prop-level overrides for that key.
      classesForKey = applyClasses(classesForKey, classContext[`${key}Class`], classContext)
      // Step 5: Add state based classes from props.
      classesForKey = applyStates(key, classesForKey, this.options.classes, classContext)
      // Now we have our final classes, assign to the given key.
      return Object.assign(classMap, { [key]: classesForKey })
    }, {})
  }

  /**
   * Given a particular type, report any "additional" props to pass to the
   * various slots.
   * @param {string} type
   * @return {array}
   */
  typeProps (type) {
    const extract = obj => Object.keys(obj).reduce((props, slot) => {
      return Array.isArray(obj[slot]) ? props.concat(obj[slot]) : props
    }, [])
    const props = extract(this.options.slotProps)
    return this.options.library[type]
      ? props.concat(extract(this.options.library[type].slotProps || {}))
      : props
  }

  /**
   * Given a type and a slot, get the relevant slot props object.
   * @param {string} type
   * @param {string} slot
   * @return {object}
   */
  slotProps (type, slot, typeProps) {
    let props = Array.isArray(this.options.slotProps[slot]) ? this.options.slotProps[slot] : []
    const def = this.options.library[type]
    if (def && def.slotProps && Array.isArray(def.slotProps[slot])) {
      props = props.concat(def.slotProps[slot])
    }
    return props.reduce((props, prop) => Object.assign(props, { [prop]: typeProps[prop] }), {})
  }

  /**
   * Determine what type of component to render given the "type".
   * @param {string} type
   */
  component (type) {
    if (this.options.library.hasOwnProperty(type)) {
      return this.options.library[type].component
    }
    return false
  }

  /**
   * What component should be rendered for the given slot location and type.
   * @param {string} type the type of component
   * @param {string} slot the name of the slot
   */
  slotComponent (type, slot) {
    const def = this.options.library[type]
    if (def && def.slotComponents && def.slotComponents[slot]) {
      return def.slotComponents[slot]
    }
    return this.options.slotComponents[slot]
  }

  /**
   * Get validation rules by merging any passed in with global rules.
   * @return {object} object of validation functions
   */
  rules (rules = {}) {
    return { ...this.options.rules, ...rules }
  }

  /**
   * Attempt to get the vue-i18n configured locale.
   */
  i18n (vm) {
    if (vm.$i18n) {
      switch (typeof vm.$i18n.locale) {
        case 'string':
          return vm.$i18n.locale
        case 'function':
          return vm.$i18n.locale()
      }
    }
    return false
  }

  /**
   * Select the proper locale to use.
   */
  getLocale (vm) {
    if (!this.selectedLocale) {
      this.selectedLocale = [
        this.options.locale,
        this.i18n(vm),
        'en'
      ].reduce((selection, locale) => {
        if (selection) {
          return selection
        }
        if (locale) {
          const option = parseLocale(locale)
            .find(locale => has(this.options.locales, locale))
          if (option) {
            selection = option
          }
        }
        return selection
      }, false)
    }
    return this.selectedLocale
  }

  /**
   * Change the locale to a pre-registered one.
   * @param {string} localeTag
   */
  setLocale (locale) {
    if (has(this.options.locales, locale)) {
      this.options.locale = locale
      this.selectedLocale = locale
      // Trigger validation on all forms to swap languages
      this.registry.forEach((form, name) => {
        form.hasValidationErrors()
      })
    }
  }

  /**
   * Get the validation message for a particular error.
   */
  validationMessage (rule, validationContext, vm) {
    const generators = this.options.locales[this.getLocale(vm)]
    if (generators.hasOwnProperty(rule)) {
      return generators[rule](validationContext)
    }
    if (generators.hasOwnProperty('default')) {
      return generators.default(validationContext)
    }
    return 'Invalid field value'
  }

  /**
   * Given an instance of a FormulateForm register it.
   * @param {vm} form
   */
  register (form) {
    if (form.$options.name === 'FormulateForm' && form.name) {
      this.registry.set(form.name, form)
    }
  }

  /**
   * Given an instance of a form, remove it from the registry.
   * @param {vm} form
   */
  deregister (form) {
    if (
      form.$options.name === 'FormulateForm' &&
      form.name &&
      this.registry.has(form.name)
    ) {
      this.registry.delete(form.name)
    }
  }

  /**
   * Given an array, this function will attempt to make sense of the given error
   * and hydrate a form with the resulting errors.
   *
   * @param {error} err
   * @param {string} formName
   * @param {error}
   */
  handle (err, formName, skip = false) {
    const e = skip ? err : this.options.errorHandler(err, formName)
    if (formName && this.registry.has(formName)) {
      this.registry.get(formName).applyErrors({
        formErrors: arrayify(e.formErrors),
        inputErrors: e.inputErrors || {}
      })
    }
    return e
  }

  /**
   * Reset a form.
   * @param {string} formName
   * @param {object} initialValue
   */
  reset (formName, initialValue = {}) {
    this.resetValidation(formName)
    this.setValues(formName, initialValue)
  }

  /**
   * Submit a named form.
   * @param {string} formName
   */
  submit (formName) {
    const form = this.registry.get(formName)
    form.formSubmitted()
  }

  /**
   * Reset the form's validation messages.
   * @param {string} formName
   */
  resetValidation (formName) {
    const form = this.registry.get(formName)
    form.hideErrors(formName)
    form.namedErrors = []
    form.namedFieldErrors = {}
  }

  /**
   * Set the form values.
   * @param {string} formName
   * @param {object} values
   */
  setValues (formName, values) {
    if (values && !Array.isArray(values) && typeof values === 'object') {
      const form = this.registry.get(formName)
      form.setValues({ ...values })
    }
  }

  /**
   * Get the file uploader.
   */
  getUploader () {
    return this.options.uploader || false
  }

  /**
   * Get the global upload url.
   */
  getUploadUrl () {
    return this.options.uploadUrl || false
  }

  /**
   * When re-hydrating a file uploader with an array, get the sub-object key to
   * access the url of the file. Usually this is just "url".
   */
  getFileUrlKey () {
    return this.options.fileUrlKey || 'url'
  }

  /**
   * Create a new instance of an upload.
   */
  createUpload (fileList, context) {
    return new FileUpload(fileList, context, this.options)
  }

  /**
   * A FormulateForm failed to submit due to existing validation errors.
   */
  failedValidation (form) {
    return this.options.failedValidation(this)
  }
}

export default new Formulate()
