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
    queryOperator: 'and',
    attributeModel: 'standard',
    customAttribute_type: '',
  },
  {
    attributeKey: 'email',
    filterOperator: 'isPresent',
    queryOperator: 'and',
    attributeModel: 'standard',
    customAttribute_type: '',
  },
  {
    attributeKey: 'email',
    filterOperator: 'doesNotContain',
    values: '@chatwoot.com',
    queryOperator: 'or',
    attributeModel: 'standard',
    customAttribute_type: '',
  },
]);
</script>

<template>
  <Story title="Components/ConversationFilter">
    <div class="w-full p-5">
      <ConversationFilter v-model="filter" />
    </div>

    <div class="p-5">
      <h3>Current Filters</h3>
      <pre class="p-5 h-96 overflow-scroll bg-white rounded-xl shadow mt-2">{{
        filter
      }}</pre>
    </div>
  </Story>
</template>
