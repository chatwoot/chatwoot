<script setup>
import { computed } from 'vue';
import CheckBox from 'v3/components/Form/CheckBox.vue';
import { ALERT_EVENTS } from './constants';

const props = defineProps({
  label: {
    type: String,
    default: '',
  },
  value: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update']);

const alertEvents = ALERT_EVENTS;

const selectedValue = computed({
  get: () => props.value.split('+'),
  set: value => {
    const sortedValues = value.sort().filter(Boolean);
    emit('update', sortedValues.join('+'));
  },
});

const setValue = (isChecked, value) => {
  const updatedValue = isChecked
    ? [...selectedValue.value, value]
    : selectedValue.value.filter(item => item !== value);
  selectedValue.value = updatedValue;
};

const alertDescription = computed(() => {
  const base =
    'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_COMBINATIONS.';
  if (props.value === '') {
    return base + 'NONE';
  }

  return base + props.value.toUpperCase();
});
</script>

<template>
  <div>
    <label class="pb-1 text-sm font-medium leading-6 text-ash-900">
      {{ label }}
    </label>
    <div class="grid gap-3 mt-2">
      <div
        v-for="option in alertEvents"
        :key="option.value"
        class="flex items-center gap-2"
      >
        <CheckBox
          :id="`checkbox-${option.value}`"
          :is-checked="selectedValue.includes(option.value)"
          @update="(_val, isChecked) => setValue(isChecked, option.value)"
        />
        <label
          :for="`checkbox-${option.value}`"
          class="text-sm font-medium"
          :class="
            selectedValue.includes(option.value)
              ? 'text-ash-900'
              : 'text-ash-800'
          "
        >
          {{
            $t(
              `PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_TYPES.${option.label.toUpperCase()}`
            )
          }}
        </label>
      </div>
      <div class="text-n-slate-11 text-sm font-medium mt-2">
        {{ $t(alertDescription) }}
      </div>
    </div>
  </div>
</template>
