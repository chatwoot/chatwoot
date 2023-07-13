<template>
  <div class="column">
    <woot-modal-header :header-title="headerTitle" />
    <form class="row modal-content" @submit.prevent="applyText">
      <h4 v-if="draftMessage" class="sub-block-title margin-top-1 w-full">
        {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.DRAFT_TITLE') }}
      </h4>
      <p v-if="draftMessage">
        {{ draftMessage }}
      </p>
      <h4 v-if="draftMessage" class="sub-block-title margin-top-1  w-full">
        {{
          $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.GENERATED_TITLE')
        }}
      </h4>
      <AILoader v-if="isGenerating" />
      <p v-else v-dompurify-html="formatMessage(generatedContent, false)" />
      <div class="modal-footer justify-content-end w-full">
        <woot-button variant="clear" @click.prevent="onClose">
          {{
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.CANCEL')
          }}
        </woot-button>
        <woot-button :disabled="!generatedContent">
          {{
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.APPLY')
          }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import OpenAPI from 'dashboard/api/integrations/openapi';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import AILoader from './AILoader.vue';
import aiMixin from 'dashboard/mixins/aiMixin';

export default {
  components: {
    AILoader,
  },
  mixins: [aiMixin, messageFormatterMixin],
  props: {
    aiOption: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      generatedContent: '',
      isGenerating: true,
      initialMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      appIntegrations: 'integrations/getAppIntegrations',
    }),
    headerTitle() {
      const translationKey = this.aiOption?.toUpperCase();
      return translationKey
        ? `${this.$t(
            `INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.${translationKey}`
          )} ${this.$t(`INTEGRATION_SETTINGS.OPEN_AI.WITH_AI`)}`
        : '';
    },
  },
  mounted() {
    this.initialMessage = this.draftMessage;
    this.processEvent(this.aiOption);
  },

  methods: {
    onClose() {
      this.$emit('close');
    },

    async processEvent(type = 'rephrase') {
      try {
        const result = await OpenAPI.processEvent({
          hookId: this.hookId,
          type,
          content: this.draftMessage,
          conversationId: this.conversationId,
        });
        const {
          data: { message: generatedMessage },
        } = result;
        this.generatedContent = generatedMessage;
      } catch (error) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.OPEN_AI.GENERATE_ERROR'));
      } finally {
        this.isGenerating = false;
      }
    },
    applyText() {
      this.$emit('apply-text', this.generatedContent);
      this.onClose();
    },
  },
};
</script>

<style lang="scss" scoped>
.modal-content {
  padding-top: var(--space-small);
}

.container {
  width: 100%;
}
</style>
