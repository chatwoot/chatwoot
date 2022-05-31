<template>
  <div class="dashboard-app--frame--container">
    <div
      v-for="(configItem, index) in config"
      :key="index"
      class="dashboard-app--frame"
    >
      <iframe v-if="configItem.type === 'frame'" :src="configItem.url" />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    config: {
      type: Array,
      default: () => [],
    },
  },
};
</script>

<style scoped>
.dashboard-app--frame--container,
.dashboard-app--frame,
.dashboard-app--frame iframe {
  height: 100%;
  width: 100%;
}

.dashboard-app--frame iframe {
  border: 0;
}
</style>
