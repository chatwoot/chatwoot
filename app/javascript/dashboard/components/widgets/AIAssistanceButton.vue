<template>
  <div v-if="isAIIntegrationEnabled" class="position-relative">
    <AIAssistanceCTAButton
      v-if="shouldShowAIAssistCTAButtonForAgent"
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
  <div
    v-else-if="shouldShowAIAssistCTAButtonForAdmin"
    class="position-relative"
  >
    <AIAssistanceCTAButton @click="openAICta" />
    <woot-modal :show.sync="showAICtaModal" :on-close="hideAICtaModal">
      <AICTAModal @close="hideAICtaModal" />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AICTAModal from './AICTAModal.vue';
import AIAssistanceModal from './AIAssistanceModal.vue';
import adminMixin from 'dashboard/mixins/aiMixin';
import aiMixin from 'dashboard/mixins/isAdmin';
import { CMD_AI_ASSIST } from 'dashboard/routes/dashboard/commands/commandBarBusEvents';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { buildHotKeys } from 'shared/helpers/KeyboardHelpers';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import AIAssistanceCTAButton from './AIAssistanceCTAButton.vue';

export default {
  components: {
    AIAssistanceModal,
    AICTAModal,
    AIAssistanceCTAButton,
  },
  mixins: [aiMixin, eventListenerMixins, adminMixin, uiSettingsMixin],
  data: () => ({
    showAIAssistanceModal: false,
    showAICtaModal: false,
    aiOption: '',
    initialMessage: '',
  }),
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    isAICTAModalDismissed() {
      return this.uiSettings.is_open_ai_cta_modal_dismissed;
    },
    // Show CTA button for admins when AI integration is enabled and the AI assistance modal is not dismissed
    shouldShowAIAssistCTAButtonForAdmin() {
      return (
        this.isAdmin &&
        !this.isAIIntegrationEnabled &&
        !this.isAICTAModalDismissed
      );
    },
    // Show CTA button for agents who never opened the AI assistance modal
    shouldShowAIAssistCTAButtonForAgent() {
      return (
        !this.isAdmin &&
        !this.isAIIntegrationEnabled &&
        !this.isAICTAModalDismissed
      );
    },
  },

  mounted() {
    bus.$on(CMD_AI_ASSIST, this.onAIAssist);
    this.initialMessage = this.draftMessage;
  },

  methods: {
    onKeyDownHandler(event) {
      const keyPattern = buildHotKeys(event);
      const shouldRevertTheContent =
        ['meta+z', 'ctrl+z'].includes(keyPattern) && !!this.initialMessage;
      if (shouldRevertTheContent) {
        this.$emit('replace-text', this.initialMessage);
        this.initialMessage = '';
      }
    },
    hideAIAssistanceModal() {
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
