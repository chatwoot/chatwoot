<template>
  <div>
    <label
      class="flex justify-between pb-1 text-sm font-medium leading-6 text-ash-900"
    >
      {{ label }}
    </label>
    <div class="flex flex-col gap-4">
      <div
        v-for="item in items"
        :key="item.id"
        class="flex flex-row items-start gap-2"
      >
        <CheckBox
          :is-checked="item.model"
          :value="item.value"
          @update="onChange"
        />
        <label class="text-sm font-normal text-ash-900">
          {{ item.label }}
        </label>
      </div>
    </div>
  </div>
</template>
<script setup>
import CheckBox from 'v3/components/Form/CheckBox.vue';
defineProps({
  label: {
    type: String,
    required: true,
  },
  items: {
    type: Array,
    required: true,
  },
});
const emit = defineEmits(['change']);
const onChange = (id, value) => {
  emit('change', id, value);
};
</script>
