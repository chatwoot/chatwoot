import { cloneDeep } from './libs/utils'
import FileUpload from './FileUpload'

export default class FormSubmission {
  /**
   * Initialize a formulate form.
   * @param {vm} form an instance of FormulateForm
   */
  constructor (form) {
    this.form = form
  }

  /**
   * Determine if the form has any validation errors.
   *
   * @return {Promise} resolves a boolean
   */
  hasValidationErrors () {
    return this.form.hasValidationErrors()
  }

  /**
   * Asynchronously generate the values payload of this form.
   * @return {Promise} resolves to json
   */
  values () {
    return new Promise((resolve, reject) => {
      const pending = []
      const values = cloneDeep(this.form.proxy)
      for (const key in values) {
        if (typeof this.form.proxy[key] === 'object' && this.form.proxy[key] instanceof FileUpload) {
          pending.push(
            this.form.proxy[key].upload().then(data => Object.assign(values, { [key]: data }))
          )
        }
      }
      Promise.all(pending)
        .then(() => resolve(values))
        .catch(err => reject(err))
    })
  }
}
