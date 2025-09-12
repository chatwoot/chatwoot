<script setup>
import CardPopover from '../CardPopover.vue';

const mockItems = [
  {
    id: 1,
    name: 'Website Support',
    icon: 'i-lucide-globe',
  },
  {
    id: 2,
    name: 'Email Support',
    icon: 'i-lucide-mail',
  },
  {
    id: 3,
    name: 'WhatsApp Business',
    icon: 'i-lucide-message-circle',
  },
  {
    id: 4,
    name: 'Facebook Messenger',
    icon: 'i-lucide-facebook',
  },
];
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/CardPopover"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Basic Usage">
      <div class="p-8 bg-n-background flex gap-4 h-96 items-start">
        <CardPopover
          :count="3"
          title="Added Inboxes"
          icon="i-lucide-inbox"
          :items="mockItems.slice(0, 3)"
          @fetch="() => console.log('Fetch triggered')"
        />
      </div>
    </Variant>
  </Story>
</template>
