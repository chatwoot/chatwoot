<script setup>
import AssignmentCard from './AssignmentCard.vue';

const agentAssignments = [
  {
    id: 1,
    title: 'Assignment policy',
    description: 'Manage how conversations get assigned in inboxes.',
    features: [
      {
        icon: 'i-lucide-circle-fading-arrow-up',
        label: 'Assign by conversations evenly or by available capacity',
      },
      {
        icon: 'i-lucide-scale',
        label: 'Add fair distribution rules to avoid overloading any agent',
      },
      {
        icon: 'i-lucide-inbox',
        label: 'Add inboxes to a policy - one policy per inbox',
      },
    ],
  },
  {
    id: 2,
    title: 'Agent capacity policy',
    description: 'Manage workload for agents.',
    features: [
      {
        icon: 'i-lucide-glass-water',
        label: 'Define maximum conversations per inbox',
      },
      {
        icon: 'i-lucide-circle-minus',
        label: 'Create exceptions based on labels and time',
      },
      {
        icon: 'i-lucide-users-round',
        label: 'Add agents to a policy - one policy per agent',
      },
    ],
  },
];
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/AssignmentCard"
    :layout="{ type: 'grid', width: '1000px' }"
  >
    <Variant title="Assignment Card">
      <div class="px-4 py-4 bg-n-background flex gap-6 justify-between">
        <AssignmentCard
          v-for="(item, index) in agentAssignments"
          :key="index"
          :title="item.title"
          :description="item.description"
          :features="item.features"
        />
      </div>
    </Variant>
  </Story>
</template>
