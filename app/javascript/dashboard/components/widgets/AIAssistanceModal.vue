<template>
  <div class="column">
    <woot-modal-header :header-title="headerTitle" />
    <form class="row modal-content" @submit.prevent="applyText">
      <div v-if="draftContent" class="container">
        <h4 class="sub-block-title margin-top-1">
          {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.DRAFT_TITLE') }}
        </h4>
      </div>
      <p v-if="draftContent">
        {{ draftContent }}
      </p>
      <div v-if="draftContent" class="container">
        <h4 class="sub-block-title margin-top-1">
          {{
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.GENERATED_TITLE')
          }}
        </h4>
      </div>
      <AILoader v-if="isGenerating" />
      <div v-else>
        <p>
          {{ generatedContent }}
        </p>
      </div>

      <div class="modal-footer justify-content-end w-full">
        <woot-button variant="clear" @click.prevent="onClose">
          {{
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.CANCEL')
          }}
        </woot-button>
        <woot-button :disabled="!enableButtons">
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
import AILoader from './AILoader.vue';
import aiMixin from 'dashboard/mixins/aiMixin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { buildHotKeys } from 'shared/helpers/KeyboardHelpers';

export default {
  components: {
    AILoader,
  },
  mixins: [aiMixin, eventListenerMixins],
  props: {
    aiOption: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      draftContent: '',
      generatedContent: '',
      isGenerating: true,
      initialMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      appIntegrations: 'integrations/getAppIntegrations',
    }),
    conversationId() {
      return this.currentChat?.id;
    },
    headerTitle() {
      const translationKey = this.aiOption?.toUpperCase();
      return translationKey
        ? this.$t(`INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.${translationKey}`)
        : '';
    },
    enableButtons() {
      return this.generatedContent.length > 0;
    },
  },
  mounted() {
    const savedDraftMessages = this.draftMessages || {};
    const replyType = 'REPLY';
    const key = `draft-${this.conversationId}-${replyType}`;
    const message = `${savedDraftMessages[key] || ''}`;
    this.draftContent = message;
    this.processEvent(this.aiOption);
  },

  methods: {
    onClose() {
      this.$emit('close');
    },
    onKeyDownHandler(event) {
      const keyPattern = buildHotKeys(event);
      const shouldRevertTheContent =
        ['meta+z', 'ctrl+z'].includes(keyPattern) && !!this.initialMessage;

      if (shouldRevertTheContent) {
        this.$emit('replace-text', this.initialMessage);
        this.initialMessage = '';
      }
    },
    async processEvent(type = 'rephrase') {
      try {
        const result = await OpenAPI.processEvent({
          hookId: this.hookId,
          type,
          content: this.draftContent,
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
