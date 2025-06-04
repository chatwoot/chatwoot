<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import IssueHeader from './IssueHeader.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
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

const unlinkIssue = () => {
  emit('unlinkIssue', props.linkedIssue.id);
};
</script>

<template>
  <div
    class="flex flex-col items-start gap-2 px-4 py-3 border-b border-n-strong group/note"
  >
    <div class="flex flex-col w-full">
      <IssueHeader
        :identifier="linkedIssue.issue.identifier"
        :link-id="linkedIssue.id"
        :issue-url="linkedIssue.issue.url"
        @unlink-issue="unlinkIssue"
      />

      <span class="mt-2 text-sm font-medium text-n-slate-12">
        {{ linkedIssue.issue.title }}
      </span>

      <span
        v-if="linkedIssue.issue.description"
        class="mt-1 text-sm text-n-slate-11 line-clamp-3"
      >
        {{ linkedIssue.issue.description }}
      </span>
    </div>

    <div class="flex flex-row items-center h-6 gap-2">
      <div class="flex items-center gap-1.5 text-left">
        <Avatar
          :src="getAssignee(linkedIssue.issue).thumbnail"
          :username="getAssignee(linkedIssue.issue).name"
          :size="16"
        />
        <span class="my-0 truncate text-capitalize" :class="textClass">
          {{ getAssignee(linkedIssue.issue).name }}
        </span>
      </div>
      <div
        v-if="getAssignee(linkedIssue.issue)"
        class="w-px h-3 bg-n-slate-4"
      />

      <div class="flex items-center gap-1 py-1">
        <Icon
          icon="i-lucide-activity"
          class="text-n-sate-11 size-4"
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
  </div>
</template>
