<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
  parameters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

// Initialize localProps with complete structure matching AMB composer
const localProps = ref({
  sections: props.properties.sections || [
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
  images: props.properties.images || [],
  received_title: props.properties.received_title || 'Please select an option',
  received_subtitle: props.properties.received_subtitle || '',
  received_image_identifier: props.properties.received_image_identifier || '',
  received_style: props.properties.received_style || 'icon',
  reply_title: props.properties.reply_title || 'Selection Made',
  reply_subtitle: props.properties.reply_subtitle || 'Your selection',
  reply_style: props.properties.reply_style || 'icon',
  reply_image_title: props.properties.reply_image_title || '',
  reply_image_subtitle: props.properties.reply_image_subtitle || '',
  reply_secondary_subtitle: props.properties.reply_secondary_subtitle || '',
  reply_tertiary_subtitle: props.properties.reply_tertiary_subtitle || '',
});

// Style options for received and reply messages
const styleOptions = [
  { value: 'icon', label: 'Icon' },
  { value: 'small', label: 'Small' },
  { value: 'large', label: 'Large' },
];

watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);

// Image Management
const addImage = () => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'image/*';
  input.onchange = e => {
    const file = e.target.files[0];
    if (file) {
      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        alert('Image file size must be less than 5MB');
        return;
      }

      const reader = new FileReader();
      reader.onload = event => {
        // Generate a user-friendly identifier based on filename
        const fileNameWithoutExt = file.name.replace(/\.[^/.]+$/, '');
        const cleanName = fileNameWithoutExt
          .replace(/[^a-zA-Z0-9]/g, '_')
          .toLowerCase();
        const imageIndex = localProps.value.images.length + 1;

        const imageData = {
          identifier: `${cleanName}_${imageIndex}`,
          data: event.target.result.split(',')[1], // Remove data:image/...;base64, prefix
          preview: event.target.result, // Keep full data URL for preview
          description: file.name,
          originalName: file.name,
          size: file.size,
        };
        localProps.value.images.push(imageData);
      };
      reader.readAsDataURL(file);
    }
  };
  input.click();
};

const removeImage = index => {
  const removedImage = localProps.value.images[index];

  // Clear any references to this image in items
  localProps.value.sections.forEach(section => {
    section.items.forEach(item => {
      if (item.image_identifier === removedImage.identifier) {
        item.image_identifier = '';
      }
    });
  });

  // Clear references in received/reply messages
  if (localProps.value.received_image_identifier === removedImage.identifier) {
    localProps.value.received_image_identifier = '';
  }

  localProps.value.images.splice(index, 1);
};

const formatFileSize = bytes => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / k ** i).toFixed(2)) + ' ' + sizes[i];
};

const getImageByIdentifier = identifier => {
  return localProps.value.images.find(img => img.identifier === identifier);
};

// Section Management
const addSection = () => {
  localProps.value.sections.push({
    title: `Section ${localProps.value.sections.length + 1}`,
    multipleSelection: false,
    items: [
      {
        title: 'Option 1',
        subtitle: 'Description 1',
        identifier: `item_${Date.now()}_1`,
        order: 0,
        image_identifier: '',
      },
    ],
  });
};

const removeSection = index => {
  if (localProps.value.sections.length > 1) {
    localProps.value.sections.splice(index, 1);
  }
};

// Item Management
const addListItem = sectionIndex => {
  const section = localProps.value.sections[sectionIndex];
  const itemCount = section.items.length;
  section.items.push({
    title: `Option ${itemCount + 1}`,
    subtitle: `Description ${itemCount + 1}`,
    identifier: `item_${Date.now()}_${itemCount + 1}`,
    order: itemCount,
    image_identifier: '',
  });
};

const removeListItem = (sectionIndex, itemIndex) => {
  localProps.value.sections[sectionIndex].items.splice(itemIndex, 1);
  // Update order for remaining items
  localProps.value.sections[sectionIndex].items.forEach((item, i) => {
    item.order = i;
  });
};

// Image Picker Modal
const showImagePicker = ref(false);
const currentImageSelection = ref({
  type: null, // 'item', 'received', 'reply'
  sectionIndex: null,
  itemIndex: null,
});

const openImagePicker = (type, sectionIndex = null, itemIndex = null) => {
  currentImageSelection.value = { type, sectionIndex, itemIndex };
  showImagePicker.value = true;
};

