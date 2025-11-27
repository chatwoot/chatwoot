<script setup>
import { ref } from 'vue';
import RadioCard from '../RadioCard.vue';

const selectedOption = ref('round_robin');

const handleSelect = value => {
  selectedOption.value = value;
  console.log('Selected:', value);
};
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/RadioCard"
    :layout="{ type: 'grid', width: '600px' }"
  >
    <Variant title="Basic Usage">
      <div class="p-8 bg-n-background space-y-4">
        <RadioCard
          id="round_robin"
          label="Round Robin"
          description="Distributes conversations evenly among all available agents in a rotating manner"
          :is-active="selectedOption === 'round_robin'"
          @select="handleSelect"
        />
        <RadioCard
          id="balanced"
          label="Balanced Assignment"
          description="Assigns conversations based on agent workload to maintain balance"
          :is-active="selectedOption === 'balanced'"
          @select="handleSelect"
        />
      </div>
    </Variant>

    <Variant title="Active State">
      <div class="p-8 bg-n-background">
        <RadioCard
          id="active_option"
          label="Active Option"
          description="This option is currently selected and active"
          is-active
          @select="handleSelect"
        />
      </div>
    </Variant>

    <Variant title="Inactive State">
      <div class="p-8 bg-n-background">
        <RadioCard
          id="inactive_option"
          label="Inactive Option"
          description="This option is not selected and can be clicked to activate"
          is-active
          @select="handleSelect"
        />
      </div>
    </Variant>
  </Story>
</template>
