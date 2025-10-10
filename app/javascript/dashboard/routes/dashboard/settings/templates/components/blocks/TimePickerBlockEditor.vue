<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { addDays } from 'date-fns';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

// Initialize with default values matching AMB composer
const localProps = ref({
  // Event details
  eventTitle: '',
  eventDescription: '',
  timeslots: [],
  timezoneOffset: 0,

  // Received message
  receivedTitle: 'Please pick a time',
  receivedSubtitle: 'Select your preferred time slot',
  receivedImageIdentifier: '',
  receivedStyle: 'large',

  // Reply message
  replyTitle: 'Thank you!',
  replySubtitle: '',
  replyImageIdentifier: '',
  replyStyle: 'large',
  replyImageTitle: '',
  replyImageSubtitle: '',
  replySecondarySubtitle: '',
  replyTertiarySubtitle: '',

  // Images
  images: [],

  ...props.properties,
});

// Style options matching AMB
const styleOptions = [
  { value: 'icon', label: 'Icon (280x65)' },
  { value: 'small', label: 'Small (280x85)' },
  { value: 'large', label: 'Large (280x210)' },
];

// Available images from properties
const availableImages = computed(() => {
  return localProps.value.images || [];
});

// Auto-sync reply image with received image
watch(
  () => localProps.value.receivedImageIdentifier,
  newIdentifier => {
    if (!localProps.value.replyImageIdentifier) {
      localProps.value.replyImageIdentifier = newIdentifier;
    }
  },
  { immediate: true }
);

// Emit changes
watch(
  localProps,
  newValue => {
    emit('update:properties', newValue);
  },
  { deep: true }
);

// Timeslot management
const addTimeslot = () => {
  const newSlot = {
    startTime: new Date(addDays(new Date(), 1)).toISOString(),
    duration: 3600, // 60 minutes in seconds
  };
  localProps.value.timeslots.push(newSlot);
};

const removeTimeslot = index => {
  localProps.value.timeslots.splice(index, 1);
};

// Image upload handler
const handleImageUpload = () => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'image/*';
  input.onchange = e => {
    const file = e.target.files[0];
    if (file) {
      const MAX_SIZE = 5 * 1024 * 1024; // 5MB
      if (file.size > MAX_SIZE) {
        // Use console.warn instead of alert
        // eslint-disable-next-line no-console
        console.warn('Image file size must be less than 5MB');
        return;
      }

      const reader = new FileReader();
      reader.onload = event => {
        const fileNameWithoutExt = file.name.replace(/\.[^/.]+$/, '');
        const cleanName = fileNameWithoutExt
          .replace(/[^a-zA-Z0-9]/g, '_')
          .toLowerCase();
        const imageIndex = localProps.value.images.length + 1;

        const imageData = {
          identifier: `${cleanName}_${imageIndex}`,
          data: event.target.result.split(',')[1],
          preview: event.target.result,
          description: file.name,
          originalName: file.name,
          size: file.size,
        };

        if (!localProps.value.images) {
          localProps.value.images = [];
        }
        localProps.value.images.push(imageData);
      };
      reader.readAsDataURL(file);
    }
  };
  input.click();
};

const removeImage = index => {
  localProps.value.images.splice(index, 1);
};

const formatFileSize = bytes => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / k ** i).toFixed(2)) + ' ' + sizes[i];
};

// Initialize empty arrays if needed
onMounted(() => {
  if (!localProps.value.images) {
    localProps.value.images = [];
  }
  if (!localProps.value.timeslots) {
    localProps.value.timeslots = [];
  }
});
</script>

