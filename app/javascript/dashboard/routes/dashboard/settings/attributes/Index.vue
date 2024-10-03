<script setup>
import { computed, onMounted, ref } from 'vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import AddAttribute from './AddAttribute.vue';
import CustomAttribute from './CustomAttribute.vue';
import SettingsLayout from '../SettingsLayout.vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

const { t } = useI18n();

const getters = useStoreGetters();
const store = useStore();

const showAddPopup = ref(false);
const selectedTabIndex = ref(0);
const uiFlags = computed(() => getters['attributes/getUIFlags'].value);

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
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

onMounted(() => {
  store.dispatch('attributes/get');
});

const attributeModel = computed(() =>
  selectedTabIndex.value ? 'contact_attribute' : 'conversation_attribute'
);

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(attributeModel.value)
);

const onClickTabChange = index => {
  selectedTabIndex.value = index;
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="!attributes.length"
    :no-records-message="$t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('ATTRIBUTES_MGMT.HEADER')"
        :description="$t('ATTRIBUTES_MGMT.DESCRIPTION')"
        :link-text="$t('ATTRIBUTES_MGMT.LEARN_MORE')"
        feature-name="custom_attributes"
      >
        <template #actions>
          <woot-button
            class="button nice rounded-md"
            icon="add-circle"
            @click="openAddPopup"
          >
            {{ $t('ATTRIBUTES_MGMT.HEADER_BTN_TXT') }}
          </woot-button>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #preBody>
      <woot-tabs
        class="font-medium [&_.tabs]:p-0 mb-4"
        :index="selectedTabIndex"
        @change="onClickTabChange"
      >
        <woot-tabs-item
          v-for="(tab, index) in tabs"
          :key="tab.key"
          :index="index"
          :name="tab.name"
          :show-badge="false"
        />
      </woot-tabs>
    </template>
    <template #body>
      <CustomAttribute
        :key="attributeModel"
        :attribute-model="attributeModel"
      />
    </template>
    <woot-modal
      v-if="showAddPopup"
      v-model:show="showAddPopup"
      :on-close="hideAddPopup"
    >
      <AddAttribute
        :on-close="hideAddPopup"
        :selected-attribute-model-tab="selectedTabIndex"
      />
    </woot-modal>
  </SettingsLayout>
</template>
