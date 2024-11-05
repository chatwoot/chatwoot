<script setup>
import { ref } from 'vue';
import ConversationFilter from './ConversationFilter.vue';

const filter = ref([
  {
    attributeKey: 'status',
    attributeModel: 'standard',
    filterOperator: 'equalTo',
    values: [{ id: 'all', name: 'All' }],
    queryOperator: 'and',
    customAttributeType: '',
  },
  {
    attributeKey: 'priority',
    filterOperator: 'notEqualTo',
    values: 'Urgent',
    queryOperator: 'or',
    attributeModel: 'standard',
    customAttribute_type: '',
  },
]);
</script>

<template>
  <Story title="Components/ConversaitonFilter">
    <div class="w-full p-5">
      <ConversationFilter v-model="filter" />
    </div>
  </Story>
</template>
