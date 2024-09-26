<template>
  <section
    class="relative flex flex-col items-center justify-center w-full h-full min-h-screen p-4 overflow-hidden font-interDisplay"
  >
    <div
      class="relative w-full max-w-[940px] mx-auto overflow-hidden h-full max-h-[448px]"
    >
      <div
        class="w-full h-full space-y-4 overflow-y-hidden opacity-50 pointer-events-none"
      >
        <slot name="empty-state-item" />
      </div>
      <div
        class="absolute inset-x-0 bottom-0 flex flex-col items-center justify-end w-full h-full pb-9 bg-gradient-to-t from-white dark:from-slate-900 to-transparent"
      >
        <slot name="empty-state" />
      </div>
    </div>
  </section>
</template>
