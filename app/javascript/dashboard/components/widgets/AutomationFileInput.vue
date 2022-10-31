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
    <p class="file-button">{{ label }}</p>
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
    initialFileName: {
      type: String,
      default: '',
    },
  },
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
  background-color: var(--white);
  border-radius: var(--border-radius-small);
  border: 1px dashed var(--w-100);
  padding: var(--space-smaller) var(--space-small);
  align-items: center;
  font-size: var(--font-size-mini);
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
.file-button {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  width: 100%;
}
</style>
