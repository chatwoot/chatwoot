<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import {
  format,
  addMinutes,
  startOfDay,
  addDays,
  startOfWeek,
  addWeeks,
  subWeeks,
} from 'date-fns';
import { zonedTimeToUtc } from 'date-fns-tz';
import EnhancedTimePickerModal from 'dashboard/components-next/message/modals/EnhancedTimePickerModal.vue';
import AppleFormBuilder from 'dashboard/components-next/message/modals/AppleFormBuilder.vue';

const props = defineProps({
  conversation: {
    type: Object,
    default: () => ({})
  }
});

const emit = defineEmits(['send', 'cancel']);

const { t } = useI18n();
const store = useStore();

const activeTab = ref('list_picker');

// Form Builder State
const showFormBuilder = ref(false);

// iMessage App State
const selectedAppId = ref('');
const selectedAppData = ref({});

// Computed properties
const availableApps = computed(() => {
  const inboxId = props.conversation?.inbox_id;

  if (!inboxId) {
    return [];
  }

  // Get the full inbox data from the store
  const inbox = store.getters['inboxes/getInboxById'](inboxId);

  if (!inbox) {
    return [];
  }

  // Try both possible field names directly on inbox
  const apps = inbox.imessageApps || inbox.imessage_apps || [];

  if (!Array.isArray(apps) || apps.length === 0) {
    return [];
  }

  const enabledApps = apps.filter(app => app.enabled !== false);
  return enabledApps;
});

const selectedApp = computed(() => {
  if (!selectedAppId.value) return null;
  return availableApps.value.find(app => app.id === selectedAppId.value);
});

// Enhanced Time Picker State
const showEnhancedTimePicker = ref(false);

// Inline Time Picker State
const inlineTimePickerData = ref({
  selectedDate: format(addDays(new Date(), 1), 'yyyy-MM-dd'), // Default to tomorrow
  selectedInterval: 30, // minutes
  useBusinessHours: true,
  customStartTime: '09:00',
  customEndTime: '17:00',
  serviceDuration: 60, // minutes
  maxSlots: 10,
  selectedSlots: [],
});

const selectedSlotIds = ref(new Set());
const currentWeekStart = ref(startOfWeek(new Date()));

// Multi-day selection storage: Map of date -> Set of slot IDs
const multiDaySelections = ref(new Map());

// Global selected slots across all dates with unique keys
const globalSelectedSlots = ref(new Map()); // Map of unique slot key -> slot data

// Business hours configuration - Make sure Friday is enabled
const businessHours = ref({
  monday: { start: '09:00', end: '17:00', enabled: true },
  tuesday: { start: '09:00', end: '17:00', enabled: true },
  wednesday: { start: '09:00', end: '17:00', enabled: true },
  thursday: { start: '09:00', end: '17:00', enabled: true },
  friday: { start: '09:00', end: '17:00', enabled: true }, // Enable Friday
  saturday: { start: '10:00', end: '16:00', enabled: false },
  sunday: { start: '10:00', end: '16:00', enabled: false },
});

// Time interval options
const intervalOptions = [
  { value: 15, label: '15 min', icon: '⏱️' },
  { value: 30, label: '30 min', icon: '🕐' },
  { value: 60, label: '1 hour', icon: '🕑' },
];

