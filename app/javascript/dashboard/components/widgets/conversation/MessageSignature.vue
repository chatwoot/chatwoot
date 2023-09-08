<template>
  <div
    v-tooltip="$t('CONVERSATION.FOOTER.MESSAGE_SIGN_TOOLTIP')"
    class="my-0 mx-4 px-1 flex max-h-[8vh] items-baseline justify-between hover:bg-slate-25 dark:hover:bg-slate-800 border border-dashed border-slate-100 dark:border-slate-700 rounded-sm overflow-auto"
  >
    <p
      v-if="isSignatureAvailable"
      v-dompurify-html="formatMessage(messageSignature)"
      class="w-fit !m-0 [&>p]:m-0"
    />
    <p v-else class="w-fit !m-0">
      {{ $t('CONVERSATION.FOOTER.MESSAGE_SIGNATURE_NOT_CONFIGURED') }}
      <woot-button
        color-scheme="primary"
        variant="link"
        @click="openProfileSettings"
      >
        {{ $t('CONVERSATION.FOOTER.CLICK_HERE') }}
      </woot-button>
    </p>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import WootButton from '../../ui/WootButton.vue';

export default {
  components: { WootButton },
  mixins: [messageFormatterMixin],
  props: {
    messageSignature: {
      type: String,
      default: '',
    },
  },
  computed: {
    isSignatureAvailable() {
      return !!this.messageSignature;
    },
  },
  methods: {
    openProfileSettings() {
      return this.$router.push({ name: 'profile_settings_index' });
    },
  },
};
</script>
