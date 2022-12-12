import nanoid from 'nanoid/non-secure'
import { setId } from './libs/utils'

/**
 * The file upload class holds and represents a file’s upload state durring
 * the upload flow.
 */
class FileUpload {
  /**
   * Create a file upload object.
   * @param {FileList} fileList
   * @param {object} context
   */
  constructor (input, context, globalOptions = {}) {
    this.input = input
    this.fileList = input.files
    this.files = []
    this.options = {
      ...{ mimes: {} },
      ...globalOptions
    }
    this.results = false
    this.context = context
    this.dataTransferCheck()
    if (context && context.uploadUrl) {
      this.options.uploadUrl = context.uploadUrl
    }
    this.uploadPromise = null
    if (Array.isArray(this.fileList)) {
      this.rehydrateFileList(this.fileList)
    } else {
      this.addFileList(this.fileList)
    }
  }

  /**
   * Given a pre-existing array of files, create a faux FileList.
   * @param {array} items expects an array of objects [{ url: '/uploads/file.pdf' }]
   * @param {string} pathKey the object-key to access the url (defaults to "url")
   */
  rehydrateFileList (items) {
    const fauxFileList = items.reduce((fileList, item) => {
      const key = this.options ? this.options.fileUrlKey : 'url'
      const url = item[key]
      const ext = (url && url.lastIndexOf('.') !== -1) ? url.substr(url.lastIndexOf('.') + 1) : false
      const mime = this.options.mimes[ext] || false
      fileList.push(Object.assign({}, item, url ? {
        name: item.name || url.substr((url.lastIndexOf('/') + 1) || 0),
        type: item.type ? item.type : mime,
        previewData: url
      } : {}))
      return fileList
    }, [])
    this.addFileList(fauxFileList)
    this.results = this.mapUUID(items)
  }

  /**
   * Produce an array of files and alert the callback.
   * @param {FileList}
   */
  addFileList (fileList) {
    for (let i = 0; i < fileList.length; i++) {
      const file = fileList[i]
      const uuid = nanoid()
      const removeFile = function () {
        this.removeFile(uuid)
      }
      this.files.push({
        progress: false,
        error: false,
        complete: false,
        justFinished: false,
        name: file.name || 'file-upload',
        file,
        uuid,
        path: false,
        removeFile: removeFile.bind(this),
        previewData: file.previewData || false
      })
    }
  }

  /**
   * Check if the file has an.
   */
  hasUploader () {
    return !!this.context.uploader
  }

  /**
   * Check if the given uploader is axios instance. This isn't a great way of
   * testing if it is or not, but AFIK there isn't a better way right now:
   *
   * https://github.com/axios/axios/issues/737
   */
  uploaderIsAxios () {
    if (
      this.hasUploader() &&
      typeof this.context.uploader.request === 'function' &&
      typeof this.context.uploader.get === 'function' &&
      typeof this.context.uploader.delete === 'function' &&
      typeof this.context.uploader.post === 'function'
    ) {
      return true
    }
    return false
  }

