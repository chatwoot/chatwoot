<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AlooAssistantAPI from 'dashboard/api/aloo/assistant';

const props = defineProps({
  assistant: {
    type: Object,
    required: true,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update', 'save']);
const { t } = useI18n();

const voices = ref([]);
const isLoadingVoices = ref(false);
const voiceError = ref(null);
const isPreviewPlaying = ref(false);
const previewAudio = ref(null);

const voiceEnabled = computed(() => props.assistant.voice_enabled ?? false);
const voiceConfig = computed(() => props.assistant.voice_config || {});

const selectedVoiceId = computed(
  () => voiceConfig.value.elevenlabs_voice_id || ''
);
const stability = computed(() => voiceConfig.value.elevenlabs_stability ?? 0.5);
const similarityBoost = computed(
  () => voiceConfig.value.elevenlabs_similarity_boost ?? 0.75
);

const loadVoices = async () => {
  if (!props.assistant.id) return;

  isLoadingVoices.value = true;
  voiceError.value = null;

  try {
    const response = await AlooAssistantAPI.getVoices(props.assistant.id);
    voices.value = response.data.voices || [];
  } catch (error) {
    voiceError.value =
      error.response?.data?.error || t('ALOO.SETTINGS.VOICE.VOICES_ERROR');
  } finally {
    isLoadingVoices.value = false;
  }
};

const updateVoiceEnabled = value => {
  emit('update', { voice_enabled: value });
};

const updateVoiceConfig = (key, value) => {
  emit('update', {
    voice_config: {
      ...voiceConfig.value,
      [key]: value,
    },
  });
};

const previewVoice = async () => {
  const voiceId = selectedVoiceId.value;
  if (!voiceId) return;

  if (previewAudio.value) {
    previewAudio.value.pause();
    previewAudio.value = null;
  }

  isPreviewPlaying.value = true;

  try {
    const response = await AlooAssistantAPI.previewVoice(
      props.assistant.id,
      voiceId,
      t('ALOO.SETTINGS.VOICE.PREVIEW_TEXT')
    );
    const audioUrl = URL.createObjectURL(response.data);
    previewAudio.value = new Audio(audioUrl);
    previewAudio.value.onended = () => {
      isPreviewPlaying.value = false;
    };
    previewAudio.value.onerror = () => {
      isPreviewPlaying.value = false;
      voiceError.value = t('ALOO.SETTINGS.VOICE.PREVIEW_ERROR');
    };
    previewAudio.value.play();
  } catch (error) {
    voiceError.value =
      error.response?.data?.error || t('ALOO.SETTINGS.VOICE.PREVIEW_ERROR');
    isPreviewPlaying.value = false;
  }
};

onMounted(() => {
  if (voiceEnabled.value) {
    loadVoices();
  }
});

watch(voiceEnabled, newVal => {
  if (newVal && voices.value.length === 0) {
    loadVoices();
  }
});
</script>

<template>
  <div>
    <SettingsSection
      :title="$t('ALOO.SETTINGS.VOICE.TITLE')"
      :sub-title="$t('ALOO.SETTINGS.VOICE.DESCRIPTION')"
    >
      <div class="space-y-6">
        <div
          class="flex items-center justify-between p-4 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <div class="flex-1 mr-4">
            <p class="text-sm font-medium text-n-slate-12">
              {{ $t('ALOO.SETTINGS.VOICE.VOICE_ENABLED.LABEL') }}
            </p>
            <p class="text-xs text-n-slate-11">
              {{ $t('ALOO.SETTINGS.VOICE.VOICE_ENABLED.DESCRIPTION') }}
            </p>
          </div>
          <Switch
            :model-value="voiceEnabled"
            @update:model-value="updateVoiceEnabled"
          />
        </div>

        <template v-if="voiceEnabled">
          <div class="space-y-6">
            <div class="p-4 rounded-lg bg-n-alpha-1 border border-n-weak">
              <p class="text-sm font-medium text-n-slate-12 mb-3">
                {{ $t('ALOO.SETTINGS.VOICE.VOICE_SELECTION.TITLE') }}
              </p>

              <div
                v-if="voiceError"
                class="mb-3 p-3 rounded bg-r-50 text-r-800 text-sm"
              >
                {{ voiceError }}
              </div>

              <div class="flex items-center gap-3">
                <select
                  :value="selectedVoiceId"
                  :disabled="isLoadingVoices"
                  class="flex-1 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand"
                  @change="
                    updateVoiceConfig(
                      'elevenlabs_voice_id',
                      $event.target.value
                    )
                  "
                >
                  <option value="" disabled>
                    {{
                      isLoadingVoices
                        ? $t('ALOO.SETTINGS.VOICE.VOICE_SELECTION.LOADING')
                        : $t('ALOO.SETTINGS.VOICE.VOICE_SELECTION.PLACEHOLDER')
                    }}
                  </option>
                  <option
                    v-for="voice in voices"
                    :key="voice.voice_id"
                    :value="voice.voice_id"
                  >
                    {{ voice.name }}
                  </option>
                </select>

                <Button
                  :disabled="!selectedVoiceId || isPreviewPlaying"
                  variant="secondary"
                  size="small"
                  @click="previewVoice"
                >
                  {{
                    isPreviewPlaying
                      ? $t(
                          'ALOO.SETTINGS.VOICE.VOICE_SELECTION.PREVIEW_PLAYING'
                        )
                      : $t('ALOO.SETTINGS.VOICE.VOICE_SELECTION.PREVIEW')
                  }}
                </Button>
              </div>
            </div>

            <div class="p-4 rounded-lg bg-n-alpha-1 border border-n-weak">
              <p class="text-sm font-medium text-n-slate-12 mb-4">
                {{ $t('ALOO.SETTINGS.VOICE.VOICE_SETTINGS.TITLE') }}
              </p>

              <div class="space-y-6">
                <div>
                  <div class="flex items-center justify-between mb-2">
                    <label class="text-sm text-n-slate-12">
                      {{
                        $t('ALOO.SETTINGS.VOICE.VOICE_SETTINGS.STABILITY.LABEL')
                      }}
                    </label>
                    <span class="text-sm text-n-slate-11 font-mono">
                      {{ stability.toFixed(2) }}
                    </span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.05"
                    :value="stability"
                    class="w-full h-2 bg-n-slate-6 rounded-lg appearance-none cursor-pointer accent-n-brand"
                    @input="
                      updateVoiceConfig(
                        'elevenlabs_stability',
                        parseFloat($event.target.value)
                      )
                    "
                  />
                  <p class="text-xs text-n-slate-11 mt-1">
                    {{
                      $t(
                        'ALOO.SETTINGS.VOICE.VOICE_SETTINGS.STABILITY.DESCRIPTION'
                      )
                    }}
                  </p>
                </div>

                <div>
                  <div class="flex items-center justify-between mb-2">
                    <label class="text-sm text-n-slate-12">
                      {{
                        $t(
                          'ALOO.SETTINGS.VOICE.VOICE_SETTINGS.SIMILARITY_BOOST.LABEL'
                        )
                      }}
                    </label>
                    <span class="text-sm text-n-slate-11 font-mono">
                      {{ similarityBoost.toFixed(2) }}
                    </span>
                  </div>
                  <input
                    type="range"
                    min="0"
                    max="1"
                    step="0.05"
                    :value="similarityBoost"
                    class="w-full h-2 bg-n-slate-6 rounded-lg appearance-none cursor-pointer accent-n-brand"
                    @input="
                      updateVoiceConfig(
                        'elevenlabs_similarity_boost',
                        parseFloat($event.target.value)
                      )
                    "
                  />
                  <p class="text-xs text-n-slate-11 mt-1">
                    {{
                      $t(
                        'ALOO.SETTINGS.VOICE.VOICE_SETTINGS.SIMILARITY_BOOST.DESCRIPTION'
                      )
                    }}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </template>

        <div class="pt-4">
          <Button :is-loading="isSaving" @click="emit('save')">
            {{ $t('ALOO.ACTIONS.SAVE') }}
          </Button>
        </div>
      </div>
    </SettingsSection>
  </div>
</template>
