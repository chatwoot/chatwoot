<script setup>
import TypingIndicator from './assets/typing.gif';
</script>

<template>
  <div class="w-full mb-4 flex items-center justify-start">
    <div
      class="px-2 py-2 bg-white max-w-4xl text-slate-700 leading-6 text-sm rounded-md inline-block border border-slate-100"
    >
      <img :src="TypingIndicator" alt="TypingIndicator" class="h-4" />
    </div>
  </div>
</template>
