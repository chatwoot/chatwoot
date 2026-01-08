<script setup>
import { computed, onMounted, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import AttributeListItem from 'dashboard/components-next/ConversationWorkflow/AttributeListItem.vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

const { t } = useI18n();

const getters = useStoreGetters();
const store = useStore();
const { currentAccount } = useAccount();
const inboxes = useMapGetter('inboxes/getInboxes');

const [showAddPopup, toggleAddPopup] = useToggle(false);
const selectedTabIndex = ref(0);
const uiFlags = computed(() => getters['attributes/getUIFlags'].value);
const [showEditPopup, toggleEditPopup] = useToggle(false);
const [showDeletePopup, toggleDeletePopup] = useToggle(false);
const selectedAttribute = ref({});

const openAddPopup = () => {
  toggleAddPopup(true);
};
const hideAddPopup = () => {
  toggleAddPopup(false);
};
const hideEditPopup = () => {
  toggleEditPopup(false);
  selectedAttribute.value = {};
};
const closeDelete = () => {
  toggleDeletePopup(false);
  selectedAttribute.value = {};
};

const tabs = computed(() => {
  return [
    {
      key: 0,
      name: t('ATTRIBUTES_MGMT.TABS.CONVERSATION'),
    },
    {
      key: 1,
      name: t('ATTRIBUTES_MGMT.TABS.CONTACT'),
    },
  ];
});

const tabsForTabBar = computed(() =>
  tabs.value.map(tab => ({ label: tab.name, key: tab.key }))
);

onMounted(() => {
  store.dispatch('attributes/get');
});

const attributeModel = computed(() =>
  selectedTabIndex.value ? 'contact_attribute' : 'conversation_attribute'
);

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(attributeModel.value)
);

const onClickTabChange = tab => {
  selectedTabIndex.value = tab.key;
};

const handleEditAttribute = attribute => {
  selectedAttribute.value = attribute;
  toggleEditPopup(true);
};

const handleDeleteAttribute = attribute => {
  selectedAttribute.value = attribute;
  toggleDeletePopup(true);
};

const confirmDeleteAttribute = async () => {
  try {
    await store.dispatch('attributes/delete', selectedAttribute.value.id);
    useAlert(t('ATTRIBUTES_MGMT.DELETE.API.SUCCESS_MESSAGE'));
    closeDelete();
  } catch (error) {
    const errorMessage =
      error?.response?.message || t('ATTRIBUTES_MGMT.DELETE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const requiredAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const hasPreChatBadge = attribute => {
  return (inboxes.value || []).some(inbox => {
    const fields =
      inbox?.pre_chat_form_options?.pre_chat_fields ||
      inbox?.channel?.pre_chat_form_options?.pre_chat_fields ||
      [];
    return fields.some(field => field.name === attribute.attribute_key);
  });
};

const buildBadges = attribute => {
  const badges = [];
  if (hasPreChatBadge(attribute)) {
    badges.push({
      type: 'pre-chat',
    });
  }

  if (
    attribute.attribute_model === 'conversation_attribute' &&
    requiredAttributeKeys.value.includes(attribute.attribute_key)
  ) {
    badges.push({
      type: 'resolution',
    });
  }

  return badges;
};

const derivedAttributes = computed(() =>
  attributes.value.map(attribute => ({
    ...attribute,
    label: attribute.attribute_display_name,
    type: attribute.attribute_display_type,
    value: attribute.attribute_key,
    badges: buildBadges(attribute),
  }))
);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('ATTRIBUTES_MGMT.HEADER')"
        :description="$t('ATTRIBUTES_MGMT.DESCRIPTION')"
        :link-text="$t('ATTRIBUTES_MGMT.LEARN_MORE')"
        feature-name="custom_attributes"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('ATTRIBUTES_MGMT.HEADER_BTN_TXT')"
            @click="openAddPopup"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <TabBar
          :tabs="tabsForTabBar"
          :initial-active-tab="selectedTabIndex"
          class="max-w-xl"
          @tab-changed="onClickTabChange"
        />
        <div v-if="derivedAttributes.length" class="grid gap-3">
          <AttributeListItem
            v-for="attribute in derivedAttributes"
            :key="attribute.id"
            :attribute="attribute"
            :badges="attribute.badges"
            @edit="handleEditAttribute"
            @delete="handleDeleteAttribute"
          />
        </div>
        <p
          v-else
          class="flex-1 py-20 text-n-slate-12 flex items-center justify-center text-base"
        >
          {{ $t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404') }}
        </p>
      </div>
    </template>
    <AddAttribute
      v-if="showAddPopup"
      v-model:show="showAddPopup"
      :on-close="hideAddPopup"
      :selected-attribute-model-tab="selectedTabIndex"
    />
    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditAttribute
        :selected-attribute="selectedAttribute"
        :is-updating="uiFlags.isUpdating"
        @on-close="hideEditPopup"
      />
    </woot-modal>
    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="
        $t('ATTRIBUTES_MGMT.DELETE.CONFIRM.TITLE', {
          attributeName: selectedAttribute.attribute_display_name,
        })
      "
      :message="$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="`${$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.YES')} ${
        selectedAttribute.attribute_display_name || ''
      }`"
      :reject-text="$t('ATTRIBUTES_MGMT.DELETE.CONFIRM.NO')"
      :confirm-value="selectedAttribute.attribute_display_name"
      :confirm-place-holder-text="
        $t('ATTRIBUTES_MGMT.DELETE.CONFIRM.PLACE_HOLDER', {
          attributeName: selectedAttribute.attribute_display_name,
        })
      "
      @on-confirm="confirmDeleteAttribute"
      @on-close="closeDelete"
    />
  </SettingsLayout>
</template>