// Computed properties for inline time picker
const availableSlots = computed(() => {
  try {
    if (!inlineTimePickerData.value.selectedDate) return [];

    const date = new Date(inlineTimePickerData.value.selectedDate + 'T00:00:00');
    const dayName = format(date, 'EEEE').toLowerCase();

    console.log('Generating slots for:', {
      selectedDate: inlineTimePickerData.value.selectedDate,
      dayName,
      useBusinessHours: inlineTimePickerData.value.useBusinessHours
    });

    // Check if the selected date is in the past
    const today = new Date();
    const selectedDate = new Date(inlineTimePickerData.value.selectedDate + 'T00:00:00');
    const isToday = selectedDate.toDateString() === today.toDateString();
    const isPastDate = selectedDate < today && !isToday;

    if (isPastDate) {
      console.log('Date is in the past, no slots generated');
      return [];
    }

    let startTime;
    let endTime;

    if (inlineTimePickerData.value.useBusinessHours) {
      const businessHour = businessHours.value[dayName];
      console.log('Business hour for', dayName, ':', businessHour);

      if (!businessHour?.enabled) {
        console.log('Business day not enabled for', dayName);
        return [];
      }

      // Ensure we have valid start and end times
      const startStr = businessHour.start || '09:00';
      const endStr = businessHour.end || '17:00';

      startTime = new Date(`${inlineTimePickerData.value.selectedDate}T${startStr}:00`);
      endTime = new Date(`${inlineTimePickerData.value.selectedDate}T${endStr}:00`);

      console.log('Using business hours:', { start: startStr, end: endStr });
    } else {
      const startStr = inlineTimePickerData.value.customStartTime || '09:00';
      const endStr = inlineTimePickerData.value.customEndTime || '17:00';

      startTime = new Date(`${inlineTimePickerData.value.selectedDate}T${startStr}:00`);
      endTime = new Date(`${inlineTimePickerData.value.selectedDate}T${endStr}:00`);

      console.log('Using custom hours:', { start: startStr, end: endStr });
    }

    console.log('Time range:', { startTime, endTime });

    // If it's today, ensure we only show future time slots
    if (isToday) {
      const now = new Date();
      if (startTime <= now) {
        const minutesToAdd = inlineTimePickerData.value.selectedInterval - (now.getMinutes() % inlineTimePickerData.value.selectedInterval);
        startTime = new Date(now.getTime() + minutesToAdd * 60000);
        startTime.setSeconds(0, 0);
      }
    }

    const slots = [];
    let currentSlot = new Date(startTime);
    let slotId = 0;

    while (currentSlot < endTime) {
      const slotEnd = addMinutes(currentSlot, inlineTimePickerData.value.serviceDuration);

      if (slotEnd <= endTime) {
        const slotKey = `${inlineTimePickerData.value.selectedDate}_${slotId}`;
        const isSelected = globalSelectedSlots.value.has(slotKey);

        slots.push({
          id: slotId.toString(),
          key: slotKey,
          date: inlineTimePickerData.value.selectedDate,
          startTime: new Date(currentSlot),
          endTime: new Date(slotEnd),
          duration: inlineTimePickerData.value.serviceDuration,
          available: true,
          selected: isSelected,
          displayTime: format(currentSlot, 'HH:mm'),
          displayEndTime: format(slotEnd, 'HH:mm'),
          utcTime: zonedTimeToUtc(currentSlot, Intl.DateTimeFormat().resolvedOptions().timeZone).toISOString().replace('Z', '+0000'),
          localTime: format(currentSlot, "yyyy-MM-dd'T'HH:mm:ss"),
        });
      }

      currentSlot = addMinutes(currentSlot, inlineTimePickerData.value.selectedInterval);
      slotId++;
    }

    console.log('Generated slots:', slots.length);
    return slots;
  } catch (error) {
    console.error('Error generating slots:', error);
    return [];
  }
});

