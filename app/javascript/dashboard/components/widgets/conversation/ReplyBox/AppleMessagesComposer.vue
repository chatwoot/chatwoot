 <script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import EnhancedTimePickerModal from 'dashboard/components-next/message/modals/EnhancedTimePickerModal.vue';

const emit = defineEmits(['send', 'cancel']);

const { t } = useI18n();

const activeTab = ref('list_picker');

// Enhanced Time Picker State
const showEnhancedTimePicker = ref(false);

// List Picker State
const listPickerData = ref({
  sections: [
    {
      title: 'Options',
      multiple_selection: false,
      items: [
        { title: 'Option 1', subtitle: 'Description 1' },
        { title: 'Option 2', subtitle: 'Description 2' },
      ],
    },
  ],
  images: [], // Support for images array
  received_title: 'Please select an option',
  received_subtitle: '',
  received_image_identifier: '', // Support for header image
  received_style: 'icon',
  reply_title: 'Selection Made',
  reply_subtitle: 'Your selection',
  reply_style: 'icon',
  reply_image_title: '',
  reply_image_subtitle: '',
  reply_secondary_subtitle: '',
  reply_tertiary_subtitle: '',
});

// Quick Reply State
const quickReplyData = ref({
  summary_text: 'Quick Reply Question',
  items: [{ title: 'Yes' }, { title: 'No' }],
});

// Time Picker State
const timePickerData = ref({
  event: {
    title: 'Schedule Appointment',
    description: 'Select a time slot',
    timeslots: [
      {
        startTime: new Date('2025-12-15T14:00:00Z').toISOString(), // Future date after Nov 30, 2025
        duration: 60,
      },
      {
        startTime: new Date('2025-12-15T15:00:00Z').toISOString(), // Additional slot
        duration: 60,
      },
    ],
  },
  timezone_offset: -480,
  received_title: 'Please pick a time',
  received_subtitle: 'Select your preferred time slot',
  received_style: 'icon',
  reply_title: 'Thank you!',
  reply_subtitle: '',
  reply_style: 'icon',
  reply_image_title: '',
  reply_image_subtitle: '',
  reply_secondary_subtitle: '',
  reply_tertiary_subtitle: '',
});

// Apple MSP style options
const styleOptions = [
  { value: 'icon', label: 'Icon (280x65)' },
  { value: 'small', label: 'Small (280x85)' },
  { value: 'large', label: 'Large (280x210)' },
];

// Image management
const addImage = () => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'image/*';
  input.onchange = e => {
    const file = e.target.files[0];
    if (file) {
      // Validate file size (max 5MB for better performance)
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
        const imageIndex = listPickerData.value.images.length + 1;

        const imageData = {
          identifier: `${cleanName}_${imageIndex}`,
          data: event.target.result.split(',')[1], // Remove data:image/...;base64, prefix
          preview: event.target.result, // Keep full data URL for preview
          description: file.name,
          originalName: file.name,
          size: file.size,
        };
        listPickerData.value.images.push(imageData);
      };
      reader.readAsDataURL(file);
    }
  };
  input.click();
};

// Format file size for display
const formatFileSize = bytes => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / k ** i).toFixed(2)) + ' ' + sizes[i];
};

const removeImage = index => {
  listPickerData.value.images.splice(index, 1);
};

const addListItem = sectionIndex => {
  const newItem = {
    title: 'New Item',
    subtitle: '',
  };
  listPickerData.value.sections[sectionIndex].items.push(newItem);
};

const removeListItem = (sectionIndex, itemIndex) => {
  listPickerData.value.sections[sectionIndex].items.splice(itemIndex, 1);
};

const addQuickReplyItem = () => {
  if (quickReplyData.value.items.length < 5) {
    quickReplyData.value.items.push({
      title: 'New Reply',
    });
  }
};

const removeQuickReplyItem = index => {
  if (quickReplyData.value.items.length > 2) {
    quickReplyData.value.items.splice(index, 1);
  }
};

