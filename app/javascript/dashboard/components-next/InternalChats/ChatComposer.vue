<script setup>
import { computed, nextTick, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  isSending: { type: Boolean, default: false },
  placeholder: { type: String, default: '' },
  autofocus: { type: Boolean, default: false },
  maxLength: { type: Number, default: 10000 },
  maxRows: { type: Number, default: 6 },
});

const emit = defineEmits(['update:modelValue', 'send']);

const { t } = useI18n();
const textareaRef = ref(null);
const dragRejectTimer = ref(null);
const showDragReject = ref(false);

const draft = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});

const canSend = computed(() => Boolean(draft.value.trim()) && !props.isSending);

const showCounter = computed(() => draft.value.length > props.maxLength * 0.8);
const isOverLimit = computed(() => draft.value.length > props.maxLength * 0.95);

const resize = () => {
  const el = textareaRef.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = `${Math.min(el.scrollHeight, props.maxRows * 22)}px`;
};

const focus = async () => {
  await nextTick();
  textareaRef.value?.focus();
};

const onKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    if (canSend.value) emit('send');
  }
};

const flashDragReject = () => {
  showDragReject.value = true;
  if (dragRejectTimer.value) clearTimeout(dragRejectTimer.value);
  dragRejectTimer.value = setTimeout(() => {
    showDragReject.value = false;
  }, 3000);
};

const onDragOver = event => {
  if (event.dataTransfer?.types?.includes('Files')) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'none';
  }
};

const onDrop = event => {
  if (event.dataTransfer?.files?.length) {
    event.preventDefault();
    flashDragReject();
  }
};

const onPaste = event => {
  const items = Array.from(event.clipboardData?.items || []);
  if (items.some(item => item.kind === 'file')) {
    event.preventDefault();
    flashDragReject();
  }
};

watch(
  () => props.modelValue,
  () => nextTick(resize)
);

watch(
  () => props.autofocus,
  value => {
    if (value) focus();
  },
  { immediate: true }
);

onUnmounted(() => {
  if (dragRejectTimer.value) clearTimeout(dragRejectTimer.value);
});

defineExpose({ focus });
</script>

<template>
  <div class="mx-2 mb-2 rounded-xl border border-n-weak bg-n-solid-1">
    <div class="relative -mt-px px-2.5 py-0">
      <textarea
        ref="textareaRef"
        v-model="draft"
        rows="1"
        class="max-h-36 w-full resize-none border-0 bg-transparent px-0 py-2.5 text-sm leading-5 text-n-slate-12 outline-none placeholder:text-n-slate-10 disabled:opacity-60"
        :placeholder="placeholder"
        :disabled="isSending"
        :maxlength="maxLength"
        :aria-label="placeholder"
        @keydown="onKeydown"
        @input="resize"
        @dragover="onDragOver"
        @drop="onDrop"
        @paste="onPaste"
      />
    </div>

    <div
      v-if="showDragReject"
      class="flex items-center gap-1.5 border-t border-n-weak bg-n-amber-3 px-3 py-1.5 text-xs text-n-amber-12"
      role="status"
      aria-live="polite"
    >
      <span class="i-lucide-info size-3.5 shrink-0" />
      {{ t('INTERNAL_CHATS.DRAG_REJECT_MESSAGE') }}
    </div>

    <div class="flex items-center justify-between gap-2 px-2 pb-2">
      <div class="flex-1">
        <span
          v-if="showCounter"
          class="px-1 text-xs tabular-nums"
          :class="isOverLimit ? 'text-n-ruby-11' : 'text-n-amber-11'"
        >
          {{
            t('INTERNAL_CHATS.CHAR_COUNT', {
              count: draft.length,
              max: maxLength,
            })
          }}
        </span>
      </div>

      <Button
        icon="i-lucide-send-horizontal"
        size="sm"
        color="blue"
        variant="solid"
        class="shrink-0"
        :is-loading="isSending"
        :disabled="!canSend"
        :title="t('INTERNAL_CHATS.SEND_TOOLTIP')"
        :aria-label="t('INTERNAL_CHATS.SEND')"
        @click="emit('send')"
      />
    </div>
  </div>
</template>