const weekDays = computed(() => {
  const startDate = currentWeekStart.value;
  const days = [];

  for (let i = 0; i < 7; i++) {
    const date = addDays(startDate, i);
    const dayName = format(date, 'EEEE').toLowerCase();
    const businessHour = businessHours.value[dayName];

    days.push({
      date: format(date, 'yyyy-MM-dd'),
      displayDate: format(date, 'MMM d'),
      dayName: format(date, 'EEE'),
      isToday: format(date, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd'),
      isSelected: format(date, 'yyyy-MM-dd') === inlineTimePickerData.value.selectedDate,
      isBusinessDay: businessHour?.enabled || false,
      hasSlots: !!businessHour?.enabled,
      isPast: date < startOfDay(new Date()),
    });
  }

  return days;
});

const selectedSlotsData = computed(() => {
  // Return all selected slots across all dates, sorted by date and time
  const allSelectedSlots = Array.from(globalSelectedSlots.value.values());
  return allSelectedSlots.sort((a, b) => {
    const dateCompare = a.date.localeCompare(b.date);
    if (dateCompare !== 0) return dateCompare;
    // Use the startTime Date object directly
    return a.startTime.getTime() - b.startTime.getTime();
  });
});

// Methods for inline time picker
const toggleSlot = (slot) => {
  if (!slot.available) return;

  const slotKey = slot.key;
  const isCurrentlySelected = globalSelectedSlots.value.has(slotKey);

  if (isCurrentlySelected) {
    // Remove slot
    globalSelectedSlots.value.delete(slotKey);
    selectedSlotIds.value.delete(slot.id);

    // Update multi-day selections map
    const dateSelections = multiDaySelections.value.get(slot.date) || new Set();
    dateSelections.delete(slot.id);
    if (dateSelections.size === 0) {
      multiDaySelections.value.delete(slot.date);
    } else {
      multiDaySelections.value.set(slot.date, dateSelections);
    }
  } else {
    // Check max slots limit
    if (globalSelectedSlots.value.size < inlineTimePickerData.value.maxSlots) {
      // Add slot - store the complete slot data for UI display with static date
      const staticSlot = {
        ...slot,
        key: slotKey,
        date: String(slot.date), // Convert to static string to prevent reactivity issues
        startTime: new Date(slot.startTime), // Create new Date object
        endTime: new Date(slot.endTime), // Create new Date object
        displayTime: slot.displayTime,
        displayEndTime: slot.displayEndTime,
        duration: slot.duration,
        utcTime: slot.utcTime,
        localTime: slot.localTime,
        available: slot.available,
        selected: slot.selected,
        id: slot.id,
      };

      globalSelectedSlots.value.set(slotKey, staticSlot);
      selectedSlotIds.value.add(slot.id);

      // Update multi-day selections map
      const dateSelections = multiDaySelections.value.get(slot.date) || new Set();
      dateSelections.add(slot.id);
      multiDaySelections.value.set(slot.date, dateSelections);
    }
  }

  updateTimePickerData();
};

const selectDate = (dateString) => {
  // Save current date selections before switching
  if (inlineTimePickerData.value.selectedDate && selectedSlotIds.value.size > 0) {
    multiDaySelections.value.set(
      inlineTimePickerData.value.selectedDate,
      new Set(selectedSlotIds.value)
    );
  }

  // Switch to new date
  inlineTimePickerData.value.selectedDate = dateString;

  // Load selections for the new date
  const dateSelections = multiDaySelections.value.get(dateString) || new Set();
  selectedSlotIds.value = new Set(dateSelections);

  updateTimePickerData();
};

const navigateWeek = (direction) => {
  if (direction === 'prev') {
    currentWeekStart.value = subWeeks(currentWeekStart.value, 1);
  } else {
    currentWeekStart.value = addWeeks(currentWeekStart.value, 1);
  }
};

const updateTimePickerData = () => {
  // Update formData with all selected slots across all dates for Apple MSP format
  const slots = Array.from(globalSelectedSlots.value.values()).map(slot => ({
    identifier: slot.key,
    startTime: slot.utcTime,
    duration: slot.duration * 60, // Convert to seconds for Apple MSP
  }));

  timePickerData.value.event.timeslots = slots;

  // Debug logging
  console.log('🔥 Inline Time Picker - updateTimePickerData:', {
    globalSelectedSlots: globalSelectedSlots.value.size,
    formattedSlots: slots,
    sampleSlot: slots[0],
  });
};

// Find next available business day
const findNextBusinessDay = () => {
  try {
    let date = new Date();
    date.setDate(date.getDate() + 1); // Start from tomorrow

    for (let i = 0; i < 7; i++) { // Check up to 7 days ahead
      const dayName = format(date, 'EEEE').toLowerCase();
      const businessHour = businessHours.value[dayName];

      if (businessHour?.enabled) {
        return format(date, 'yyyy-MM-dd');
      }

      date.setDate(date.getDate() + 1);
    }

    // Fallback to tomorrow if no business days found
    return format(addDays(new Date(), 1), 'yyyy-MM-dd');
  } catch (error) {
    console.error('Error finding next business day:', error);
    // Fallback to tomorrow
    return format(addDays(new Date(), 1), 'yyyy-MM-dd');
  }
};

// Initialize with next business day
const initializeTimePickerDate = () => {
  try {
    // Use the findNextBusinessDay function to get a proper business day
    const nextBusinessDay = findNextBusinessDay();
    inlineTimePickerData.value.selectedDate = nextBusinessDay;

    console.log('Initialized with business day:', nextBusinessDay);
    console.log('Day of week:', new Date(nextBusinessDay + 'T00:00:00').toLocaleDateString('en-US', { weekday: 'long' }));
    console.log('Business hours:', businessHours.value);
    console.log('Use business hours:', inlineTimePickerData.value.useBusinessHours);

    // Force update after a tick to ensure reactive values are set
    setTimeout(() => {
      console.log('Available slots after init:', availableSlots.value.length);
    }, 100);
  } catch (error) {
    console.error('Error initializing time picker date:', error);
    // Fallback to tomorrow
    inlineTimePickerData.value.selectedDate = format(addDays(new Date(), 1), 'yyyy-MM-dd');
  }
};

// Initialize on component mount
onMounted(() => {
  initializeTimePickerDate();
});

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
    updatedTimePickerData: timePickerData.value,
  });

  // Don't auto-send, just save the configuration
};

