<script setup>
import { computed } from 'vue';
import Icon from 'next/icon/Icon.vue';
import * as Sentry from '@sentry/vue';
import FormSelect from 'v3/components/Form/Select.vue';

const props = defineProps({
  value: {
    type: String,
    required: true,
    validator: value =>
      ['ding', 'bell', 'chime', 'magic', 'ping'].includes(value),
  },
  label: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change']);

const alertTones = computed(() => [
  {
    value: 'ding',
    label: 'Ding',
  },
  {
    value: 'bell',
    label: 'Bell',
  },
  {
    value: 'chime',
    label: 'Chime',
  },
  {
    value: 'magic',
    label: 'Magic',
  },
  {
    value: 'ping',
    label: 'Ping',
  },
]);

const selectedValue = computed({
  get: () => props.value,
  set: value => {
    emit('change', value);
  },
});

const audio = new Audio();

const playAudio = async () => {
  try {
    // Has great support https://caniuse.com/mdn-api_htmlaudioelement
    audio.src = `/audio/dashboard/${selectedValue.value}.mp3`;
    await audio.play();
  } catch (error) {
    Sentry.captureException(error);
  }
};
</script>

<template>
  <div class="flex items-center gap-2">
    <FormSelect
      v-model="selectedValue"
      name="alertTone"
      spacing="compact"
      class="flex-grow"
      :value="selectedValue"
      :options="alertTones"
      :label="label"
    >
      <option
        v-for="tone in alertTones"
        :key="tone.label"
        :value="tone.value"
        :selected="tone.value === selectedValue"
      >
        {{ tone.label }}
      </option>
    </FormSelect>
    <button
      v-tooltip.top="
        $t('PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.PLAY')
      "
      class="border-0 shadow-sm outline-none flex justify-center items-center size-10 appearance-none rounded-xl ring-ash-200 ring-1 ring-inset focus:ring-2 focus:ring-inset focus:ring-primary-500 flex-shrink-0 mt-[1.75rem]"
      @click="playAudio"
    >
      <Icon icon="i-lucide-volume-2" />
    </button>
  </div>
</template>
