<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

defineProps({
  content: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <Banner color="amber">
    <div class="flex items-center gap-2">
      <div class="flex">
        <FluentIcon icon="info" size="16" />
      </div>
      {{ content }}
    </div>
  </Banner>
</template>
