<script>
import { ref } from 'vue';
import { mapGetters } from 'vuex';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAI } from 'dashboard/composables/useAI';
import AICTAModal from './AICTAModal.vue';
import AIAssistanceModal from './AIAssistanceModal.vue';
import { CMD_AI_ASSIST } from 'dashboard/helper/commandbar/events';
import AIAssistanceCTAButton from './AIAssistanceCTAButton.vue';
import { emitter } from 'shared/helpers/mitt';

export default {
  components: {
    AIAssistanceModal,
    AICTAModal,
    AIAssistanceCTAButton,
  },
  emits: ['replaceText'],
  setup(props, { emit }) {
    const { uiSettings, updateUISettings } = useUISettings();

    const { isAIIntegrationEnabled, draftMessage, recordAnalytics } = useAI();

    const { isAdmin } = useAdmin();

    const initialMessage = ref('');

    const initializeMessage = draftMsg => {
      initialMessage.value = draftMsg;
    };
    const keyboardEvents = {
      '$mod+KeyZ': {
        action: () => {
          if (initialMessage.value) {
            emit('replaceText', initialMessage.value);
            initialMessage.value = '';
          }
        },
        allowOnFocusedInput: true,
      },
    };
    useKeyboardEvents(keyboardEvents);

    return {
      uiSettings,
      updateUISettings,
      isAdmin,
      initialMessage,
      initializeMessage,
      recordAnalytics,
      isAIIntegrationEnabled,
      draftMessage,
    };
  },
  data: () => ({
    showAIAssistanceModal: false,
    showAICtaModal: false,
    aiOption: '',
  }),
  computed: {
    ...mapGetters({
      isAChatwootInstance: 'globalConfig/isAChatwootInstance',
    }),
    isAICTAModalDismissed() {
      return this.uiSettings.is_open_ai_cta_modal_dismissed;
    },
    // Display a AI CTA button for admins if the AI integration has not been added yet and the AI assistance modal has not been dismissed.
    shouldShowAIAssistCTAButtonForAdmin() {
      return (
        this.isAdmin &&
        !this.isAIIntegrationEnabled &&
        !this.isAICTAModalDismissed &&
        this.isAChatwootInstance
      );
    },
    // Display a AI CTA button for agents and other admins who have not yet opened the AI assistance modal.
    shouldShowAIAssistCTAButton() {
      return this.isAIIntegrationEnabled && !this.isAICTAModalDismissed;
    },
  },

  mounted() {
    emitter.on(CMD_AI_ASSIST, this.onAIAssist);
    this.initializeMessage(this.draftMessage);
  },

  methods: {
    hideAIAssistanceModal() {
      this.recordAnalytics('DISMISS_AI_SUGGESTION', {
        aiOption: this.aiOption,
      });
      this.showAIAssistanceModal = false;
    },
    openAIAssist() {
      // Dismiss the CTA modal if it is not dismissed
      if (!this.isAICTAModalDismissed) {
        this.updateUISettings({
          is_open_ai_cta_modal_dismissed: true,
        });
      }
      this.initializeMessage(this.draftMessage);
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'ai_assist' });
    },
    hideAICtaModal() {
      this.showAICtaModal = false;
    },
    openAICta() {
      this.showAICtaModal = true;
    },
    onAIAssist(option) {
      this.aiOption = option;
      this.showAIAssistanceModal = true;
    },
    insertText(message) {
      this.$emit('replaceText', message);
    },
  },
};
</script>

<template>
  <div>
    <div v-if="isAIIntegrationEnabled" class="relative">
      <AIAssistanceCTAButton
        v-if="shouldShowAIAssistCTAButton"
        @open="openAIAssist"
      />
      <woot-button
        v-else
        v-tooltip.top-end="$t('INTEGRATION_SETTINGS.OPEN_AI.AI_ASSIST')"
        icon="wand"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        @click="openAIAssist"
      />
      <woot-modal
        v-model:show="showAIAssistanceModal"
        :on-close="hideAIAssistanceModal"
      >
        <AIAssistanceModal
          :ai-option="aiOption"
          @apply-text="insertText"
          @close="hideAIAssistanceModal"
        />
      </woot-modal>
    </div>
    <div v-else-if="shouldShowAIAssistCTAButtonForAdmin" class="relative">
      <AIAssistanceCTAButton @click="openAICta" />
      <woot-modal v-model:show="showAICtaModal" :on-close="hideAICtaModal">
        <AICTAModal @close="hideAICtaModal" />
      </woot-modal>
    </div>
  </div>
</template>
