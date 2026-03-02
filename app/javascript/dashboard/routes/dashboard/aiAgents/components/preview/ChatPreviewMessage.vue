<script setup>
defineProps({
  role: { type: String, required: true },
  content: { type: String, default: '' },
  isStreaming: { type: Boolean, default: false },
  isError: { type: Boolean, default: false },
});
</script>

<template>
  <div
    class="flex w-full"
    :class="role === 'user' ? 'justify-end' : 'justify-start'"
  >
    <!-- Avatar -->
    <div v-if="role === 'assistant'" class="flex items-start gap-2 max-w-[85%]">
      <div
        class="flex items-center justify-center size-7 rounded-lg bg-n-alpha-2 shrink-0 mt-0.5"
      >
        <span class="i-lucide-bot size-3.5 text-n-slate-11" />
      </div>
      <div
        class="rounded-2xl rounded-tl-md px-4 py-2.5 text-sm leading-relaxed"
        :class="
          isError
            ? 'bg-n-ruby-3 text-n-ruby-11'
            : 'bg-n-solid-3 text-n-slate-12'
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

    <!-- User message -->
    <div v-else class="max-w-[85%]">
      <div
        class="rounded-2xl rounded-br-md px-4 py-2.5 text-sm leading-relaxed bg-n-blue-9 text-white"
      >
        <span class="whitespace-pre-wrap">{{ content }}</span>
      </div>
    </div>
  </div>
</template>
