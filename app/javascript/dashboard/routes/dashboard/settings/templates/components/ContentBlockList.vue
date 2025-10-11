<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import ContentBlockEditor from './ContentBlockEditor.vue';

const props = defineProps({
  blocks: {
    type: Array,
    default: () => [],
  },
  parameters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:blocks']);

const { t } = useI18n();

// State
const showBlockTypeSelector = ref(false);
const editingBlockIndex = ref(null);
const draggingIndex = ref(null);

// Block types with their configurations
const blockTypes = computed(() => [
  {
    type: 'text',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.TEXT'),
    icon: 'i-lucide-type',
    description: 'Simple text message with variable support',
  },
  {
    type: 'time_picker',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.TIME_PICKER'),
    icon: 'i-lucide-clock',
    description: 'Interactive time slot selector',
  },
  {
    type: 'list_picker',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.LIST_PICKER'),
    icon: 'i-lucide-list',
    description: 'Interactive list selection',
  },
  {
    type: 'payment',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.PAYMENT'),
    icon: 'i-lucide-credit-card',
    description: 'Payment request form',
  },
  {
    type: 'form',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.FORM'),
    icon: 'i-lucide-file-text',
    description: 'Custom form with multiple fields',
  },
  {
    type: 'button_group',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.BUTTON_GROUP'),
    icon: 'i-lucide-square',
    description: 'Group of action buttons',
  },
  {
    type: 'quick_reply',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.QUICK_REPLY'),
    icon: 'i-lucide-message-square',
    description: 'Quick reply suggestions',
  },
  {
    type: 'media',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TYPES.MEDIA'),
    icon: 'i-lucide-image',
    description: 'Image or video content',
  },
]);

// Methods
const getDefaultProperties = type => {
  const defaults = {
    text: {
      content: '',
    },
    time_picker: {
      eventTitle: '',
      eventDescription: '',
      timeslots: [],
      timezoneOffset: 0,
      images: [],
      receivedTitle: 'Please pick a time',
      receivedSubtitle: 'Select your preferred time slot',
      receivedImageIdentifier: '',
      receivedStyle: 'large',
      replyTitle: 'Thank you!',
      replySubtitle: '',
      replyImageIdentifier: '',
      replyStyle: 'large',
      replyImageTitle: '',
      replyImageSubtitle: '',
      replySecondarySubtitle: '',
      replyTertiarySubtitle: '',
    },
    list_picker: {
      sections: [
        {
          title: 'Options',
          multipleSelection: false,
          items: [
            {
              title: 'Option 1',
              subtitle: 'Description 1',
              identifier: 'item_1',
              order: 0,
              image_identifier: '',
            },
            {
              title: 'Option 2',
              subtitle: 'Description 2',
              identifier: 'item_2',
              order: 1,
              image_identifier: '',
            },
          ],
        },
      ],
      images: [],
      received_title: 'Please select an option',
      received_subtitle: '',
      received_image_identifier: '',
      received_style: 'icon',
      reply_title: 'Selection Made',
      reply_subtitle: '',
      reply_style: 'icon',
      reply_image_title: '',
      reply_image_subtitle: '',
      reply_secondary_subtitle: '',
      reply_tertiary_subtitle: '',
    },
    payment: {
      merchantName: '{{merchant_name}}',
      amount: '{{amount}}',
      currency: 'USD',
      description: '{{description}}',
    },
    form: {
      title: '',
      fields: [],
    },
    button_group: {
      buttons: [],
    },
    quick_reply: {
      summaryText: 'Quick Reply Question',
      items: [{ title: 'Yes' }, { title: 'No' }],
    },
    media: {
      url: '',
      type: 'image',
    },
  };

  return defaults[type] || {};
};

const addBlock = type => {
  const newBlock = {
    blockType: type,
    properties: getDefaultProperties(type),
    orderIndex: props.blocks.length,
    conditions: null,
  };

  const updatedBlocks = [...props.blocks, newBlock];
  emit('update:blocks', updatedBlocks);
  showBlockTypeSelector.value = false;

  // Auto-open editor for new block
  editingBlockIndex.value = updatedBlocks.length - 1;
};

const updateBlock = (index, properties) => {
  const updatedBlocks = [...props.blocks];
  updatedBlocks[index] = {
    ...updatedBlocks[index],
    properties,
  };
  emit('update:blocks', updatedBlocks);
};

const deleteBlock = index => {
  const updatedBlocks = props.blocks.filter((_, i) => i !== index);
  // Update order indices
  updatedBlocks.forEach((block, i) => {
    block.orderIndex = i;
  });
  emit('update:blocks', updatedBlocks);

  if (editingBlockIndex.value === index) {
    editingBlockIndex.value = null;
  }
};

const moveBlock = (fromIndex, toIndex) => {
  if (toIndex < 0 || toIndex >= props.blocks.length) return;

  const updatedBlocks = [...props.blocks];
  const [movedBlock] = updatedBlocks.splice(fromIndex, 1);
  updatedBlocks.splice(toIndex, 0, movedBlock);

  // Update order indices
  updatedBlocks.forEach((block, i) => {
    block.orderIndex = i;
  });

  emit('update:blocks', updatedBlocks);

  // Update editing index if needed
  if (editingBlockIndex.value === fromIndex) {
    editingBlockIndex.value = toIndex;
  }
};

const onDragStart = index => {
  draggingIndex.value = index;
};

const onDragOver = (event, index) => {
  event.preventDefault();
  if (draggingIndex.value !== null && draggingIndex.value !== index) {
    moveBlock(draggingIndex.value, index);
    draggingIndex.value = index;
  }
};

const onDragEnd = () => {
  draggingIndex.value = null;
};

const toggleBlockEditor = index => {
  editingBlockIndex.value = editingBlockIndex.value === index ? null : index;
};

const getBlockIcon = type => {
  const blockType = blockTypes.value.find(bt => bt.type === type);
  return blockType ? blockType.icon : 'i-lucide-box';
};

const getBlockLabel = type => {
  const blockType = blockTypes.value.find(bt => bt.type === type);
  return blockType ? blockType.label : type;
};
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h3 class="text-lg font-semibold text-n-slate-12">
        {{ t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ t('TEMPLATES.BUILDER.CONTENT_BLOCKS.DESCRIPTION') }}
      </p>
    </div>

    <!-- Empty State -->
    <div
      v-if="blocks.length === 0"
      class="text-center py-12 bg-n-slate-2 rounded-lg"
    >
      <i class="i-lucide-blocks text-4xl text-n-slate-8 mb-3" />
      <p class="text-sm text-n-slate-11 mb-4">
        {{ t('TEMPLATES.BUILDER.CONTENT_BLOCKS.EMPTY') }}
      </p>
      <Button
        icon="i-lucide-plus"
        :label="t('TEMPLATES.BUILDER.CONTENT_BLOCKS.ADD')"
        @click="showBlockTypeSelector = true"
      />
    </div>

    <!-- Blocks List -->
    <div v-else class="space-y-3">
      <div
        v-for="(block, index) in blocks"
        :key="index"
        class="border border-n-slate-7 rounded-lg bg-white transition-all"
        :class="[
          draggingIndex === index ? 'opacity-50' : '',
          editingBlockIndex === index ? 'ring-2 ring-n-blue-7' : '',
        ]"
        draggable="true"
        @dragstart="onDragStart(index)"
        @dragover="e => onDragOver(e, index)"
        @dragend="onDragEnd"
      >
        <!-- Block Header -->
        <div class="flex items-center gap-3 p-4">
          <!-- Drag Handle -->
          <button
            class="cursor-move text-n-slate-9 hover:text-n-slate-12"
            @mousedown.stop
          >
            <i class="i-lucide-grip-vertical text-lg" />
          </button>

          <!-- Block Icon and Info -->
          <div class="flex items-center gap-3 flex-1">
            <div
              class="w-10 h-10 rounded-lg bg-n-blue-2 flex items-center justify-center"
            >
              <i
                class="text-lg text-n-blue-11"
                :class="[getBlockIcon(block.blockType)]"
              />
            </div>
            <div>
              <div class="font-medium text-n-slate-12">
                {{ getBlockLabel(block.blockType) }}
              </div>
              <div class="text-xs text-n-slate-10">
                {{
                  t('TEMPLATES.BUILDER.CONTENT_BLOCKS.BLOCK_POSITION', {
                    index: index + 1,
                    total: blocks.length,
                  })
                }}
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-1">
            <Button
              v-tooltip.top="t('TEMPLATES.BUILDER.CONTENT_BLOCKS.MOVE_UP')"
              icon="i-lucide-chevron-up"
              slate
              xs
              faded
              :disabled="index === 0"
              @click="moveBlock(index, index - 1)"
            />
            <Button
              v-tooltip.top="t('TEMPLATES.BUILDER.CONTENT_BLOCKS.MOVE_DOWN')"
              icon="i-lucide-chevron-down"
              slate
              xs
              faded
              :disabled="index === blocks.length - 1"
              @click="moveBlock(index, index + 1)"
            />
            <Button
              v-tooltip.top="
                t('TEMPLATES.BUILDER.CONTENT_BLOCKS.BLOCK_SETTINGS')
              "
              :icon="
                editingBlockIndex === index
                  ? 'i-lucide-settings'
                  : 'i-lucide-settings'
              "
              slate
              xs
              faded
              :class="[
                editingBlockIndex === index ? 'bg-n-blue-2 text-n-blue-11' : '',
              ]"
              @click="toggleBlockEditor(index)"
            />
            <Button
              v-tooltip.top="t('TEMPLATES.BUILDER.CONTENT_BLOCKS.DELETE_BLOCK')"
              icon="i-lucide-trash-2"
              ruby
              xs
              faded
              @click="deleteBlock(index)"
            />
          </div>
        </div>

        <!-- Block Editor (Expandable) -->
        <div
          v-if="editingBlockIndex === index"
          class="border-t border-n-slate-7 p-4 bg-n-slate-1"
        >
          <ContentBlockEditor
            :block-type="block.blockType"
            :properties="block.properties"
            :parameters="parameters"
            @update:properties="props => updateBlock(index, props)"
          />
        </div>
      </div>
    </div>

    <!-- Block Type Selector Modal -->
    <woot-modal
      v-model:show="showBlockTypeSelector"
      :on-close="() => (showBlockTypeSelector = false)"
    >
      <div class="w-full max-w-4xl p-6">
        <h3 class="text-xl font-semibold text-n-slate-12 mb-6">
          {{ t('TEMPLATES.BUILDER.CONTENT_BLOCKS.ADD') }}
        </h3>

        <div class="grid grid-cols-2 gap-4">
          <button
            v-for="blockType in blockTypes"
            :key="blockType.type"
            class="flex items-start gap-4 p-4 border-2 border-n-slate-7 rounded-lg hover:border-n-blue-7 hover:bg-n-blue-1 transition-all text-left"
            @click="addBlock(blockType.type)"
          >
            <div
              class="w-12 h-12 rounded-lg bg-n-blue-2 flex items-center justify-center flex-shrink-0"
            >
              <i class="text-2xl text-n-blue-11" :class="[blockType.icon]" />
            </div>
            <div class="flex-1">
              <div class="font-medium text-n-slate-12 mb-1">
                {{ blockType.label }}
              </div>
              <div class="text-sm text-n-slate-10">
                {{ blockType.description }}
              </div>
            </div>
          </button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
