<script setup>
import { ref } from 'vue';
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

const showDropdown = ref(false);

const handleClick = () => {
  emit('click');
};

const conversationRequiredAttributes = [
  {
    action: 'add',
    value: 'installation_type',
    label: 'Installation Type',
    type: 'Text',
  },
];

const attributeOptions = [
  {
    action: 'add',
    value: 'installation_type',
    label: 'Installation Type',
    type: 'Text',
  },
  {
    action: 'add',
    value: 'follow_up',
    label: 'Follow up with the customer',
  },
  {
    action: 'add',
    value: 'review_status',
    label: 'Review Status',
  },
  {
    action: 'add',
    value: 'priority',
    label: 'Priority',
  },
  {
    action: 'add',
    value: 'department',
    label: 'Department',
  },
  {
    action: 'add',
    value: 'customer_type',
    label: 'Customer Type',
  },
];

const handleAddAttributesClick = event => {
  event.stopPropagation();
  showDropdown.value = !showDropdown.value;
};

const handleAttributeAction = () => {
  showDropdown.value = false;
};

const closeDropdown = () => {
  showDropdown.value = false;
};

const handleDelete = () => {};
</script>

<template>
  <CardLayout
    class="[&>div]:px-0 [&>div]:py-0 [&>div]:divide-y [&>div]:divide-n-weak"
    @click="handleClick"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <h3 class="text-base font-medium text-n-slate-12">{{ title }}</h3>
        <div v-on-clickaway="closeDropdown" class="relative">
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.ADD.TITLE')"
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
            class="top-full mt-1 ltr:right-0 rtl:left-0"
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
