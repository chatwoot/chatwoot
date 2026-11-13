<script setup>
import { ref, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

// Plays a message the way callers hear it: the recording Captain saved for it while the text is
// unchanged, otherwise the browser reads the text aloud
const props = defineProps({
  text: {
    type: String,
    default: '',
  },
  // The saved recording, played only while `text` is still the saved text
  audioUrl: {
    type: String,
    default: '',
  },
  savedText: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const isPlaying = ref(false);
let audio = null;

const stop = () => {
  audio?.pause();
  audio = null;
  window.speechSynthesis?.cancel();
  isPlaying.value = false;
};

const play = () => {
  const text = props.text.trim();
  if (props.audioUrl && text === props.savedText.trim()) {
    audio = new Audio(props.audioUrl);
    audio.onended = stop;
    audio.play().catch(stop);
  } else if (window.speechSynthesis && text) {
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.onend = stop;
    utterance.onerror = stop;
    window.speechSynthesis.speak(utterance);
  } else {
    return;
  }
  isPlaying.value = true;
};

const toggle = () => (isPlaying.value ? stop() : play());

onBeforeUnmount(stop);
</script>

<template>
  <NextButton
    :label="
      isPlaying
        ? t('INBOX_MGMT.CALL_SETTINGS.STOP')
        : t('INBOX_MGMT.CALL_SETTINGS.PLAY')
    "
    :icon="isPlaying ? 'i-ph-stop-fill' : 'i-ph-play-fill'"
    :disabled="!text.trim()"
    slate
    outline
    xs
    @click="toggle"
  />
</template>
