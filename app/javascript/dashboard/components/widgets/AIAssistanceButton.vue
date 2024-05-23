<template>
  <div v-if="!isFetchingAppIntegrations">
    <div v-if="isAIIntegrationEnabled" class="relative">
      <AIAssistanceCTAButton
        v-if="shouldShowAIAssistCTAButton"
        @click="openAIAssist"
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
        :show.sync="showAIAssistanceModal"
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
      <woot-modal :show.sync="showAICtaModal" :on-close="hideAICtaModal">
        <AICTAModal @close="hideAICtaModal" />
      </woot-modal>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AICTAModal from './AICTAModal.vue';
import AIAssistanceModal from './AIAssistanceModal.vue';
import adminMixin from 'dashboard/mixins/aiMixin';
import aiMixin from 'dashboard/mixins/isAdmin';
import { CMD_AI_ASSIST } from 'dashboard/routes/dashboard/commands/commandBarBusEvents';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import AIAssistanceCTAButton from './AIAssistanceCTAButton.vue';

export default {
  components: {
    AIAssistanceModal,
    AICTAModal,
    AIAssistanceCTAButton,
  },
  mixins: [aiMixin, keyboardEventListenerMixins, adminMixin, uiSettingsMixin],
  data: () => ({
    showAIAssistanceModal: false,
    showAICtaModal: false,
    aiOption: '',
    initialMessage: '',
  }),
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
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
    bus.$on(CMD_AI_ASSIST, this.onAIAssist);
    this.initialMessage = this.draftMessage;
  },

  methods: {
    getKeyboardEvents() {
      return {
        '$mod+KeyZ': {
          action: () => {
            if (this.initialMessage) {
              this.$emit('replace-text', this.initialMessage);
              this.initialMessage = '';
            }
          },
        },
      };
    },
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
      this.initialMessage = this.draftMessage;
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
      this.$emit('replace-text', message);
    },
  },
};
</script>
