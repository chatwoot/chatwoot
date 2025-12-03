<template>
  <div
    v-if="attachment"
    class="mb-2.5 rounded-[7px] px-2 py-1.5 flex items-center gap-2"
    :class="
      $dm(
        'bg-slate-100 text-slate-700',
        'dark:bg-slate-900 dark:text-slate-100'
      )
    "
  >
    <!-- Image Preview -->
    <div
      v-if="isImage"
      class="relative w-10 h-10 rounded overflow-hidden flex-shrink-0"
    >
      <img
        :src="attachment.thumbUrl"
        class="w-full h-full object-cover"
        alt="Preview"
      />
    </div>

    <!-- File Icon for non-images -->
    <div
      v-else
      class="flex items-center justify-center w-10 h-10 rounded flex-shrink-0"
      :class="$dm('bg-slate-200', 'dark:bg-slate-700')"
    >
      <fluent-icon icon="document" size="20" />
    </div>

    <!-- File Info -->
    <div class="flex-1 min-w-0">
      <p class="text-sm truncate">
        <strong>{{ fileType }}:</strong> {{ fileName }}
      </p>
    </div>

    <!-- Remove Button -->
    <button
      class="flex-shrink-0 p-1 rounded-md"
      :class="$dm('hover:bg-slate-200', 'dark:hover:bg-slate-800')"
      @click="onRemove"
    >
      <fluent-icon icon="dismiss" size="12" />
    </button>
  </div>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';

export default {
  name: 'AttachmentPreview',
  components: {
    FluentIcon,
  },
  mixins: [darkModeMixin],
  props: {
    attachment: {
      type: Object,
      default: null,
    },
    onRemove: {
      type: Function,
      default: () => {},
    },
  },
  computed: {
    isImage() {
      return this.attachment?.fileType === 'image';
    },
    fileName() {
      if (this.attachment?.file?.name) {
        return this.attachment.file.name;
      }
      return this.isImage ? 'Image' : 'File';
    },
    fileType() {
      if (this.isImage) return 'Image';
      if (this.attachment?.fileType === 'video') return 'Video';
      return 'File';
    },
  },
};
</script>
