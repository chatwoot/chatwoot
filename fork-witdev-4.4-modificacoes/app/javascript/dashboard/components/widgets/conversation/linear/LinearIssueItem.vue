<script setup>
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import IssueHeader from './IssueHeader.vue';

const props = defineProps({
  linkedIssue: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['unlinkIssue']);

const { linkedIssue } = props;

const priorityMap = {
  1: 'Urgent',
  2: 'High',
  3: 'Medium',
  4: 'Low',
};

const issue = computed(() => linkedIssue.issue);

const assignee = computed(() => {
  const assigneeDetails = issue.value.assignee;
  if (!assigneeDetails) return null;
  return {
    name: assigneeDetails.name,
    thumbnail: assigneeDetails.avatarUrl,
  };
});

const labels = computed(() => issue.value.labels?.nodes || []);

const priorityLabel = computed(() => priorityMap[issue.value.priority]);

const unlinkIssue = () => {
  emit('unlinkIssue', linkedIssue.id, linkedIssue.issue.identifier);
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex flex-col w-full">
      <IssueHeader
        :identifier="issue.identifier"
        :link-id="linkedIssue.id"
        :issue-url="issue.url"
        @unlink-issue="unlinkIssue"
      />

      <h3 class="mt-2 text-sm font-medium text-n-slate-12">
        {{ issue.title }}
      </h3>

      <p
        v-if="issue.description"
        class="mt-1 text-sm text-n-slate-11 line-clamp-3"
      >
        {{ issue.description }}
      </p>
    </div>

    <div class="flex flex-col gap-2">
      <div class="flex items-center gap-2">
        <div v-if="assignee" class="flex items-center gap-1.5">
          <Avatar :src="assignee.thumbnail" :name="assignee.name" :size="16" />
          <span class="text-xs capitalize truncate text-n-slate-12">
            {{ assignee.name }}
          </span>
        </div>

        <div v-if="assignee" class="w-px h-3 bg-n-slate-4" />

        <div class="flex items-center gap-1">
          <Icon
            icon="i-lucide-activity"
            class="size-4"
            :style="{ color: issue.state?.color }"
          />
          <span class="text-xs text-n-slate-12">
            {{ issue.state?.name }}
          </span>
        </div>

        <div v-if="priorityLabel" class="w-px h-3 bg-n-slate-4" />

        <div v-if="priorityLabel" class="flex items-center gap-1.5">
          <CardPriorityIcon :priority="priorityLabel.toLowerCase()" />
          <span class="text-xs text-n-slate-12">
            {{ priorityLabel }}
          </span>
        </div>
      </div>

      <div v-if="labels.length" class="flex flex-wrap">
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
    </div>
  </div>
</template>
