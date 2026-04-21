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

<template>
  <div>
    <label class="flex justify-between pb-1 text-heading-3 text-n-slate-12">
      {{ label }}
    </label>
    <div class="flex flex-col gap-3 mt-2">
      <div
        v-for="item in items"
        :key="item.id"
        class="flex flex-row items-start gap-2"
      >
        <CheckBox
          :id="`checkbox-condition-${item.value}`"
          :is-checked="item.model"
          :value="item.value"
          @update="onChange"
        />
        <label
          class="text-body-main text-n-slate-12"
          :for="`checkbox-condition-${item.value}`"
        >
          {{ item.label }}
        </label>
      </div>
    </div>
  </div>
</template>
