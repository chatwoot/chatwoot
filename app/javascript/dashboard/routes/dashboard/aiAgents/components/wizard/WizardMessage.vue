<script setup>
defineProps({
  role: { type: String, required: true },
  content: { type: String, default: '' },
  isStreaming: { type: Boolean, default: false },
});
</script>

<template>
  <div
    class="flex w-full"
    :class="role === 'user' ? 'justify-end' : 'justify-start'"
  >
    <div
      class="max-w-[85%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed"
      :class="
        role === 'user'
          ? 'bg-n-blue-9 text-white rounded-br-md'
          : 'bg-n-solid-3 text-n-slate-12 rounded-bl-md'
      "
    >
      <span v-if="content" class="whitespace-pre-wrap">{{ content }}</span>
      <span v-if="isStreaming && !content" class="flex items-center gap-1">
        <span class="size-1.5 rounded-full bg-n-slate-9 animate-bounce" />
        <span
          class="size-1.5 rounded-full bg-n-slate-9 animate-bounce [animation-delay:0.15s]"
        />
        <span
          class="size-1.5 rounded-full bg-n-slate-9 animate-bounce [animation-delay:0.3s]"
        />
      </span>
      <span
        v-if="isStreaming && content"
        class="inline-block w-1 h-4 bg-n-slate-9 ml-0.5 animate-pulse align-text-bottom"
      />
    </div>
  </div>
</template>