const handleEnhancedTimePickerSaveAndSend = enhancedData => {
  // Update the existing timePickerData with enhanced data
  Object.assign(timePickerData.value, enhancedData);
  showEnhancedTimePicker.value = false;

  // Debug logging
  console.log(
    '🔥 AppleMessagesComposer - handleEnhancedTimePickerSaveAndSend:',
    {
      enhancedData,
      timeslotsCount: enhancedData.event?.timeslots?.length,
      updatedTimePickerData: timePickerData.value,
    }
  );

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
    updatedTimePickerData: timePickerData.value,
  });
};

const sendAppleMessage = () => {
  let content_type;
  let content_attributes;
  let content;

  switch (activeTab.value) {
    case 'list_picker':
      content_type = 'apple_list_picker';

      // Prepare content_attributes with images if they exist
      content_attributes = { ...listPickerData.value };

      // Only include images if they exist and are not empty
      if (
        listPickerData.value.images &&
        listPickerData.value.images.length > 0
      ) {
        content_attributes.images = listPickerData.value.images.map(
          (img, index) => ({
            identifier: `image_${index}`,
            data: img.data,
            description: img.description || `Image ${index + 1}`,
          })
        );

        // Associate images with list items using imageIdentifier
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
                }
              });
            }
          });
        }
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
    case 'forms':
      // Forms are created through the modal, this shouldn't be reached
      return;
    case 'imessage_apps':
      if (!selectedApp.value) {
        return;
      }
      content_type = 'apple_custom_app';

      // Only send fields that are allowed by the backend validator
      // ALLOWED_APPLE_CUSTOM_APP_KEYS = [:app_id, :app_name, :bid, :url, :use_live_layout]
      content_attributes = {
        app_id: selectedApp.value.appId || selectedApp.value.app_id,
        app_name: selectedApp.value.name,
        bid: selectedApp.value.bid,
        url: selectedApp.value.url,
        use_live_layout: selectedApp.value.useLiveLayout || selectedApp.value.use_live_layout || false
      };

      content = `${selectedApp.value.name}: ${selectedApp.value.description || 'App invocation'}`;

      // Debug logging for 422 error
      console.log('🔧 Debug - Selected app data:', selectedApp.value);
      console.log('🔧 Debug - Content attributes being sent (filtered):', content_attributes);
      break;
  }

  emit('send', {
    content_type,
    content_attributes,
    content,
  });
};

