<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow } from 'date-fns';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  domain: { type: String, default: '' },
  contactsCount: { type: Number, default: 0 },
  description: { type: String, default: '' },
  avatarUrl: { type: String, default: '' },
  updatedAt: { type: [String, Number], default: null },
});

const emit = defineEmits(['showCompany']);

const { t } = useI18n();

const onClickViewDetails = () => emit('showCompany', props.id);

const displayName = computed(() => props.name || t('COMPANIES.UNNAMED'));

const avatarSource = computed(() => props.avatarUrl || null);

const formattedUpdatedAt = computed(() => {
  if (!props.updatedAt) return '';
  return formatDistanceToNow(new Date(props.updatedAt), { addSuffix: true });
});
</script>

<template>
  <CardLayout layout="row" @click="onClickViewDetails">
    <div class="flex items-center justify-start flex-1 gap-4">
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
            v-if="domain && description"
            class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate"
          >
            <Icon icon="i-lucide-globe" size="size-3.5 text-n-slate-11" />
            <span class="truncate">{{ domain }}</span>
          </span>
        </div>
        <div class="flex items-center justify-between">
          <div class="flex flex-wrap items-center gap-x-3 gap-y-1 min-w-0">
            <span
              v-if="domain && !description"
              class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate"
            >
              <Icon icon="i-lucide-globe" size="size-3.5 text-n-slate-11" />
              <span class="truncate">{{ domain }}</span>
            </span>
            <span v-if="description" class="text-sm text-n-slate-11 truncate">
              {{ description }}
            </span>
            <div
              v-if="(description || domain) && contactsCount"
              class="w-px h-3 bg-n-slate-6"
            />
            <span
              v-if="contactsCount"
              class="inline-flex items-center gap-1.5 text-sm text-n-slate-11 truncate"
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
  </CardLayout>
</template>