  /**
   * Get a new uploader function.
   */
  getUploader (...args) {
    if (this.uploaderIsAxios()) {
      const formData = new FormData()
      formData.append(this.context.name || 'file', args[0])
      if (this.context.uploadUrl === false) {
        throw new Error('No uploadURL specified: https://vueformulate.com/guide/inputs/file/#props')
      }
      return this.context.uploader.post(this.context.uploadUrl, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        onUploadProgress: progressEvent => {
          // args[1] here is the upload progress handler function
          args[1](Math.round((progressEvent.loaded * 100) / progressEvent.total))
        }
      })
        .then(res => res.data)
        .catch(err => args[2](err))
    }
    return this.context.uploader(...args)
  }

  /**
   * Perform the file upload.
   */
  upload () {
    // If someone calls upload() when an upload is already in process or there
    // already was an upload completed, chain the upload request to the
    // existing one. Already uploaded files wont re-upload and it ensures any
    // files that were added after the initial list are completed too.
    this.uploadPromise = this.uploadPromise
      ? this.uploadPromise.then(() => this.__performUpload())
      : this.__performUpload()
    return this.uploadPromise
  }

  /**
   * Perform the actual upload event. Intended to be a private method that is
   * only called through the upload() function as chaining utility.
   */
  __performUpload () {
    return new Promise((resolve, reject) => {
      if (!this.hasUploader()) {
        return reject(new Error('No uploader has been defined'))
      }
      Promise.all(this.files.map(file => {
        file.error = false
        file.complete = !!file.path
        return file.path ? Promise.resolve(file.path) : this.getUploader(
          file.file,
          (progress) => {
            file.progress = progress
            this.context.rootEmit('file-upload-progress', progress)
            if (progress >= 100) {
              if (!file.complete) {
                file.justFinished = true
                setTimeout(() => { file.justFinished = false }, this.options.uploadJustCompleteDuration)
              }
              file.complete = true
              this.context.rootEmit('file-upload-complete', file)
            }
          },
          (error) => {
            file.progress = 0
            file.error = error
            file.complete = true
            this.context.rootEmit('file-upload-error', error)
            reject(error)
          },
          this.options
        )
      }))
        .then(results => {
          this.results = this.mapUUID(results)
          resolve(results)
        })
        .catch(err => {
          throw new Error(err)
        })
    })
  }

  /**
   * Remove a file from the uploader (and the file list)
   * @param {string} uuid
   */
  removeFile (uuid) {
    const originalLength = this.files.length
    this.files = this.files.filter(file => file && file.uuid !== uuid)
    if (Array.isArray(this.results)) {
      this.results = this.results.filter(file => file && file.__id !== uuid)
    }
    this.context.performValidation()
    if (window && this.fileList instanceof FileList && this.supportsDataTransfers) {
      const transfer = new DataTransfer()
      this.files.forEach(file => transfer.items.add(file.file))
      this.fileList = transfer.files
      this.input.files = this.fileList
    } else {
      this.fileList = this.fileList.filter(file => file && file.__id !== uuid)
    }
    if (originalLength > this.files.length) {
      this.context.rootEmit('file-removed', this.files)
    }
  }

  /**
   * Given another input element, add the files from that FileList to the
   * input being represented by this FileUpload.
   *
   * @param {HTMLElement} input
   */
  mergeFileList (input) {
    this.addFileList(input.files)
    // Create a new mutable FileList
    if (this.supportsDataTransfers) {
      const transfer = new DataTransfer()
      this.files.forEach(file => {
        if (file.file instanceof File) {
          transfer.items.add(file.file)
        }
      })
      this.fileList = transfer.files
      this.input.files = this.fileList
      // Reset the merged FileList to empty
      input.files = (new DataTransfer()).files
    }
    this.context.performValidation()
    this.loadPreviews()
    if (this.context.uploadBehavior !== 'delayed') {
      this.upload()
    }
  }

  /**
   * load image previews for all uploads.
   */
  loadPreviews () {
    this.files.map(file => {
      if (!file.previewData && window && window.FileReader && /^image\//.test(file.file.type)) {
        const reader = new FileReader()
        reader.onload = e => Object.assign(file, { previewData: e.target.result })
        reader.readAsDataURL(file.file)
      }
    })
  }

  /**
   * Check if the current browser supports the DataTransfer constructor.
   */
  dataTransferCheck () {
    try {
      new DataTransfer() // eslint-disable-line
      this.supportsDataTransfers = true
    } catch (err) {
      this.supportsDataTransfers = false
    }
  }

  /**
   * Get the files.
   */
  getFiles () {
    return this.files
  }

  /**
   * Run setId on each item of a pre-existing array of items.
   * @param {array} items expects an array of objects [{ url: '/uploads/file.pdf' }]
   */
  mapUUID (items) {
    return items.map((result, index) => {
      this.files[index].path = result !== undefined ? result : false
      return result && setId(result, this.files[index].uuid)
    })
  }

  toString () {
    const descriptor = this.files.length ? this.files.length + ' files' : 'empty'
    return this.results ? JSON.stringify(this.results, null, '  ') : `FileUpload(${descriptor})`
  }
}

export default FileUpload
