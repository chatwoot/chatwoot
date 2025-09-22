<script setup>
import { ref } from 'vue';
import SingleSelect from './SingleSelect.vue';

const options = [
  { name: 'Open', id: 'open' },
  { name: 'Closed', id: 'closed' },
  { name: 'Pending', id: 'pending' },
  { name: 'Resolved', id: 'resolved' },
  { name: 'Spam', id: 'spam' },
  { name: 'All', id: 'all' },
];

const selected = ref(options[0]);
</script>

<template>
  <Story
    title="Components/Filters/Single Select Input"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="With Search">
      <div class="min-h-[400px]">
        <SingleSelect v-model="selected" :options="options" />
      </div>
    </Variant>
    <Variant title="Without Search">
      <div class="min-h-[400px]">
        <SingleSelect v-model="selected" disable-search :options="options" />
      </div>
    </Variant>
  </Story>
</template>
