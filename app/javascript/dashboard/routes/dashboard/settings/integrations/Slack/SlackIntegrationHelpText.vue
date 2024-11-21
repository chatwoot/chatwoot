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
    class="flex-1 w-full p-6 shadow outline-1 outline outline-n-container rounded-2xl bg-n-solid-2 px-6 py-5"
  >
    <div class="prose-lg max-w-5xl text-n-slate-11">
      <h5>
        {{ $t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}
      </h5>
      <p>
        <span
          v-dompurify-html="formatMessage(
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
