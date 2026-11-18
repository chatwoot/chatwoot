<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

// Plays the recording Captain saved for a message, which is what callers hear. Playable only while
// the text is unchanged since it was saved; saving the new text records it again. Parents show it
// only when a recording exists.
const props = defineProps({
  text: {
    type: String,
    default: '',
  },
  audioUrl: {
    type: String,
    required: true,
  },
  savedText: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const isPlaying = ref(false);
let audio = null;

const isEdited = computed(() => props.text.trim() !== props.savedText.trim());

const stop = () => {
  audio?.pause();
  audio = null;
  isPlaying.value = false;
};

const play = () => {
  audio = new Audio(props.audioUrl);
  audio.onended = stop;
  audio.play().catch(stop);
  isPlaying.value = true;
};

const toggle = () => (isPlaying.value ? stop() : play());

onBeforeUnmount(stop);
</script>

<template>
  <NextButton
    v-tooltip.top="
      isEdited ? t('INBOX_MGMT.CALL_SETTINGS.PLAY_AFTER_SAVE') : ''
    "
    :label="
      isPlaying
        ? t('INBOX_MGMT.CALL_SETTINGS.STOP')
        : t('INBOX_MGMT.CALL_SETTINGS.PLAY')
    "
    :icon="isPlaying ? 'i-ph-stop-fill' : 'i-ph-play-fill'"
    :disabled="isEdited"
    slate
    outline
    xs
    @click="toggle"
  />
</template>
