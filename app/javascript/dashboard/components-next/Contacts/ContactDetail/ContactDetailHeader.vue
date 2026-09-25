<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useEnrichment } from 'dashboard/composables/useEnrichment';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import ContactLabels from 'dashboard/components-next/Contacts/ContactLabels/ContactLabels.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';

const props = defineProps({
  contact: { type: Object, required: true },
  openConversationsCount: { type: Number, default: 0 },
});

const emit = defineEmits([
  'edit',
  'merge',
  'delete',
  'toggleBlock',
  'showOpenConversations',
]);

const DESCRIPTION_CLAMP_LENGTH = 200;
// Contacts store social profiles as handles; these prefixes turn them into links.
const SOCIAL_LINKS = [
  {
    key: 'linkedin',
    icon: 'i-ri-linkedin-box-fill',
    url: 'https://linkedin.com/',
  },
  { key: 'twitter', icon: 'i-ri-twitter-x-fill', url: 'https://x.com/' },
  {
    key: 'facebook',
    icon: 'i-ri-facebook-circle-fill',
    url: 'https://facebook.com/',
  },
  {
    key: 'instagram',
    icon: 'i-ri-instagram-fill',
    url: 'https://instagram.com/',
  },
  { key: 'github', icon: 'i-ri-github-fill', url: 'https://github.com/' },
  { key: 'tiktok', icon: 'i-ri-tiktok-fill', url: 'https://tiktok.com/@' },
  { key: 'telegram', icon: 'i-ri-telegram-fill', url: 'https://t.me/' },
];

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { isAdmin } = useAdmin();
const { accountId } = useAccount();
const uiFlags = useMapGetter('contacts/getUIFlags');

const upgradeDialogRef = ref(null);
const avatarPreviewUrl = ref('');
const isUploadingAvatar = ref(false);
const isDescriptionExpanded = ref(false);
const showActionsMenu = ref(false);

const attributes = computed(() => props.contact.additionalAttributes || {});
const socialProfiles = computed(() => attributes.value.socialProfiles || {});
const description = computed(() => attributes.value.description || '');
const isDescriptionLong = computed(
  () => description.value.length > DESCRIPTION_CLAMP_LENGTH
);

// Mirrors the identity clues the server needs before it can look a contact up.
const { showRefreshButton, requiresUpgrade } = useEnrichment(
  computed(
    () =>
      Boolean(props.contact.email) ||
      Boolean(socialProfiles.value.linkedin) ||
      Boolean(props.contact.companyId || attributes.value.companyName)
  )
);

const socialLinks = computed(() =>
  SOCIAL_LINKS.filter(({ key }) => socialProfiles.value[key]).map(
    ({ key, icon, url }) => {
      const handle = socialProfiles.value[key];
      return {
        key,
        icon,
        url: handle.startsWith('http') ? handle : `${url}${handle}`,
      };
    }
  )
);

const role = computed(() => {
  const { jobTitle, companyName } = attributes.value;
  if (jobTitle && companyName) {
    return t('CONTACTS_LAYOUT.DETAIL.HEADER.ROLE_AT', {
      title: jobTitle,
      company: companyName,
    });
  }
  return jobTitle || companyName || '';
});

const companyRoute = computed(
  () =>
    props.contact.companyId && {
      name: 'companies_dashboard_show',
      params: {
        accountId: accountId.value,
        companyId: props.contact.companyId,
      },
    }
);

const enrichedAt = computed(() => {
  const value = attributes.value.enrichedAt;
  return value && dynamicTime(new Date(value).getTime() / 1000);
});

const isCustomer = computed(() => props.contact.contactType === 'customer');

const menuItems = computed(() => [
  {
    label: isCustomer.value
      ? t('CONTACTS_LAYOUT.DETAIL.HEADER.MARK_AS_LEAD')
      : t('CONTACTS_LAYOUT.DETAIL.HEADER.MARK_AS_CUSTOMER'),
    action: 'changeContactType',
    value: 'changeContactType',
    icon: isCustomer.value ? 'i-lucide-user-round' : 'i-lucide-badge-check',
  },
  {
    label: props.contact.blocked
      ? t('CONTACTS_LAYOUT.HEADER.UNBLOCK_CONTACT')
      : t('CONTACTS_LAYOUT.HEADER.BLOCK_CONTACT'),
    action: 'toggleBlock',
    value: 'toggleBlock',
    icon: props.contact.blocked ? 'i-lucide-circle-check' : 'i-lucide-ban',
  },
  {
    label: t('CONTACTS_LAYOUT.DETAIL.HEADER.MERGE'),
    action: 'merge',
    value: 'merge',
    icon: 'i-lucide-merge',
  },
  ...(isAdmin.value
    ? [
        {
          label: t('CONTACTS_LAYOUT.DETAILS.DELETE_CONTACT'),
          action: 'delete',
          value: 'delete',
          icon: 'i-lucide-trash-2',
        },
      ]
    : []),
]);

