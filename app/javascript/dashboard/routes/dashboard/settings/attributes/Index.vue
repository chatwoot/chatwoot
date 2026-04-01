<script setup>
import { computed, onMounted, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { useAlert } from 'dashboard/composables';
import AddAttribute from './AddAttribute.vue';
import EditAttribute from './EditAttribute.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AttributeListItem from 'dashboard/components-next/ConversationWorkflow/AttributeListItem.vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';

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

const helpURL = computed(() => getHelpUrlForFeature('custom_attributes'));

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

const onSelectTab = tab => {
  selectedTabIndex.value = tab.key;
};

onMounted(() => {
  store.dispatch('attributes/get');
});

const attributeModel = computed(() =>
  selectedTabIndex.value ? 'contact_attribute' : 'conversation_attribute'
);

const attributes = computed(() =>
  getters['attributes/getAttributesByModel'].value(attributeModel.value)
);

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
    :loading-message="t('ATTRIBUTES_MGMT.LIST.LOADING')"
  >
    <template #header>
      <div
        class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('ATTRIBUTES_MGMT.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('ATTRIBUTES_MGMT.HEADER') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ t('ATTRIBUTES_MGMT.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('ATTRIBUTES_MGMT.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <Button
          solid
          teal
          lg
          icon="i-lucide-plus"
          :label="t('ATTRIBUTES_MGMT.HEADER_BTN_TXT')"
          class="w-full shrink-0 rounded-xl font-bold shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
          @click="openAddPopup"
        />
      </div>
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <div
          class="overflow-hidden rounded-2xl border border-outline-variant/10 shadow-xl"
        >
          <div
            class="flex flex-col gap-3 border-b border-surface-container-high/50 bg-surface-container-high/30 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6"
          >
            <p
              class="mb-0 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.LABEL') }}
            </p>
            <div
              class="inline-flex w-full gap-1 rounded-lg border border-outline-variant/15 bg-surface-container-low/80 p-1 sm:w-auto"
              role="tablist"
            >
              <button
                v-for="tab in tabs"
                :key="tab.key"
                type="button"
                role="tab"
                :aria-selected="selectedTabIndex === tab.key"
                class="flex-1 rounded-md px-4 py-2 text-sm font-semibold transition-all duration-200 sm:flex-none"
                :class="
                  selectedTabIndex === tab.key
                    ? 'bg-surface-container-low text-secondary shadow-sm'
                    : 'text-on-surface-variant hover:text-on-surface'
                "
                @click="onSelectTab(tab)"
              >
                {{ tab.name }}
              </button>
            </div>
          </div>

          <div class="bg-surface-container-low">
            <div
              v-if="derivedAttributes.length"
              class="divide-y divide-surface-container-high/30"
            >
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
              class="mb-0 px-6 py-16 text-center text-base text-on-surface-variant"
            >
              {{ t('ATTRIBUTES_MGMT.LIST.EMPTY_RESULT.404') }}
            </p>
          </div>
        </div>

        <p
          v-if="derivedAttributes.length"
          class="mb-0 text-xs font-medium text-on-primary-container"
        >
          {{
            t('ATTRIBUTES_MGMT.LIST.SHOWING_COUNT', {
              count: derivedAttributes.length,
            })
          }}
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
