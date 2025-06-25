<script>
export default {
  name: 'AvailableAgents',
  props: {
    agents: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div class="flex space-x-2">
    <div
      v-for="agent in agents"
      :key="agent.id"
      class="w-8 h-8 rounded-full overflow-hidden border border-gray-300"
    >
      <img
        :src="agent.avatar"
        :alt="agent.name"
        class="object-cover w-full h-full"
      />
    </div>
  </div>
</template>
