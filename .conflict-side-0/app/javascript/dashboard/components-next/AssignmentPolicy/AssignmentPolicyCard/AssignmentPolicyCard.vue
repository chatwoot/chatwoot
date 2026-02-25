<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { formatToTitleCase } from 'dashboard/helper/commons';

import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import CardPopover from '../components/CardPopover.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  description: { type: String, default: '' },
  assignmentOrder: { type: String, default: '' },
  conversationPriority: { type: String, default: '' },
  assignedInboxCount: { type: Number, default: 0 },
  inboxes: { type: Array, default: () => [] },
  isFetchingInboxes: { type: Boolean, default: false },
});

const emit = defineEmits(['edit', 'delete', 'fetchInboxes']);

const { t } = useI18n();

const inboxes = computed(() => {
  return props.inboxes.map(inbox => {
    return {
      name: inbox.name,
      id: inbox.id,
      icon: getInboxIconByType(inbox.channelType, inbox.medium, 'line'),
    };
  });
});

const order = computed(() => {
  return formatToTitleCase(props.assignmentOrder);
});

const priority = computed(() => {
  return formatToTitleCase(props.conversationPriority);
});

const handleEdit = () => {
  emit('edit', props.id);
};

const handleDelete = () => {
  emit('delete', props.id);
};

const handleFetchInboxes = () => {
  if (props.inboxes?.length > 0) return;
  emit('fetchInboxes', props.id);
};
</script>

<template>
  <CardLayout class="[&>div]:px-5">
    <div class="flex flex-col gap-2 relative justify-between w-full">
      <div class="flex items-center gap-3 justify-between w-full">
        <div class="flex items-center gap-3">
          <h3 class="text-heading-2 text-n-slate-12 line-clamp-1">
            {{ name }}
          </h3>
          <CardPopover
            :title="
              t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.CARD.POPOVER')
            "
            icon="i-lucide-inbox"
            :count="assignedInboxCount"
            :items="inboxes"
            :is-fetching="isFetchingInboxes"
            @fetch="handleFetchInboxes"
          />
        </div>
        <div class="flex items-center gap-2">
          <Button
            :label="
              t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.CARD.EDIT')
            "
            sm
            slate
            link
            class="px-2"
            @click="handleEdit"
          />
          <div v-if="order" class="w-px h-2.5 bg-n-slate-5" />
          <Button icon="i-lucide-trash" sm slate ghost @click="handleDelete" />
        </div>
      </div>
      <p class="text-n-slate-11 text-body-para line-clamp-1 mb-0 py-1">
        {{ description }}
      </p>
      <div class="flex items-center gap-3 py-1.5">
        <span v-if="order" class="text-n-slate-11 text-body-para">
          {{
            `${t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.CARD.ORDER')}:`
          }}
          <span class="text-n-slate-12">{{ order }}</span>
        </span>
        <div v-if="order" class="w-px h-3 bg-n-strong" />
        <span v-if="priority" class="text-n-slate-11 text-body-para">
          {{
            `${t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.CARD.PRIORITY')}:`
          }}
          <span class="text-n-slate-12">{{ priority }}</span>
        </span>
      </div>
    </div>
  </CardLayout>
</template>
