<template>
  <div class="flex flex-col">
    <woot-modal-header :header-title="$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.QUALITY_CHECK')" />
    <form
      class="modal-content flex flex-col w-full pt-2 px-8 pb-8"
    >
      <div v-if="checkerObjects" class="bg-gray-50 dark:bg-gray-700 p-3 rounded-lg">
        <div class="grid grid-cols-3 gap-3 mb-2">
          <dl v-for="(checker, index) in checkerObjects" :key="index" :class="qualityBgColor(checker.passed, 100)" class="dark:bg-gray-600 rounded-lg flex flex-col items-center justify-center h-[78px]" >
            <dt :class="qualityBgColor(checker.passed, 200)" class="text-slate-700 dark:text-slate-700 w-8 h-8 rounded-full dark:bg-gray-500 text-sm font-medium flex items-center justify-center mb-1">{{ checker.score }}</dt>
            <dd class="text-slate-7 dark:text-slate-700 text-sm font-medium">{{ qualityCheckTitle(index) }}</dd>
          </dl>
        </div>
      </div>
      <div v-if="needsRevision">
        <h4 class="text-base mt-1 text-slate-700 dark:text-slate-100">
          {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.QUALITY_CHECK.FEEDBACK') }}
        </h4>
        <p v-dompurify-html="formatMessage(answerQualityCheck.feedback, false)" />
      </div>
      <div v-if="needsSuggestion">
        <h4 class="text-base mt-1 text-slate-700 dark:text-slate-100">
          {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.QUALITY_CHECK.SUGGESTION') }}
        </h4>
        <p class="text-sm" v-dompurify-html="formatMessage(suggestedContent, false)" />
      </div>
      <div class="flex flex-row justify-between gap-2 py-2 px-0 w-full">
        <div>
          <woot-button class="small" variant="clear" @click.prevent="onClose">
            {{
              $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.CLOSE')
            }}
          </woot-button>
          <woot-button class="small" color-scheme="secondary" :disabled="!suggestedContent" v-if="needsSuggestion" @click.prevent="applySuggestion">
            {{
              $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.APPLY')
            }}
          </woot-button>
          <woot-button class="small" color-scheme="secondary" v-if="needsRevision" @click.prevent="onClose">
            {{
              $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.REVISE')
            }}
          </woot-button>
          <woot-button class="small" color-scheme="secondary" v-if="canTranslateResponse && canSendDespiteCheckFailure" @click.prevent="ignoreCheckAndSend">
            {{
              $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.SEND_ANYWAY')
            }}
          </woot-button>
        </div>
        <div>

          <woot-button v-if="canTranslateResponse && checkPassed" class="small" @click.prevent="translateMessage">
            {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.NEXT_STEP') }}
            {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.TRANSLATE') }}
          </woot-button>
          <woot-button v-else-if="canTranslateResponse && !checkPassed" class="small" @click.prevent="translateMessage">
            {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.TRANSLATE_ANYWAY') }}
          </woot-button>
          <woot-button class="small" v-else @click.prevent="ignoreCheckAndSend">
            {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.NEXT_STEP') }}
            {{ $t('INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.SEND_ANYWAY') }}
          </woot-button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import aiMessageCheckMixin from 'shared/mixins/aiMessageCheckMixin';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import WootButton from '../ui/WootButton.vue';
import alertMixin from '../../../shared/mixins/alertMixin';

export default {
  components: { WootButton },
  props: {
    aiCheckResponse: {
      type: Object,
      required: true,
    },
    conversationId: {
      type: Number,
      required: true,
    },
    message: {
      type: String,
      required: true,
    }
  },
  data: () => ({
    translatedMessage: '',
  }),
  mixins: [messageFormatterMixin, aiMessageCheckMixin, alertMixin],
  computed: {
    ...mapGetters({
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      accountId: 'getCurrentAccountId',
      uiSettings: 'getUISettings',
    }),
    headerTitle() {
      return this.$t(`INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.QUALITY_CHECK`)
    },
    needsRevision(){
      return !this.checkPassed;
    },
    needsSuggestion() {
      return !this.languageGrammarPassed;
    },
    suggestedContent(){
      return this.languageGrammarCheck?.corrected_message || '';
    },
    translationFeatureEnabled(){
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.AI_TRANSLATION
      );
    },
    canTranslateResponse() {
      return this.canShowTranslation && this.translationFeatureEnabled;
    }
  },
  methods: {
    applySuggestion() {
      this.$emit('apply-text', this.suggestedContent);
      this.onClose();
    },
    ignoreCheckAndSend(){
      this.$emit('proceed-with-sending-message');
      this.onClose();
    },
    onClose() {
      this.$emit('close');
    },
    qualityBgColor(passed, fade){
      if (passed) {
        return `bg-green-${fade}`;
      } else {
        return `bg-red-${fade}`;
      }
    },
    qualityCheckTitle(type){
      return this.$t(
        `INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.QUALITY_CHECK.HEADERS.${type.toUpperCase()}`
      );
    },
    async translateMessage(){
      this.$emit('translate-response');
      this.onClose();
    },
  },
};
</script>
<style>
.quality-check-modal .modal-container{
  width: 750px;
}
</style>