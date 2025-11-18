<script setup>
import AgentCapacityPolicyCard from './AgentCapacityPolicyCard.vue';

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

const withCount = policy => ({
  ...policy,
  assignedAgentCount: policy.users.length,
});

const policyA = withCount({
  id: 1,
  name: 'High Volume Support',
  description:
    'Capacity-based policy for handling high conversation volumes with experienced agents',
  users: [mockUsers[0], mockUsers[1], mockUsers[2]],
  isFetchingUsers: false,
});

const policyB = withCount({
  id: 2,
  name: 'Specialized Team',
  description: 'Custom capacity limits for specialized support team members',
  users: [mockUsers[3], mockUsers[4]],
  isFetchingUsers: false,
});

const emptyPolicy = withCount({
  id: 3,
  name: 'New Policy',
  description: 'Recently created policy with no assigned agents yet',
  users: [],
  isFetchingUsers: false,
});

const loadingPolicy = withCount({
  id: 4,
  name: 'Loading Policy',
  description: 'Policy currently loading agent information',
  users: [],
  isFetchingUsers: true,
});

const onEdit = id => console.log('Edit policy:', id);
const onDelete = id => console.log('Delete policy:', id);
const onFetchUsers = id => console.log('Fetch users for policy:', id);
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/AgentCapacityPolicyCard"
    :layout="{ type: 'grid', width: '1200px' }"
  >
    <Variant title="Multiple Cards (Various States)">
      <div class="p-4 bg-n-background">
        <div class="grid grid-cols-1 gap-4">
          <AgentCapacityPolicyCard
            v-bind="policyA"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-users="onFetchUsers"
          />
          <AgentCapacityPolicyCard
            v-bind="policyB"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-users="onFetchUsers"
          />
          <AgentCapacityPolicyCard
            v-bind="emptyPolicy"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-users="onFetchUsers"
          />
          <AgentCapacityPolicyCard
            v-bind="loadingPolicy"
            @edit="onEdit"
            @delete="onDelete"
            @fetch-users="onFetchUsers"
          />
        </div>
      </div>
    </Variant>
  </Story>
</template>
