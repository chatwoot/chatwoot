<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
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
  <BaseCell class="flex gap-2 items-center text-slate-300 dark:text-slate-400">
    <template v-if="filteredProfiles.length">
      <a
        v-for="profile in filteredProfiles"
        :key="profile"
        :href="`https://${profile}.com/${profiles[profile]}`"
        target="_blank"
        class="hover:text-slate-500"
        rel="noopener noreferrer nofollow"
      >
        <FluentIcon class="size-4" :icon="`brand-${profile}`" />
      </a>
    </template>
  </BaseCell>
</template>
