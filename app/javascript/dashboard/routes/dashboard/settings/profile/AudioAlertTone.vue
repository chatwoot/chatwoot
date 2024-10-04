<script setup>
import { computed } from 'vue';
import FormSelect from 'v3/components/Form/Select.vue';

const props = defineProps({
  value: {
    type: String,
    required: true,
    validator: value => ['ding', 'bell'].includes(value),
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
]);

const selectedValue = computed({
  get: () => props.value,
  set: value => {
    emit('change', value);
  },
});
</script>

<template>
  <FormSelect
    v-model="selectedValue"
    name="alertTone"
    spacing="compact"
    :value="selectedValue"
    :options="alertTones"
    :label="label"
    class="max-w-xl"
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
</template>
