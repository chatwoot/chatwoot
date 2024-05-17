<script setup>
import { format } from 'date-fns';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import { computed } from 'vue';
const priorityMap = {
  0: 'Low',
  1: 'Medium',
  2: 'High',
  3: 'Urgent',
};
const props = defineProps({
  issue: {
    type: Object,
    required: true,
  },
});

const formattedDate = computed(() => {
  return format(new Date(props.issue.createdAt), 'hh:mm a, MMM dd');
});

const assignee = computed(() => {
  if (!props.issue.assignee) {
    return null;
  }
  return {
    name: props.issue.assignee.name,
    thumbnail: props.issue.assignee.avatarUrl,
  };
});

const labels = computed(() => {
  if (props.issue.labels.nodes.length) {
    return props.issue.labels.nodes;
  }
  return [];
});
const priorityLabel = computed(() => {
  return priorityMap[props.issue.priority];
});
</script>
<template>
  <div
    class="absolute flex flex-col items-start bg-[#fdfdfd] dark:bg-slate-800 z-50 p-4 border border-solid border-slate-75 dark:border-slate-700 w-[384px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <div class="flex flex-col items-start gap-2">
      <div
        class="flex items-center justify-center gap-1 px-2 py-1 font-medium border rounded-lg border-ash-200"
      >
        <fluent-icon
          icon="linear"
          size="19"
          class="text-[#5E6AD2]"
          view-box="0 0 19 19"
        />
        <span class="text-xs font-medium text-ash-900">
          {{ issue.identifier }}
        </span>
      </div>
      <span class="text-sm font-medium text-ash-900">
        {{ issue.title }}
      </span>
      <span class="text-sm text-ash-800">
        {{
          issue.description.length > 130
            ? issue.description.slice(0, 130) + '...'
            : issue.description
        }}
      </span>
    </div>
    <div class="flex flex-row gap-2 divide-x divide-ash-200">
      <user-avatar-with-name v-if="assignee" :user="assignee" />
      <div class="flex items-center gap-1 px-2">
        <fluent-icon icon="status" size="14" />
        <h6 class="my-0 text-xs text-slate-600">{{ issue.state.name }}</h6>
      </div>
      <div class="flex items-center gap-1 px-2">
        <fluent-icon icon="priority-high" size="14" view-box="0 0 14 14" />
        <h6 class="my-0 text-xs text-slate-600">{{ priorityLabel }}</h6>
      </div>
    </div>
    <div v-if="labels.length" class="flex items-center gap-1">
      <woot-label
        v-for="label in labels"
        :key="label.id"
        :title="label.name"
        :description="label.description"
        :color="label.color"
        variant="smooth"
        small
      />
    </div>

    <div class="flex items-center">
      <span class="text-xs text-ash-800">
        {{ `Created at ${formattedDate}` }}
      </span>
    </div>
  </div>
</template>
