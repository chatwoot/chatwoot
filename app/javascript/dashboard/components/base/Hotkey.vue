<template>
  <kbd class="hotkey">
    <slot />
  </kbd>
</template>

<style lang="scss">
kbd.hotkey {
  @apply inline-flex p-0.5 leading-[0.625rem] min-w-[1rem] tracking-wide uppercase text-slate-800 dark:text-slate-100 bg-slate-50 dark:bg-slate-600 text-xxs border border-solid border-slate-75 dark:border-slate-600 rounded flex-shrink-0 items-center select-none justify-center;
}
</style>
