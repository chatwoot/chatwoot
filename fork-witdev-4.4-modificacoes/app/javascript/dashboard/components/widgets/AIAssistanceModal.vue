<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useAI } from 'dashboard/composables/useAI';
import AILoader from './AILoader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    AILoader,
    NextButton,
  },
  props: {
    aiOption: {
      type: String,
      required: true,
    },
  },
  emits: ['close', 'applyText'],
  setup() {
    const { formatMessage } = useMessageFormatter();
    const { draftMessage, processEvent, recordAnalytics } = useAI();
    return { draftMessage, processEvent, recordAnalytics, formatMessage };
  },
  data() {
    return {
      generatedContent: '',
      isGenerating: true,
    };
  },
  computed: {
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
      this.$emit('applyText', this.generatedContent);
      this.onClose();
    },
  },
};
</script>

<template>
  <div class="flex flex-col">
    <woot-modal-header :header-title="headerTitle" />
    <form
      class="flex flex-col w-full modal-content"
      @submit.prevent="applyText"
    >
      <div v-if="draftMessage" class="w-full">
        <h4 class="mt-1 text-base text-slate-700 dark:text-slate-100">
          {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.DRAFT_TITLE') }}
        </h4>
        <p v-dompurify-html="formatMessage(draftMessage, false)" />
        <h4 class="mt-1 text-base text-slate-700 dark:text-slate-100">
          {{
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.GENERATED_TITLE')
          }}
        </h4>
      </div>
      <div>
        <AILoader v-if="isGenerating" />
        <p v-else v-dompurify-html="formatMessage(generatedContent, false)" />
      </div>

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.CANCEL')
          "
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :disabled="!generatedContent"
          :label="
            $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.APPLY')
          "
        />
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
.modal-content {
  @apply pt-2 px-8 pb-8;
}

.container {
  width: 100%;
}
</style>
