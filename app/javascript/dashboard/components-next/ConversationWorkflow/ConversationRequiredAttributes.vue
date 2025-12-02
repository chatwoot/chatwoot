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

const attributeOptions = [
  {
    id: 1,
    attribute_display_name: 'Severity',
    attribute_display_type: 'text',
    attribute_description:
      'Status used by Pranav to check the quality of the conversations.',
    attribute_key: 'severity',
    regex_pattern: null,
    regex_cue: null,
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2023-12-19T02:18:08.226Z',
    updated_at: '2024-04-29T08:45:12.660Z',
  },
  {
    id: 3,
    attribute_display_name: 'Cloud customer',
    attribute_display_type: 'checkbox',
    attribute_description: 'Cloud customer',
    attribute_key: 'cloud_customer',
    regex_pattern: null,
    regex_cue: null,
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2023-12-20T05:33:32.866Z',
    updated_at: '2023-12-20T05:33:32.866Z',
  },
  {
    id: 4,
    attribute_display_name: 'Plan',
    attribute_display_type: 'list',
    attribute_description: 'Plan',
    attribute_key: 'plan',
    regex_pattern: null,
    regex_cue: null,
    attribute_values: ['gold', 'silver', 'bronze'],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2024-03-11T07:19:56.016Z',
    updated_at: '2024-03-11T07:19:56.016Z',
  },
  {
    id: 5,
    attribute_display_name: 'Signup date',
    attribute_display_type: 'date',
    attribute_description: 'Signup',
    attribute_key: 'signup_date',
    regex_pattern: null,
    regex_cue: null,
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2024-03-11T07:20:14.864Z',
    updated_at: '2024-03-11T07:20:14.864Z',
  },
  {
    id: 6,
    attribute_display_name: 'Home page',
    attribute_display_type: 'link',
    attribute_description: 'home page\n',
    attribute_key: 'home_page',
    regex_pattern: null,
    regex_cue: null,
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2024-03-11T07:20:31.415Z',
    updated_at: '2024-03-11T07:20:31.415Z',
  },
  {
    id: 7,
    attribute_display_name: 'Reg number',
    attribute_display_type: 'number',
    attribute_description: 'Reg number\n',
    attribute_key: 'reg_number',
    regex_pattern: null,
    regex_cue: null,
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2024-03-11T07:21:00.514Z',
    updated_at: '2024-03-11T07:21:00.514Z',
  },
].map(attribute => ({
  ...attribute,
  action: 'add',
  value: attribute.attribute_key,
  label: attribute.attribute_display_name,
  type: attribute.attribute_display_type,
}));

const conversationRequiredAttributes = attributeOptions.slice(0, 4);

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
