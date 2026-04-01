<script>
// Copilot Loader Component
</script>

<template>
  <div class="flex justify-start">
    <div class="flex items-center gap-2">
      <span class="font-medium text-secondary">
        {{ $t('CAPTAIN.COPILOT.LOADER') }}
      </span>
      <div class="flex gap-1">
        <div
          class="size-2 animate-bounce rounded-full bg-secondary [animation-delay:-0.3s]"
        />
        <div
          class="size-2 animate-bounce rounded-full bg-secondary [animation-delay:-0.15s]"
        />
        <div class="size-2 animate-bounce rounded-full bg-secondary" />
      </div>
    </div>
  </div>
</template>
