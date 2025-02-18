<script setup>
import { format } from 'date-fns';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';
import IssueHeader from './IssueHeader.vue';
import { computed } from 'vue';

const props = defineProps({
  issue: {
    type: Object,
    required: true,
  },
  linkId: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['unlinkIssue']);

const priorityMap = {
  1: 'Urgent',
  2: 'High',
  3: 'Medium',
  4: 'Low',
};

const formattedDate = computed(() => {
  const { createdAt } = props.issue;
  return format(new Date(createdAt), 'hh:mm a, MMM dd');
});

const assignee = computed(() => {
  const assigneeDetails = props.issue.assignee;

  if (!assigneeDetails) return null;
  const { name, avatarUrl } = assigneeDetails;

  return {
    name,
    thumbnail: avatarUrl,
  };
});

const labels = computed(() => {
  return props.issue.labels?.nodes || [];
});

const priorityLabel = computed(() => {
  return priorityMap[props.issue.priority];
});

const unlinkIssue = () => {
  emit('unlinkIssue', props.linkId);
};
</script>

<template>
  <div
    class="absolute flex flex-col items-start bg-white dark:bg-slate-800 z-50 px-4 py-3 border border-solid border-ash-200 w-[384px] rounded-xl gap-4 max-h-96 overflow-auto"
  >
    <div class="flex flex-col w-full">
      <IssueHeader
        :identifier="issue.identifier"
        :link-id="linkId"
        :issue-url="issue.url"
        @unlink-issue="unlinkIssue"
      />

      <span class="mt-2 text-sm font-medium text-ash-900">
        {{ issue.title }}
      </span>
      <span
        v-if="issue.description"
        class="mt-1 text-sm text-ash-800 line-clamp-3"
      >
        {{ issue.description }}
      </span>
    </div>
    <div class="flex flex-row items-center h-6 gap-2">
      <UserAvatarWithName v-if="assignee" :user="assignee" class="py-1" />
      <div v-if="assignee" class="w-px h-3 bg-ash-200" />
      <div class="flex items-center gap-1 py-1">
        <fluent-icon
          icon="status"
          size="14"
          :style="{ color: issue.state.color }"
        />
        <h6 class="text-xs text-ash-900">
          {{ issue.state.name }}
        </h6>
      </div>
      <div v-if="priorityLabel" class="w-px h-3 bg-ash-200" />
      <div v-if="priorityLabel" class="flex items-center gap-1 py-1">
        <fluent-icon
          :icon="`priority-${priorityLabel.toLowerCase()}`"
          size="14"
          view-box="0 0 12 12"
        />
        <h6 class="text-xs text-ash-900">{{ priorityLabel }}</h6>
      </div>
    </div>
    <div v-if="labels.length" class="flex flex-wrap items-center gap-1">
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
        {{
          $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.CREATED_AT', {
            createdAt: formattedDate,
          })
        }}
      </span>
    </div>
  </div>
</template>
