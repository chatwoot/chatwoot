<template>
  <div>
    <label
      class="flex justify-between pb-1 text-sm font-medium leading-6 text-ash-900"
    >
      {{ label }}
    </label>
    <div
      class="flex flex-row justify-between h-10 max-w-xl p-2 border border-solid rounded-xl border-ash-200"
    >
      <div
        v-for="option in alertEvents"
        :key="option.value"
        class="flex flex-row items-center justify-center gap-2 px-4 border-r border-ash-200 grow last:border-r-0"
      >
        <input
          :id="`radio-${option.value}`"
          v-model="selectedValue"
          class="shadow-sm cursor-pointer grid place-items-center border-2 border-ash-200 appearance-none rounded-full w-4 h-4 checked:bg-primary-600 before:content-[''] before:bg-primary-600 before:border-4 before:rounded-full before:border-ash-25 checked:before:w-[14px] checked:before:h-[14px] checked:border checked:border-primary-600"
          type="radio"
          :value="option.value"
        />
        <label
          :for="`radio-${option.value}`"
          class="text-sm font-medium"
          :class="
            selectedValue === option.value ? 'text-ash-900' : 'text-ash-800'
          "
        >
          {{
            $t(
              `PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPES.${option.label.toUpperCase()}`
            )
          }}
        </label>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { ALERT_EVENTS } from './constants';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  value: {
    type: String,
    default: 'all',
  },
});

const alertEvents = ALERT_EVENTS;

const emit = defineEmits(['update']);

const selectedValue = computed({
  get: () => props.value,
  set: value => {
    emit('update', value);
  },
});
</script>
