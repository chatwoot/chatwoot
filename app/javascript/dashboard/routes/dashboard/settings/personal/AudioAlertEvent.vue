<template>
  <div>
    <label
      class="flex justify-between pb-1 text-sm font-medium leading-6 text-ash-900"
    >
      {{ label }}
    </label>
    <div
      class="flex flex-row justify-between h-10 max-w-xl p-2 border border-solid rounded-md border-ash-200"
    >
      <div
        class="flex flex-row items-center justify-center gap-2 px-4 border-r border-ash-200 grow"
      >
        <input
          id="audio_enable_alert_none"
          v-model="localAudioAlert"
          class="accent-primary-600"
          type="radio"
          value="none"
          @input="onChange"
        />
        <label
          class="text-sm font-medium text-ash-900"
          :class="{ 'text-ash-400': localAudioAlert !== 'none' }"
        >
          {{
            $t(
              'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.NONE'
            )
          }}
        </label>
      </div>
      <div
        class="flex flex-row items-center justify-center gap-2 px-4 border-r border-ash-200 grow"
      >
        <input
          id="audio_enable_alert_mine"
          v-model="localAudioAlert"
          class="accent-primary-600"
          type="radio"
          value="mine"
          @input="onChange"
        />
        <label
          class="text-sm font-medium text-ash-900"
          :class="{ 'text-ash-400': localAudioAlert !== 'mine' }"
        >
          {{
            $t(
              'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.ASSIGNED'
            )
          }}
        </label>
      </div>
      <div class="flex flex-row items-center justify-center gap-2 px-4 grow">
        <input
          id="audio_enable_alert_all"
          v-model="localAudioAlert"
          class="accent-primary-600"
          type="radio"
          value="all"
          @input="onChange"
        />
        <label
          class="text-sm font-medium text-ash-900"
          :class="{ 'text-ash-400': localAudioAlert !== 'all' }"
        >
          {{
            $t(
              'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPE.ALL_CONVERSATIONS'
            )
          }}
        </label>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  audioAlert: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
});

const localAudioAlert = ref(props.audioAlert);

watch(
  () => props.audioAlert,
  newValue => {
    localAudioAlert.value = newValue;
  }
);

const emit = defineEmits(['change']);
const onChange = e => {
  emit('change', e);
};
</script>
