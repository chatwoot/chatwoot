<script setup>
import { ref } from 'vue';
import FairDistribution from '../FairDistribution.vue';

const fairDistributionLimit = ref(100);
const fairDistributionWindow = ref(3600);
const windowUnit = ref('minutes');
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/FairDistribution"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Basic Usage">
      <div class="p-8 bg-n-background">
        <FairDistribution
          v-model:fair-distribution-limit="fairDistributionLimit"
          v-model:fair-distribution-window="fairDistributionWindow"
          v-model:window-unit="windowUnit"
        />
      </div>
    </Variant>
  </Story>
</template>
