<template>
  <div class="flex flex-col">
    <woot-modal-header :header-title="headerTitle" />
    <form
      class="modal-content flex flex-col w-full"
      @submit.prevent="applyText"
    >
      <div v-if="draftMessage" class="w-full">
        <h4 class="text-base mt-1 text-slate-700 dark:text-slate-100">
          {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.DRAFT_TITLE') }}
        </h4>
        <p v-dompurify-html="formatMessage(draftMessage, false)" />
        <h4 class="text-base mt-1 text-slate-700 dark:text-slate-100">
          {{
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.GENERATED_TITLE')
          }}
        </h4>
      </div>
      <div>
        <AILoader v-if="isGenerating" />
        <p v-else v-dompurify-html="formatMessage(generatedContent, false)" />
      </div>

      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
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
    };
  },
  computed: {
    ...mapGetters({
      appIntegrations: 'integrations/getAppIntegrations',
    }),
    headerTitle() {
      const translationKey = this.aiOption?.toUpperCase();
      return translationKey
        ? this.$t(`INTEGRATION_SETTINGS.OPEN_AI.WITH_AI`, {
            option: this.$t(
              `INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.${translationKey}`
            ),
          })
        : '';
    },
  },
  mounted() {
    this.generateAIContent(this.aiOption);
  },

  methods: {
    onClose() {
      this.$emit('close');
    },

    async generateAIContent(type = 'rephrase') {
      this.isGenerating = true;
      this.generatedContent = await this.processEvent(type);
      this.isGenerating = false;
    },
    applyText() {
      this.recordAnalytics(this.aiOption);
      this.$emit('apply-text', this.generatedContent);
      this.onClose();
    },
  },
};
</script>

<style lang="scss" scoped>
.modal-content {
  @apply pt-2 px-8 pb-8;
}

.container {
  width: 100%;
}
</style>
