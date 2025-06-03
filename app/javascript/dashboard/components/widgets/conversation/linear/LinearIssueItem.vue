<script setup>
// import { format } from 'date-fns';
import IssueHeader from './IssueHeader.vue';
import UserAvatarWithName from 'dashboard/components/widgets/UserAvatarWithName.vue';

defineProps({
  linkedIssue: {
    type: Object,
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

// const getFormattedDate = createdAt => {
//   return format(new Date(createdAt), 'hh:mm a, MMM dd');
// };

const getAssignee = issue => {
  const assigneeDetails = issue.assignee;
  if (!assigneeDetails) return null;
  const { name, avatarUrl } = assigneeDetails;
  return {
    name,
    thumbnail: avatarUrl,
  };
};

const getLabels = issue => {
  return issue.labels?.nodes || [];
};

const getPriorityLabel = priority => {
  return priorityMap[priority];
};

const unlinkIssue = linkId => {
  emit('unlinkIssue', linkId);
};
</script>

<template>
  <div
    class="flex flex-col items-start gap-2 px-4 py-3 border-b border-n-strong group/note"
  >
    <!-- Issue Header -->
    <div class="flex flex-col w-full">
      <IssueHeader
        :identifier="linkedIssue.issue.identifier"
        :link-id="linkedIssue.id"
        :issue-url="linkedIssue.issue.url"
        @unlink-issue="unlinkIssue"
      />

      <!-- Issue Title -->
      <span class="mt-2 text-sm font-medium text-n-slate-12">
        {{ linkedIssue.issue.title }}
      </span>

      <!-- Issue Description -->
      <span
        v-if="linkedIssue.issue.description"
        class="mt-1 text-sm text-n-slate-11 line-clamp-3"
      >
        {{ linkedIssue.issue.description }}
      </span>
    </div>

    <!-- Issue Metadata -->
    <div class="flex flex-row items-center h-6 gap-2">
      <!-- Assignee -->
      <UserAvatarWithName
        v-if="getAssignee(linkedIssue.issue)"
        :user="getAssignee(linkedIssue.issue)"
        class="py-1"
      />
      <div
        v-if="getAssignee(linkedIssue.issue)"
        class="w-px h-3 bg-n-slate-4"
      />

      <!-- Status -->
      <div class="flex items-center gap-1 py-1">
        <fluent-icon
          icon="status"
          size="14"
          :style="{ color: linkedIssue.issue.state?.color }"
        />
        <h6 class="text-xs text-n-slate-12">
          {{ linkedIssue.issue.state?.name }}
        </h6>
      </div>

      <!-- Priority -->
      <div
        v-if="getPriorityLabel(linkedIssue.issue.priority)"
        class="w-px h-3 bg-n-slate-4"
      />
      <div
        v-if="getPriorityLabel(linkedIssue.issue.priority)"
        class="flex items-center gap-1 py-1"
      >
        <fluent-icon
          :icon="`priority-${getPriorityLabel(linkedIssue.issue.priority).toLowerCase()}`"
          size="14"
          view-box="0 0 12 12"
        />
        <h6 class="text-xs text-n-slate-12">
          {{ getPriorityLabel(linkedIssue.issue.priority) }}
        </h6>
      </div>
    </div>

    <!-- Labels -->
    <div
      v-if="getLabels(linkedIssue.issue).length"
      class="flex flex-wrap items-center gap-1"
    >
      <woot-label
        v-for="label in getLabels(linkedIssue.issue)"
        :key="label.id"
        :title="label.name"
        :description="label.description"
        :color="label.color"
        variant="smooth"
        small
      />
    </div>

    <!-- Created Date -->
    <!-- <div class="flex items-center">
      <span class="text-xs text-n-slate-11">
        {{
          $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.CREATED_AT', {
            createdAt: getFormattedDate(linkedIssue.issue.createdAt),
          })
        }}
      </span>
    </div> -->
  </div>
</template>
