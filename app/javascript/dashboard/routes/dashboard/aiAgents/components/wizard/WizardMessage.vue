<script setup>
defineProps({
  role: { type: String, required: true },
  content: { type: String, default: '' },
  isStreaming: { type: Boolean, default: false },
  error: { type: String, default: '' },
  hidden: { type: Boolean, default: false },
});

defineEmits(['retry']);
</script>

<template>
  <div
    v-if="!hidden"
    class="flex w-full gap-2.5"
    :class="role === 'user' ? 'justify-end' : 'justify-start'"
  >
    <!-- AI Avatar -->
    <div v-if="role === 'assistant'" class="flex shrink-0 items-start pt-0.5">
      <div
        class="flex items-center justify-center size-8 rounded-full bg-gradient-to-br from-n-blue-9 to-n-blue-11 shadow-sm"
      >
        <span class="i-lucide-sparkles size-4 text-white" />
      </div>
    </div>

    <!-- Message Bubble -->
    <div
      class="max-w-[78%] rounded-2xl px-4 py-3 text-sm leading-relaxed shadow-sm"
      :class="[
        role === 'user'
          ? 'bg-n-blue-9 text-white rounded-br-sm'
          : 'bg-n-solid-2 text-n-slate-12 rounded-bl-sm border border-n-weak',
        error ? 'border-n-ruby-7' : '',
      ]"
    >
      <span v-if="content" class="whitespace-pre-wrap">{{ content }}</span>

      <!-- Typing indicator (no content yet) -->
      <span
        v-if="isStreaming && !content"
        class="flex items-center gap-1.5 py-1"
      >
        <span class="size-2 rounded-full bg-n-slate-8 animate-bounce" />
        <span
          class="size-2 rounded-full bg-n-slate-8 animate-bounce [animation-delay:0.15s]"
        />
        <span
          class="size-2 rounded-full bg-n-slate-8 animate-bounce [animation-delay:0.3s]"
        />
      </span>

      <!-- Streaming cursor -->
      <span
        v-if="isStreaming && content"
        class="inline-block w-0.5 h-4 bg-n-slate-9 ml-0.5 animate-pulse align-text-bottom rounded-full"
      />

      <!-- Error display -->
      <div v-if="error" class="mt-2 flex items-center gap-1.5">
        <span class="i-lucide-alert-circle size-3.5 text-n-ruby-9" />
        <span class="text-xs text-n-ruby-9">{{ error }}</span>
      </div>
    </div>
  </div>
</template>
