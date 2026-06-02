<script setup>
import AssignmentPolicyCard from './AssignmentPolicyCard.vue';

const mockInboxes = [
  {
    id: 1,
    name: 'Website Support',
    channel_type: 'Channel::WebWidget',
    inbox_type: 'Website',
  },
  {
    id: 2,
    name: 'Email Support',
    channel_type: 'Channel::Email',
    inbox_type: 'Email',
  },
  {
    id: 3,
    name: 'WhatsApp Business',
    channel_type: 'Channel::Whatsapp',
    inbox_type: 'WhatsApp',
  },
  {
    id: 4,
    name: 'Facebook Messenger',
    channel_type: 'Channel::FacebookPage',
    inbox_type: 'Messenger',
  },
];

const withCount = policy => ({
  ...policy,
  assignedInboxCount: policy.inboxes.length,
});

const policyA = withCount({
  id: 1,
  name: 'Website & Email',
  description: 'Distributes conversations evenly among available agents',
  assignmentOrder: 'round_robin',
  conversationPriority: 'high',
  inboxes: [mockInboxes[0], mockInboxes[1]],
  isFetchingInboxes: false,
});

const policyB = withCount({
  id: 2,
  name: 'WhatsApp & Messenger',
  description: 'Assigns based on capacity and workload',
  assignmentOrder: 'capacity_based',
  conversationPriority: 'medium',
  inboxes: [mockInboxes[2], mockInboxes[3]],
  isFetchingInboxes: false,
});

const emptyPolicy = withCount({
  id: 3,
  name: 'No Inboxes Yet',
  description: 'Policy with no assigned inboxes',
  assignmentOrder: 'manual',
  conversationPriority: 'low',
  inboxes: [],
  isFetchingInboxes: false,
});

const onEdit = id => console.log('Edit policy:', id);
const onDelete = id => console.log('Delete policy:', id);
const onFetch = () => console.log('Fetch inboxes');
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/AssignmentPolicyCard"
    :layout="{ type: 'grid', width: '1200px' }"
  >
    <Variant title="Three Cards (Two with inboxes, One empty)">
      <div class="p-4 bg-n-background">
        <div class="grid grid-cols-1 gap-4">
          <AssignmentPolicyCard
            v-bind="policyA"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-inboxes="onFetch"
          />
          <AssignmentPolicyCard
            v-bind="policyB"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-inboxes="onFetch"
          />
          <AssignmentPolicyCard
            v-bind="emptyPolicy"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-inboxes="onFetch"
          />
        </div>
      </div>
    </Variant>
  </Story>
</template>
