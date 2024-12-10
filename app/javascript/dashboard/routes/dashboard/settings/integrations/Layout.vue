<template>
  <div class="flex flex-col flex-1 gap-8 overflow-auto">
    <slot name="header" />
    <div class="w-full overflow-x-auto text-slate-700 dark:text-slate-200">
      <slot />
    </div>
    <slot name="footer" />
  </div>
</template>
