<template>
  <ul
    v-if="fileUploads.length"
    :class="context.classes.files"
  >
    <li
      v-for="file in fileUploads"
      :key="file.uuid"
      :data-has-error="!!file.error"
      :data-has-preview="!!(imagePreview && file.previewData)"
    >
      <FormulateSlot
        name="file"
        :context="context"
        :file="file"
        :image-preview="imagePreview"
      >
        <component
          :is="context.slotComponents.file"
          :context="context"
          :file="file"
          :image-preview="imagePreview"
        />
      </FormulateSlot>
      <div
        v-if="file.error"
        :class="context.classes.fileUploadError"
        v-text="file.error"
      />
    </li>
    <div
      v-if="isMultiple && context.addLabel"
      :class="context.classes.fileAdd"
      role="button"
    >
      {{ context.addLabel }}
      <input
        ref="addFiles"
        type="file"
        multiple
        :class="context.classes.fileAddInput"
        @change="appendFiles"
      >
    </div>
  </ul>
</template>

<script>
import { has } from './libs/utils'
import FileUpload from './FileUpload'

export default {
  name: 'FormulateFiles',
  props: {
    files: {
      type: FileUpload,
      required: true
    },
    imagePreview: {
      type: Boolean,
      default: false
    },
    context: {
      type: Object,
      required: true
    }
  },
  computed: {
    fileUploads () {
      return this.files.files || []
    },
    isMultiple () {
      return has(this.context.attributes, 'multiple')
    }
  },
  watch: {
    files () {
      if (this.imagePreview) {
        this.files.loadPreviews()
      }
    }
  },
  mounted () {
    if (this.imagePreview) {
      this.files.loadPreviews()
    }
  },
  methods: {
    appendFiles () {
      const input = this.$refs.addFiles
      if (input.files.length) {
        this.files.mergeFileList(input)
      }
    }
  }
}
</script>