watch(
  () => [props.contact.id, props.contact.thumbnail],
  () => {
    avatarPreviewUrl.value = '';
    isDescriptionExpanded.value = false;
  }
);

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
    await store.dispatch('contacts/enrich', props.contact.id);
    useAlert(t('CONTACTS_LAYOUT.DETAIL.PROFILE.REFRESH_SUCCESS'));
  } catch (error) {
    // The server is the source of truth for the plan; the page's flags can be stale.
    if (error.response?.status === 403) {
      upgradeDialogRef.value?.open();
      return;
    }
    useAlert(
      error.response?.data?.error ||
        t('CONTACTS_LAYOUT.DETAIL.PROFILE.REFRESH_ERROR')
    );
  }
};

const handleAvatarUpload = async ({ file, url }) => {
  avatarPreviewUrl.value = url;
  isUploadingAvatar.value = true;
  try {
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      avatar: file,
      isFormData: true,
    });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.SUCCESS_MESSAGE'));
  } catch {
    avatarPreviewUrl.value = '';
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.UPLOAD.ERROR_MESSAGE'));
  } finally {
    isUploadingAvatar.value = false;
  }
};

const handleAvatarDelete = async () => {
  try {
    await store.dispatch('contacts/deleteAvatar', props.contact.id);
    avatarPreviewUrl.value = '';
    useAlert(t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error.message || t('CONTACTS_LAYOUT.DETAILS.AVATAR.DELETE.ERROR_MESSAGE')
    );
  }
};

const changeContactType = async () => {
  try {
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      contactType: isCustomer.value ? 'lead' : 'customer',
    });
    useAlert(t('CONTACTS_LAYOUT.DETAIL.HEADER.TYPE_CHANGE_SUCCESS'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAIL.HEADER.TYPE_CHANGE_ERROR'));
  }
};

const handleMenuAction = ({ action }) => {
  showActionsMenu.value = false;
  if (action === 'changeContactType') changeContactType();
  else if (action === 'toggleBlock') emit('toggleBlock');
  else if (action === 'merge') emit('merge');
  else if (action === 'delete') emit('delete');
};
</script>

