<script setup>
import { computed, h, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle, useElementSize } from '@vueuse/core';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  instruction: {
    type: String,
    required: true,
  },
  tools: {
    type: Array,
    default: () => [],
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'hover', 'delete', 'update']);

const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});

const state = reactive({
  id: '',
  title: '',
  description: '',
  instruction: '',
});

const instructionContentRef = ref();

const [isEditing, toggleEditing] = useToggle();
const [isInstructionExpanded, toggleInstructionExpanded] = useToggle();

const { height: contentHeight } = useElementSize(instructionContentRef);
const needsOverlay = computed(() => contentHeight.value > 160);

const startEdit = () => {
  Object.assign(state, {
    id: props.id,
    title: props.title,
    description: props.description,
    instruction: props.instruction,
    tools: props.tools,
  });
  toggleEditing(true);
};

const rules = {
  title: { required, minLength: minLength(1) },
  description: { required },
  instruction: { required },
};

const v$ = useVuelidate(rules, state);

const titleError = computed(() =>
  v$.value.title.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.ERROR')
    : ''
);

const descriptionError = computed(() =>
  v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.ERROR')
    : ''
);

const onClickUpdate = () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;
  emit('update', { ...state });
  toggleEditing(false);
};

const instructionError = computed(() =>
  v$.value.instruction.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.ERROR')
    : ''
);

const LINK_INSTRUCTION_CLASS =
  '[&_a[href^="tool://"]]:text-n-iris-11 [&_a:not([href^="tool://"])]:text-n-slate-12 [&_a]:pointer-events-none [&_a]:cursor-default';

const renderInstruction = instruction => () =>
  h('p', {
    class: `text-sm text-n-slate-12 py-4 mb-0 prose prose-sm min-w-0 break-words max-w-none ${LINK_INSTRUCTION_CLASS}`,
    innerHTML: instruction,
  });
</script>

<template>
  <CardLayout
    selectable
    class="relative [&>div]:!py-4"
    :class="{
      '[&>div]:ltr:!pr-4 [&>div]:rtl:!pl-4': !isEditing,
      '[&>div]:ltr:!pr-10 [&>div]:rtl:!pl-10': isEditing,
    }"
    layout="row"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div
      v-show="selectable && !isEditing"
      class="absolute top-[1.125rem] ltr:left-3 rtl:right-3"
    >
      <Checkbox v-model="modelValue" />
    </div>

    <div v-if="!isEditing" class="flex flex-col w-full">
      <div class="flex items-start justify-between w-full gap-2">
        <div class="flex flex-col items-start">
          <span class="text-sm text-n-slate-12 font-medium">{{ title }}</span>
          <span class="text-sm text-n-slate-11 mt-2">
            {{ description }}
          </span>
        </div>
        <div class="flex items-center gap-2">
          <!-- <Button label="Test" slate xs ghost class="!text-sm" />
          <span class="w-px h-4 bg-n-weak" /> -->
          <Button icon="i-lucide-pen" slate xs ghost @click="startEdit" />
          <span class="w-px h-4 bg-n-weak" />
          <Button
            icon="i-lucide-trash"
            slate
            xs
            ghost
            @click="emit('delete', id)"
          />
        </div>
      </div>

      <div
        class="relative overflow-hidden transition-all duration-300 ease-in-out group/expandable"
        :class="{ 'cursor-pointer': needsOverlay }"
        :style="{
          maxHeight: isInstructionExpanded ? `${contentHeight}px` : '10rem',
        }"
        @click="needsOverlay ? toggleInstructionExpanded() : null"
      >
        <div ref="instructionContentRef">
          <component
            :is="renderInstruction(formatMessage(instruction, false))"
          />
        </div>

        <div
          class="absolute bottom-0 w-full flex items-end justify-center text-xs text-n-slate-11 bg-gradient-to-t h-40 from-n-solid-2 via-n-solid-2 via-10% to-transparent transition-all duration-500 ease-in-out px-2 py-1 rounded pointer-events-none"
          :class="{
            'visible opacity-100': !isInstructionExpanded,
            'invisible opacity-0': isInstructionExpanded || !needsOverlay,
          }"
        >
          <Icon
            icon="i-lucide-chevron-down"
            class="text-n-slate-7 mb-4 size-4 group-hover/expandable:text-n-slate-11 transition-colors duration-200"
          />
        </div>
      </div>
      <span
        v-if="tools?.length"
        class="text-sm text-n-slate-11 font-medium mb-1"
      >
        {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TOOLS_USED') }}
        {{ tools?.map(tool => `@${tool}`).join(', ') }}
      </span>
    </div>
    <div v-else class="overflow-hidden flex flex-col gap-4 w-full">
      <Input
        v-model="state.title"
        :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL')"
        :placeholder="
          t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
        "
        :message="titleError"
        :message-type="titleError ? 'error' : 'info'"
      />

      <TextArea
        v-model="state.description"
        :label="
          t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL')
        "
        :placeholder="
          t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.PLACEHOLDER')
        "
        :message="descriptionError"
        :message-type="descriptionError ? 'error' : 'info'"
        show-character-count
      />
      <Editor
        v-model="state.instruction"
        :label="
          t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL')
        "
        :placeholder="
          t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.PLACEHOLDER')
        "
        :message="instructionError"
        :message-type="instructionError ? 'error' : 'info'"
        :show-character-count="false"
        enable-captain-tools
      />
      <div class="flex items-center gap-3">
        <Button
          faded
          slate
          sm
          :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.UPDATE.CANCEL')"
          @click="toggleEditing(false)"
        />
        <Button
          sm
          :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.UPDATE.UPDATE')"
          @click="onClickUpdate"
        />
      </div>
    </div>
  </CardLayout>
</template>
