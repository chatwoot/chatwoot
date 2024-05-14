<template>
  <div class="flex flex-col gap-2">
    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between group">
        <a
          :href="issue.url"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-block rounded-sm mb-0 break-all py-0.5 text-primary-600"
        >
          {{ `${issue.identifier}  ${issue.title}` }}
        </a>
        <woot-button
          size="small"
          variant="clear"
          color-scheme="secondary"
          class="!px-2 hover:!bg-transparent hidden dark:hover:!bg-transparent underline group-hover:block"
          @click="unlinkIssue"
        >
          {{ $t('INTEGRATION_SETTINGS.LINEAR.UNLINK.TITLE') }}
        </woot-button>
      </div>

      <span class="text-sm font-normal text-slate-900 dark:text-slate-25">
        {{ issue.description }}
      </span>
    </div>

    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.STATUS') }}
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          {{ issue.state.name }}
        </span>
      </div>
    </div>

    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.PRIORITY') }}
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          {{ priorityLabel }}
        </span>
      </div>
    </div>
    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.ASSIGNEE') }}
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          {{ assigneeName }}
        </span>
      </div>
    </div>
    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.LABELS') }}
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          {{ labels }}
        </span>
      </div>
    </div>
    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ISSUE.CREATED_AT') }}
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          {{ formatDate(issue.createdAt) }}
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import { format } from 'date-fns';
const priorityMap = {
  0: 'Low',
  1: 'Medium',
  2: 'High',
  3: 'Urgent',
};
export default {
  props: {
    issue: {
      type: Object,
      required: true,
    },
    linkId: {
      type: String,
      required: true,
    },
  },
  computed: {
    priorityLabel() {
      return priorityMap[this.issue.priority];
    },
    assigneeName() {
      return this.issue.assignee ? this.issue.assignee.name : '---';
    },
    labels() {
      return this.issue.labels.nodes.length
        ? this.issue.labels.nodes.map(label => label.name).join(', ')
        : '---';
    },
  },
  methods: {
    unlinkIssue() {
      this.$emit('unlink-issue', this.linkId);
    },
    formatDate(timestamp) {
      return format(new Date(timestamp), 'MMM dd, hh:mm a');
    },
  },
};
</script>