const handleEnhancedTimePickerSave = timePickerData => {
  // Update the existing timePickerData with enhanced data
  Object.assign(timePickerData.value, timePickerData);
  showEnhancedTimePicker.value = false;
  
  // Debug logging
  console.log('🔥 AppleMessagesComposer - handleEnhancedTimePickerSave:', {
    timePickerData,
    timeslotsCount: timePickerData.event?.timeslots?.length,
    updatedTimePickerData: timePickerData.value
  });
  
  // Don't auto-send, just save the configuration
};

const handleEnhancedTimePickerSaveAndSend = enhancedData => {
  // Update the existing timePickerData with enhanced data
  Object.assign(timePickerData.value, enhancedData);
  showEnhancedTimePicker.value = false;

  // Debug logging
  console.log('🔥 AppleMessagesComposer - handleEnhancedTimePickerSaveAndSend:', {
    enhancedData,
    timeslotsCount: enhancedData.event?.timeslots?.length,
    updatedTimePickerData: timePickerData.value
  });

  // Automatically send the message
  sendAppleMessage();
};

const handleEnhancedTimePickerPreview = enhancedData => {
  // Update the existing timePickerData for preview
  Object.assign(timePickerData.value, enhancedData);
  
  // Debug logging for preview
  console.log('🔥 AppleMessagesComposer - Preview Data:', {
    enhancedData,
    timeslotsCount: enhancedData.event?.timeslots?.length,
    updatedTimePickerData: timePickerData.value
  });
};

const sendAppleMessage = () => {
  console.log('🔥 sendAppleMessage function called!');
  console.log('🔥 Active tab:', activeTab.value);
  console.log('🔥 listPickerData.value.images:', listPickerData.value.images);

  let content_type;
  let content_attributes;
  let content;

  switch (activeTab.value) {
    case 'list_picker':
      content_type = 'apple_list_picker';

      // Prepare content_attributes with images if they exist
      content_attributes = { ...listPickerData.value };

      console.log(
        '🔥 Raw listPickerData before processing:',
        JSON.stringify(listPickerData.value, null, 2)
      );
      console.log(
        '🔥 received_image_identifier value:',
        listPickerData.value.received_image_identifier
      );

      // Only include images if they exist and are not empty
      if (
        listPickerData.value.images &&
        listPickerData.value.images.length > 0
      ) {
        console.log(
          '🔥 Including images in content_attributes:',
          listPickerData.value.images.length
        );
        content_attributes.images = listPickerData.value.images.map(
          (img, index) => ({
            identifier: `image_${index}`,
            data: img.data,
            description: img.description || `Image ${index + 1}`,
          })
        );
        console.log('🔥 Mapped images:', content_attributes.images);

        // 🔥 CRITICAL FIX: Associate images with list items using imageIdentifier
        // Update sections to reference images by their identifiers
        if (
          content_attributes.sections &&
          content_attributes.sections.length > 0
        ) {
          content_attributes.sections.forEach((section, sectionIndex) => {
            if (section.items && section.items.length > 0) {
              section.items.forEach((item, itemIndex) => {
                // Associate each item with an image if available
                if (itemIndex < content_attributes.images.length) {
                  item.imageIdentifier =
                    content_attributes.images[itemIndex].identifier;
                  console.log(
                    `🔥 Associated item "${item.title}" with image "${content_attributes.images[itemIndex].identifier}"`
                  );
                }
              });
            }
          });
        }
      } else {
        console.log('🔥 No images to include');
      }

      content = listPickerData.value.received_title || 'List Picker Message';
      break;
    case 'quick_reply':
      content_type = 'apple_quick_reply';
      // Add default reply message fields for Quick Reply
      content_attributes = {
        ...quickReplyData.value,
        received_title: 'Please select an option',
        received_subtitle: '',
        received_style: 'small',
        reply_title: 'Selected: ${item.title}',
        reply_subtitle: '',
        reply_style: 'icon',
      };
      content = quickReplyData.value.summary_text || 'Quick Reply Message';
      break;
    case 'time_picker':
      content_type = 'apple_time_picker';
      content_attributes = timePickerData.value;
      content = timePickerData.value.event?.title || 'Time Picker Message';
      break;
  }

  console.log('🔥 Sending Apple Message:', {
    content_type,
    content_attributes,
    content,
  });
  console.log(
    '🔥 Content attributes detailed:',
    JSON.stringify(content_attributes, null, 2)
  );
  console.log(
    '🔥 Images in content_attributes:',
    content_attributes.images ? content_attributes.images.length : 'NO IMAGES'
  );
  console.log('🔥 About to emit send event');

  emit('send', {
    content_type,
    content_attributes,
    content,
  });

  console.log('🔥 Send event emitted');
};

