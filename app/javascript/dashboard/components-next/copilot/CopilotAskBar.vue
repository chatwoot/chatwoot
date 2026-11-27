<script setup>
import { useRouter } from 'vue-router';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useCopilotDot } from 'dashboard/composables/useCopilotDot';
import { useCopilotPrompts } from 'dashboard/composables/useCopilotPrompts';
import Button from '../button/Button.vue';
import Icon from '../icon/Icon.vue';

const props = defineProps({
  source: {
    type: String,
    required: true,
  },
});

const question = defineModel({ type: String, default: '' });

const STAGGER_CLASSES = [
  '[animation-delay:60ms]',
  '[animation-delay:120ms]',
  '[animation-delay:180ms]',
];

const router = useRouter();
const { openCopilot } = useCopilotDot();
const { prompts, selectPrompt } = useCopilotPrompts({
  canSuggestReply: false,
});

const askCopilot = message => {
  openCopilot(props.source);
  emitter.emit(BUS_EVENTS.ASK_COPILOT, message);
};

const openCopilotPage = () => {
  openCopilot(props.source);
  router.push({ name: 'copilot_index' });
};

const askQuestion = () => {
  if (!question.value.trim()) return;

  askCopilot(question.value);
  question.value = '';
};
</script>

<template>
  <div class="w-full">
    <form
      class="flex items-center gap-2 p-1.5 ps-3.5 rounded-2xl bg-n-solid-2 outline outline-1 outline-n-strong shadow-md transition-[box-shadow,outline-color] duration-200 ease-out hover:shadow-lg focus-within:outline-n-brand focus-within:ring-4 focus-within:ring-n-brand/10 animate-fade-in-up motion-reduce:animate-none motion-reduce:transition-none"
      @submit.prevent="askQuestion"
    >
      <Icon
        icon="i-woot-captain"
        class="flex-shrink-0 text-lg text-n-slate-10"
      />
      <input
        v-model="question"
        type="text"
        :placeholder="$t('CAPTAIN.COPILOT.ASK_PLACEHOLDER')"
        class="reset-base flex-1 min-w-0 h-10 bg-transparent text-sm text-n-slate-12 placeholder:text-n-slate-10 outline-none"
      />
      <Button
        v-tooltip.top="$t('CAPTAIN.COPILOT.OPEN')"
        type="button"
        icon="i-lucide-history"
        ghost
        slate
        :aria-label="$t('CAPTAIN.COPILOT.OPEN')"
        class="!rounded-xl !text-n-slate-11"
        @click="openCopilotPage"
      />
      <Button
        type="submit"
        icon="i-lucide-arrow-up"
        :aria-label="$t('CONVERSATION.REPLYBOX.SEND')"
        class="!rounded-xl"
      />
    </form>
    <div class="flex flex-col mt-2">
      <button
        v-for="(prompt, index) in prompts"
        :key="prompt.key"
        type="button"
        class="group flex items-center justify-between gap-3 px-3.5 py-2 rounded-xl text-start text-sm text-n-slate-11 transition duration-150 ease-out hover:bg-n-alpha-2 hover:text-n-slate-12 active:scale-[0.99] focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand animate-fade-in-up [animation-fill-mode:backwards] motion-reduce:animate-none motion-reduce:transition-none"
        :class="STAGGER_CLASSES[index]"
        @click="askCopilot(selectPrompt(prompt.key))"
      >
        {{ prompt.label }}
        <Icon
          icon="i-lucide-arrow-up-right"
          class="flex-shrink-0 text-n-slate-10 transition duration-150 ease-out group-hover:text-n-slate-12 group-hover:-translate-y-px ltr:group-hover:translate-x-px rtl:group-hover:-translate-x-px rtl:-scale-x-100 motion-reduce:transition-none"
        />
      </button>
    </div>
  </div>
</template>
