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
    <div class="grid grid-cols-2 gap-5 p-5">
      <div>
        <ConversationFilter v-model="filter" />
      </div>

      <pre class="bg-white rounded-xl border border-n-weak p-6">{{
        filter
      }}</pre>
    </div>
  </Story>
</template>
