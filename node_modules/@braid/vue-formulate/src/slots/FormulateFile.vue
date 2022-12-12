<template>
  <div :class="context.classes.file">
    <div
      v-if="!!(imagePreview && file.previewData)"
      :class="context.classes.fileImagePreview"
    >
      <img
        :src="file.previewData"
        :class="context.classes.fileImagePreviewImage"
      >
    </div>
    <div
      :class="context.classes.fileName"
      :title="file.name"
      v-text="file.name"
    />
    <div
      v-if="file.progress !== false"
      :data-just-finished="file.justFinished"
      :data-is-finished="!file.justFinished && file.complete"
      :class="context.classes.fileProgress"
    >
      <div
        :class="context.classes.fileProgressInner"
        :style="{width: file.progress + '%'}"
      />
    </div>
    <div
      v-if="(file.complete && !file.justFinished) || file.progress === false"
      :class="context.classes.fileRemove"
      @click="file.removeFile"
    />
  </div>
</template>

<script>
export default {
  props: {
    file: {
      type: Object,
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
  }
}
</script>
