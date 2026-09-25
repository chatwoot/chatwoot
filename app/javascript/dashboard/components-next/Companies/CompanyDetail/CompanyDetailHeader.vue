<script setup>
import { computed, ref, toRef, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useCompanyEnrichment } from 'dashboard/composables/useCompanyEnrichment';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useCompaniesStore } from 'dashboard/stores/companies';

const props = defineProps({
  company: { type: Object, required: true },
  openConversationsCount: { type: Number, default: 0 },
});

const emit = defineEmits(['edit', 'delete', 'showOpenConversations']);

const DESCRIPTION_CLAMP_LENGTH = 200;
const SOCIAL_ICONS = {
  linkedin: 'i-ri-linkedin-box-fill',
  x: 'i-ri-twitter-x-fill',
  twitter: 'i-ri-twitter-x-fill',
  facebook: 'i-ri-facebook-circle-fill',
  instagram: 'i-ri-instagram-fill',
  github: 'i-ri-github-fill',
  youtube: 'i-ri-youtube-fill',
};

const { t } = useI18n();
const companiesStore = useCompaniesStore();
const { isAdmin } = useAdmin();
const router = useRouter();
const { accountId } = useAccount();
const { showRefreshButton, requiresUpgrade } = useCompanyEnrichment(
  toRef(props, 'company')
);
const upgradeDialogRef = ref(null);

const avatarPreviewUrl = ref('');
const isUploadingAvatar = ref(false);
const isDescriptionExpanded = ref(false);
const showActionsMenu = ref(false);

const uiFlags = computed(() => companiesStore.getUIFlags);
const displayName = computed(
  () => props.company.name || t('COMPANIES.UNNAMED')
);
const isAvatarBusy = computed(
  () =>
    isUploadingAvatar.value ||
    uiFlags.value.deletingAvatar ||
    uiFlags.value.updatingItem
);
const isDescriptionLong = computed(
  () => (props.company.description || '').length > DESCRIPTION_CLAMP_LENGTH
);
const socialProfiles = computed(() =>
  Object.entries(props.company.additionalAttributes?.social_profiles || {}).map(
    ([type, url]) => ({
      type,
      url,
      icon: SOCIAL_ICONS[type] || 'i-lucide-link',
    })
  )
);

const phone = computed(() => props.company.additionalAttributes?.phone);
const enrichedAt = computed(() => {
  const value = props.company.additionalAttributes?.enriched_at;
  return value && dynamicTime(new Date(value).getTime() / 1000);
});

