<template>
  <div
    class="min-w-full border rounded-xl border-slate-75 dark:border-slate-800/50"
  >
    <!-- Header -->
    <div
      class="grid content-center h-12 grid-cols-12 gap-4 px-6 py-0 border-b bg-slate-25 border-slate-75 dark:border-slate-800 rounded-t-xl dark:bg-slate-900"
    >
      <div
        class="flex items-center font-medium capitalize text-xs py-2 px-0 tracking-[10%] text-slate-700 dark:text-slate-100 text-left rtl:text-right col-span-2"
      >
        POLICY BREACHED
      </div>
      <div
        class="flex items-center col-span-6 px-0 py-2 text-xs font-medium text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        CONVERSATION
      </div>
      <div
        class="flex items-center px-0 text-xs font-medium text-left capitalize col-span-2py-2 text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        AGENT
      </div>
      <div
        class="col-span-2 px-0 py-2 text-xs font-medium text-left capitalize text-slate-700 dark:text-slate-100 rtl:text-right"
      />
    </div>
    <div
      class="grid content-center h-16 grid-cols-12 gap-4 px-6 py-0 bg-white border-b border-slate-75 dark:border-slate-800/50 dark:bg-slate-900"
    >
      <div
        class="flex items-center capitalize py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 text-left rtl:text-right col-span-2"
      >
        Premium SLA
      </div>
      <div
        class="flex items-center col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        #198 with John Doe
        <card-labels :conversation-id="148" />
      </div>
      <div
        class="flex items-center col-span-2 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        Elijah
      </div>
      <div
        class="flex items-center col-span-2 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
      >
        <woot-button color-scheme="secondary" variant="link">
          View details
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';
</script>
