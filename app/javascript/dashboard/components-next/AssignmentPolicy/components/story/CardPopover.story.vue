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

const mockUsers = [
  {
    id: 1,
    name: 'John Smith',
    email: 'john.smith@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  },
  {
    id: 2,
    name: 'Sarah Johnson',
    email: 'sarah.johnson@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=2',
  },
  {
    id: 3,
    name: 'Mike Chen',
    email: 'mike.chen@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
  },
  {
    id: 4,
    name: 'Emily Davis',
    email: 'emily.davis@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=4',
  },
  {
    id: 5,
    name: 'Alex Rodriguez',
    email: 'alex.rodriguez@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
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
    <Variant title="Basic Usage">
      <div class="p-8 bg-n-background flex gap-4 h-96 items-start">
        <CardPopover
          :count="3"
          title="Added Agents"
          icon="i-lucide-users-round"
          :items="mockUsers.slice(0, 3)"
          @fetch="() => console.log('Fetch triggered')"
        />
      </div>
    </Variant>
  </Story>
</template>
