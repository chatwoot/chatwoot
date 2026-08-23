<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SettingsListItem from '../components/SettingsListItem.vue';

const props = defineProps({
  canned: {
    type: Object,
    required: true,
  },
  isAdmin: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['edit', 'delete', 'approve', 'reject', 'duplicate']);

const { t } = useI18n();
const { getPlainText } = useMessageFormatter();

const categoryLabel = computed(() => {
  const category = (props.canned.category || '').trim();
  return category || t('CANNED_MGMT.UNCATEGORIZED');
});

const visibilityLabel = computed(() =>
  t(`CANNED_MGMT.VISIBILITY_LABEL.${props.canned.visibility || 'global'}`)
);

const approvalStatus = computed(
  () => props.canned.approval_status || 'pending'
);

const showStatusBadge = computed(() => approvalStatus.value !== 'approved');

const statusLabel = computed(() =>
  t(`CANNED_MGMT.STATUS_LABEL.${approvalStatus.value}`)
);

const statusBadgeClass = computed(() => {
  if (approvalStatus.value === 'rejected') {
    return 'bg-n-ruby-3 text-n-ruby-12';
  }
  return 'bg-n-slate-3 text-n-slate-12';
});

const contentPreview = computed(() => getPlainText(props.canned.content));
</script>

<template>
  <SettingsListItem :title="canned.short_code">
    <template #icon>
      <Icon
        icon="i-lucide-message-square-text"
        class="size-5 text-n-slate-11"
      />
    </template>
    <template #badges>
      <span
        v-if="showStatusBadge"
        class="inline-flex shrink-0 px-2 py-0.5 text-xs font-medium rounded-md"
        :class="statusBadgeClass"
      >
        {{ statusLabel }}
      </span>
    </template>
    <template #meta>
      <span class="truncate">{{ categoryLabel }}</span>
      <div class="w-px h-3 rounded-lg bg-n-strong shrink-0" />
      <span class="truncate">{{ visibilityLabel }}</span>
      <template v-if="contentPreview">
        <div class="w-px h-3 rounded-lg bg-n-strong shrink-0" />
        <span class="truncate">{{ contentPreview }}</span>
      </template>
    </template>
    <template #actions>
      <template v-if="isAdmin && approvalStatus === 'pending'">
        <Button
          v-tooltip.top="$t('CANNED_MGMT.APPROVE.PERSONAL')"
          icon="i-lucide-user-check"
          slate
          sm
          :is-loading="isLoading"
          @click="$emit('approve', 'personal')"
        />
        <Button
          v-tooltip.top="$t('CANNED_MGMT.APPROVE.ACCOUNT')"
          icon="i-lucide-users"
          slate
          sm
          :is-loading="isLoading"
          @click="$emit('approve', 'global')"
        />
        <Button
          v-tooltip.top="$t('CANNED_MGMT.REJECT.BUTTON')"
          icon="i-lucide-x"
          slate
          sm
          class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
          :is-loading="isLoading"
          @click="$emit('reject')"
        />
      </template>
      <Button
        v-tooltip.top="$t('CANNED_MGMT.DUPLICATE.TOOLTIP')"
        icon="i-woot-clone"
        slate
        sm
        :is-loading="isLoading"
        @click="$emit('duplicate')"
      />
      <Button
        v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
        icon="i-woot-edit-pen"
        slate
        sm
        @click="$emit('edit')"
      />
      <Button
        v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
        icon="i-woot-bin"
        slate
        sm
        class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
        :is-loading="isLoading"
        @click="$emit('delete')"
      />
    </template>
  </SettingsListItem>
</template>
