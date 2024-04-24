<template>
  <form-select
    v-model="localAlertTone"
    name="alertTone"
    spacing="compact"
    :value="localAlertTone"
    :options="alertTones"
    :label="label"
    class="max-w-xl"
    @input="onChange"
  >
    <option
      v-for="tone in alertTones"
      :key="tone.label"
      :value="tone.value"
      :selected="tone.value === alertTone"
    >
      {{ tone.label }}
    </option>
  </form-select>
</template>
<script setup>
import { computed, ref } from 'vue';
import FormSelect from 'v3/components/Form/Select.vue';

const props = defineProps({
  alertTone: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
});

const localAlertTone = ref(props.alertTone);
const emit = defineEmits(['change']);
const onChange = () => {
  emit('change', localAlertTone.value);
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
