<script setup>
import { computed } from 'vue';
import CheckBox from 'v3/components/Form/CheckBox.vue';
import { ALERT_EVENTS, EVENT_TYPES } from './constants';

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
const alertEventValues = Object.values(EVENT_TYPES);

const selectedValue = computed({
  get: () => {
    // maintain backward compatibility
    if (props.value === 'none') return [];
    if (props.value === 'mine') return [EVENT_TYPES.ASSIGNED];
    if (props.value === 'all') return [...alertEventValues];

    const validValues = props.value
      .split('+')
      .filter(value => alertEventValues.includes(value));

    return [...new Set(validValues)];
  },
  set: value => {
    const sortedValues = value.filter(Boolean).sort();
    const uniqueValues = [...new Set(sortedValues)];

    if (uniqueValues.length === 0) {
      emit('update', 'none');
      return;
    }

    emit('update', uniqueValues.join('+'));
  },
});

const setValue = (isChecked, value) => {
  let updatedValue = selectedValue.value;
  if (isChecked) {
    updatedValue.push(value);
  } else {
    updatedValue = updatedValue.filter(item => item !== value);
  }

  selectedValue.value = updatedValue;
};

const alertDescription = computed(() => {
  const base =
    'PROFILE_SETTINGS.FORM.AUDIO_NOTIFICATIONS_SECTION.ALERT_COMBINATIONS.';

  if (props.value === '' || props.value === 'none') {
    return base + 'NONE';
  }

  return base + selectedValue.value.join('+').toUpperCase();
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
          class="text-sm text-ash-900 font-normal"
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