const selectImage = image => {
  const { type, sectionIndex, itemIndex } = currentImageSelection.value;

  if (type === 'received') {
    localProps.value.received_image_identifier = image.identifier;
  } else if (type === 'reply') {
    // Note: Reply message doesn't use image_identifier in the composer
    // but we keep the logic for consistency
  } else if (type === 'item' && sectionIndex !== null && itemIndex !== null) {
    localProps.value.sections[sectionIndex].items[itemIndex].image_identifier =
      image.identifier;
  }

  showImagePicker.value = false;
};

const closeImagePicker = () => {
  showImagePicker.value = false;
  currentImageSelection.value = {
    type: null,
    sectionIndex: null,
    itemIndex: null,
  };
};
</script>

<template>
  <div class="space-y-6">
    <!-- Received Message Configuration -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak"
    >
      <h4 class="text-sm font-semibold text-n-slate-12 mb-3">
        {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.RECEIVED_MESSAGE.TITLE') }}
      </h4>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.RECEIVED_MESSAGE.MESSAGE_TITLE'
              )
            }}
          </label>
          <input
            v-model="localProps.received_title"
            type="text"
            placeholder="Please select an option"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.RECEIVED_MESSAGE.SUBTITLE')
            }}
          </label>
          <input
            v-model="localProps.received_subtitle"
            type="text"
            placeholder="Optional subtitle"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.RECEIVED_MESSAGE.HEADER_IMAGE'
              )
            }}
          </label>
          <div class="grid grid-cols-4 gap-2">
            <!-- None option -->
            <div
              class="relative cursor-pointer border-2 rounded-lg overflow-hidden transition-all"
              :class="
                localProps.received_image_identifier === ''
                  ? 'border-n-blue-8 bg-n-blue-1'
                  : 'border-n-weak hover:border-n-blue-8'
              "
              @click="localProps.received_image_identifier = ''"
            >
              <div class="h-16 flex items-center justify-center bg-n-alpha-2">
                <span class="text-2xl">🚫</span>
              </div>
              <div class="text-xs text-center py-1 bg-n-solid-1">None</div>
            </div>
            <!-- Image options -->
            <div
              v-for="image in localProps.images"
              :key="image.identifier"
              class="relative cursor-pointer border-2 rounded-lg overflow-hidden transition-all"
              :class="
                localProps.received_image_identifier === image.identifier
                  ? 'border-n-blue-8 bg-n-blue-1'
                  : 'border-n-weak hover:border-n-blue-8'
              "
              @click="localProps.received_image_identifier = image.identifier"
            >
              <img
                :src="image.preview"
                :alt="image.originalName"
                class="w-full h-16 object-cover"
              />
              <div
                class="text-xs text-center py-1 bg-n-solid-1 truncate px-1"
                :title="image.originalName || image.description"
              >
                {{
                  (image.originalName || image.description).substring(0, 12)
                }}...
              </div>
              <div
                v-if="localProps.received_image_identifier === image.identifier"
                class="absolute top-1 right-1 bg-n-blue-9 rounded-full w-5 h-5 flex items-center justify-center"
              >
                <span class="text-white text-xs">✓</span>
              </div>
            </div>
          </div>
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.RECEIVED_MESSAGE.STYLE')
            }}
          </label>
          <select
            v-model="localProps.received_style"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7 h-10"
          >
            <option
              v-for="style in styleOptions"
              :key="style.value"
              :value="style.value"
            >
              {{ style.label }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Reply Message Configuration -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak"
    >
      <h4 class="text-sm font-semibold text-n-slate-12 mb-3">
        {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.TITLE') }}
      </h4>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.MESSAGE_TITLE'
              )
            }}
          </label>
          <input
            v-model="localProps.reply_title"
            type="text"
            placeholder="Selection Made"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.SUBTITLE')
            }}
          </label>
          <input
            v-model="localProps.reply_subtitle"
            type="text"
            placeholder="Your selection"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.IMAGE_TITLE')
            }}
          </label>
          <input
            v-model="localProps.reply_image_title"
            type="text"
            placeholder="Optional image title"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.IMAGE_SUBTITLE'
              )
            }}
          </label>
          <input
            v-model="localProps.reply_image_subtitle"
            type="text"
            placeholder="Optional image subtitle"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.SECONDARY_SUBTITLE'
              )
            }}
          </label>
          <input
            v-model="localProps.reply_secondary_subtitle"
            type="text"
            placeholder="Right-aligned title"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.TERTIARY_SUBTITLE'
              )
            }}
          </label>
          <input
            v-model="localProps.reply_tertiary_subtitle"
            type="text"
            placeholder="Right-aligned subtitle"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-1">
            {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.REPLY_MESSAGE.STYLE') }}
          </label>
          <select
            v-model="localProps.reply_style"
            class="w-full px-3 py-2 border border-n-slate-7 rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          >
            <option
              v-for="style in styleOptions"
              :key="style.value"
              :value="style.value"
            >
              {{ style.label }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Images Management -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak"
    >
      <div class="flex justify-between items-center mb-3">
        <h4 class="text-sm font-semibold text-n-slate-12">
          {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.IMAGES.TITLE') }}
        </h4>
        <Button icon="i-lucide-image-plus" xs blue @click="addImage">
          {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.IMAGES.ADD') }}
        </Button>
      </div>

      <div
        v-if="localProps.images.length === 0"
        class="text-sm text-n-slate-11 italic text-center py-6"
      >
        {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.IMAGES.EMPTY') }}
      </div>

      <div v-else class="grid grid-cols-3 gap-2">
        <div
          v-for="(image, index) in localProps.images"
          :key="index"
          class="relative group border border-n-weak rounded-lg overflow-hidden hover:border-n-blue-8 transition-colors"
        >
          <img
            v-if="image.preview"
            :src="image.preview"
            :alt="image.originalName || image.description"
            class="w-full h-24 object-cover"
          />
          <div
            v-else
            class="w-full h-24 bg-n-alpha-3 flex items-center justify-center"
          >
            <span class="text-2xl">📷</span>
          </div>
          <div
            class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-70 transition-opacity flex items-center justify-center"
          >
            <button
              class="opacity-0 group-hover:opacity-100 px-2 py-1 bg-n-ruby-9 text-white rounded text-xs hover:bg-n-ruby-10 transition-all"
              @click.stop="removeImage(index)"
            >
              Remove
            </button>
          </div>
          <div
            class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-75 text-white text-xs px-2 py-1 truncate"
            :title="`${image.originalName || image.description} (${formatFileSize(image.size)})`"
          >
            {{ image.originalName || image.description }}
          </div>
          <div
            class="absolute top-1 right-1 bg-black bg-opacity-75 text-white text-xs px-1.5 py-0.5 rounded"
          >
            {{ formatFileSize(image.size) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Sections and Items -->
    <div class="space-y-4">
      <div
        class="flex justify-between items-center mb-4 p-4 rounded-lg border-2 border-green-600 bg-green-50"
      >
        <h4 class="text-lg font-bold text-green-900">
          {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.SECTIONS.TITLE') }}
        </h4>
        <Button icon="i-lucide-plus" xs @click="addSection">
          {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.SECTIONS.ADD') }}
        </Button>
      </div>

      <!-- Each Section with its Items -->
      <div
        v-for="(section, sectionIndex) in localProps.sections"
        :key="sectionIndex"
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak"
      >
        <!-- Section Header -->
        <div class="flex items-start gap-3 mb-4">
          <div class="flex-1">
            <label
              class="block text-xs font-semibold text-n-slate-11 uppercase mb-2"
            >
              {{
                t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.SECTIONS.SECTION_TITLE')
              }}
              {{ sectionIndex + 1 }}
            </label>
            <input
              v-model="section.title"
              type="text"
              placeholder="Enter section title"
              class="w-full px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
          <Button
            v-if="localProps.sections.length > 1"
            icon="i-lucide-trash-2"
            ruby
            xs
            class="mt-6"
            @click="removeSection(sectionIndex)"
          >
            {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.SECTIONS.REMOVE') }}
          </Button>
        </div>

        <!-- Multiple Selection Checkbox -->
        <div class="mb-4 flex items-center gap-2">
          <input
            :id="`multipleSelection-${sectionIndex}`"
            v-model="section.multipleSelection"
            type="checkbox"
            class="w-4 h-4 text-n-blue-9 bg-n-solid-1 border-n-weak rounded focus:ring-n-blue-8 focus:ring-2"
          />
          <label
            :for="`multipleSelection-${sectionIndex}`"
            class="text-sm text-n-slate-12 cursor-pointer"
          >
            {{
              t(
                'TEMPLATES.BUILDER.LIST_PICKER_BLOCK.SECTIONS.MULTIPLE_SELECTION'
              )
            }}
          </label>
        </div>

        <!-- Section Items -->
        <div class="space-y-2 mb-3">
          <div
            v-for="(item, itemIndex) in section.items"
            :key="itemIndex"
            class="space-y-2"
          >
            <!-- Item Title and Subtitle -->
            <div class="grid grid-cols-[1fr_1fr_auto] gap-2">
              <input
                v-model="item.title"
                type="text"
                placeholder="Option title"
                class="px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7 text-sm"
              />
              <input
                v-model="item.subtitle"
                type="text"
                placeholder="Description"
                class="px-3 py-2 border border-n-weak rounded-lg bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7 text-sm"
              />
              <Button
                icon="i-lucide-trash-2"
                ruby
                xs
                @click="removeListItem(sectionIndex, itemIndex)"
              >
                Remove
              </Button>
            </div>

            <!-- Image Selection Row -->
            <div
              class="flex items-center gap-2 px-3 py-2 bg-n-alpha-1 rounded-lg"
            >
              <span class="text-xs text-n-slate-11 min-w-[80px]">Image:</span>

              <!-- Current image preview -->
              <div
                v-if="
                  item.image_identifier &&
                  getImageByIdentifier(item.image_identifier)
                "
                class="flex items-center gap-2 flex-1"
              >
                <img
                  :src="getImageByIdentifier(item.image_identifier).preview"
                  class="w-8 h-8 object-cover rounded border border-n-weak"
                  :alt="item.title"
                />
                <div class="flex-1 text-xs text-n-slate-11 truncate">
                  {{
                    getImageByIdentifier(item.image_identifier).originalName ||
                    getImageByIdentifier(item.image_identifier).description
                  }}
                </div>
                <button
                  class="px-2 py-1 text-xs bg-n-slate-3 text-n-slate-11 rounded hover:bg-n-slate-4"
                  @click="item.image_identifier = ''"
                >
                  Clear
                </button>
              </div>

              <!-- No image selected -->
              <span v-else class="flex-1 text-xs text-n-slate-10 italic">
                No image selected
              </span>

              <!-- Select image button -->
              <button
                v-if="localProps.images.length > 0"
                class="px-2 py-1 text-xs bg-n-blue-9 text-white rounded hover:bg-n-blue-10"
                @click="openImagePicker('item', sectionIndex, itemIndex)"
              >
                {{ item.image_identifier ? 'Change' : 'Select' }}
              </button>
              <span v-else class="text-xs text-n-slate-10 italic">
                Add images first
              </span>
            </div>
          </div>
        </div>

        <!-- Add Item Button -->
        <Button
          icon="i-lucide-plus"
          xs
          slate
          @click="addListItem(sectionIndex)"
        >
          {{ t('TEMPLATES.BUILDER.LIST_PICKER_BLOCK.ITEMS.ADD') }}
        </Button>
      </div>
    </div>

    <!-- Image Picker Modal -->
    <div
      v-if="showImagePicker"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click="closeImagePicker"
    >
      <div
        class="bg-white rounded-lg p-6 max-w-2xl w-full m-4 max-h-[80vh] overflow-y-auto"
        @click.stop
      >
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-n-slate-12">Select Image</h3>
          <button
            class="text-n-slate-11 hover:text-n-slate-12"
            @click="closeImagePicker"
          >
            ✕
          </button>
        </div>

        <div class="grid grid-cols-3 gap-3">
          <div
            v-for="image in localProps.images"
            :key="image.identifier"
            class="relative cursor-pointer border-2 border-n-weak rounded-lg overflow-hidden hover:border-n-blue-8 transition-colors"
            @click="selectImage(image)"
          >
            <img
              :src="image.preview"
              :alt="image.originalName"
              class="w-full h-32 object-cover"
            />
            <div
              class="text-xs text-center py-2 bg-n-solid-1 truncate px-2"
              :title="image.originalName || image.description"
            >
              {{ image.originalName || image.description }}
            </div>
          </div>
        </div>

        <div v-if="localProps.images.length === 0" class="text-center py-8">
          <p class="text-sm text-n-slate-11">No images available</p>
        </div>
      </div>
    </div>
  </div>
</template>
