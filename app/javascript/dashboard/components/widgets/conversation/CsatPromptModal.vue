<template>
  <woot-modal :show="show" :on-close="onCancel">
    <div class="overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('CONVERSATION.CSAT_PROMPT.TITLE')"
        :header-content="$t('CONVERSATION.CSAT_PROMPT.MESSAGE')"
      />
      <div class="w-full form-container">
        <div class="flex flex-row justify-end gap-2 px-0 w-full">
          <woot-button color-scheme="success" @click="onSendCsat">
            {{ $t('CONVERSATION.CSAT_PROMPT.SEND_CSAT') }}
          </woot-button>
          <woot-button color-scheme="secondary" @click="onSkipCsat">
            {{ $t('CONVERSATION.CSAT_PROMPT.SKIP_CSAT') }}
          </woot-button>
        </div>
      </div>
    </div>
  </woot-modal>
</template>

<script>
export default {
  name: 'CsatPromptModal',
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    onSendCsat() {
      this.$emit('send-csat');
    },
    onSkipCsat() {
      this.$emit('skip-csat');
    },
    onCancel() {
      this.$emit('cancel');
    },
  },
};
</script>
