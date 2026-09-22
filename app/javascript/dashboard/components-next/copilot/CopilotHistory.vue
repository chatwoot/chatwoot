<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  threads: { type: Array, default: () => [] },
  selectedId: { type: Number, default: null },
  loading: { type: Boolean, default: false },
  error: { type: Boolean, default: false },
  hasMore: { type: Boolean, default: false },
});
defineEmits(['select', 'loadMore', 'retry']);
</script>

<template>
  <div class="flex-1 min-h-0 overflow-y-auto px-3 py-3">
    <h3 class="text-xs font-medium text-n-slate-11 px-2 mb-2">
      {{ $t('CAPTAIN.COPILOT.HISTORY') }}
    </h3>
    <ul class="list-none p-0 m-0 space-y-1">
      <li v-for="thread in threads" :key="thread.id">
        <button
          class="w-full text-start rounded-lg px-3 py-2 hover:bg-n-alpha-2 focus-visible:ring-2 focus-visible:ring-n-blue-9"
          :class="{ 'bg-n-alpha-2': selectedId === thread.id }"
          :aria-current="selectedId === thread.id ? 'true' : undefined"
          @click="$emit('select', thread)"
        >
          <span class="line-clamp-2 text-sm text-n-slate-12 break-words">
            {{ thread.title }}
          </span>
          <span class="block mt-1 text-xs text-n-slate-10">
            {{ new Date(thread.created_at * 1000).toLocaleDateString() }}
          </span>
        </button>
      </li>
    </ul>
    <p v-if="loading" role="status" class="px-2 py-3 text-n-slate-11">
      {{ $t('CAPTAIN.COPILOT.HISTORY_LOADING') }}
    </p>
    <div v-else-if="error" role="alert" class="px-2 py-3 space-y-2">
      <p class="text-n-slate-11">{{ $t('CAPTAIN.COPILOT.HISTORY_ERROR') }}</p>
      <Button
        :label="$t('CAPTAIN.COPILOT.RETRY')"
        sm
        slate
        outline
        @click="$emit('retry')"
      />
    </div>
    <p v-else-if="!threads.length" class="px-2 py-3 text-n-slate-11">
      {{ $t('CAPTAIN.COPILOT.HISTORY_EMPTY') }}
    </p>
    <Button
      v-else-if="hasMore"
      :label="$t('CAPTAIN.COPILOT.LOAD_MORE')"
      class="mt-3 w-full"
      sm
      slate
      ghost
      @click="$emit('loadMore')"
    />
  </div>
</template>