const goToBilling = () => {
  upgradeDialogRef.value?.close();
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

const handleRefresh = async () => {
  // Plans without enrichment (e.g. Startups) get an upgrade prompt instead.
  if (requiresUpgrade.value) {
    upgradeDialogRef.value?.open();
    return;
  }
  try {
    await companiesStore.enrich(props.company.id);
    useAlert(t('COMPANIES.DETAIL.PROFILE.MESSAGES.REFRESH_SUCCESS'));
  } catch (error) {
    // The server is the source of truth for the plan; the page's flags can be stale.
    if (error.response?.status === 403) {
      upgradeDialogRef.value?.open();
      return;
    }
    useAlert(
      error.response?.data?.error ||
        t('COMPANIES.DETAIL.PROFILE.MESSAGES.REFRESH_ERROR')
    );
  }
};

const menuItems = computed(() =>
  isAdmin.value
    ? [
        {
          label: t('COMPANIES.DETAIL.DELETE.BUTTON'),
          action: 'delete',
          value: 'delete',
          icon: 'i-lucide-trash-2',
        },
      ]
    : []
);

watch(
  () => [props.company.id, props.company.avatarUrl],
  () => {
    avatarPreviewUrl.value = '';
    isDescriptionExpanded.value = false;
  }
);

const handleAvatarUpload = async ({ file, url }) => {
  avatarPreviewUrl.value = url;
  isUploadingAvatar.value = true;
  try {
    await companiesStore.update({ id: props.company.id, avatar: file });
    useAlert(t('COMPANIES.DETAIL.AVATAR.UPLOAD_SUCCESS'));
  } catch {
    avatarPreviewUrl.value = '';
    useAlert(t('COMPANIES.DETAIL.AVATAR.UPLOAD_ERROR'));
  } finally {
    isUploadingAvatar.value = false;
  }
};

const handleAvatarDelete = async () => {
  try {
    await companiesStore.deleteCompanyAvatar(props.company.id);
    avatarPreviewUrl.value = '';
    useAlert(t('COMPANIES.DETAIL.AVATAR.DELETE_SUCCESS'));
  } catch {
    useAlert(t('COMPANIES.DETAIL.AVATAR.DELETE_ERROR'));
  }
};

const handleMenuAction = ({ action }) => {
  showActionsMenu.value = false;
  if (action === 'delete') emit('delete');
};
</script>

<template>
  <header class="flex flex-col gap-4">
    <div class="flex items-center gap-4">
      <Avatar
        :name="displayName"
        :src="avatarPreviewUrl || company.avatarUrl || ''"
        :size="48"
        :allow-upload="!isAvatarBusy"
        class="shrink-0"
        hide-offline-status
        @upload="handleAvatarUpload"
        @delete="handleAvatarDelete"
      />

      <div class="flex flex-col flex-1 min-w-0 gap-1.5">
        <div class="flex flex-wrap items-center gap-x-2.5 gap-y-1">
          <h1 class="break-words text-heading-1 text-n-slate-12">
            {{ displayName }}
          </h1>
          <button
            v-if="openConversationsCount"
            type="button"
            class="inline-flex items-center gap-1.5 px-1.5 py-px rounded-md text-label-small bg-n-amber-3 text-n-amber-11 hover:bg-n-amber-4"
            @click="emit('showOpenConversations')"
          >
            <span class="rounded-full size-1.5 bg-n-amber-9" />
            {{
              t(
                'COMPANIES.DETAIL.HEADER.OPEN_COUNT',
                { count: openConversationsCount },
                openConversationsCount
              )
            }}
          </button>
        </div>

        <div class="flex flex-wrap items-center text-sm gap-x-3 gap-y-1">
          <a
            v-if="company.domain"
            :href="`https://${company.domain}`"
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-1 text-n-slate-11 hover:text-n-slate-12"
          >
            {{ company.domain }}
            <span class="i-lucide-arrow-up-right size-3.5" />
          </a>
          <a
            v-if="phone"
            :href="`tel:${phone}`"
            class="inline-flex items-center gap-1 text-n-slate-11 hover:text-n-slate-12"
          >
            <span class="i-lucide-phone size-3.5" />
            {{ phone }}
          </a>
          <span
            v-if="socialProfiles.length && (company.domain || phone)"
            class="w-px h-3.5 bg-n-weak"
          />
          <a
            v-for="profile in socialProfiles"
            :key="profile.type"
            v-tooltip.top="profile.url"
            :href="profile.url"
            target="_blank"
            rel="noopener noreferrer"
            class="text-n-slate-10 hover:text-n-slate-12"
          >
            <span :class="profile.icon" class="block size-4" />
          </a>
        </div>
      </div>

      <div class="flex items-center gap-1 shrink-0">
        <Button
          v-if="showRefreshButton"
          v-tooltip.top="
            enrichedAt
              ? t('COMPANIES.DETAIL.HEADER.REFRESH_WITH_TIME', {
                  time: enrichedAt,
                })
              : t('COMPANIES.DETAIL.PROFILE.ACTIONS.REFRESH')
          "
          icon="i-lucide-refresh-cw"
          variant="ghost"
          color="slate"
          size="sm"
          :is-loading="uiFlags.enrichingItem"
          @click="handleRefresh"
        />
        <Button
          v-tooltip.top="t('COMPANIES.DETAIL.HEADER.EDIT')"
          icon="i-lucide-pencil"
          variant="ghost"
          color="slate"
          size="sm"
          @click="emit('edit')"
        />
        <div
          v-if="menuItems.length"
          v-on-clickaway="() => (showActionsMenu = false)"
          class="relative"
        >
          <Button
            icon="i-lucide-ellipsis"
            variant="ghost"
            color="slate"
            size="sm"
            @click="showActionsMenu = !showActionsMenu"
          />
          <DropdownMenu
            v-if="showActionsMenu"
            :menu-items="menuItems"
            class="mt-1 ltr:right-0 rtl:left-0 w-48 top-full"
            @action="handleMenuAction"
          />
        </div>
      </div>
    </div>

    <div
      v-if="company.description"
      class="flex flex-col items-start max-w-4xl gap-1"
    >
      <p
        class="mb-0 text-body-main text-n-slate-11"
        :class="{ 'line-clamp-2': !isDescriptionExpanded }"
      >
        {{ company.description }}
      </p>
      <button
        v-if="isDescriptionLong"
        type="button"
        class="p-0 text-label-small text-n-slate-11 hover:text-n-slate-12"
        @click="isDescriptionExpanded = !isDescriptionExpanded"
      >
        {{
          isDescriptionExpanded
            ? t('COMPANIES.DETAIL.HEADER.LESS')
            : t('COMPANIES.DETAIL.HEADER.MORE')
        }}
      </button>
    </div>

    <p
      v-if="isUploadingAvatar || uiFlags.deletingAvatar"
      class="text-sm text-n-slate-11"
    >
      {{ t('COMPANIES.DETAIL.AVATAR.UPDATING') }}
    </p>
    <Dialog
      ref="upgradeDialogRef"
      :title="t('COMPANIES.DETAIL.ENRICHMENT_UPGRADE.TITLE')"
      :description="t('COMPANIES.DETAIL.ENRICHMENT_UPGRADE.DESCRIPTION')"
      :confirm-button-label="t('COMPANIES.DETAIL.ENRICHMENT_UPGRADE.UPGRADE')"
      @confirm="goToBilling"
    />
  </header>
</template>
