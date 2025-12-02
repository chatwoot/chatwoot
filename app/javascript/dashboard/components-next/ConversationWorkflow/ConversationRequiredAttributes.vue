<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ConversationRequiredAttributeItem from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributeItem.vue';
import ConversationRequiredEmpty from 'dashboard/components-next/Conversation/ConversationRequiredEmpty.vue';

defineProps({
  title: { type: String, default: '' },
  description: { type: String, default: '' },
});

const emit = defineEmits(['click']);
const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();
const showDropdown = ref(false);
const isSaving = ref(false);
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);

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

const attributeOptions = computed(() =>
  allAttributeOptions.value.filter(
    attribute => !selectedAttributeKeys.value.includes(attribute.value)
  )
);

const conversationRequiredAttributes = computed(() =>
  selectedAttributeKeys.value
    .map(key =>
      allAttributeOptions.value.find(attribute => attribute.value === key)
    )
    .filter(Boolean)
);

const handleAddAttributesClick = event => {
  event.stopPropagation();
  showDropdown.value = !showDropdown.value;
};

const saveRequiredAttributes = async keys => {
  try {
    isSaving.value = true;
    await updateAccount(
      { conversation_required_attributes: keys },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.ERROR'));
  } finally {
    isSaving.value = false;
    showDropdown.value = false;
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
  showDropdown.value = false;
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
  <CardLayout
    class="[&>div]:px-0 [&>div]:py-0 [&>div]:gap-0 [&>div]:divide-y [&>div]:divide-n-weak"
    @click="handleClick"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <h3 class="text-base font-medium text-n-slate-12">{{ title }}</h3>
        <div v-on-clickaway="closeDropdown" class="relative">
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
      <p class="mb-0 text-sm text-n-slate-11">{{ description }}</p>
    </div>

    <ConversationRequiredEmpty
      v-if="conversationRequiredAttributes.length === 0"
    />

    <ConversationRequiredAttributeItem
      v-for="attribute in conversationRequiredAttributes"
      :key="attribute.value"
      :attribute="attribute"
      @delete="handleDelete"
    />
  </CardLayout>
</template>
