<template>
  <div class="column">
    <woot-modal-header :header-title="headerTitle" />
    <form class="row modal-content" @submit.prevent="applyText">
      <div class="container">
        <h4 class="sub-block-title margin-top-1">
          Draft content
        </h4>
      </div>

      <p>
        {{ draftContent }}
      </p>
      <div class="container">
        <h4 class="sub-block-title margin-top-1">
          AI generated content
        </h4>
      </div>
      <div v-if="isGenerating" class="animation-container margin-top-1">
        <div class="ai-typing--wrap ">
          <fluent-icon icon="wand" size="14" class="ai-typing--icon" />
          <label>AI is writing</label>
        </div>
        <span class="loader" />
        <span class="loader" />
        <span class="loader" />
      </div>

      <div v-else>
        <p>
          {{ generatedContent }}
        </p>
      </div>

      <div class="modal-footer justify-content-end w-full">
        <!-- <woot-button
          icon="delete-outline"
          variant="clear"
          @click.prevent="onClose"
        >
          Discard
        </woot-button> -->
        <woot-button variant="clear" @click.prevent="onClose">
          Discard
        </woot-button>
        <!-- <woot-button
          v-tooltip.top-end="$t('CONVERSATION.TRY_AGAIN')"
          color-scheme="alert"
          variant="clear"
          icon="arrow-clockwise"
          :disabled="!enableButtons"
          >Retry
        </woot-button> -->
        <woot-button :disabled="!enableButtons">
          Apply
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import OpenAPI from 'dashboard/api/integrations/openapi';

export default {
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
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      draftMessages: 'getDraftMessages',
      appIntegrations: 'integrations/getAppIntegrations',
    }),
    hookId() {
      return this.appIntegrations.find(
        integration => integration.id === 'openai' && !!integration.hooks.length
      ).hooks[0].id;
    },
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
    this.processEvent('rephrase');
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

.ai-typing--wrap {
  display: flex;
  align-items: center;
  gap: 4px;

  .ai-typing--icon {
    color: var(--v-500);
  }
}

.animation-container {
  position: relative;
  display: flex;
}

.animation-container label {
  display: inline-block;
  margin-right: 8px;
  color: var(--v-400);
}

.loader {
  display: inline-block;
  width: 6px;
  height: 6px;
  margin-right: 4px;
  margin-top: 12px;
  background-color: var(--v-300);
  border-radius: 50%;
  animation: bubble-scale 1.2s infinite;
}

.loader:nth-child(2) {
  animation-delay: 0.4s;
}

.loader:nth-child(3) {
  animation-delay: 0.8s;
}

@keyframes bubble-scale {
  0%,
  100% {
    transform: scale(1);
  }
  25% {
    transform: scale(1.3);
  }
  50% {
    transform: scale(1);
  }
}
</style>
