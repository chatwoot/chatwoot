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

const labelOptions = [
  'billing',
  'bug',
  'churn-risk',
  'documentation',
  'enterprise',
  'feature-request',
  'follow-up',
  'onboarding',
  'refund',
  'security',
  'spam',
  'vip',
].map(id => ({ id, name: id }));

const selected = ref([]);
const selectedLabels = ref([]);
</script>

<template>
  <Story
    title="Components/Filters/Multiselect Input"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Short List">
      <div class="min-h-[400px]">
        <MultiSelect v-model="selected" :options="options" />
      </div>
    </Variant>
    <Variant title="Long List (with search)">
      <div class="min-h-[400px]">
        <MultiSelect v-model="selectedLabels" :options="labelOptions" />
      </div>
    </Variant>
  </Story>
</template>
