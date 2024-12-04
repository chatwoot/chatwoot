<script setup>
import ConversationListHeader from '../ConversationListHeader.vue';
import { ref } from 'vue';

// Story state
const activeStatus = ref('open');
const activeOrdering = ref('last_activity_at_desc');

const filter = () => {
  console.log('filter');
};

const updateActiveStatus = newStatus => {
  activeStatus.value = newStatus;
  console.log('updateActiveStatus', newStatus);
};

const updateActiveOrdering = newOrdering => {
  activeOrdering.value = newOrdering;
  console.log('updateActiveOrdering', newOrdering);
};
</script>

<template>
  <Story title="Components/Conversation/ConversationListHeader">
    <Variant title="Default">
      <div
        class="flex justify-center items-start w-full h-[500px] bg-n-solid-1"
      >
        <ConversationListHeader
          title="Conversations"
          :active-status="activeStatus"
          :active-ordering="activeOrdering"
          class="max-w-[400px] w-full"
          @filter="filter"
          @update:active-status="updateActiveStatus"
          @update:active-ordering="updateActiveOrdering"
        />
      </div>
    </Variant>
  </Story>
</template>
