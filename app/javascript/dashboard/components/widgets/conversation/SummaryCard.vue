<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';
import { useAlert } from 'dashboard/composables';
import CaptainLoader from 'dashboard/components/widgets/conversation/copilot/CaptainLoader.vue';

defineProps({
  content: {
    type: String,
    default: '',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['dismiss']);
const { t } = useI18n();
const copied = ref(false);

const copyToClipboard = async content => {
  try {
    await navigator.clipboard.writeText(content);
    copied.value = true;
    useAlert(t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    setTimeout(() => {
      copied.value = false;
    }, 2000);
  } catch {
    useAlert(t('CONTACT_PANEL.COPY_UNSUCCESSFUL'));
  }
};
</script>

<template>
  <div
    class="mx-4 mb-3 rounded-lg border border-n-strong bg-n-solid-2 shadow-sm overflow-hidden"
  >
    <div class="flex items-center justify-between px-3 py-2 bg-n-solid-3">
      <div class="flex items-center gap-1.5">
        <Icon
          icon="i-fluent-text-bullet-list-square-sparkle-32-regular"
          class="text-n-iris-10 size-4"
        />
        <span class="text-xs font-medium text-n-slate-12">
          {{ t('CONVERSATION.SUMMARY_CARD.TITLE') }}
        </span>
      </div>
      <div class="flex items-center gap-1">
        <NextButton
          v-if="!isLoading && content"
          :icon="copied ? 'i-lucide-check' : 'i-lucide-copy'"
          xs
          slate
          ghost
          :title="t('CONVERSATION.SUMMARY_CARD.COPY')"
          @click="copyToClipboard(content)"
        />
        <NextButton
          icon="i-lucide-x"
          xs
          slate
          ghost
          :title="t('CONVERSATION.SUMMARY_CARD.DISMISS')"
          @click="emit('dismiss')"
        />
      </div>
    </div>
    <div class="px-3 py-2.5">
      <div v-if="isLoading" class="flex items-center gap-2">
        <CaptainLoader class="text-n-iris-10 size-4" />
        <span class="text-sm text-n-slate-10">
          {{ t('CONVERSATION.REPLYBOX.COPILOT_THINKING') }}
        </span>
      </div>
      <p
        v-else
        class="text-sm text-n-slate-12 leading-relaxed m-0 whitespace-pre-line"
      >
        {{ content }}
      </p>
    </div>
  </div>
</template>
