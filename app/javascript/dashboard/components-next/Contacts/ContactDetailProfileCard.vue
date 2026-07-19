<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import ContactAssigneeSelector from 'dashboard/components-next/Contacts/ContactAssigneeSelector.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update', 'upload', 'deleteAvatar']);

const { t } = useI18n();

const avatarUrl = ref('');

const avatarSrc = computed(() => {
  return avatarUrl.value || props.selectedContact?.thumbnail || '';
});

const createdAt = computed(() => {
  return props.selectedContact?.createdAt
    ? dynamicTime(props.selectedContact.createdAt)
    : '';
});

const lastActivityAt = computed(() => {
  return props.selectedContact?.lastActivityAt
    ? dynamicTime(props.selectedContact.lastActivityAt)
    : '';
});

const handleAvatarUpload = payload => {
  avatarUrl.value = payload.url;
  emit('upload', payload);
};

const handleAvatarDelete = () => {
  avatarUrl.value = '';
  emit('deleteAvatar');
};
</script>

<template>
  <div
    class="w-full rounded-xl border border-n-weak bg-n-alpha-1 dark:bg-n-solid-2 p-4"
  >
    <div
      class="grid grid-cols-1 gap-4 min-w-0 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-start"
    >
      <div class="flex flex-col gap-3 min-w-0 sm:flex-row sm:items-start">
        <Avatar
          :src="avatarSrc"
          :name="selectedContact?.name || ''"
          :size="56"
          allow-upload
          hide-offline-status
          class="flex-shrink-0"
          @upload="handleAvatarUpload"
          @delete="handleAvatarDelete"
        />

        <div class="flex flex-col gap-3 min-w-0 flex-1">
          <div class="flex flex-col gap-1 min-w-0">
            <h3 class="text-lg font-medium text-n-slate-12 truncate">
              {{ selectedContact?.name || '—' }}
            </h3>
            <p class="text-xs text-n-slate-10">
              {{ t('CONTACTS_LAYOUT.DETAILS.CREATED_AT', { date: createdAt }) }}
              <span class="mx-1" aria-hidden="true">{{
                t('CONTACTS_LAYOUT.DETAILS.DATE_SEPARATOR')
              }}</span>
              {{
                t('CONTACTS_LAYOUT.DETAILS.LAST_ACTIVITY', {
                  date: lastActivityAt,
                })
              }}
            </p>
          </div>

          <ContactLabels :contact-id="selectedContact?.id" />
        </div>
      </div>

      <div class="flex flex-col gap-2 min-w-0 sm:items-end sm:min-w-[12rem]">
        <ContactAssigneeSelector
          :contact="selectedContact"
          @update="emit('update', $event)"
        />
      </div>
    </div>
  </div>
</template>
