<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ConversationRequiredAttributeItem from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributeItem.vue';
import ConversationRequiredEmpty from 'dashboard/components-next/Conversation/ConversationRequiredEmpty.vue';
import BasePaywallModal from 'dashboard/routes/dashboard/settings/components/BasePaywallModal.vue';

const props = defineProps({
  isEnabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click']);
const router = useRouter();
const { t } = useI18n();
const { currentAccount, accountId, isOnChatwootCloud, updateAccount } =
  useAccount();
const [showDropdown, toggleDropdown] = useToggle(false);
const [isSaving, toggleSaving] = useToggle(false);
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);
const currentUser = useMapGetter('getCurrentUser');

const isSuperAdmin = computed(() => currentUser.value.type === 'SuperAdmin');
const showPaywall = computed(() => !props.isEnabled && isOnChatwootCloud.value);
const i18nKey = computed(() =>
  isOnChatwootCloud.value ? 'PAYWALL' : 'ENTERPRISE_PAYWALL'
);

const goToBillingSettings = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

const handleClick = () => {
  emit('click');
};

const selectedAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const allAttributeOptions = computed(() =>
  (conversationAttributes.value || []).map(attribute => ({
    ...attribute,
    action: 'add',
    value: attribute.attributeKey,
    label: attribute.attributeDisplayName,
    type: attribute.attributeDisplayType,
  }))
);

const attributeOptions = computed(() => {
  const selectedKeysSet = new Set(selectedAttributeKeys.value);
  return allAttributeOptions.value.filter(
    attribute => !selectedKeysSet.has(attribute.value)
  );
});

const conversationRequiredAttributes = computed(() => {
  const attributeMap = new Map(
    allAttributeOptions.value.map(attr => [attr.value, attr])
  );
  return selectedAttributeKeys.value
    .map(key => attributeMap.get(key))
    .filter(Boolean);
});

const handleAddAttributesClick = event => {
  event.stopPropagation();
  toggleDropdown();
};

const saveRequiredAttributes = async keys => {
  try {
    toggleSaving(true);
    await updateAccount(
      { conversation_required_attributes: keys },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.ERROR'));
  } finally {
    toggleSaving(false);
    toggleDropdown(false);
  }
};

const handleAttributeAction = ({ value }) => {
  if (!value || isSaving.value) return;
  const updatedKeys = Array.from(
    new Set([...selectedAttributeKeys.value, value])
  );
  saveRequiredAttributes(updatedKeys);
};

const closeDropdown = () => {
  toggleDropdown(false);
};

const handleDelete = attribute => {
  if (isSaving.value) return;
  const updatedKeys = selectedAttributeKeys.value.filter(
    key => key !== attribute.value
  );
  saveRequiredAttributes(updatedKeys);
};
</script>

<template>
  <div
    v-if="isEnabled || showPaywall"
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
    @click="handleClick"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <div class="flex flex-col gap-2">
          <h3 class="text-base font-medium text-n-slate-12">
            {{ $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.TITLE') }}
          </h3>
          <p class="mb-0 text-sm text-n-slate-11">
            {{ $t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.DESCRIPTION') }}
          </p>
        </div>
        <div v-if="isEnabled" v-on-clickaway="closeDropdown" class="relative">
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.ADD.TITLE')"
            :is-loading="isSaving"
            :disabled="isSaving || attributeOptions.length === 0"
            @click="handleAddAttributesClick"
          />
          <DropdownMenu
            v-if="showDropdown"
            :menu-items="attributeOptions"
            show-search
            :search-placeholder="
              $t(
                'CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.ADD.SEARCH_PLACEHOLDER'
              )
            "
            class="top-full mt-1 w-52 ltr:right-0 rtl:left-0"
            @action="handleAttributeAction"
          />
        </div>
      </div>
    </div>

    <template v-if="isEnabled">
      <ConversationRequiredEmpty
        v-if="conversationRequiredAttributes.length === 0"
      />

      <ConversationRequiredAttributeItem
        v-for="attribute in conversationRequiredAttributes"
        :key="attribute.value"
        :attribute="attribute"
        @delete="handleDelete"
      />
    </template>

    <BasePaywallModal
      v-else
      class="mx-auto my-8"
      feature-prefix="CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES"
      :i18n-key="i18nKey"
      :is-on-chatwoot-cloud="isOnChatwootCloud"
      :is-super-admin="isSuperAdmin"
      @upgrade="goToBillingSettings"
    />
  </div>
</template>
