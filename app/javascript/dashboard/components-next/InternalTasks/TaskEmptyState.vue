<template>
  <div
    class="flex flex-col items-center justify-center flex-1 min-w-0 h-full bg-n-surface-1 text-center px-6"
  >
    <span
      class="size-16 rounded-2xl bg-n-alpha-2 flex items-center justify-center text-n-slate-11 i-lucide-clipboard-list text-3xl mb-4"
    />
    <h2 class="text-lg font-semibold text-n-slate-12">
      {{ $t('INTERNAL_TASKS.INBOX.SELECT_TASK_TITLE') }}
    </h2>
    <p class="mt-2 text-sm text-n-slate-11 max-w-sm">
      {{ $t('INTERNAL_TASKS.INBOX.SELECT_TASK') }}
    </p>
  </div>
</template>
