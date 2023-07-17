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
</template>
<script>
import { mapGetters } from 'vuex';

import AIAssistanceModal from './AIAssistanceModal.vue';
import aiMixin from 'dashboard/mixins/aiMixin';
import { CMD_AI_ASSIST } from 'dashboard/routes/dashboard/commands/commandBarBusEvents';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import { buildHotKeys } from 'shared/helpers/KeyboardHelpers';

export default {
  components: {
    AIAssistanceModal,
  },
  mixins: [aiMixin, eventListenerMixins],
  data: () => ({
    showAIAssistanceModal: false,
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
