<script>
// Copilot Loader Component
</script>

<template>
  <div class="flex justify-start">
    <div class="flex items-center space-x-2">
      <span class="text-n-iris-11 font-medium">
        {{ $t('CAPTAIN.COPILOT.LOADER') }}
      </span>
      <div class="flex space-x-1">
        <div
          class="w-2 h-2 rounded-full bg-n-iris-9 animate-bounce [animation-delay:-0.3s]"
        />
        <div
          class="w-2 h-2 rounded-full bg-n-iris-9 animate-bounce [animation-delay:-0.15s]"
        />
        <div class="w-2 h-2 rounded-full bg-n-iris-9 animate-bounce" />
      </div>
    </div>
  </div>
</template>
