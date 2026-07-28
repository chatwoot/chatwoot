<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useConfigStore } from 'widget-v2/stores/config';
import { useAvailability } from 'widget-v2/composables/useAvailability';

const emit = defineEmits(['submit']);

const configStore = useConfigStore();
const { isOnline } = useAvailability();

const content = ref('');
const textareaRef = ref(null);
const section = ref(null);

// Who answers by default is a question the widget can already answer: the AI
// replies instantly when nobody is on shift, a teammate is better when one is.
// Visitors can still switch, and their choice sticks.
const defaultSection = computed(() => {
  if (!configStore.hasAiAgent) return 'human';
  return isOnline.value ? 'human' : 'ai';
});

const activeSection = computed(() => section.value || defaultSection.value);

const MAX_HEIGHT = 112;

const resize = () => {
  const el = textareaRef.value;
  if (!el) return;
  el.style.height = 'auto';
  el.style.height = `${Math.min(el.scrollHeight, MAX_HEIGHT)}px`;
};

// Opening a keyboard the moment Home loads hides most of the screen on a
// phone, so only a pointer device gets the caret for free.
onMounted(() => {
  if (window.matchMedia('(pointer: fine)').matches) textareaRef.value?.focus();
});

watch(content, resize);

const submit = () => {
  const trimmed = content.value.trim();
  if (!trimmed) return;
  emit('submit', { content: trimmed, section: activeSection.value });
  content.value = '';
};

const onKeydown = event => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    submit();
  }
};
</script>

<template>
  <section class="surface-card overflow-hidden">
    <textarea
      ref="textareaRef"
      v-model="content"
      rows="2"
      :placeholder="$t('HOME.ASK_PLACEHOLDER')"
      class="block w-full px-4 pt-3.5 pb-1 text-base leading-6 bg-transparent text-cw-text placeholder:text-cw-text-faint resize-none outline-none border-none"
      @keydown="onKeydown"
    />

    <div class="flex items-center gap-2 px-3 pb-3">
      <div
        v-if="configStore.hasAiAgent"
        class="flex items-center gap-0.5 p-0.5 rounded-full bg-cw-muted"
        role="radiogroup"
        :aria-label="$t('HOME.WHO_ANSWERS')"
      >
        <button
          v-for="option in ['ai', 'human']"
          :key="option"
          type="button"
          role="radio"
          :aria-checked="activeSection === option"
          class="flex items-center gap-1 h-7 px-2.5 text-xs font-520 rounded-full transition-colors outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          :class="
            activeSection === option
              ? 'bg-cw-solid text-cw-text shadow-sm'
              : 'text-cw-text-muted hover:text-cw-text'
          "
          @click="section = option"
        >
          <span
            :class="option === 'ai' ? 'i-ph-sparkle-fill' : 'i-ph-users-three'"
          />
          {{ option === 'ai' ? $t('HOME.ANSWER_AI') : $t('HOME.ANSWER_TEAM') }}
        </button>
      </div>

      <button
        type="button"
        class="flex items-center justify-center w-8 h-8 ml-auto shrink-0 rounded-full transition-colors outline-none focus-visible:ring-[3px] focus-visible:ring-cw-ring"
        :class="
          content.trim()
            ? 'bg-cw-primary text-cw-primary-foreground hover:bg-cw-primary-strong'
            : 'bg-cw-muted text-cw-text-faint'
        "
        :disabled="!content.trim()"
        :aria-label="$t('CONVERSATION.SEND')"
        @click="submit"
      >
        <span class="i-ph-arrow-up text-lg" />
      </button>
    </div>
  </section>
</template>
