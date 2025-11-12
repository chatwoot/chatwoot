<script setup>
import ExclusionRules from '../ExclusionRules.vue';
import { ref } from 'vue';

const mockTagsList = [
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
  {
    id: 5,
    name: 'enhancement',
    color: '#2ed573',
  },
  {
    id: 6,
    name: 'question',
    color: '#ffa502',
  },
  {
    id: 7,
    name: 'duplicate',
    color: '#747d8c',
  },
  {
    id: 8,
    name: 'wontfix',
    color: '#57606f',
  },
];

const excludedLabelsBasic = ref([]);
const excludeOlderThanHoursBasic = ref(10);
</script>

<template>
  <Story
    title="Components/AgentManagementPolicy/ExclusionRules"
    :layout="{ type: 'grid', width: '1200px' }"
  >
    <Variant title="Basic Usage">
      <div class="p-8 bg-n-background h-[600px]">
        <ExclusionRules
          v-model:excluded-labels="excludedLabelsBasic"
          v-model:exclude-older-than-minutes="excludeOlderThanHoursBasic"
          :tags-list="mockTagsList"
        />
      </div>
    </Variant>
  </Story>
</template>
