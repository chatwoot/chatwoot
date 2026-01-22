<script setup>
import { computed } from 'vue';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Policy from 'dashboard/components/policy.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  question: {
    type: String,
    required: true,
  },
  answer: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: 'approved',
  },
  documentable: {
    type: Object,
    default: null,
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  showMenu: {
    type: Boolean,
    default: true,
  },
  showActions: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['action', 'navigate', 'select']);

const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAssistantAction = (action, value) => {
  emit('action', { action, value, id: props.id });
};

const handleDocumentableClick = () => {
  emit('navigate', {
    id: props.documentable.id,
    type: props.documentable.type,
  });
};
</script>

<template>
  <div class="py-4 flex flex-col gap-2">
    <div
      v-if="!compact"
      class="flex items-start gap-3 h-6"
      :class="{ 'justify-between w-full': !showActions }"
    >
      <div class="inline-flex items-center gap-2 min-w-0">
        <!-- <span
          v-if="status === 'approved'"
          class="text-sm shrink-0 truncate text-n-slate-11 inline-flex items-center gap-1"
        >
          <Icon icon="i-woot-captain" class="size-3.5" />
          {{ assistant?.name || '' }}
        </span> -->
        <div
          v-if="documentable"
          class="text-sm text-n-slate-11 grid grid-cols-[auto_1fr] items-center gap-1.5 min-w-0"
        >
          <Icon
            v-if="documentable.type === 'Captain::Document'"
            icon="i-lucide-files"
            class="size-3.5 flex-shrink-0"
          />
          <Icon
            v-else-if="documentable.type === 'User'"
            icon="i-lucide-circle-user-round"
            class="size-3.5 flex-shrink-0"
          />
          <Icon
            v-else-if="documentable.type === 'Conversation'"
            icon="i-lucide-message-circle"
            class="size-3.5 flex-shrink-0"
          />
          <span
            v-if="documentable.type === 'Captain::Document'"
            class="truncate text-body-main text-n-slate-11"
            :title="documentable.name"
          >
            {{ documentable.name }}
          </span>
          <span
            v-else-if="documentable.type === 'User'"
            class="truncate text-body-main text-n-slate-11"
            :title="documentable.available_name"
          >
            {{ documentable.available_name }}
          </span>
          <span
            v-else-if="documentable.type === 'Conversation'"
            class="hover:underline truncate cursor-pointer text-body-main text-n-slate-11"
            role="button"
            @click="handleDocumentableClick"
          >
            {{ documentable.display_id }}
          </span>
        </div>
        <div class="w-px h-3 rounded-lg bg-n-strong" />
        <span class="shrink-0 text-body-main text-n-slate-11">
          {{ timestamp }}
        </span>
      </div>
      <div v-if="!compact && showMenu">
        <Policy
          :permissions="['administrator']"
          class="gap-2 flex items-center flex-shrink-0"
        >
          <Button
            icon="i-lucide-pencil-line"
            slate
            sm
            outline
            @click="handleAssistantAction('edit', 'edit')"
          />
          <Button
            icon="i-lucide-trash"
            slate
            sm
            outline
            @click="handleAssistantAction('delete', 'delete')"
          />
        </Policy>
      </div>
    </div>
    <div class="flex justify-between items-center w-full gap-1">
      <div class="flex items-center gap-1.5">
        <div v-if="!compact" class="size-5 flex items-center">
          <Checkbox v-model="modelValue" />
        </div>
        <span class="text-n-slate-12 text-heading-3 line-clamp-1">
          {{ question }}
        </span>
      </div>
    </div>
    <span
      class="text-n-slate-11 text-body-main line-clamp-5"
      :class="{ 'ltr:pl-[1.625rem] rtl:pr-[1.625rem]': !compact }"
    >
      {{ answer }}
    </span>
    <div
      v-if="!compact"
      class="flex items-start justify-between flex-col-reverse md:flex-row gap-3"
    >
      <Policy v-if="showActions" :permissions="['administrator']">
        <div class="flex items-center gap-2 sm:gap-5 w-full">
          <Button
            v-if="status === 'pending'"
            :label="$t('CAPTAIN.RESPONSES.OPTIONS.APPROVE')"
            icon="i-lucide-circle-check-big"
            sm
            link
            class="hover:!no-underline"
            @click="handleAssistantAction('approve', 'approve')"
          />
          <Button
            :label="$t('CAPTAIN.RESPONSES.OPTIONS.EDIT_RESPONSE')"
            icon="i-lucide-pencil-line"
            sm
            slate
            link
            class="hover:!no-underline"
            @click="handleAssistantAction('edit', 'edit')"
          />
          <Button
            :label="$t('CAPTAIN.RESPONSES.OPTIONS.DELETE_RESPONSE')"
            icon="i-lucide-trash"
            sm
            ruby
            link
            class="hover:!no-underline"
            @click="handleAssistantAction('delete', 'delete')"
          />
        </div>
      </Policy>
    </div>
  </div>
</template>
