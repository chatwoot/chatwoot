<script>
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

export default {
  name: 'EmailPreviewModal',
  components: {
    Spinner,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    messageData: {
      type: Object,
      required: true,
    },
  },
  emits: ['close'],
  data() {
    return {
      isLoading: true,
      previewHtml: '',
      error: null,
    };
  },
  async mounted() {
    await this.fetchPreview();
  },
  methods: {
    async fetchPreview() {
      this.isLoading = true;
      this.error = null;
      try {
        const html = await this.$store.dispatch('getEmailPreview', {
          conversationId: this.conversationId,
          messageData: this.messageData,
        });
        this.previewHtml = html;
      } catch (error) {
        this.error = error.message || 'Failed to load email preview';
      } finally {
        this.isLoading = false;
      }
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto">
    <woot-modal-header :header-title="$t('INBOX.PREVIEW_MODAL.TITLE')" />
    <div class="p-4">
      <div v-if="isLoading" class="flex justify-center items-center py-8">
        <Spinner class="text-n-brand" />
      </div>
      <div v-else-if="error" class="text-red-600 p-4">
        {{ error }}
      </div>
      <iframe
        v-else
        :srcdoc="previewHtml"
        class="w-full h-[600px] border border-n-weak rounded"
        sandbox="allow-same-origin"
        :title="$t('INBOX.PREVIEW_MODAL.TITLE')"
      />
    </div>
  </div>
</template>
