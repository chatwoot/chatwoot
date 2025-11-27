<script setup>
import AddDataDropdown from '../AddDataDropdown.vue';

const mockInboxes = [
  {
    id: 1,
    name: 'Website Support',
    email: 'support@company.com',
    icon: 'i-lucide-globe',
  },
  {
    id: 2,
    name: 'Email Support',
    email: 'help@company.com',
    icon: 'i-lucide-mail',
  },
  {
    id: 3,
    name: 'WhatsApp Business',
    phoneNumber: '+1 555-0123',
    icon: 'i-lucide-message-circle',
  },
  {
    id: 4,
    name: 'Facebook Messenger',
    email: 'messenger@company.com',
    icon: 'i-lucide-facebook',
  },
  {
    id: 5,
    name: 'Twitter DM',
    email: 'twitter@company.com',
    icon: 'i-lucide-twitter',
  },
];

const mockTags = [
  {
    id: 1,
    name: 'urgent',
    color: '#ff4757',
  },
  {
    id: 2,
    name: 'bug',
    color: '#ff6b6b',
  },
  {
    id: 3,
    name: 'feature-request',
    color: '#4834d4',
  },
  {
    id: 4,
    name: 'documentation',
    color: '#26de81',
  },
];

const handleAdd = item => {
  console.log('Add item:', item);
};
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/AddDataDropdown"
    :layout="{ type: 'grid', width: '500px' }"
  >
    <Variant title="Basic Usage - Inboxes">
      <div class="p-8 bg-n-background flex gap-4 h-[400px] items-start">
        <AddDataDropdown
          label="Add Inbox"
          search-placeholder="Search inboxes..."
          :items="mockInboxes"
          @add="handleAdd"
        />
      </div>
    </Variant>

    <Variant title="Basic Usage - Tags">
      <div class="p-8 bg-n-background flex gap-4 h-[400px] items-start">
        <AddDataDropdown
          label="Add Tag"
          search-placeholder="Search tags..."
          :items="mockTags"
          @add="handleAdd"
        />
      </div>
    </Variant>
  </Story>
</template>
