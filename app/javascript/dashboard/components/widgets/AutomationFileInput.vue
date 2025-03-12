<script>
import { useAlert } from 'dashboard/composables';
import Spinner from 'shared/components/Spinner.vue';
export default {
  components: {
    Spinner,
  },
  props: {
    initialFileName: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  data() {
    return {
      uploadState: 'idle',
      label: this.$t('AUTOMATION.ATTACHMENT.LABEL_IDLE'),
    };
  },
  mounted() {
    if (this.initialFileName) {
      this.label = this.initialFileName;
      this.uploadState = 'uploaded';
    }
  },
  methods: {
    async onChangeFile(event) {
      this.uploadState = 'processing';
      this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOADING');
      try {
        const file = event.target.files[0];
        const id = await this.$store.dispatch(
          'automations/uploadAttachment',
          file
        );
        this.$emit('update:modelValue', [id]);
        this.uploadState = 'uploaded';
        this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOADED');
      } catch (error) {
        this.uploadState = 'failed';
        this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOAD_FAILED');
        useAlert(this.$t('AUTOMATION.ATTACHMENT.UPLOAD_ERROR'));
      }
    },
  },
};
</script>

<template>
  <label class="input-wrapper" :class="uploadState">
    <input
      v-if="uploadState !== 'processing'"
      type="file"
      name="attachment"
      :class="uploadState === 'processing' ? 'disabled' : ''"
      @change="onChangeFile"
    />
    <Spinner v-if="uploadState === 'processing'" />
    <fluent-icon v-if="uploadState === 'idle'" icon="file-upload" />
    <fluent-icon
      v-if="uploadState === 'uploaded'"
      icon="checkmark-circle"
      type="outline"
      class="success-icon"
    />
    <fluent-icon
      v-if="uploadState === 'failed'"
      icon="dismiss-circle"
      type="outline"
      class="error-icon"
    />
    <p class="file-button">{{ label }}</p>
  </label>
</template>

<style scoped>
input[type='file'] {
  @apply hidden;
}
.input-wrapper {
  @apply flex h-9 bg-white dark:bg-slate-900 py-1 px-2 items-center text-xs cursor-pointer rounded-sm border border-dashed border-woot-100 dark:border-woot-500;
}
.success-icon {
  @apply text-green-500 dark:text-green-600 mr-2;
}
.error-icon {
  @apply text-red-500 dark:text-red-600 mr-2;
}

.processing {
  @apply cursor-not-allowed opacity-90;
}
.file-button {
  @apply whitespace-nowrap overflow-hidden text-ellipsis w-full mb-0;
}
</style>
