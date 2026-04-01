<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

const props = defineProps({
  selectedChannelName: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const formattedHelpText = computed(() => {
  return formatMessage(
    t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY', {
      selectedChannelName: props.selectedChannelName,
    }),
    false
  );
});
</script>

<template>
  <div
    class="flex-1 w-full px-6 py-5 outline outline-outline-variant/15 outline-1 bg-surface-container-lowest rounded-md shadow"
  >
    <div class="prose-lg max-w-5xl">
      <h5 class="text-on-surface tracking-tight">
        {{ t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}
      </h5>
      <div
        v-dompurify-html="formattedHelpText"
        class="text-on-surface-variant"
      />
    </div>
  </div>
</template>
