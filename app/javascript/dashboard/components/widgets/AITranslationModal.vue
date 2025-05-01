<template>
  <div class="flex flex-col">
    <woot-modal-header :header-title="$t('INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.RESPONSE_TRANSLATION')" />
    <form
      class="modal-content flex flex-col w-full pt-2 px-8 pb-8"
    >
    <div>
      <div class="p-3 bg-slate-200 dark:bg-slate-700 rounded mb-2">
        <h4 class="text-base mt-1 text-slate-700 dark:text-slate-100">
          {{
            $t(
              "INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.QUALITY_CHECK.TRANSLATION.ORIGINAL_RESPONSE"
            )
          }}
        </h4>
        <p class="text-sm" v-dompurify-html="formatMessage(message, false)" />
        <div class="flex justify-end">
          <woot-button
            @click.prevent="sendOriginalMessage"
            size="small"
            color-scheme="primary"
            icon="send"
            emoji="✅"
          >
          {{ $t("INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.SEND_ORIGINAL") }}
          </woot-button>
        </div>
      </div>
        <div class="p-3 bg-slate-200 dark:bg-slate-700 rounded mb-2">
          <h4 class="text-base mt-1 text-slate-700 dark:text-slate-100">
            {{
              $t(
                "INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.QUALITY_CHECK.TRANSLATION.TRANSLATED_RESPONSE"
              )
            }}
          </h4>
          <div v-if="!translatedMessage">
            {{
              $t(
                "INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.QUALITY_CHECK.TRANSLATION.GENERATING_TRANSLATION"
              )
            }}
          </div>
          <div v-else>
            <p
              class="text-sm"
              v-dompurify-html="formatMessage(translatedMessage, false)"
            />
            <div class="flex justify-end">
              <woot-button
                @click.prevent="sendTranslatedMessage"
                size="small"
                color-scheme="primary"
                icon="send"
                emoji="✅"
              >
              {{ $t("INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.SEND_TRANSLATED") }}
              </woot-button>
            </div>
          </div>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import aiMessageCheckMixin from 'shared/mixins/aiMessageCheckMixin';
import WootButton from '../ui/WootButton.vue';
import alertMixin from '../../../shared/mixins/alertMixin';

export default {
  components: { WootButton },
  props: {
    translatedMessage: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    }
  },
  mixins: [aiMessageCheckMixin, alertMixin, messageFormatterMixin],
  computed: {
    ...mapGetters({
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      accountId: 'getCurrentAccountId',
    }),
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    sendTranslatedMessage(){
      this.sendMessage(this.translatedMessage);
    },
    sendOriginalMessage(){
      this.sendMessage(this.message);
    },
    sendMessage(content){
      this.$emit('apply-text', content);
      setTimeout(() => {
        this.$emit('proceed-with-sending-message');
        this.onClose();
      }, 500);
    },
  },
};
</script>