const cancelComposer = () => {
  emit('cancel');
};
</script>

<template>
  <div class="apple-messages-composer bg-n-solid-1 text-n-slate-12">
    <!-- Tabs -->
    <div class="flex space-x-2 mb-4 border-b border-n-weak">
      <button
        v-for="tab in ['list_picker', 'quick_reply', 'time_picker']"
        :key="tab"
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeTab === tab
            ? 'border-n-blue-8 text-n-blue-11 dark:text-n-blue-10'
            : 'border-transparent text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9'
        "
        @click="activeTab = tab"
      >
        {{ tab.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) }}
      </button>
    </div>

    <!-- List Picker Tab -->
    <div v-if="activeTab === 'list_picker'" class="space-y-6">
      <!-- Received Message Configuration -->
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
      >
        <h4
          class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
        >
          Received Message
        </h4>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Title</label>
            <input
              v-model="listPickerData.received_title"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Please select an option"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Subtitle</label>
            <input
              v-model="listPickerData.received_subtitle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Optional subtitle"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Header Image</label>
            <select
              v-model="listPickerData.received_image_identifier"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 h-10"
            >
              <option value="">No header image</option>
              <option
                v-for="(image, index) in listPickerData.images"
                :key="image.identifier"
                :value="`image_${index}`"
              >
                {{ image.originalName || image.description }} (image_{{
                  index
                }})
              </option>
            </select>
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Style</label>
            <select
              v-model="listPickerData.received_style"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 h-10"
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

      <!-- Images Management - MOVED UP for better UX flow -->
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
      >
        <div class="flex justify-between items-center mb-3">
          <h4
            class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11"
          >
            Images
          </h4>
          <button
            class="px-3 py-1 bg-n-blue-9 dark:bg-n-blue-10 text-white dark:text-n-slate-12 rounded text-sm hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-colors"
            @click="addImage"
          >
            Add Image
          </button>
        </div>
        <div
          v-if="listPickerData.images.length === 0"
          class="text-sm text-n-slate-11 dark:text-n-slate-10 italic"
        >
          No images added. Images can be referenced by list items.
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="(image, index) in listPickerData.images"
            :key="index"
            class="flex items-center justify-between p-3 bg-n-solid-1 dark:bg-n-alpha-2 rounded-lg border border-n-weak dark:border-n-alpha-6"
          >
            <div class="flex items-center space-x-3">
              <!-- Enhanced image preview -->
              <div
                class="w-12 h-12 bg-n-alpha-3 dark:bg-n-alpha-4 rounded-lg flex items-center justify-center overflow-hidden"
              >
                <img
                  v-if="image.preview"
                  :src="image.preview"
                  :alt="image.originalName || image.description"
                  class="w-full h-full object-cover rounded-lg"
                />
                <span v-else class="text-lg">📷</span>
              </div>
              <div>
                <div
                  class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11"
                >
                  {{ image.originalName || image.description }}
                </div>
                <div class="text-xs text-n-slate-11 dark:text-n-slate-10">
                  ID: {{ image.identifier }}
                </div>
                <div class="text-xs text-n-slate-10 dark:text-n-slate-9">
                  {{ formatFileSize(image.size) }}
                </div>
              </div>
            </div>
            <button
              class="px-3 py-1 bg-n-ruby-9 dark:bg-n-ruby-10 text-white dark:text-n-slate-12 rounded text-xs hover:bg-n-ruby-10 dark:hover:bg-n-ruby-11 transition-colors"
              @click="removeImage(index)"
            >
              Remove
            </button>
          </div>
        </div>
      </div>

      <!-- Section Title -->
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
      >
        <h4
          class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
        >
          Section Title
        </h4>
        <div class="space-y-3">
          <div
            v-for="(section, sectionIndex) in listPickerData.sections"
            :key="sectionIndex"
          >
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
              >Section {{ sectionIndex + 1 }} Title</label>
            <input
              v-model="section.title"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Enter section title"
            />
          </div>
        </div>
      </div>

      <!-- Options/List Items -->
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
      >
        <h4
          class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
        >
          Options
        </h4>
        <div
          v-for="(section, sectionIndex) in listPickerData.sections"
          :key="sectionIndex"
          class="space-y-3"
        >
          <div class="space-y-2">
            <div
              v-for="(item, itemIndex) in section.items"
              :key="itemIndex"
              class="grid grid-cols-4 gap-2"
            >
              <div class="flex flex-col">
                <input
                  v-model="item.title"
                  class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
                  style="height: 40px"
                  placeholder="Option title"
                />
              </div>
              <div class="flex flex-col">
                <input
                  v-model="item.subtitle"
                  class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
                  style="height: 40px"
                  placeholder="Description"
                />
              </div>
              <div class="flex flex-col">
                <select
                  v-model="item.image_identifier"
                  class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
                  style="height: 40px"
                >
                  <option value="">No image</option>
                  <option
                    v-for="image in listPickerData.images"
                    :key="image.identifier"
                    :value="image.identifier"
                  >
                    {{ image.originalName || image.description }} ({{
                      image.identifier
                    }})
                  </option>
                </select>
              </div>
              <div class="flex flex-col">
                <button
                  class="w-full px-3 py-2 bg-n-ruby-9 dark:bg-n-ruby-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-ruby-10 dark:hover:bg-n-ruby-11 transition-colors"
                  style="height: 40px"
                  @click="removeListItem(sectionIndex, itemIndex)"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>

          <button
            class="px-3 py-2 bg-n-green-9 dark:bg-n-green-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-green-10 dark:hover:bg-n-green-11 transition-colors"
            @click="addListItem(sectionIndex)"
          >
            Add Item
          </button>
        </div>
      </div>

      <!-- Reply Message Configuration -->
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
      >
        <h4
          class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
        >
          Reply Message
        </h4>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Title</label>
            <input
              v-model="listPickerData.reply_title"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Selection Made"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Subtitle</label>
            <input
              v-model="listPickerData.reply_subtitle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Your selection"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Image Title</label>
            <input
              v-model="listPickerData.reply_image_title"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Optional image title"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Image Subtitle</label>
            <input
              v-model="listPickerData.reply_image_subtitle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Optional image subtitle"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Secondary Subtitle</label>
            <input
              v-model="listPickerData.reply_secondary_subtitle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Right-aligned title"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Tertiary Subtitle</label>
            <input
              v-model="listPickerData.reply_tertiary_subtitle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              placeholder="Right-aligned subtitle"
            />
          </div>
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-1"
              >Style</label>
            <select
              v-model="listPickerData.reply_style"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
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
    </div>

    <!-- Quick Reply Tab -->
    <div v-if="activeTab === 'quick_reply'" class="space-y-4">
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
      >
        <label
          class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
          >Question</label>
        <input
          v-model="quickReplyData.summary_text"
          class="w-full px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
          placeholder="Quick Reply Question"
        />
      </div>

      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6 space-y-2"
      >
        <label
          class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11"
          >Reply Options (2-5)</label>
        <div
          v-for="(item, index) in quickReplyData.items"
          :key="index"
          class="flex space-x-2"
        >
          <input
            v-model="item.title"
            class="flex-1 px-3 py-2 border border-n-weak dark:border-n-alpha-6 rounded-lg bg-n-solid-1 dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
            style="height: 40px"
            placeholder="Reply option"
          />
          <button
            class="px-3 py-2 bg-n-ruby-9 dark:bg-n-ruby-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-ruby-10 dark:hover:bg-n-ruby-11 transition-colors"
            style="height: 40px"
            :disabled="quickReplyData.items.length <= 2"
            @click="removeQuickReplyItem(index)"
          >
            Remove
          </button>
        </div>

        <button
          class="px-3 py-2 bg-n-green-9 dark:bg-n-green-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-green-10 dark:hover:bg-n-green-11 transition-colors"
          :disabled="quickReplyData.items.length >= 5"
          @click="addQuickReplyItem"
        >
          Add Option
        </button>
      </div>
    </div>

    <!-- Time Picker Tab -->
    <div v-if="activeTab === 'time_picker'" class="space-y-6">
      <!-- Enhanced Time Picker Interface -->
      <div
        class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-alpha-6"
      >
        <div class="flex items-center justify-between mb-4">
          <div>
            <h4
              class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11"
            >
              Time Picker Configuration
            </h4>
            <p class="text-xs text-n-slate-11 dark:text-n-slate-3 mt-1">
              Configure your appointment scheduling with advanced time slot
              management
            </p>
          </div>
          <button
            class="px-4 py-2 bg-n-blue-9 dark:bg-n-blue-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-colors"
            @click="showEnhancedTimePicker = true"
          >
            Configure Time Slots
          </button>
        </div>

        <!-- Quick Preview -->
        <div
          v-if="timePickerData.event?.timeslots?.length > 0"
          class="mt-4 p-3 bg-n-green-1 dark:bg-n-green-2 border border-n-green-6 dark:border-n-green-8 rounded-lg"
        >
          <div
            class="text-sm font-medium text-n-green-11 dark:text-n-green-10 mb-2"
          >
            {{ timePickerData.event.title || 'Time Picker' }} -
            {{ timePickerData.event.timeslots.length }} slot(s) configured
          </div>
          <div class="text-xs text-n-green-10 dark:text-n-green-9">
            Ready to send to customers
          </div>
        </div>
      </div>
    </div>
    <!-- Actions -->
    <div
      class="flex justify-end space-x-3 mt-6 pt-4 border-t border-n-weak dark:border-n-slate-6"
    >
      <button
        class="px-4 py-2 text-n-slate-11 dark:text-n-slate-10 hover:text-n-slate-12 dark:hover:text-n-slate-9 transition-colors"
        @click="cancelComposer"
      >
        Cancel
      </button>
      <button
        class="px-4 py-2 bg-n-blue-9 dark:bg-n-blue-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-colors"
        @click="
          () => {
            console.log('🔥 Send button clicked!');
            sendAppleMessage();
          }
        "
      >
        Send Message
      </button>
    </div>

    <!-- Enhanced Time Picker Modal -->
    <EnhancedTimePickerModal
      :show="showEnhancedTimePicker"
      :initial-data="timePickerData"
      :business-hours="{
        monday: { start: '09:00', end: '17:00', enabled: true },
        tuesday: { start: '09:00', end: '17:00', enabled: true },
        wednesday: { start: '09:00', end: '17:00', enabled: true },
        thursday: { start: '09:00', end: '17:00', enabled: true },
        friday: { start: '09:00', end: '17:00', enabled: true },
        saturday: { start: '10:00', end: '16:00', enabled: false },
        sunday: { start: '10:00', end: '16:00', enabled: false },
      }"
      :timezone="Intl.DateTimeFormat().resolvedOptions().timeZone"
      :existing-bookings="[]"
      :service-duration="60"
      @close="showEnhancedTimePicker = false"
      @save="handleEnhancedTimePickerSave"
      @preview="handleEnhancedTimePickerPreview"
      @saveAndSend="handleEnhancedTimePickerSaveAndSend"
    />
  </div>
</template>

<style scoped>
.apple-messages-composer {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Ensure proper dark mode transitions */
.apple-messages-composer * {
  transition:
    background-color 0.2s ease,
    border-color 0.2s ease,
    color 0.2s ease;
}

/* Fix select dropdown appearance in dark mode */
.apple-messages-composer select {
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
  background-position: right 0.5rem center;
  background-repeat: no-repeat;
  background-size: 1.5em 1.5em;
  padding-right: 2.5rem;
  height: 40px !important;
}

@media (prefers-color-scheme: dark) {
  .apple-messages-composer select {
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%9ca3af' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3e%3c/svg%3e");
  }
}

/* Ensure consistent height for all form elements */
.apple-messages-composer input,
.apple-messages-composer select,
.apple-messages-composer button {
  height: 40px !important;
  min-height: 40px;
  box-sizing: border-box;
}

/* Ensure proper alignment in grid layouts */
.apple-messages-composer .grid {
  align-items: stretch;
}

.apple-messages-composer .grid > div {
  display: flex;
  flex-direction: column;
  justify-content: stretch;
}

/* Fix button alignment */
.apple-messages-composer button {
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
