<script setup>
import DataTable from '../DataTable.vue';

const mockItems = [
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
];

const handleDelete = itemId => {
  console.log('Delete item:', itemId);
};
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/DataTable"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="With Data">
      <div class="p-8 bg-n-background">
        <DataTable
          :items="mockItems"
          :is-fetching="false"
          @delete="handleDelete"
        />
      </div>
    </Variant>

    <Variant title="Loading State">
      <div class="p-8 bg-n-background">
        <DataTable :items="[]" is-fetching @delete="handleDelete" />
      </div>
    </Variant>

    <Variant title="Empty State">
      <div class="p-8 bg-n-background">
        <DataTable
          :items="[]"
          :is-fetching="false"
          empty-state-message="No items found"
          @delete="handleDelete"
        />
      </div>
    </Variant>
  </Story>
</template>
