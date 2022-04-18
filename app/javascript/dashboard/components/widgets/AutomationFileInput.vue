<template>
  <label class="input-wrapper" :class="uploadState">
    <input
      v-if="uploadState !== 'processing'"
      type="file"
      name="attachment"
      :class="uploadState === 'processing' ? 'disabled' : ''"
      @change="onChangeFile"
    />
    <spinner v-if="uploadState === 'processing'" />
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
    <span class="file-button">{{ label }}</span>
  </label>
</template>

<script>
import Spinner from 'shared/components/Spinner';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    Spinner,
  },
  mixins: [alertMixin],
  props: {
    value: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      uploadState: 'idle',
      label: this.$t('AUTOMATION.ATTACHMENT.LABEL_IDLE'),
    };
  },
  methods: {
    async onChangeFile(event) {
      this.uploadState = 'processing';
      this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOADING');
      try {
        const file = event.target.files[0];
        const formData = new FormData();
        formData.append('attachment', file, file.name);
        const id = await this.$store.dispatch(
          'automations/uploadAttachment',
          formData
        );
        this.$emit('input', [id]);
        this.uploadState = 'uploaded';
        this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOADED');
      } catch (error) {
        this.uploadState = 'failed';
        this.label = this.$t('AUTOMATION.ATTACHMENT.LABEL_UPLOAD_FAILED');
        this.showAlert(this.$t('AUTOMATION.ATTACHMENT.UPLOAD_ERROR'));
      }
    },
  },
};
</script>

<style scoped>
input[type='file'] {
  display: none;
}
.input-wrapper {
  display: flex;
  height: 39px;
  background-color: white;
  border-radius: 4px;
  border: 1px dashed #ced4db;
  padding: 4px 8px;
  align-items: center;
  font-size: 12px;
  cursor: pointer;
}
.success-icon {
  margin-right: var(--space-small);
  color: var(--g-500);
}
.error-icon {
  margin-right: var(--space-small);
  color: var(--r-500);
}

.processing {
  cursor: not-allowed;
  opacity: 0.9;
}
</style>
