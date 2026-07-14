<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['digit']);
const { t } = useI18n();

const KEYS = [
  { digit: '1', letters: '' },
  { digit: '2', letters: 'ABC' },
  { digit: '3', letters: 'DEF' },
  { digit: '4', letters: 'GHI' },
  { digit: '5', letters: 'JKL' },
  { digit: '6', letters: 'MNO' },
  { digit: '7', letters: 'PQRS' },
  { digit: '8', letters: 'TUV' },
  { digit: '9', letters: 'WXYZ' },
  { digit: '*', letters: '' },
  { digit: '0', letters: '' },
  { digit: '#', letters: '' },
];

const getKeyLabel = digit => {
  if (digit === '*') return t('CONVERSATION.VOICE_WIDGET.STAR');
  if (digit === '#') return t('CONVERSATION.VOICE_WIDGET.POUND');
  return digit;
};
</script>

<template>
  <div
    id="voice-call-keypad"
    role="group"
    :aria-label="$t('CONVERSATION.VOICE_WIDGET.KEYPAD')"
    class="grid grid-cols-3 gap-2 px-16 py-4 border-b border-n-call-widget-border"
  >
    <button
      v-for="key in KEYS"
      :key="key.digit"
      type="button"
      :aria-label="getKeyLabel(key.digit)"
      :data-digit="key.digit"
      data-test-id="voice-call-keypad-key"
      class="flex flex-col items-center justify-center h-12 rounded-xl bg-n-alpha-2 text-n-call-widget-text hover:bg-n-alpha-3 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-teal-8"
      @click="emit('digit', key.digit)"
    >
      <span class="text-base font-medium leading-none">{{ key.digit }}</span>
      <span
        v-if="key.letters"
        class="mt-1 text-[9px] leading-none tracking-widest text-n-call-widget-sub-text"
      >
        {{ key.letters }}
      </span>
    </button>
  </div>
</template>
