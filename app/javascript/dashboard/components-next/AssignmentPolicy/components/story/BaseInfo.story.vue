<script setup>
import { ref } from 'vue';
import BaseInfo from '../BaseInfo.vue';

const policyName = ref('Round Robin Policy');
const description = ref(
  'Distributes conversations evenly among available agents'
);
const enabled = ref(true);
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/BaseInfo"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Basic Usage">
      <div class="p-8 bg-n-background">
        <BaseInfo
          v-model:policy-name="policyName"
          v-model:description="description"
          v-model:enabled="enabled"
          name-label="Policy Name"
          name-placeholder="Enter policy name"
          description-label="Description"
          description-placeholder="Enter policy description"
          status-label="Status"
          status-placeholder="Active"
        />
      </div>
    </Variant>
  </Story>
</template>
