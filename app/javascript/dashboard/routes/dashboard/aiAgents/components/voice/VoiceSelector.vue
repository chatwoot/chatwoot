<script setup>
import { ref, computed, watch, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  voices: { type: Array, default: () => [] },
  modelValue: { type: String, default: '' },
  isLoading: { type: Boolean, default: false },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();
const searchQuery = ref('');
const currentAudio = ref(null);
const playingVoiceId = ref(null);

const filteredVoices = computed(() => {
  if (!searchQuery.value) return props.voices;
  const q = searchQuery.value.toLowerCase();
  return props.voices.filter(
    v =>
      v.name?.toLowerCase().includes(q) ||
      v.accent?.toLowerCase().includes(q) ||
      v.gender?.toLowerCase().includes(q) ||
      v.description?.toLowerCase().includes(q)
  );
});

const groupedVoices = computed(() => {
  const groups = {};
  filteredVoices.value.forEach(v => {
    const key = v.gender || 'other';
    if (!groups[key]) groups[key] = [];
    groups[key].push(v);
  });
  // Sort groups: female, male, neutral/other
  const order = ['female', 'male', 'neutral', 'other'];
  return order
    .filter(k => groups[k]?.length)
    .map(k => ({ gender: k, voices: groups[k] }));
});

const selectVoice = voiceId => {
  emit('update:modelValue', voiceId);
};

const playPreview = voice => {
  if (!voice.preview_url) return;

  // Stop current playback
  if (currentAudio.value) {
    currentAudio.value.pause();
    currentAudio.value = null;
  }

  if (playingVoiceId.value === voice.id) {
    playingVoiceId.value = null;
    return;
  }

  const audio = new Audio(voice.preview_url);
  currentAudio.value = audio;
  playingVoiceId.value = voice.id;

  audio.addEventListener('ended', () => {
    playingVoiceId.value = null;
    currentAudio.value = null;
  });
  audio.addEventListener('error', () => {
    playingVoiceId.value = null;
    currentAudio.value = null;
  });
  audio.play();
};

watch(
  () => props.voices,
  () => {
    searchQuery.value = '';
  }
);

onBeforeUnmount(() => {
  if (currentAudio.value) {
    currentAudio.value.pause();
    currentAudio.value = null;
  }
});

const genderLabel = gender => {
  const labels = { female: 'Female', male: 'Male', neutral: 'Neutral', other: 'Other' };
  return labels[gender] || gender;
};

// Cap long ElevenLabs descriptions to first sentence or ~80 chars
const shortDescription = voice => {
  const parts = [voice.accent, voice.use_case].filter(Boolean);
  if (voice.description) {
    // Take first sentence only
    const first = voice.description.split(/[.!]/)[0];
    parts.push(first.length > 80 ? `${first.substring(0, 77)}...` : first);
  }
  return parts.join(' · ');
};
</script>

<template>
  <div class="flex flex-col gap-3 overflow-hidden">
    <Input
      v-model="searchQuery"
      :placeholder="t('AI_AGENTS.VOICE.VOICE_SELECTOR.SEARCH_PLACEHOLDER')"
      class="w-full"
    >
      <template #prefix>
        <span class="i-lucide-search size-4 text-n-slate-9" />
      </template>
    </Input>

    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <span class="i-lucide-loader-2 size-5 text-n-slate-9 animate-spin" />
      <span class="ml-2 text-sm text-n-slate-11">
        {{ t('AI_AGENTS.VOICE.VOICE_SELECTOR.LOADING') }}
      </span>
    </div>

    <div
      v-else-if="filteredVoices.length === 0"
      class="flex items-center justify-center py-8"
    >
      <span class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.VOICE.VOICE_SELECTOR.NO_RESULTS') }}
      </span>
    </div>

    <div v-else class="flex flex-col gap-3 max-h-72 overflow-y-auto overflow-x-hidden">
      <div
        v-for="group in groupedVoices"
        :key="group.gender"
        class="flex flex-col gap-0.5"
      >
        <span class="text-xs font-medium text-n-slate-10 uppercase tracking-wider px-1 mb-1">
          {{ genderLabel(group.gender) }}
        </span>

        <div
          v-for="voice in group.voices"
          :key="voice.id"
          role="button"
          tabindex="0"
          class="flex items-center gap-2 px-2.5 py-2 rounded-lg text-left transition-colors cursor-pointer"
          :class="
            modelValue === voice.id
              ? 'bg-n-blue-3 ring-1 ring-n-blue-7'
              : 'hover:bg-n-solid-3'
          "
          @click="selectVoice(voice.id)"
          @keydown.enter="selectVoice(voice.id)"
          @keydown.space.prevent="selectVoice(voice.id)"
        >
          <!-- Check icon for selected -->
          <span
            v-if="modelValue === voice.id"
            class="i-lucide-check-circle size-4 text-n-blue-10 shrink-0"
          />
          <span v-else class="i-lucide-circle size-4 text-n-slate-8 shrink-0" />

          <!-- Voice info -->
          <div class="flex flex-col min-w-0 flex-1">
            <span class="text-sm font-medium text-n-slate-12 truncate">
              {{ voice.name }}
            </span>
            <span
              v-if="voice.description || voice.accent"
              class="text-xs text-n-slate-10 truncate"
            >
              {{ shortDescription(voice) }}
            </span>
          </div>

          <!-- Preview button -->
          <span
            v-if="voice.preview_url"
            role="button"
            tabindex="0"
            class="inline-flex items-center justify-center size-7 rounded-full hover:bg-n-solid-4 transition-colors shrink-0"
            :title="t('AI_AGENTS.VOICE.VOICE_SELECTOR.PREVIEW')"
            @click.stop="playPreview(voice)"
            @keydown.enter.stop="playPreview(voice)"
          >
            <span
              :class="
                playingVoiceId === voice.id
                  ? 'i-lucide-square size-3.5 text-n-blue-10'
                  : 'i-lucide-play size-3.5 text-n-slate-10'
              "
            />
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
