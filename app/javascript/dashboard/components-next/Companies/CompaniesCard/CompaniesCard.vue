<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow } from 'date-fns';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AccountOwnerSelect from 'dashboard/components-next/AccountOwner/AccountOwnerSelect.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  domain: { type: String, default: '' },
  contactsCount: { type: Number, default: 0 },
  description: { type: String, default: '' },
  avatarUrl: { type: String, default: '' },
  updatedAt: { type: [String, Number], default: null },
  accountOwnerId: { type: [Number, String], default: '' },
  accountOwner: { type: Object, default: null },
  agents: { type: Array, default: () => [] },
  isUpdating: { type: Boolean, default: false },
  ownerPickerResetKey: { type: [Number, String], default: 0 },
});

const emit = defineEmits(['showCompany', 'updateOwner']);

const { t } = useI18n();

const onClickViewDetails = () => emit('showCompany', props.id);

const displayName = computed(() => props.name || t('COMPANIES.UNNAMED'));

const avatarSource = computed(() => props.avatarUrl || null);

const ownerModelValue = computed(() => props.accountOwnerId || '');

const ownerSelectKey = computed(
  () => `${ownerModelValue.value || 'unassigned'}-${props.ownerPickerResetKey}`
);

const accountOwnerTitle = computed(
  () =>
    props.accountOwner?.availableName ||
    props.accountOwner?.available_name ||
    props.accountOwner?.name ||
    ''
);

const handleOwnerUpdate = accountOwnerId => {
  emit('updateOwner', {
    id: props.id,
    accountOwnerId: accountOwnerId || null,
  });
};

const formattedUpdatedAt = computed(() => {
  if (!props.updatedAt) return '';
  return formatDistanceToNow(new Date(props.updatedAt), { addSuffix: true });
});
</script>

<template>
  <CardLayout layout="row" @click="onClickViewDetails">
    <div
      class="flex flex-col w-full gap-4 sm:flex-row sm:items-center sm:justify-between min-w-0"
    >
      <div class="flex items-center justify-start flex-1 gap-4 min-w-0">
        <Avatar
          :username="displayName"
          :src="avatarSource"
          class="shrink-0"
          :name="name"
          :size="48"
          hide-offline-status
          rounded-full
        />
        <div class="flex flex-col gap-0.5 flex-1 min-w-0">
          <div class="flex flex-wrap items-center gap-x-4 gap-y-1 min-w-0">
            <span
              class="min-w-0 text-base font-medium truncate text-n-slate-12"
            >
              {{ displayName }}
            </span>
            <span
              v-if="domain && description"
              class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate min-w-0"
            >
              <Icon icon="i-lucide-globe" size="size-3.5 text-n-slate-11" />
              <span class="truncate min-w-0">{{ domain }}</span>
            </span>
          </div>
          <div class="flex items-center justify-between min-w-0 gap-3">
            <div class="flex flex-wrap items-center gap-x-3 gap-y-1 min-w-0">
              <span
                v-if="domain && !description"
                class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate min-w-0"
              >
                <Icon icon="i-lucide-globe" size="size-3.5 text-n-slate-11" />
                <span class="truncate min-w-0">{{ domain }}</span>
              </span>
              <span
                v-if="description"
                class="min-w-0 text-sm text-n-slate-11 truncate"
              >
                {{ description }}
              </span>
              <div
                v-if="(description || domain) && contactsCount"
                class="w-px h-3 bg-n-slate-6"
              />
              <span
                v-if="contactsCount"
                class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate min-w-0"
              >
                <Icon icon="i-lucide-contact" size="size-3.5 text-n-slate-11" />
                {{ t('COMPANIES.CONTACTS_COUNT', { n: contactsCount }) }}
              </span>
            </div>
            <span
              v-if="updatedAt"
              class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 flex-shrink-0"
            >
              {{ formattedUpdatedAt }}
            </span>
          </div>
        </div>
      </div>
      <div
        class="w-full sm:w-56 lg:w-64 shrink-0"
        :title="accountOwnerTitle"
        @click.stop
      >
        <label class="block mb-1 text-xs font-medium text-n-slate-11">
          {{ t('ACCOUNT_OWNER.LABEL') }}
        </label>
        <AccountOwnerSelect
          :key="ownerSelectKey"
          :model-value="ownerModelValue"
          :agents="agents"
          :disabled="isUpdating"
          class="[&>div>button]:h-8"
          @update:model-value="handleOwnerUpdate"
        />
      </div>
    </div>
  </CardLayout>
</template>
