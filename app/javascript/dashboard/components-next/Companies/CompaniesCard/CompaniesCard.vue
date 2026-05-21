<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  domain: { type: String, default: '' },
  contactsCount: { type: Number, default: 0 },
  avatarUrl: { type: String, default: '' },
  lastActivityAt: { type: [String, Number], default: null },
});

const emit = defineEmits(['showCompany']);

const { t } = useI18n();

const onClickViewDetails = () => emit('showCompany', props.id);

const displayName = computed(() => props.name || t('COMPANIES.UNNAMED'));

const avatarSource = computed(() => props.avatarUrl || null);

const hasContacts = computed(() => Number(props.contactsCount || 0) > 0);

const contactsCountLabel = computed(() =>
  t('COMPANIES.CONTACTS_COUNT', { n: Number(props.contactsCount || 0) })
);

const formattedLastActivityAt = computed(() => {
  if (!props.lastActivityAt) return '';
  return dynamicTime(props.lastActivityAt);
});
</script>

<template>
  <CardLayout layout="row" @click="onClickViewDetails">
    <div class="flex items-center justify-start flex-1 gap-4 cursor-pointer">
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
          <span class="text-base font-medium truncate text-n-slate-12">
            {{ displayName }}
          </span>
          <span
            v-if="hasContacts"
            class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate"
          >
            <Icon icon="i-lucide-contact" size="size-3.5 text-n-slate-11" />
            {{ contactsCountLabel }}
          </span>
        </div>
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center min-w-0">
            <span
              v-if="domain"
              class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate cursor-text"
              @click.stop
            >
              <Icon icon="i-lucide-globe" size="size-3.5 text-n-slate-11" />
              <span class="truncate">{{ domain }}</span>
            </span>
          </div>
          <span
            v-if="lastActivityAt"
            class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 flex-shrink-0"
          >
            {{ formattedLastActivityAt }}
          </span>
        </div>
      </div>
    </div>
  </CardLayout>
</template>