<template>
  <header class="flex flex-col gap-4">
    <div class="flex flex-wrap items-center gap-4">
      <Avatar
        :name="contact.name || ''"
        :src="avatarPreviewUrl || contact.thumbnail || ''"
        :size="48"
        :allow-upload="!isUploadingAvatar && !uiFlags.isUpdating"
        class="shrink-0"
        hide-offline-status
        @upload="handleAvatarUpload"
        @delete="handleAvatarDelete"
      />

      <div class="flex flex-col flex-1 min-w-0 gap-1.5">
        <div class="flex flex-wrap items-center gap-x-2.5 gap-y-1">
          <h1 class="break-words text-heading-1 text-n-slate-12">
            {{ contact.name }}
          </h1>
          <span
            v-if="isCustomer"
            class="inline-flex items-center gap-1 px-1.5 py-px rounded-md text-label-small bg-n-teal-3 text-n-teal-11"
          >
            <span class="i-lucide-badge-check size-3" />
            {{ t('CONTACTS_LAYOUT.DETAIL.HEADER.CUSTOMER') }}
          </span>
          <span
            v-if="contact.blocked"
            class="inline-flex items-center gap-1 px-1.5 py-px rounded-md text-label-small bg-n-ruby-3 text-n-ruby-11"
          >
            <span class="i-lucide-ban size-3" />
            {{ t('CONTACTS_LAYOUT.DETAIL.HEADER.BLOCKED') }}
          </span>
          <button
            v-if="openConversationsCount"
            type="button"
            class="inline-flex items-center gap-1.5 px-1.5 py-px rounded-md text-label-small bg-n-amber-3 text-n-amber-11 hover:bg-n-amber-4"
            @click="emit('showOpenConversations')"
          >
            <span class="rounded-full size-1.5 bg-n-amber-9" />
            {{
              t(
                'CONTACTS_LAYOUT.DETAIL.HEADER.OPEN_COUNT',
                { count: openConversationsCount },
                openConversationsCount
              )
            }}
          </button>
        </div>

        <component
          :is="companyRoute ? 'router-link' : 'span'"
          v-if="role"
          :to="companyRoute || undefined"
          class="self-start text-body-main text-n-slate-11"
          :class="{ 'hover:text-n-slate-12 hover:underline': companyRoute }"
        >
          {{ role }}
        </component>

        <div class="flex flex-wrap items-center text-sm gap-x-3 gap-y-1">
          <a
            v-if="contact.email"
            :href="`mailto:${contact.email}`"
            class="inline-flex items-center min-w-0 gap-1 text-n-slate-11 hover:text-n-slate-12"
          >
            <span class="i-lucide-mail size-3.5 shrink-0" />
            <span class="truncate">{{ contact.email }}</span>
          </a>
          <a
            v-if="contact.phoneNumber"
            :href="`tel:${contact.phoneNumber}`"
            class="inline-flex items-center gap-1 text-n-slate-11 hover:text-n-slate-12"
          >
            <span class="i-lucide-phone size-3.5" />
            {{ contact.phoneNumber }}
          </a>
          <span
            v-if="socialLinks.length && (contact.email || contact.phoneNumber)"
            class="w-px h-3.5 bg-n-weak"
          />
          <a
            v-for="profile in socialLinks"
            :key="profile.key"
            v-tooltip.top="profile.url"
            :href="profile.url"
            target="_blank"
            rel="noopener noreferrer nofollow"
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
              ? t('CONTACTS_LAYOUT.DETAIL.HEADER.REFRESH_WITH_TIME', {
                  time: enrichedAt,
                })
              : t('CONTACTS_LAYOUT.DETAIL.HEADER.REFRESH')
          "
          icon="i-lucide-refresh-cw"
          variant="ghost"
          color="slate"
          size="sm"
          :is-loading="uiFlags.isEnriching"
          @click="handleRefresh"
        />
        <Button
          v-tooltip.top="t('CONTACTS_LAYOUT.DETAIL.HEADER.EDIT')"
          icon="i-lucide-pencil"
          variant="ghost"
          color="slate"
          size="sm"
          @click="emit('edit')"
        />
        <div v-on-clickaway="() => (showActionsMenu = false)" class="relative">
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
        <VoiceCallButton
          :phone="contact.phoneNumber"
          :contact-id="contact.id"
          :label="t('CONTACT_PANEL.CALL')"
          class="ms-1"
          size="sm"
        />
        <ComposeConversation :contact-id="String(contact.id)">
          <template #trigger>
            <Button
              :label="t('CONTACTS_LAYOUT.HEADER.SEND_MESSAGE')"
              class="ms-1"
              size="sm"
            />
          </template>
        </ComposeConversation>
      </div>
    </div>

    <div v-if="description" class="flex flex-col items-start max-w-4xl gap-1">
      <p
        class="mb-0 text-body-main text-n-slate-11"
        :class="{ 'line-clamp-2': !isDescriptionExpanded }"
      >
        {{ description }}
      </p>
      <button
        v-if="isDescriptionLong"
        type="button"
        class="p-0 text-label-small text-n-slate-11 hover:text-n-slate-12"
        @click="isDescriptionExpanded = !isDescriptionExpanded"
      >
        {{
          isDescriptionExpanded
            ? t('CONTACTS_LAYOUT.DETAIL.HEADER.LESS')
            : t('CONTACTS_LAYOUT.DETAIL.HEADER.MORE')
        }}
      </button>
    </div>

    <ContactLabels :contact-id="contact.id" />

    <Dialog
      ref="upgradeDialogRef"
      :title="t('CONTACTS_LAYOUT.DETAIL.ENRICHMENT_UPGRADE.TITLE')"
      :description="t('CONTACTS_LAYOUT.DETAIL.ENRICHMENT_UPGRADE.DESCRIPTION')"
      :confirm-button-label="
        t('CONTACTS_LAYOUT.DETAIL.ENRICHMENT_UPGRADE.UPGRADE')
      "
      @confirm="goToBilling"
    />
  </header>
</template>
