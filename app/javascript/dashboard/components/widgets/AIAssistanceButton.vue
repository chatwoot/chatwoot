<template>
  <div v-if="isAIIntegrationEnabled" class="position-relative">
    <woot-button
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
  <div v-else class="position-relative">
    <woot-button
      icon="wand"
      color-scheme="secondary"
      variant="smooth"
      size="small"
      class-names="ai-btn"
      @click="openAICta"
    >
      {{ $t('INTEGRATION_SETTINGS.OPEN_AI.AI_ASSIST') }}
    </woot-button>

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

export default {
  components: {
    AIAssistanceModal,
    AICTAModal,
  },
  mixins: [aiMixin, eventListenerMixins, adminMixin],
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
      this.initialMessage = this.draftMessage;
      const ninja = document.querySelector('ninja-keys');
      ninja.open({ parent: 'ai_assist' });
    },
    hideAICtaModal() {
      this.showAICtaModal = false;
    },
    openAICta() {
      if (this.isAdmin) {
        this.showAICtaModal = true;
      }
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
<style lang="scss" scoped>
.ai-btn {
  background: linear-gradient(
      255.98deg,
      rgba(161, 87, 246, 0.2) 15.83%,
      rgba(71, 145, 247, 0.2) 81.39%
    ),
    linear-gradient(0deg, #f2f5f8, #f2f5f8);
  animation: gradient 5s ease infinite;
}
@keyframes gradient {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
</style>
