<template>
  <form-select
    v-model="selectedValue"
    name="alertTone"
    spacing="compact"
    :value="selectedValue"
    :options="alertTones"
    :label="label"
    class="max-w-xl"
    @input="onChange"
  >
    <option
      v-for="tone in alertTones"
      :key="tone.label"
      :value="tone.value"
      :selected="tone.value === selectedValue"
    >
      {{ tone.label }}
    </option>
  </form-select>
</template>
<script setup>
import { computed, ref, watch } from 'vue';
import FormSelect from 'v3/components/Form/Select.vue';

const props = defineProps({
  value: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
});

const selectedValue = ref(props.value);

watch(
  () => props.value,
  newValue => {
    selectedValue.value = newValue;
  }
);

const emit = defineEmits(['change']);
const onChange = () => {
  emit('change', selectedValue.value);
};
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
</script>
