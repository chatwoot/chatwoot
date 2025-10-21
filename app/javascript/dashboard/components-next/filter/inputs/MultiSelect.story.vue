<script setup>
import { ref } from 'vue';
import MultiSelect from './MultiSelect.vue';

const options = [
  { name: 'Open', id: 'open' },
  { name: 'Closed', id: 'closed' },
  { name: 'Pending', id: 'pending' },
  { name: 'Resolved', id: 'resolved' },
  { name: 'Spam', id: 'spam' },
  { name: 'All', id: 'all' },
];

const selected = ref([]);
</script>

<template>
  <Story
    title="Components/Filters/Multiselect Input"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <div class="min-h-[400px]">
      <MultiSelect v-model="selected" :options="options" />
    </div>
  </Story>
</template>
