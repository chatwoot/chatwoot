<template>
  <div class="flex flex-col gap-2">
    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between group">
        <!-- <woot-button
          size="tiny"
          variant="link"
          color-scheme="secondary"
          icon="delete"
          @click="deleteIssue(issue)"
        /> -->
        <a
          :href="issue.link"
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
          @click="deleteIssue(issue)"
        >
          Unlink
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
        Status
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          Todo
        </span>
      </div>
    </div>

    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        Priority
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          {{ issue.priorityLabel }}
        </span>
      </div>
    </div>
    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        Assignee
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          Muhsin
        </span>
      </div>
    </div>
    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        Labels
      </span>
      <div class="flex flex-col w-full gap-2">
        <span
          class="text-sm font-normal text-left text-slate-900 dark:text-slate-25 tabular-nums"
        >
          ---
        </span>
      </div>
    </div>
    <div class="flex justify-between w-full">
      <span
        class="text-sm sticky top-0 h-fit font-normal tracking-[-0.6%] min-w-[140px] truncate text-slate-600 dark:text-slate-200"
      >
        Created At
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
export default {
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  methods: {
    deleteIssue(issue) {
      this.$emit('delete', issue);
    },
    formatDate(timestamp) {
      return format(timestamp, 'MMM dd, hh:mm a');
    },
  },
};
</script>