const cancelComposer = () => {
  emit('cancel');
};

// Form Builder Handlers
const openFormBuilder = () => {
  showFormBuilder.value = true;
};

const handleFormCreated = (formData) => {
  emit('send', formData);
  showFormBuilder.value = false;
};

const closeFormBuilder = () => {
  showFormBuilder.value = false;
};

// iMessage App Handlers
const selectApp = (appId) => {
  selectedAppId.value = appId;
  selectedAppData.value = {};
};

const updateAppData = (key, value) => {
  selectedAppData.value[key] = value;
};
</script>

<template>
  <div class="apple-messages-composer bg-n-solid-1 text-n-slate-12">
    <!-- Tabs -->
    <div class="flex space-x-2 mb-4 border-b border-n-weak">
      <button
        v-for="tab in ['list_picker', 'quick_reply', 'time_picker', 'forms', 'imessage_apps']"
        :key="tab"
        class="px-4 py-2 text-sm font-medium border-b-2 transition-colors"
        :class="
          activeTab === tab
            ? 'border-n-blue-8 text-n-blue-11 dark:text-n-blue-10'
            : 'border-transparent text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9'
        "
        @click="activeTab = tab"
      >
        {{ tab === 'imessage_apps' ? 'iMessage Apps' : tab.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) }}
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
      <!-- Inline Time Picker Interface -->
      <div class="space-y-4">
        <!-- Quick Settings -->
        <div class="flex items-center justify-between">
          <h4 class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11">
            Schedule Appointment - {{ selectedSlotsData.length }} slot(s) configured
          </h4>
          <div class="flex items-center space-x-4">
            <!-- Time Interval Selector -->
            <div class="flex space-x-1">
              <button
                v-for="interval in intervalOptions"
                :key="interval.value"
                class="px-2 py-1 text-xs rounded transition-colors"
                :class="
                  inlineTimePickerData.selectedInterval === interval.value
                    ? 'bg-n-blue-9 text-white dark:bg-n-blue-10'
                    : 'bg-n-alpha-2 text-n-slate-11 hover:bg-n-alpha-3 dark:bg-n-alpha-3 dark:text-n-slate-10'
                "
                @click="inlineTimePickerData.selectedInterval = interval.value"
              >
                {{ interval.icon }} {{ interval.label }}
              </button>
            </div>
            <!-- Advanced Settings Button -->
            <button
              class="px-3 py-1 text-xs bg-n-alpha-2 dark:bg-n-alpha-3 text-n-slate-11 dark:text-n-slate-10 rounded hover:bg-n-alpha-3 dark:hover:bg-n-alpha-4 transition-colors"
              @click="showEnhancedTimePicker = true"
            >
              Advanced
            </button>
          </div>
        </div>

        <!-- Date Navigation -->
        <div class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6">
          <div class="flex items-center justify-between mb-3">
            <button
              class="flex items-center px-2 py-1 text-sm text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-3 rounded transition-colors"
              @click="navigateWeek('prev')"
            >
              <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Previous
            </button>

            <div class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11">
              {{ format(currentWeekStart, 'MMM d') }} - {{ format(addDays(currentWeekStart, 6), 'MMM d, yyyy') }}
            </div>

            <button
              class="flex items-center px-2 py-1 text-sm text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-3 rounded transition-colors"
              @click="navigateWeek('next')"
            >
              Next
              <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>

          <!-- Week View -->
          <div class="grid grid-cols-7 gap-1">
            <button
              v-for="day in weekDays"
              :key="day.date"
              class="p-2 text-center rounded transition-colors"
              :class="[
                day.isSelected
                  ? 'bg-n-blue-9 text-white dark:bg-n-blue-10'
                  : day.isToday
                    ? 'bg-n-blue-2 text-n-blue-11 dark:bg-n-blue-3 dark:text-n-blue-10 border border-n-blue-6'
                    : day.hasSlots && !day.isPast
                      ? 'bg-n-alpha-1 text-n-slate-11 hover:bg-n-alpha-2 dark:bg-n-alpha-2 dark:text-n-slate-10 dark:hover:bg-n-alpha-3'
                      : 'bg-n-alpha-1 text-n-slate-9 cursor-not-allowed dark:bg-n-alpha-2 dark:text-n-slate-8 opacity-50',
              ]"
              :disabled="!day.hasSlots || day.isPast"
              @click="selectDate(day.date)"
            >
              <div class="text-xs font-medium">{{ day.dayName }}</div>
              <div class="text-sm">{{ day.displayDate }}</div>
            </button>
          </div>
        </div>

        <!-- Available Time Slots -->
        <div class="bg-n-alpha-2 dark:bg-n-alpha-3 p-4 rounded-lg border border-n-weak dark:border-n-slate-6">
          <div class="flex items-center justify-between mb-3">
            <h4 class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11">
              Available Slots for {{ format(new Date(inlineTimePickerData.selectedDate), 'MMM d, yyyy') }}
            </h4>
            <div class="text-xs text-n-slate-11 dark:text-n-slate-10">
              {{ selectedSlotsData.length }} / {{ inlineTimePickerData.maxSlots }} selected
            </div>
          </div>

          <div v-if="availableSlots.length === 0" class="text-center py-4">
            <div class="text-sm text-n-slate-11 dark:text-n-slate-10">
              No available time slots for this date
            </div>
          </div>

          <div v-else class="grid grid-cols-3 gap-2 max-h-48 overflow-y-auto">
            <button
              v-for="slot in availableSlots"
              :key="slot.id"
              class="flex items-center justify-between p-2 rounded border transition-colors"
              :class="[
                slot.selected
                  ? 'border-n-green-8 bg-n-green-2 text-n-green-11 dark:border-n-green-9 dark:bg-n-green-3 dark:text-n-green-10'
                  : 'border-n-weak bg-white hover:border-n-strong hover:bg-n-alpha-1 text-n-slate-11 dark:border-n-slate-6 dark:bg-n-alpha-2 dark:hover:bg-n-alpha-3 dark:text-n-slate-10'
              ]"
              @click="toggleSlot(slot)"
            >
              <div class="text-xs">
                <div class="font-medium">{{ slot.displayTime }}</div>
                <div class="opacity-75">{{ slot.duration }}min</div>
              </div>
              <div
                class="w-2 h-2 rounded-full"
                :class="slot.selected ? 'bg-n-green-9' : 'bg-n-blue-8'"
              />
            </button>
          </div>
        </div>

        <!-- Selected Slots Summary -->
        <div v-if="selectedSlotsData.length > 0" class="bg-n-green-1 dark:bg-n-green-2 p-3 rounded-lg border border-n-green-6 dark:border-n-green-7">
          <h4 class="text-sm font-medium text-n-green-11 dark:text-n-green-10 mb-2">
            Selected Time Slots
          </h4>
          <div class="space-y-1">
            <div
              v-for="slot in selectedSlotsData"
              :key="slot.key"
              class="flex items-center justify-between text-xs text-n-green-10 dark:text-n-green-9"
            >
              <span>{{ format(new Date(slot.date), 'MMM d') }} at {{ slot.displayTime }} - {{ slot.displayEndTime }}</span>
              <button
                class="p-1 hover:bg-n-green-3 dark:hover:bg-n-green-4 rounded transition-colors"
                @click="toggleSlot(slot)"
              >
                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
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
        @click="sendAppleMessage"
      >
        Send Message
      </button>
    </div>

    <!-- Forms Tab -->
    <div v-if="activeTab === 'forms'" class="space-y-6">
      <div class="text-center py-12">
        <div class="mb-6">
          <div class="w-16 h-16 bg-woot-100 dark:bg-woot-900 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg class="w-8 h-8 text-woot-600 dark:text-woot-400" fill="currentColor" viewBox="0 0 24 24">
              <path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z" />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-n-slate-12 dark:text-n-slate-11 mb-2">
            Create Interactive Forms
          </h3>
          <p class="text-sm text-n-slate-10 dark:text-n-slate-9 max-w-md mx-auto">
            Build dynamic forms with multiple field types, validation, and templates. Perfect for surveys, contact forms, and data collection.
          </p>
        </div>

        <div class="flex flex-wrap gap-3 justify-center mb-6">
          <span class="px-3 py-1 bg-woot-50 dark:bg-woot-900 text-woot-700 dark:text-woot-300 text-xs rounded-full">
            📝 Text Fields
          </span>
          <span class="px-3 py-1 bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-300 text-xs rounded-full">
            🔘 Single Choice
          </span>
          <span class="px-3 py-1 bg-purple-50 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 text-xs rounded-full">
            ☑️ Multiple Choice
          </span>
          <span class="px-3 py-1 bg-orange-50 dark:bg-orange-900/30 text-orange-700 dark:text-orange-300 text-xs rounded-full">
            📅 Date & Time
          </span>
          <span class="px-3 py-1 bg-pink-50 dark:bg-pink-900/30 text-pink-700 dark:text-pink-300 text-xs rounded-full">
            🔢 Number Stepper
          </span>
        </div>

        <button
          @click="openFormBuilder"
          class="px-6 py-3 bg-woot-600 hover:bg-woot-700 text-white font-medium rounded-lg transition-colors"
        >
          🛠️ Open Form Builder
        </button>
      </div>
    </div>

    <!-- iMessage Apps Tab -->
    <div v-if="activeTab === 'imessage_apps'" class="space-y-6">
      <!-- No Apps Configured Message -->
      <div v-if="availableApps.length === 0" class="text-center py-12">
        <div class="w-16 h-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-slate-400" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
          </svg>
        </div>
        <h3 class="text-lg font-semibold text-n-slate-12 dark:text-n-slate-11 mb-2">
          No iMessage Apps Configured
        </h3>
        <p class="text-sm text-n-slate-10 dark:text-n-slate-9 max-w-md mx-auto mb-4">
          Configure iMessage apps in your inbox settings to enable custom app invocations.
        </p>
        <p class="text-xs text-n-slate-9 dark:text-n-slate-8">
          Go to Settings → Inboxes → Your Apple Messages Channel → iMessage Apps Configuration
        </p>
      </div>

      <!-- App Selection -->
      <div v-else>
        <div class="mb-6">
          <h4 class="text-sm font-semibold text-n-slate-12 dark:text-n-slate-11 mb-3">
            Select iMessage App
          </h4>
          <div class="space-y-2">
            <label
              v-for="app in availableApps"
              :key="app.id"
              class="flex items-center space-x-3 p-3 border border-n-weak rounded-lg cursor-pointer hover:bg-n-alpha-2 transition-colors"
              :class="selectedAppId === app.id ? 'border-n-woot-8 bg-n-woot-1' : ''"
            >
              <input
                v-model="selectedAppId"
                type="radio"
                :value="app.id"
                class="rounded-full border-n-weak text-n-woot-8 focus:ring-n-woot-8"
              />
              <div class="flex-1">
                <div class="font-medium text-n-slate-12 dark:text-n-slate-11">{{ app.name }}</div>
                <div class="text-sm text-n-slate-10 dark:text-n-slate-9">{{ app.description }}</div>
                <div class="text-xs text-n-slate-8 dark:text-n-slate-7 font-mono mt-1">{{ app.app_id }}</div>
              </div>
            </label>
          </div>
        </div>
      </div>
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
      @save-and-send="handleEnhancedTimePickerSaveAndSend"
    />

    <!-- Apple Form Builder Modal -->
    <AppleFormBuilder
      :show="showFormBuilder"
      :msp-id="conversation?.inbox?.channel?.business_id || ''"
      :conversation-id="conversation?.id?.toString() || ''"
      @close="closeFormBuilder"
      @create="handleFormCreated"
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
