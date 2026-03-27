<script>
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { useAlert } from 'dashboard/composables';

export default {
  name: 'CannedResponseFileInput',
  props: {
    modelValue: {
      type: Array,
      default: () => [],
    },
    initialFiles: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['update:modelValue'],
  data() {
    return {
      attachments: this.modelValue || [],
      uploadedFiles: this.initialFiles || [],
    };
  },
  watch: {
    modelValue(newValue) {
      this.attachments = newValue || [];
    },
    initialFiles(newValue) {
      this.uploadedFiles = newValue || [];
    },
  },
  methods: {
    async handleFileUpload(event) {
      const files = Array.from(event.target.files);
      if (files.length === 0) return;

      try {
        const uploadPromises = files.map(file => uploadFile(file));
        const results = await Promise.all(uploadPromises);
        const blobIds = results.map(result => result.blobId);
        this.attachments = [...this.attachments, ...blobIds];
        this.$emit('update:modelValue', this.attachments);
      } catch (error) {
        useAlert(this.$t('CANNED_MGMT.ADD.FORM.ATTACHMENTS.UPLOAD_ERROR'));
      }
    },
    removeFile(index) {
      this.uploadedFiles.splice(index, 1);
    },
    removeAttachment(index) {
      this.attachments.splice(index, 1);
      this.$emit('update:modelValue', this.attachments);
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <input type="file" accept="image/*" multiple @change="handleFileUpload" />

    <div v-if="uploadedFiles.length > 0" class="flex flex-col gap-1">
      <p class="text-xs text-n-default">
        {{ $t('CANNED_MGMT.EDIT.FORM.ATTACHMENTS.EXISTING') }}
      </p>
      <div class="flex flex-wrap gap-2">
        <div
          v-for="(file, index) in uploadedFiles"
          :key="file.id"
          class="relative inline-block"
        >
          <img
            :src="file.file_url"
            :alt="file.filename"
            class="w-20 h-20 object-cover rounded"
          />
          <button
            type="button"
            class="absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full text-xs flex items-center justify-center"
            :aria-label="$t('CANNED_MGMT.EDIT.FORM.ATTACHMENTS.REMOVE')"
            @click="removeFile(index)"
          >
            <fluent-icon icon="dismiss" size="12" />
          </button>
        </div>
      </div>
    </div>

    <p v-if="attachments.length > 0" class="text-xs text-n-default">
      {{ attachments.length }}
      {{ $t('CANNED_MGMT.ADD.FORM.ATTACHMENTS.NEW_FILES') }}
    </p>
  </div>
</template>
