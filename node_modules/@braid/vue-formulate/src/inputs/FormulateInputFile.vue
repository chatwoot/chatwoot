<template>
  <div
    :class="context.classes.element"
    :data-type="context.type"
    :data-has-files="hasFiles"
  >
    <FormulateSlot
      name="prefix"
      :context="context"
    >
      <component
        :is="context.slotComponents.prefix"
        v-if="context.slotComponents.prefix"
        :context="context"
      />
    </FormulateSlot>
    <div
      :class="context.classes.uploadArea"
      :data-has-files="hasFiles"
    >
      <input
        ref="file"
        :data-is-drag-hover="isOver"
        type="file"
        v-bind="attributes"
        v-on="$listeners"
        @blur="context.blurHandler"
        @change="handleFile"
        @dragover="handleDragOver"
        @dragleave="handleDragLeave"
      >
      <FormulateSlot
        name="uploadAreaMask"
        :context="context"
        :has-files="hasFiles"
      >
        <component
          :is="context.slotComponents.uploadAreaMask"
          v-show="!hasFiles"
          :has-files="context.slotComponents.uploadAreaMask === 'div' ? false : hasFiles"
          :data-has-files="context.slotComponents.uploadAreaMask === 'div' ? hasFiles : false"
          :class="context.classes.uploadAreaMask"
        />
      </FormulateSlot>
      <FormulateFiles
        v-if="hasFiles"
        :files="context.model"
        :image-preview="context.type === 'image' && context.imageBehavior === 'preview'"
        :context="context"
      />
    </div>
    <FormulateSlot
      name="suffix"
      :context="context"
    >
      <component
        :is="context.slotComponents.suffix"
        v-if="context.slotComponents.suffix"
        :context="context"
      />
    </FormulateSlot>
  </div>
</template>

<script>
import FormulateInputMixin from '../FormulateInputMixin'
import FileUpload from '../FileUpload'
import FormulateFiles from '../FormulateFiles.vue'

export default {
  name: 'FormulateInputFile',
  components: {
    FormulateFiles
  },
  mixins: [FormulateInputMixin],
  data () {
    return {
      isOver: false
    }
  },
  computed: {
    hasFiles () {
      return !!(this.context.model instanceof FileUpload && this.context.model.files.length)
    }
  },
  created () {
    if (Array.isArray(this.context.model)) {
      if (typeof this.context.model[0][this.$formulate.getFileUrlKey()] === 'string') {
        this.context.model = this.$formulate.createUpload({
          files: this.context.model
        }, this.context)
      }
    }
  },
  mounted () {
    // Add a listener to the window to prevent drag/drops that miss the dropzone
    // from opening the file and navigating the user away from the page.
    if (window && this.context.preventWindowDrops) {
      window.addEventListener('dragover', this.preventDefault)
      window.addEventListener('drop', this.preventDefault)
    }
  },
  destroyed () {
    if (window && this.context.preventWindowDrops) {
      window.removeEventListener('dragover', this.preventDefault)
      window.removeEventListener('drop', this.preventDefault)
    }
  },
  methods: {
    preventDefault (e) {
      if (e.target.tagName !== 'INPUT' && e.target.getAttribute('type') !== 'file') {
        e = e || event
        e.preventDefault()
      }
    },
    handleFile () {
      this.isOver = false
      const input = this.$refs.file
      if (input.files.length) {
        this.context.model = this.$formulate.createUpload(input, this.context)
        // nextTick required for attemptImmediateUpload to pass instanceof reliably
        this.$nextTick(() => this.attemptImmediateUpload())
      }
    },
    attemptImmediateUpload () {
      if (this.context.uploadBehavior === 'live' &&
        this.context.model instanceof FileUpload) {
        this.context.hasValidationErrors().then(errors => {
          if (!errors) {
            this.context.model.upload()
          }
        })
      }
    },
    handleDragOver (e) {
      e.preventDefault()
      this.isOver = true
    },
    handleDragLeave (e) {
      e.preventDefault()
      this.isOver = false
    }
  }
}
</script>
