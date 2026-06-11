<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { dynamicTime } from 'shared/helpers/timeHelper';
import MobileBottomSheet from './MobileBottomSheet.vue';
import MobileMultiPickerSheet from './MobileMultiPickerSheet.vue';
import { vHapticTap } from './hapticTap';

const props = defineProps({
  contactId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['back', 'openConversation']);

const store = useStore();
const { t } = useI18n();
const { light, medium, success } = useHaptics();

const showLabelsSheet = ref(false);
const showEditSheet = ref(false);
const isSaving = ref(false);

const editName = ref('');
const editEmail = ref('');
const editPhone = ref('');

const contact = computed(
  () => store.getters['contacts/getContact'](props.contactId) || {}
);
const contactLabels = computed(
  () => store.getters['contactLabels/getContactLabels'](props.contactId) || []
);
const accountLabels = computed(() => store.getters['labels/getLabels'] || []);
const contactConversations = computed(
  () =>
    store.getters['contactConversations/getContactConversation'](
      props.contactId
    ) || []
);

const additionalAttributes = computed(
  () => contact.value.additional_attributes || {}
);

const locationLabel = computed(() => {
  const { city, country } = additionalAttributes.value;
  return [city, country].filter(Boolean).join(', ');
});

const infoRows = computed(() =>
  [
    {
      key: 'phone',
      icon: 'i-lucide-phone',
      label: t('MOBILE.CONTACT.PHONE'),
      value: contact.value.phone_number,
      href: contact.value.phone_number
        ? `tel:${contact.value.phone_number}`
        : null,
    },
    {
      key: 'email',
      icon: 'i-lucide-mail',
      label: t('MOBILE.CONTACT.EMAIL'),
      value: contact.value.email,
      href: contact.value.email ? `mailto:${contact.value.email}` : null,
    },
    {
      key: 'company',
      icon: 'i-lucide-building-2',
      label: t('MOBILE.CONTACT.COMPANY'),
      value: additionalAttributes.value.company_name,
      href: null,
    },
    {
      key: 'location',
      icon: 'i-lucide-map-pin',
      label: t('MOBILE.CONTACT.LOCATION'),
      value: locationLabel.value,
      href: null,
    },
  ].filter(row => row.value)
);

const statusLabels = computed(() => ({
  open: t('MOBILE.ACTIONS.STATUS.OPEN'),
  pending: t('MOBILE.ACTIONS.STATUS.PENDING'),
  snoozed: t('MOBILE.ACTIONS.STATUS.SNOOZE'),
  resolved: t('MOBILE.ACTIONS.STATUS.RESOLVE'),
}));

const labelItems = computed(() =>
  accountLabels.value.map(label => ({
    key: label.title,
    label: label.title,
  }))
);

const conversationPreview = conversation => {
  const lastMessage =
    conversation.last_non_activity_message ||
    conversation.messages?.[conversation.messages.length - 1];
  return lastMessage?.content || t('MOBILE.CONTACT.ATTACHMENT');
};

const conversationTime = conversation =>
  dynamicTime(conversation.timestamp || conversation.created_at);

const conversationMeta = conversation =>
  [
    `#${conversation.id}`,
    statusLabels.value[conversation.status] || conversation.status,
    conversationTime(conversation),
  ]
    .filter(Boolean)
    .join(' · ');

const onBack = () => {
  light();
  emit('back');
};

const onConversationClick = conversation => {
  medium();
  emit('openConversation', conversation.id);
};

const openEditSheet = () => {
  medium();
  editName.value = contact.value.name || '';
  editEmail.value = contact.value.email || '';
  editPhone.value = contact.value.phone_number || '';
  showEditSheet.value = true;
};

const onSaveContact = async () => {
  if (!editName.value.trim() || isSaving.value) return;
  success();
  isSaving.value = true;
  try {
    await store.dispatch('contacts/update', {
      id: props.contactId,
      name: editName.value.trim(),
      ...(editEmail.value.trim() && { email: editEmail.value.trim() }),
      ...(editPhone.value.trim() && { phoneNumber: editPhone.value.trim() }),
    });
    showEditSheet.value = false;
    useAlert(t('MOBILE.CONTACT.UPDATED'));
  } catch {
    useAlert(t('MOBILE.CONTACT.UPDATE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const handleLabelsApply = async labels => {
  medium();
  showLabelsSheet.value = false;
  try {
    await store.dispatch('contactLabels/update', {
      contactId: props.contactId,
      labels,
    });
    useAlert(t('MOBILE.CONTACT.LABELS_UPDATED'));
  } catch {
    useAlert(t('MOBILE.CONTACT.UPDATE_ERROR'));
  }
};

onMounted(() => {
  store.dispatch('contacts/show', { id: props.contactId });
  store.dispatch('contactLabels/get', props.contactId);
  store.dispatch('contactConversations/get', props.contactId);
  store.dispatch('labels/get');
});
</script>

<template>
  <div
    class="flex h-full w-full flex-col bg-n-surface-1"
    @touchstart.stop
    @touchmove.stop
    @touchend.stop
  >
    <!-- Header -->
    <header
      class="flex items-center gap-2 border-b border-n-weak bg-white dark:bg-n-background px-2 py-2 pt-[max(8px,env(safe-area-inset-top))]"
    >
      <button
        v-haptic-tap
        class="flex size-10 items-center justify-center rounded-full text-n-slate-11 active:bg-n-alpha-2"
        :aria-label="t('MOBILE.CONTACT.BACK')"
        @click="onBack"
      >
        <span class="i-lucide-chevron-left size-6" />
      </button>
      <h2 class="flex-1 truncate text-base font-semibold text-n-slate-12">
        {{ t('MOBILE.CONTACT.TITLE') }}
      </h2>
      <button
        v-haptic-tap
        class="flex size-10 items-center justify-center rounded-full text-n-slate-11 active:bg-n-alpha-2"
        :aria-label="t('MOBILE.CONTACT.EDIT')"
        @click="openEditSheet"
      >
        <span class="i-lucide-pencil size-5" />
      </button>
    </header>

    <div
      class="flex-1 overflow-y-auto pb-[calc(24px+env(safe-area-inset-bottom))]"
    >
      <!-- Hero -->
      <section class="flex flex-col items-center gap-2 px-4 pb-2 pt-6">
        <Avatar
          :src="contact.thumbnail || ''"
          :name="contact.name || ''"
          :size="72"
          class="shrink-0"
        />
        <h3 class="max-w-full truncate text-lg font-semibold text-n-slate-12">
          {{ contact.name }}
        </h3>
        <div class="flex items-center gap-3">
          <a
            v-if="contact.phone_number"
            v-haptic-tap
            :href="`tel:${contact.phone_number}`"
            class="flex size-11 items-center justify-center rounded-full bg-n-blue-2 text-n-blue-10 active:opacity-80"
            :aria-label="t('MOBILE.CONTACT.CALL')"
          >
            <span class="i-lucide-phone size-5" />
          </a>
          <a
            v-if="contact.email"
            v-haptic-tap
            :href="`mailto:${contact.email}`"
            class="flex size-11 items-center justify-center rounded-full bg-n-blue-2 text-n-blue-10 active:opacity-80"
            :aria-label="t('MOBILE.CONTACT.SEND_EMAIL')"
          >
            <span class="i-lucide-mail size-5" />
          </a>
        </div>
      </section>

      <!-- Info -->
      <section v-if="infoRows.length" class="px-4 pt-5">
        <h4 class="mb-2 text-[13px] font-medium text-n-slate-10">
          {{ t('MOBILE.CONTACT.INFO') }}
        </h4>
        <div
          class="overflow-hidden rounded-2xl border border-n-weak bg-white dark:bg-n-background shadow-sm"
        >
          <component
            :is="row.href ? 'a' : 'div'"
            v-for="(row, index) in infoRows"
            :key="row.key"
            :href="row.href || undefined"
            class="flex items-center gap-3 px-4 py-3"
            :class="{ 'border-t border-n-weak': index !== 0 }"
          >
            <span
              class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-surface-2 text-n-slate-11"
            >
              <span class="size-4" :class="row.icon" />
            </span>
            <div class="min-w-0 flex-1">
              <p class="text-xs text-n-slate-10">{{ row.label }}</p>
              <p class="truncate text-sm font-medium text-n-slate-12">
                {{ row.value }}
              </p>
            </div>
          </component>
        </div>
      </section>

      <!-- Labels do contato -->
      <section class="px-4 pt-6">
        <div class="mb-2 flex items-center justify-between gap-3">
          <h4 class="text-[13px] font-medium text-n-slate-10">
            {{ t('MOBILE.CONTACT.LABELS') }}
          </h4>
          <button
            v-haptic-tap
            class="flex items-center gap-1.5 rounded-full bg-n-blue-2 px-3 py-1.5 text-sm font-medium text-n-blue-10 active:opacity-80"
            @click="showLabelsSheet = true"
          >
            <span class="i-lucide-tag size-4" />
            {{ t('MOBILE.ACTIONS.CTA.ADD_LABEL') }}
          </button>
        </div>
        <div
          class="min-h-[3.5rem] rounded-2xl border border-n-weak bg-white dark:bg-n-background px-4 py-3 shadow-sm"
        >
          <div v-if="contactLabels.length" class="flex flex-wrap gap-2">
            <span
              v-for="label in contactLabels"
              :key="label"
              class="rounded-full bg-n-brand/10 px-3 py-1 text-sm font-medium text-n-brand"
            >
              {{ label }}
            </span>
          </div>
          <p v-else class="text-sm text-n-slate-10">
            {{ t('MOBILE.CONTACT.NO_LABELS') }}
          </p>
        </div>
      </section>

      <!-- Conversas anteriores -->
      <section class="px-4 pt-6">
        <h4 class="mb-2 text-[13px] font-medium text-n-slate-10">
          {{ t('MOBILE.CONTACT.CONVERSATIONS') }}
        </h4>
        <div
          class="overflow-hidden rounded-2xl border border-n-weak bg-white dark:bg-n-background shadow-sm"
        >
          <button
            v-for="(conversation, index) in contactConversations"
            :key="conversation.id"
            v-haptic-tap
            class="flex w-full items-center gap-3 px-4 py-3 text-left active:bg-n-alpha-2"
            :class="{ 'border-t border-n-weak': index !== 0 }"
            @click="onConversationClick(conversation)"
          >
            <div class="min-w-0 flex-1">
              <p class="truncate text-sm font-medium text-n-slate-12">
                {{ conversationPreview(conversation) }}
              </p>
              <p class="mt-0.5 text-xs text-n-slate-10">
                {{ conversationMeta(conversation) }}
              </p>
            </div>
            <span
              class="i-lucide-chevron-right size-4 shrink-0 text-n-slate-9"
            />
          </button>
          <p
            v-if="!contactConversations.length"
            class="px-4 py-4 text-sm text-n-slate-10"
          >
            {{ t('MOBILE.CONTACT.NO_CONVERSATIONS') }}
          </p>
        </div>
      </section>
    </div>

    <!-- Sheet: labels do contato -->
    <MobileMultiPickerSheet
      :open="showLabelsSheet"
      :title="t('MOBILE.CONTACT.LABELS')"
      :items="labelItems"
      :selected-keys="contactLabels"
      :search-placeholder="t('MOBILE.ACTIONS.SEARCH.LABELS')"
      :empty-text="t('MOBILE.ACTIONS.EMPTY.LABELS')"
      :apply-label="t('MOBILE.ACTIONS.CTA.APPLY')"
      @close="showLabelsSheet = false"
      @apply="handleLabelsApply"
    />

    <!-- Sheet: editar contato -->
    <MobileBottomSheet
      v-if="showEditSheet"
      :title="t('MOBILE.CONTACT.EDIT')"
      @close="showEditSheet = false"
    >
      <div class="flex flex-col gap-3 pb-2">
        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-10">
            {{ t('MOBILE.CONTACT.NAME') }}
          </span>
          <input
            v-model="editName"
            type="text"
            class="h-10 rounded-lg border border-n-weak bg-white dark:bg-n-background px-3 text-sm text-n-slate-12"
          />
        </label>
        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-10">
            {{ t('MOBILE.CONTACT.EMAIL') }}
          </span>
          <input
            v-model="editEmail"
            type="email"
            class="h-10 rounded-lg border border-n-weak bg-white dark:bg-n-background px-3 text-sm text-n-slate-12"
          />
        </label>
        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-10">
            {{ t('MOBILE.CONTACT.PHONE') }}
          </span>
          <input
            v-model="editPhone"
            type="tel"
            class="h-10 rounded-lg border border-n-weak bg-white dark:bg-n-background px-3 text-sm text-n-slate-12"
          />
        </label>
        <button
          v-haptic-tap
          class="mt-1 h-11 rounded-lg bg-n-brand text-sm font-medium text-white active:opacity-90 disabled:opacity-40"
          :disabled="!editName.trim() || isSaving"
          @click="onSaveContact"
        >
          {{ t('MOBILE.CONTACT.SAVE') }}
        </button>
      </div>
    </MobileBottomSheet>
  </div>
</template>