<template>
  <div class="space-y-6">
    <!-- Images Section -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
    >
      <div class="flex justify-between items-center mb-3">
        <h4 class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11">
          {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.IMAGES.TITLE') }}
        </h4>
        <button
          class="px-3 py-1 bg-n-blue-9 dark:bg-n-blue-10 text-white rounded text-sm hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-colors"
          @click="handleImageUpload"
        >
          {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.IMAGES.ADD') }}
        </button>
      </div>

      <div
        v-if="availableImages.length === 0"
        class="text-sm text-n-slate-11 dark:text-n-slate-10 italic text-center py-4"
      >
        {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.IMAGES.NONE') }}
      </div>
      <div v-else class="grid grid-cols-3 gap-2">
        <div
          v-for="(image, index) in availableImages"
          :key="index"
          class="relative group border border-n-weak dark:border-n-slate-6 rounded-lg overflow-hidden hover:border-n-blue-8 dark:hover:border-n-blue-9 transition-colors"
        >
          <img
            v-if="image.preview"
            :src="image.preview"
            :alt="image.originalName || image.description"
            class="w-full h-24 object-cover"
          />
          <div
            class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-70 transition-opacity flex items-center justify-center"
          >
            <button
              class="opacity-0 group-hover:opacity-100 px-2 py-1 bg-n-ruby-9 text-white rounded text-xs hover:bg-n-ruby-10 transition-all"
              @click.stop="removeImage(index)"
            >
              {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.IMAGES.REMOVE') }}
            </button>
          </div>
          <div
            class="absolute bottom-0 left-0 right-0 bg-black bg-opacity-75 text-white text-xs px-2 py-1 truncate"
            :title="`${image.originalName || image.description} (${formatFileSize(image.size)})`"
          >
            {{ image.originalName || image.description }}
          </div>
        </div>
      </div>
    </div>

    <!-- Event Details -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
    >
      <h4
        class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
      >
        {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.TITLE') }}
      </h4>
      <div class="space-y-3">
        <div>
          <label
            class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
          >
            {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.EVENT_TITLE') }}
          </label>
          <input
            v-model="localProps.eventTitle"
            type="text"
            :placeholder="
              t(
                'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.EVENT_TITLE_PLACEHOLDER'
              )
            "
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
          >
            {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.DESCRIPTION') }}
          </label>
          <textarea
            v-model="localProps.eventDescription"
            rows="2"
            :placeholder="
              t(
                'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.DESCRIPTION_PLACEHOLDER'
              )
            "
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
          >
            {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.TIMEZONE_OFFSET') }}
          </label>
          <input
            v-model.number="localProps.timezoneOffset"
            type="number"
            :placeholder="
              t(
                'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.TIMEZONE_OFFSET_PLACEHOLDER'
              )
            "
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
          <p class="text-xs text-n-slate-10 mt-1">
            {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.EVENT.TIMEZONE_HELP') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Timeslots -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
    >
      <div class="flex justify-between items-center mb-3">
        <h4 class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11">
          {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.TITLE') }}
        </h4>
        <button
          class="px-3 py-1 bg-green-600 hover:bg-green-700 text-white rounded text-sm transition-colors"
          @click="addTimeslot"
        >
          {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.ADD') }}
        </button>
      </div>

      <div
        v-if="localProps.timeslots.length === 0"
        class="text-sm text-n-slate-11 dark:text-n-slate-10 italic text-center py-4"
      >
        {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.NONE') }}
      </div>
      <div v-else class="space-y-2">
        <div
          v-for="(slot, index) in localProps.timeslots"
          :key="index"
          class="flex items-center gap-2 p-2 bg-n-alpha-1 dark:bg-n-alpha-2 rounded-lg"
        >
          <div class="flex-1 grid grid-cols-2 gap-2">
            <div>
              <label
                class="block text-xs text-n-slate-11 dark:text-n-slate-10 mb-1"
              >
                {{
                  t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.START_TIME')
                }}
              </label>
              <input
                v-model="slot.startTime"
                type="datetime-local"
                class="w-full px-2 py-1 text-sm border border-n-weak dark:border-n-slate-6 rounded bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11"
              />
            </div>
            <div>
              <label
                class="block text-xs text-n-slate-11 dark:text-n-slate-10 mb-1"
              >
                {{
                  t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.DURATION')
                }}
              </label>
              <input
                v-model.number="slot.duration"
                type="number"
                :placeholder="
                  t(
                    'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.DURATION_PLACEHOLDER'
                  )
                "
                class="w-full px-2 py-1 text-sm border border-n-weak dark:border-n-slate-6 rounded bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11"
              />
            </div>
          </div>
          <button
            class="px-2 py-1 bg-n-ruby-9 dark:bg-n-ruby-10 text-white rounded text-sm hover:bg-n-ruby-10 dark:hover:bg-n-ruby-11 transition-colors"
            @click="removeTimeslot(index)"
          >
            {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.TIMESLOTS.REMOVE') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Received Message -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
    >
      <h4
        class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
      >
        {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.TITLE') }}
      </h4>
      <div class="space-y-3">
        <div>
          <label
            class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
          >
            {{
              t(
                'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.MESSAGE_TITLE'
              )
            }}
          </label>
          <input
            v-model="localProps.receivedTitle"
            type="text"
            :placeholder="
              t(
                'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.MESSAGE_TITLE_PLACEHOLDER'
              )
            "
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
          >
            {{
              t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.SUBTITLE')
            }}
          </label>
          <input
            v-model="localProps.receivedSubtitle"
            type="text"
            :placeholder="
              t(
                'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.SUBTITLE_PLACEHOLDER'
              )
            "
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.IMAGE')
              }}
            </label>
            <div class="flex items-center gap-2">
              <select
                v-model="localProps.receivedImageIdentifier"
                class="flex-1 px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              >
                <option value="">
                  {{
                    t(
                      'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.NO_IMAGE'
                    )
                  }}
                </option>
                <option
                  v-for="image in availableImages"
                  :key="image.identifier"
                  :value="image.identifier"
                >
                  {{
                    image.originalName || image.description || image.identifier
                  }}
                </option>
              </select>
              <img
                v-if="
                  localProps.receivedImageIdentifier &&
                  availableImages.find(
                    img => img.identifier === localProps.receivedImageIdentifier
                  )
                "
                :src="
                  availableImages.find(
                    img => img.identifier === localProps.receivedImageIdentifier
                  ).preview
                "
                class="w-12 h-12 object-cover rounded border border-n-weak dark:border-n-slate-6 flex-shrink-0"
                alt="Preview"
              />
            </div>
          </div>

          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.RECEIVED_MESSAGE.STYLE')
              }}
            </label>
            <select
              v-model="localProps.receivedStyle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
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

    <!-- Reply Message -->
    <div
      class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6"
    >
      <h4
        class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3"
      >
        {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.TITLE') }}
      </h4>
      <div class="space-y-3">
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.MESSAGE_TITLE'
                )
              }}
            </label>
            <input
              v-model="localProps.replyTitle"
              type="text"
              :placeholder="
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.MESSAGE_TITLE_PLACEHOLDER'
                )
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.SUBTITLE')
              }}
            </label>
            <input
              v-model="localProps.replySubtitle"
              type="text"
              :placeholder="
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.SUBTITLE_PLACEHOLDER'
                )
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.IMAGE') }}
            </label>
            <div class="flex items-center gap-2">
              <select
                v-model="localProps.replyImageIdentifier"
                class="flex-1 px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
              >
                <option value="">
                  {{
                    t(
                      'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.NO_IMAGE'
                    )
                  }}
                </option>
                <option
                  v-for="image in availableImages"
                  :key="image.identifier"
                  :value="image.identifier"
                >
                  {{
                    image.originalName || image.description || image.identifier
                  }}
                </option>
              </select>
              <img
                v-if="
                  localProps.replyImageIdentifier &&
                  availableImages.find(
                    img => img.identifier === localProps.replyImageIdentifier
                  )
                "
                :src="
                  availableImages.find(
                    img => img.identifier === localProps.replyImageIdentifier
                  ).preview
                "
                class="w-12 h-12 object-cover rounded border border-n-weak dark:border-n-slate-6 flex-shrink-0"
                alt="Preview"
              />
            </div>
          </div>

          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{ t('TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.STYLE') }}
            </label>
            <select
              v-model="localProps.replyStyle"
              class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
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

        <!-- Additional Reply Fields -->
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.IMAGE_TITLE'
                )
              }}
            </label>
            <input
              v-model="localProps.replyImageTitle"
              type="text"
              :placeholder="
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.IMAGE_TITLE_PLACEHOLDER'
                )
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.IMAGE_SUBTITLE'
                )
              }}
            </label>
            <input
              v-model="localProps.replyImageSubtitle"
              type="text"
              :placeholder="
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.IMAGE_SUBTITLE_PLACEHOLDER'
                )
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.SECONDARY_SUBTITLE'
                )
              }}
            </label>
            <input
              v-model="localProps.replySecondarySubtitle"
              type="text"
              :placeholder="
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.SECONDARY_SUBTITLE_PLACEHOLDER'
                )
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <div>
            <label
              class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
            >
              {{
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.TERTIARY_SUBTITLE'
                )
              }}
            </label>
            <input
              v-model="localProps.replyTertiarySubtitle"
              type="text"
              :placeholder="
                t(
                  'TEMPLATES.BUILDER.TIME_PICKER_BLOCK.REPLY_MESSAGE.TERTIARY_SUBTITLE_PLACEHOLDER'
                )
              "
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
