<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  replyLabel: {
    type: String,
    required: true,
  },
  hasLatest: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['open', 'goToLatest']);

const { t } = useI18n();
const replyShortcut = useKbd(['alt', 'l']);
const noteShortcut = useKbd(['alt', 'p']);

const actions = computed(() => [
  {
    mode: REPLY_EDITOR_MODES.REPLY,
    icon: 'i-lucide-reply',
    label: props.replyLabel,
    shortcut: replyShortcut.value,
  },
  {
    mode: REPLY_EDITOR_MODES.NOTE,
    icon: 'i-lucide-lock',
    label: t('CONVERSATION.REPLYBOX.PRIVATE_NOTE'),
    shortcut: noteShortcut.value,
  },
]);
</script>

<template>
  <div
    class="flex items-center h-11 gap-1 px-1.5 text-sm rounded-xl outline outline-1 -outline-offset-1 outline-n-weak bg-n-slate-3/60 backdrop-blur-xl backdrop-saturate-150 shadow-md text-n-slate-11"
  >
    <button
      v-for="action in actions"
      :key="action.mode"
      type="button"
      class="flex items-center min-w-0 h-8 gap-2 px-2.5 rounded-lg text-n-slate-12 transition-colors hover:bg-n-alpha-2 focus-visible:outline-none focus-visible:bg-n-alpha-2"
      @click="emit('open', action.mode)"
    >
      <Icon :icon="action.icon" class="flex-shrink-0 size-4" />
      <span class="min-w-0 truncate">{{ action.label }}</span>
      <kbd
        class="flex-shrink-0 px-1 text-xs font-sans tracking-wide border rounded border-n-strong text-n-slate-11"
      >
        {{ action.shortcut }}
      </kbd>
    </button>
    <NextButton
      v-if="hasLatest"
      :label="$t('CONVERSATION.CONTACT_HISTORY.GO_TO_LATEST')"
      icon="i-lucide-chevrons-up"
      link
      xs
      class="flex-shrink-0 ms-auto me-2.5 whitespace-nowrap"
      @click="emit('goToLatest')"
    />
  </div>
</template>
