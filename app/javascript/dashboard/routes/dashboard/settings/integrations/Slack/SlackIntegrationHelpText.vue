<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
export default {
  props: {
    selectedChannelName: {
      type: String,
      required: true,
    },
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
};
</script>

<template>
  <div
    class="flex-1 w-full p-6 bg-white rounded-md border border-slate-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
  >
    <div class="prose-lg max-w-5xl">
      <h5 class="dark:text-slate-100">
        {{ $t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}
      </h5>
      <p>
        <span
          v-dompurify-html="
            formatMessage(
              $t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY', {
                selectedChannelName: selectedChannelName,
              }),
              false
            )
          "
        />
      </p>
    </div>
  </div>
</template>
