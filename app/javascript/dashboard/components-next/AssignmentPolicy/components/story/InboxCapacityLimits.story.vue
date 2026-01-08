<script setup>
import InboxCapacityLimits from '../InboxCapacityLimits.vue';
import { ref } from 'vue';

const mockInboxList = [
  {
    value: 1,
    label: 'Website Support',
    icon: 'i-lucide-globe',
  },
  {
    value: 2,
    label: 'Email Support',
    icon: 'i-lucide-mail',
  },
  {
    value: 3,
    label: 'WhatsApp Business',
    icon: 'i-lucide-message-circle',
  },
  {
    value: 4,
    label: 'Facebook Messenger',
    icon: 'i-lucide-facebook',
  },
  {
    value: 5,
    label: 'Twitter DM',
    icon: 'i-lucide-twitter',
  },
  {
    value: 6,
    label: 'Telegram',
    icon: 'i-lucide-send',
  },
];

const inboxCapacityLimitsEmpty = ref([]);
const inboxCapacityLimitsNew = ref([
  { id: 1, inboxId: 1, conversationLimit: 5 },
  { inboxId: null, conversationLimit: null },
]);

const handleDelete = id => {
  console.log('Delete capacity limit:', id);
};
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/InboxCapacityLimits"
    :layout="{ type: 'grid', width: '900px' }"
  >
    <Variant title="Empty State">
      <div class="p-8 bg-n-background">
        <InboxCapacityLimits
          v-model:inbox-capacity-limits="inboxCapacityLimitsEmpty"
          :inbox-list="mockInboxList"
          :is-fetching="false"
          :is-updating="false"
          @delete="handleDelete"
        />
      </div>
    </Variant>

    <Variant title="Loading State">
      <div class="p-8 bg-n-background">
        <InboxCapacityLimits
          v-model:inbox-capacity-limits="inboxCapacityLimitsEmpty"
          :inbox-list="mockInboxList"
          is-fetching
          :is-updating="false"
          @delete="handleDelete"
        />
      </div>
    </Variant>

    <Variant title="With New Row and existing data">
      <div class="p-8 bg-n-background">
        <InboxCapacityLimits
          v-model:inbox-capacity-limits="inboxCapacityLimitsNew"
          :inbox-list="mockInboxList"
          :is-fetching="false"
          :is-updating="false"
          @delete="handleDelete"
        />
      </div>
    </Variant>

    <Variant title="Interactive Demo">
      <div class="p-8 bg-n-background">
        <InboxCapacityLimits
          v-model:inbox-capacity-limits="inboxCapacityLimitsEmpty"
          :inbox-list="mockInboxList"
          :is-fetching="false"
          :is-updating="false"
          @delete="handleDelete"
        />
        <div class="mt-4 p-4 bg-n-alpha-2 rounded-lg">
          <h4 class="text-sm font-medium mb-2">Current Limits:</h4>
          <pre class="text-xs">{{
            JSON.stringify(inboxCapacityLimitsEmpty, null, 2)
          }}</pre>
        </div>
      </div>
    </Variant>
  </Story>
</template>
