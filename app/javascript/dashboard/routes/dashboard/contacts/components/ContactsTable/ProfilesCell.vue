<script setup>
import { computed } from 'vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

const props = defineProps({
  profiles: {
    type: Object,
    required: true,
  },
});

const filteredProfiles = computed(() =>
  Object.keys(props.profiles).filter(profile => props.profiles[profile])
);
</script>

<template>
  <div class="cell--social-profiles flex gap-2 items-center">
    <template v-if="filteredProfiles.length">
      <a
        v-for="profile in filteredProfiles"
        :key="profile"
        :href="`https://${profile}.com/${profiles[profile]}`"
        target="_blank"
        rel="noopener noreferrer nofollow"
      >
        <FluentIcon class="size-4" :icon="`brand-${profile}`" />
      </a>
    </template>
    <span v-else class="text-slate-300 dark:text-slate-700"> --- </span>
  </div>
</template>
