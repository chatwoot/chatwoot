<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import CardPopover from '../components/CardPopover.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  description: { type: String, default: '' },
  assignedAgentCount: { type: Number, default: 0 },
  users: { type: Array, default: () => [] },
  isFetchingUsers: { type: Boolean, default: false },
});

const emit = defineEmits(['edit', 'delete', 'fetchUsers']);

const { t } = useI18n();

const users = computed(() => {
  return props.users.map(user => {
    return {
      name: user.name,
      key: user.id,
      email: user.email,
      avatarUrl: user.avatarUrl,
    };
  });
});

const handleEdit = () => {
  emit('edit', props.id);
};

const handleDelete = () => {
  emit('delete', props.id);
};

const handleFetchUsers = () => {
  if (props.users?.length > 0) return;
  emit('fetchUsers', props.id);
};
</script>

<template>
  <CardLayout class="[&>div]:px-5">
    <div class="flex flex-col gap-2 relative justify-between w-full">
      <div class="flex items-center gap-3 justify-between w-full">
        <div class="flex items-center gap-3">
          <h3 class="text-base font-medium text-n-slate-12 line-clamp-1">
            {{ name }}
          </h3>
          <CardPopover
            :title="
              t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.CARD.POPOVER')
            "
            icon="i-lucide-users-round"
            :count="assignedAgentCount"
            :items="users"
            :is-fetching="isFetchingUsers"
            @fetch="handleFetchUsers"
          />
        </div>
        <div class="flex items-center gap-2">
          <Button
            :label="
              t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.CARD.EDIT')
            "
            sm
            slate
            link
            class="px-2"
            @click="handleEdit"
          />
          <div class="w-px h-2.5 bg-n-slate-5" />
          <Button icon="i-lucide-trash" sm slate ghost @click="handleDelete" />
        </div>
      </div>
      <p class="text-n-slate-11 text-sm line-clamp-1 mb-0 py-1">
        {{ description }}
      </p>
    </div>
  </CardLayout>
</template>
