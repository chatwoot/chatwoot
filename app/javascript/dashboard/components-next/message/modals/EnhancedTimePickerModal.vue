<!-- eslint-disable no-unused-vars -->
<!-- eslint-disable no-use-before-define -->
<!-- eslint-disable no-plusplus -->
<!-- eslint-disable no-lonely-if -->
<!-- eslint-disable default-case -->
<!-- eslint-disable no-alert -->
<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable @intlify/vue-i18n/no-raw-text -->
<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  format,
  addMinutes,
  startOfDay,
  endOfDay,
  isWithinInterval,
  parseISO,
  formatISO,
  addDays,
  startOfWeek,
  endOfWeek,
  addWeeks,
  subWeeks,
  addMonths,
  subMonths,
  isSameWeek,
  isSameMonth,
} from 'date-fns';
import { zonedTimeToUtc, utcToZonedTime } from 'date-fns-tz';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  initialData: {
    type: Object,
    default: () => ({}),
  },
  availableImages: {
    type: Array,
    default: () => [],
  },
  businessHours: {
    type: Object,
    default: () => ({
      monday: { start: '09:00', end: '17:00', enabled: true },
      tuesday: { start: '09:00', end: '17:00', enabled: true },
      wednesday: { start: '09:00', end: '17:00', enabled: true },
      thursday: { start: '09:00', end: '17:00', enabled: true },
      friday: { start: '09:00', end: '17:00', enabled: true },
      saturday: { start: '10:00', end: '16:00', enabled: false },
      sunday: { start: '10:00', end: '16:00', enabled: false },
    }),
  },
  timezone: {
    type: String,
    default: Intl.DateTimeFormat().resolvedOptions().timeZone,
  },
  existingBookings: {
    type: Array,
    default: () => [],
  },
  serviceDuration: {
    type: Number,
    default: 60, // minutes
  },
});

const emit = defineEmits([
  'close',
  'save',
  'preview',
  'saveAndSend',
  'uploadImage',
]);

const { t } = useI18n();

// Modal state
const modalRef = ref(null);
const isVisible = ref(false);
const isAnimating = ref(false);

// Watch for modal open to reset state if needed
watch(
  () => props.show,
  newVal => {
    if (newVal) {
      // Modal opened - state is ready
    }
  }
);

// Helper to get image URL by identifier
const getImageByIdentifier = identifier => {
  if (!identifier) return null;
  return props.availableImages.find(img => img.identifier === identifier);
};

const getImagePreviewUrl = identifier => {
  const image = getImageByIdentifier(identifier);
  if (!image) return null;
  return image.preview || image.image_url;
};

// Form data
const formData = ref({
  eventTitle: 'Schedule Appointment',
  eventDescription: 'Select your preferred time slot',
  receivedTitle: 'Please pick a time',
  receivedSubtitle: 'Select your preferred time slot',
  receivedImageIdentifier: '',
  receivedStyle: 'large',
  replyTitle: 'Thank you!',
  replySubtitle: "We'll see you then!",
  replyImageIdentifier: '',
  replyStyle: 'large',
  timezoneOffset: 0,
  selectedInterval: 30, // minutes
  customStartTime: '09:00',
  customEndTime: '17:00',
  selectedDate: format(addDays(new Date(), 1), 'yyyy-MM-dd'), // Default to tomorrow
  selectedSlots: [],
  maxSlots: 10,
  allowMultipleSelection: true, // Always allow multiple selection
  useBusinessHours: true,
  useCustomRange: false,
});

// Automatically sync reply image with received image
watch(
  () => formData.value.receivedImageIdentifier,
  newIdentifier => {
    // When received image changes, automatically update reply image to match
    formData.value.replyImageIdentifier = newIdentifier;
  },
  { immediate: true }
);

// Image availability indicator
const hasAvailableImages = computed(() => {
  return props.availableImages && props.availableImages.length > 0;
});

// Time interval options
const intervalOptions = [
  { value: 15, label: '15 minutes', icon: '⏱️' },
  { value: 30, label: '30 minutes', icon: '🕐' },
  { value: 60, label: '1 hour', icon: '🕑' },
  { value: 120, label: '2 hours', icon: '🕕' },
];

// Current view state
const currentView = ref('slots'); // Start directly with slots view instead of setup
const selectedSlotIds = ref(new Set());
const hoveredSlot = ref(null);
const focusedSlotIndex = ref(-1);

// Extended date navigation state
const currentWeekStart = ref(startOfWeek(new Date()));
const viewMode = ref('week'); // 'week' or 'month'
const selectedMonth = ref(new Date());

// Multi-day selection storage: Map of date -> Set of slot IDs
const multiDaySelections = ref(new Map());

// Global selected slots across all dates with unique keys
const globalSelectedSlots = ref(new Map()); // Map of unique slot key -> slot data

// Computed properties
const availableSlots = computed(() => {
  if (!formData.value.selectedDate) return [];

  const date = new Date(formData.value.selectedDate);
  const dayName = format(date, 'EEEE').toLowerCase();

  // Check if the selected date is in the past
  const today = new Date();
  const selectedDate = new Date(formData.value.selectedDate);
  const isToday = selectedDate.toDateString() === today.toDateString();
  const isPastDate = selectedDate < today && !isToday;

  if (isPastDate) return []; // Don't generate slots for past dates

  let startTime;
  let endTime;

  if (formData.value.useBusinessHours) {
    const businessHour = props.businessHours[dayName];
    if (!businessHour?.enabled) return [];

    startTime = new Date(
      `${formData.value.selectedDate}T${businessHour.start}:00`
    );
    endTime = new Date(`${formData.value.selectedDate}T${businessHour.end}:00`);
  } else {
    startTime = new Date(
      `${formData.value.selectedDate}T${formData.value.customStartTime}:00`
    );
    endTime = new Date(
      `${formData.value.selectedDate}T${formData.value.customEndTime}:00`
    );
  }

  // If it's today, ensure we only show future time slots
  if (isToday) {
    const now = new Date();
    if (startTime <= now) {
      // Round up to the next available slot
      const minutesToAdd =
        formData.value.selectedInterval -
        (now.getMinutes() % formData.value.selectedInterval);
      startTime = new Date(now.getTime() + minutesToAdd * 60000);
      startTime.setSeconds(0, 0); // Reset seconds and milliseconds
    }
  }

  const slots = [];
  let currentSlot = startTime;
  let slotId = 0;

  while (currentSlot < endTime) {
    const slotEnd = addMinutes(currentSlot, props.serviceDuration);

    if (slotEnd <= endTime) {
      const isAvailable = !isSlotConflicted(currentSlot, slotEnd);
      // Create unique slot key combining date and time
      const slotKey = `${formData.value.selectedDate}_${slotId}`;
      const isSelected = globalSelectedSlots.value.has(slotKey);

      slots.push({
        id: slotId.toString(),
        key: slotKey,
        date: formData.value.selectedDate,
        startTime: currentSlot,
        endTime: slotEnd,
        duration: props.serviceDuration,
        available: isAvailable,
        selected: isSelected,
        displayTime: format(currentSlot, 'HH:mm'),
        displayEndTime: format(slotEnd, 'HH:mm'),
        utcTime: formatISO(zonedTimeToUtc(currentSlot, props.timezone)).replace(
          'Z',
          '+0000'
        ),
        localTime: format(currentSlot, "yyyy-MM-dd'T'HH:mm:ss"),
      });
    }

    currentSlot = addMinutes(currentSlot, formData.value.selectedInterval);
    slotId++;
  }

  return slots;
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

const isFormValid = computed(() => {
  return (
    formData.value.eventTitle.trim() &&
    formData.value.receivedTitle.trim() &&
    selectedSlotsData.value.length > 0
  );
});

const weekDays = computed(() => {
  const startDate = currentWeekStart.value;
  const days = [];

  for (let i = 0; i < 7; i++) {
    const date = addDays(startDate, i);
    const dayName = format(date, 'EEEE').toLowerCase();
    const businessHour = props.businessHours[dayName];

    days.push({
      date: format(date, 'yyyy-MM-dd'),
      displayDate: format(date, 'MMM d'),
      dayName: format(date, 'EEE'),
      isToday: format(date, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd'),
      isSelected: format(date, 'yyyy-MM-dd') === formData.value.selectedDate,
      isBusinessDay: businessHour?.enabled || false,
      hasSlots: !!businessHour?.enabled,
      isPast: date < startOfDay(new Date()),
    });
  }

  return days;
});

const monthDays = computed(() => {
  const year = selectedMonth.value.getFullYear();
  const month = selectedMonth.value.getMonth();
  const firstDay = new Date(year, month, 1);
  const lastDay = new Date(year, month + 1, 0);
  const startDate = startOfWeek(firstDay);
  const endDate = endOfWeek(lastDay);

  const days = [];
  let currentDate = startDate;

  while (currentDate <= endDate) {
    const dayName = format(currentDate, 'EEEE').toLowerCase();
    const businessHour = props.businessHours[dayName];
    const isCurrentMonth = currentDate.getMonth() === month;

    days.push({
      date: format(currentDate, 'yyyy-MM-dd'),
      displayDate: format(currentDate, 'd'),
      dayName: format(currentDate, 'EEE'),
      isToday:
        format(currentDate, 'yyyy-MM-dd') === format(new Date(), 'yyyy-MM-dd'),
      isSelected:
        format(currentDate, 'yyyy-MM-dd') === formData.value.selectedDate,
      isBusinessDay: businessHour?.enabled || false,
      hasSlots: !!businessHour?.enabled,
      isPast: currentDate < startOfDay(new Date()),
      isCurrentMonth,
    });

    currentDate = addDays(currentDate, 1);
  }

  return days;
});

const currentWeekLabel = computed(() => {
  const start = currentWeekStart.value;
  const end = addDays(start, 6);

  if (isSameMonth(start, end)) {
    return `${format(start, 'MMM d')} - ${format(end, 'd, yyyy')}`;
  }
  return `${format(start, 'MMM d')} - ${format(end, 'MMM d, yyyy')}`;
});

const currentMonthLabel = computed(() => {
  return format(selectedMonth.value, 'MMMM yyyy');
});

// Methods
const isSlotConflicted = (startTime, endTime) => {
  return props.existingBookings.some(booking => {
    const bookingStart = parseISO(booking.startTime);
    const bookingEnd = parseISO(booking.endTime);

    return (
      (startTime >= bookingStart && startTime < bookingEnd) ||
      (endTime > bookingStart && endTime <= bookingEnd) ||
      (startTime <= bookingStart && endTime >= bookingEnd)
    );
  });
};

const toggleSlot = slot => {
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
    if (globalSelectedSlots.value.size < formData.value.maxSlots) {
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
      const dateSelections =
        multiDaySelections.value.get(slot.date) || new Set();
      dateSelections.add(slot.id);
      multiDaySelections.value.set(slot.date, dateSelections);
    }
  }

  // Update formData with selected slots for validation and data export
  updateSelectedSlots();

  updateSelectedSlots();
};

const updateSelectedSlots = () => {
  // Update formData with all selected slots across all dates for Apple MSP format
  const slots = Array.from(globalSelectedSlots.value.values()).map(slot => ({
    identifier: slot.key,
    startTime: slot.utcTime,
    duration: slot.duration * 60, // Convert to seconds for Apple MSP
  }));

  formData.value.selectedSlots = slots;
};

const selectDate = dateString => {
  // Save current date selections before switching
  if (formData.value.selectedDate && selectedSlotIds.value.size > 0) {
    multiDaySelections.value.set(
      formData.value.selectedDate,
      new Set(selectedSlotIds.value)
    );
  }

  // Switch to new date
  formData.value.selectedDate = dateString;

  // Load selections for the new date
  const dateSelections = multiDaySelections.value.get(dateString) || new Set();
  selectedSlotIds.value = new Set(dateSelections);
};

// Extended navigation methods
const navigateWeek = direction => {
  if (direction === 'prev') {
    currentWeekStart.value = subWeeks(currentWeekStart.value, 1);
  } else {
    currentWeekStart.value = addWeeks(currentWeekStart.value, 1);
  }
};

const navigateMonth = direction => {
  if (direction === 'prev') {
    selectedMonth.value = subMonths(selectedMonth.value, 1);
  } else {
    selectedMonth.value = addMonths(selectedMonth.value, 1);
  }
};

const goToToday = () => {
  const today = new Date();
  currentWeekStart.value = startOfWeek(today);
  selectedMonth.value = today;
  formData.value.selectedDate = format(today, 'yyyy-MM-dd');
  selectedSlotIds.value.clear();
  updateSelectedSlots();
};

const switchViewMode = mode => {
  viewMode.value = mode;
  if (mode === 'month') {
    selectedMonth.value = new Date(formData.value.selectedDate);
  } else {
    currentWeekStart.value = startOfWeek(new Date(formData.value.selectedDate));
  }
};

const clearAllSelections = () => {
  globalSelectedSlots.value.clear();
  selectedSlotIds.value.clear();
  multiDaySelections.value.clear();
  updateSelectedSlots();
};

const removeSlotByKey = slotKey => {
  const slot = globalSelectedSlots.value.get(slotKey);
  if (slot) {
    globalSelectedSlots.value.delete(slotKey);

    // Update multi-day selections map
    const dateSelections = multiDaySelections.value.get(slot.date) || new Set();
    dateSelections.delete(slot.id);
    if (dateSelections.size === 0) {
      multiDaySelections.value.delete(slot.date);
    } else {
      multiDaySelections.value.set(slot.date, dateSelections);
    }

    // Update current day selections if it's the current date
    if (slot.date === formData.value.selectedDate) {
      selectedSlotIds.value.delete(slot.id);
    }

    updateSelectedSlots();
  }
};

const generateQuickSlots = () => {
  const tomorrow = addDays(new Date(), 1);
  const dayAfter = addDays(new Date(), 2);

  const quickDates = [
    format(tomorrow, 'yyyy-MM-dd'),
    format(dayAfter, 'yyyy-MM-dd'),
  ];

  const quickSlots = [];

  quickDates.forEach(dateString => {
    const tempDate = formData.value.selectedDate;
    formData.value.selectedDate = dateString;

    const daySlots = availableSlots.value
      .filter(slot => slot.available)
      .slice(0, 3);
    quickSlots.push(
      ...daySlots.map(slot => ({
        ...slot,
        date: dateString,
        displayDate: format(new Date(dateString), 'MMM d'),
      }))
    );

    formData.value.selectedDate = tempDate;
  });

  return quickSlots.slice(0, 6);
};

const handleKeyNavigation = event => {
  // Don't intercept keys when user is typing in input fields
  const activeElement = document.activeElement;
  if (
    activeElement &&
    (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA')
  ) {
    return;
  }

  const slots = availableSlots.value.filter(slot => slot.available);
  if (slots.length === 0) return;

  switch (event.key) {
    case 'ArrowDown':
      event.preventDefault();
      focusedSlotIndex.value = Math.min(
        focusedSlotIndex.value + 1,
        slots.length - 1
      );
      break;
    case 'ArrowUp':
      event.preventDefault();
      focusedSlotIndex.value = Math.max(focusedSlotIndex.value - 1, 0);
      break;
    case 'Enter':
    case ' ':
      event.preventDefault();
      if (
        focusedSlotIndex.value >= 0 &&
        focusedSlotIndex.value < slots.length
      ) {
        toggleSlot(slots[focusedSlotIndex.value]);
      }
      break;
    case 'Escape':
      closeModal();
      break;
  }
};

const openModal = () => {
  isVisible.value = true;
  isAnimating.value = true;

  // Initialize form data
  if (props.initialData) {
    Object.assign(formData.value, props.initialData);
  }

  // Calculate timezone offset
  const now = new Date();
  formData.value.timezoneOffset = -now.getTimezoneOffset();

  nextTick(() => {
    if (modalRef.value) {
      modalRef.value.focus();
    }
    setTimeout(() => {
      isAnimating.value = false;
    }, 300);
  });
};

const closeModal = () => {
  isAnimating.value = true;
  setTimeout(() => {
    isVisible.value = false;
    isAnimating.value = false;
    emit('close');
  }, 300);
};

const saveTimePickerData = () => {
  if (!isFormValid.value) return;

  // Collect all images that are actually being used
  const usedImageIdentifiers = [
    formData.value.receivedImageIdentifier,
    formData.value.replyImageIdentifier,
  ].filter(Boolean);

  const usedImages = props.availableImages.filter(img =>
    usedImageIdentifiers.includes(img.identifier)
  );

  const timePickerData = {
    event: {
      title: '', // Apple MSP requires empty title in event
      description: formData.value.eventDescription,
      imageIdentifier: formData.value.receivedImageIdentifier, // Include event image
      timeslots: formData.value.selectedSlots,
    },
    timezone_offset: formData.value.timezoneOffset,
    received_title: formData.value.receivedTitle,
    received_subtitle: formData.value.receivedSubtitle,
    received_image_identifier: formData.value.receivedImageIdentifier,
    received_style: formData.value.receivedStyle,
    reply_title: formData.value.replyTitle,
    reply_subtitle: formData.value.replySubtitle,
    reply_image_identifier: formData.value.replyImageIdentifier,
    reply_style: formData.value.replyStyle,
    images: usedImages, // Include the actual images being used
  };

  emit('save', timePickerData);
  closeModal();
};

const saveAndSendTimePickerData = () => {
  if (!isFormValid.value) return;

  // Collect all images that are actually being used
  const usedImageIdentifiers = [
    formData.value.receivedImageIdentifier,
    formData.value.replyImageIdentifier,
  ].filter(Boolean);

  console.log('DEBUG saveAndSendTimePickerData:');
  console.log(
    'receivedImageIdentifier:',
    formData.value.receivedImageIdentifier
  );
  console.log('replyImageIdentifier:', formData.value.replyImageIdentifier);
  console.log('usedImageIdentifiers:', usedImageIdentifiers);

  const usedImages = props.availableImages.filter(img =>
    usedImageIdentifiers.includes(img.identifier)
  );

  console.log(
    'usedImages:',
    usedImages.map(img => img.identifier)
  );

  const timePickerData = {
    event: {
      title: '', // Apple MSP requires empty title in event
      description: formData.value.eventDescription,
      imageIdentifier: formData.value.receivedImageIdentifier, // Include event image
      timeslots: formData.value.selectedSlots,
    },
    timezone_offset: formData.value.timezoneOffset,
    received_title: formData.value.receivedTitle,
    received_subtitle: formData.value.receivedSubtitle,
    received_image_identifier: formData.value.receivedImageIdentifier,
    received_style: formData.value.receivedStyle,
    reply_title: formData.value.replyTitle,
    reply_subtitle: formData.value.replySubtitle,
    reply_image_identifier: formData.value.replyImageIdentifier,
    reply_style: formData.value.replyStyle,
    images: usedImages, // Include the actual images being used
  };

  console.log(
    'timePickerData being sent:',
    JSON.stringify(timePickerData, null, 2)
  );

  emit('saveAndSend', timePickerData);
  closeModal();
};

const previewTimePickerData = () => {
  if (!isFormValid.value) return;

  const timePickerData = {
    event: {
      title: '', // Apple MSP requires empty title in event
      description: formData.value.eventDescription,
      timeslots: formData.value.selectedSlots,
    },
    timezone_offset: formData.value.timezoneOffset,
    received_title: formData.value.receivedTitle,
    received_subtitle: formData.value.receivedSubtitle,
    received_image_identifier: formData.value.receivedImageIdentifier,
    received_style: formData.value.receivedStyle,
    reply_title: formData.value.replyTitle,
    reply_subtitle: formData.value.replySubtitle,
    reply_image_identifier: formData.value.replyImageIdentifier,
    reply_style: formData.value.replyStyle,
  };

  emit('preview', timePickerData);
};

// Watchers
watch(
  () => props.show,
  newValue => {
    if (newValue) {
      openModal();
    } else {
      closeModal();
    }
  }
);

watch(
  () => formData.value.selectedInterval,
  () => {
    selectedSlotIds.value.clear();
    updateSelectedSlots();
  }
);

watch(
  () => formData.value.useBusinessHours,
  () => {
    selectedSlotIds.value.clear();
    updateSelectedSlots();
  }
);

// Image upload handler
const triggerImageUpload = () => {
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
        // Emit to parent to handle image storage
        emit('uploadImage', {
          file,
          data: event.target.result,
          name: file.name,
          size: file.size,
        });
      };
      reader.readAsDataURL(file);
    }
  };
  input.click();
};

// Lifecycle
onMounted(() => {
  document.addEventListener('keydown', handleKeyNavigation);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeyNavigation);
});
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable @intlify/vue-i18n/no-raw-text -->
<template>
  <!-- Modal Backdrop -->
  <Teleport to="body">
    <div
      v-if="isVisible"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-75 transition-opacity duration-300"
      :class="{ 'opacity-100': !isAnimating, 'opacity-0': isAnimating }"
      @click.self="closeModal"
    >
      <!-- Modal Container -->
      <div
        ref="modalRef"
        class="w-full max-w-4xl max-h-[90vh] bg-white dark:bg-n-slate-1 rounded-xl shadow-2xl border border-n-weak dark:border-n-slate-6 overflow-hidden transition-all duration-300 transform"
        :class="{
          'scale-100 opacity-100': !isAnimating,
          'scale-95 opacity-0': isAnimating,
        }"
        tabindex="-1"
        role="dialog"
        aria-labelledby="modal-title"
        aria-describedby="modal-description"
      >
        <!-- Modal Header -->
        <div
          class="flex items-center justify-between p-6 border-b border-n-weak dark:border-n-slate-6"
        >
          <div>
            <h2
              id="modal-title"
              class="text-xl font-semibold text-n-slate-12 dark:text-n-slate-1"
            >
              Enhanced Time Picker
            </h2>
            <p
              id="modal-description"
              class="text-sm text-n-slate-11 dark:text-n-slate-3 mt-1"
            >
              Create advanced scheduling options with granular time slot control
            </p>
          </div>
          <button
            class="text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-3 dark:hover:text-n-slate-1 transition-colors text-xl font-light leading-none p-1"
            aria-label="Close modal"
            @click="closeModal"
          >
            ×
          </button>
        </div>

        <!-- Modal Content -->
        <div class="flex h-[calc(90vh-200px)]">
          <!-- Left Panel - Configuration -->
          <div
            class="w-1/2 p-6 border-r border-n-weak dark:border-n-slate-6 overflow-y-auto"
          >
            <!-- Event Configuration -->
            <div class="mb-6">
              <h3
                class="text-lg font-medium text-n-slate-12 dark:text-n-slate-1 mb-4"
              >
                Event Details
              </h3>
              <div class="space-y-4">
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Event Title *
                  </label>
                  <input
                    v-model="formData.eventTitle"
                    type="text"
                    class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 focus:ring-1 focus:ring-n-blue-8 dark:focus:ring-n-blue-9 transition-colors"
                    placeholder="Schedule Appointment"
                  />
                </div>
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Description
                  </label>
                  <textarea
                    v-model="formData.eventDescription"
                    rows="2"
                    class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 focus:ring-1 focus:ring-n-blue-8 dark:focus:ring-n-blue-9 resize-none transition-colors"
                    placeholder="Select your preferred time slot"
                  />
                </div>
              </div>
            </div>

            <!-- Time Configuration -->
            <div class="mb-6">
              <h3
                class="text-lg font-medium text-n-slate-12 dark:text-n-slate-1 mb-4"
              >
                Time Settings
              </h3>
              <div class="space-y-4">
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Time Interval
                  </label>
                  <div class="grid grid-cols-2 gap-2">
                    <button
                      v-for="interval in intervalOptions"
                      :key="interval.value"
                      class="flex items-center justify-center p-3 border rounded-lg transition-all duration-200 transform hover:scale-105"
                      :class="
                        formData.selectedInterval === interval.value
                          ? 'border-n-blue-8 bg-n-blue-2 text-n-blue-11 dark:border-n-blue-9 dark:bg-n-blue-3 dark:text-n-blue-10 shadow-md'
                          : 'border-n-weak hover:border-n-strong bg-white dark:bg-n-alpha-2 text-n-slate-11 dark:text-n-slate-10 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3'
                      "
                      @click="formData.selectedInterval = interval.value"
                    >
                      <span class="mr-2">{{ interval.icon }}</span>
                      <span class="text-sm font-medium">{{
                        interval.label
                      }}</span>
                    </button>
                  </div>
                </div>

                <div>
                  <label class="flex items-center space-x-2 cursor-pointer">
                    <input
                      v-model="formData.useBusinessHours"
                      type="checkbox"
                      class="w-4 h-4 text-n-blue-9 border-n-weak rounded focus:ring-n-blue-8 dark:focus:ring-n-blue-9 transition-colors"
                    />
                    <span
                      class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11"
                    >
                      Use Business Hours
                    </span>
                  </label>
                </div>

                <div
                  v-if="!formData.useBusinessHours"
                  class="grid grid-cols-2 gap-3"
                >
                  <div>
                    <label
                      class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                    >
                      Start Time
                    </label>
                    <input
                      v-model="formData.customStartTime"
                      type="time"
                      class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 transition-colors"
                    />
                  </div>
                  <div>
                    <label
                      class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                    >
                      End Time
                    </label>
                    <input
                      v-model="formData.customEndTime"
                      type="time"
                      class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 transition-colors"
                    />
                  </div>
                </div>

                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Maximum Slots ({{ formData.maxSlots }})
                  </label>
                  <input
                    v-model.number="formData.maxSlots"
                    type="range"
                    min="1"
                    max="20"
                    class="w-full h-2 bg-n-alpha-3 rounded-lg appearance-none cursor-pointer slider"
                  />
                </div>
              </div>
            </div>

            <!-- Message Configuration -->
            <div class="mb-6">
              <div class="flex items-center justify-between mb-4">
                <h3
                  class="text-lg font-medium text-n-slate-12 dark:text-n-slate-11"
                >
                  Message Settings
                </h3>
                <button
                  type="button"
                  class="px-3 py-1.5 text-sm bg-n-blue-9 dark:bg-n-blue-10 text-white rounded hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-colors"
                  @click="triggerImageUpload"
                >
                  📷 Upload Image
                </button>
              </div>
              <div class="space-y-4">
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Received Message Title *
                  </label>
                  <input
                    v-model="formData.receivedTitle"
                    type="text"
                    class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 transition-colors"
                    placeholder="Please pick a time"
                  />
                </div>
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Received Message Subtitle
                  </label>
                  <input
                    v-model="formData.receivedSubtitle"
                    type="text"
                    class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 transition-colors"
                    placeholder="Select your preferred time slot"
                  />
                </div>
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label
                      class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                    >
                      Received Image
                      <span
                        v-if="!hasAvailableImages"
                        class="text-xs text-n-slate-10 dark:text-n-slate-9 font-normal ml-2"
                      >
                        (Upload in List Picker first)
                      </span>
                    </label>
                    <div class="flex items-center gap-2">
                      <select
                        v-model="formData.receivedImageIdentifier"
                        :disabled="!hasAvailableImages"
                        class="flex-1 px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <option value="">No image</option>
                        <option
                          v-for="image in availableImages"
                          :key="image.identifier"
                          :value="image.identifier"
                        >
                          {{
                            image.originalName ||
                            image.original_name ||
                            image.description ||
                            image.identifier
                          }}
                        </option>
                      </select>
                      <img
                        v-if="
                          formData.receivedImageIdentifier &&
                          getImagePreviewUrl(formData.receivedImageIdentifier)
                        "
                        :src="
                          getImagePreviewUrl(formData.receivedImageIdentifier)
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
                      Received Style
                    </label>
                    <select
                      v-model="formData.receivedStyle"
                      class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
                    >
                      <option value="icon">Icon (280x65)</option>
                      <option value="small">Small (280x85)</option>
                      <option value="large">Large (280x210)</option>
                    </select>
                  </div>
                </div>
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Reply Message Title
                  </label>
                  <input
                    v-model="formData.replyTitle"
                    type="text"
                    class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 transition-colors"
                    placeholder="Thank you!"
                  />
                </div>
                <div>
                  <label
                    class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                  >
                    Reply Message Subtitle
                  </label>
                  <input
                    v-model="formData.replySubtitle"
                    type="text"
                    class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 transition-colors"
                    placeholder="We'll see you then!"
                  />
                </div>
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label
                      class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                    >
                      Reply Image
                      <span
                        v-if="!hasAvailableImages"
                        class="text-xs text-n-slate-10 dark:text-n-slate-9 font-normal ml-2"
                      >
                        (Upload in List Picker first)
                      </span>
                    </label>
                    <div class="flex items-center gap-2">
                      <select
                        v-model="formData.replyImageIdentifier"
                        :disabled="!hasAvailableImages"
                        class="flex-1 px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <option value="">No image</option>
                        <option
                          v-for="image in availableImages"
                          :key="image.identifier"
                          :value="image.identifier"
                        >
                          {{
                            image.originalName ||
                            image.original_name ||
                            image.description ||
                            image.identifier
                          }}
                        </option>
                      </select>
                      <img
                        v-if="
                          formData.replyImageIdentifier &&
                          getImagePreviewUrl(formData.replyImageIdentifier)
                        "
                        :src="getImagePreviewUrl(formData.replyImageIdentifier)"
                        class="w-12 h-12 object-cover rounded border border-n-weak dark:border-n-slate-6 flex-shrink-0"
                        alt="Preview"
                      />
                    </div>
                  </div>
                  <div>
                    <label
                      class="block text-sm font-medium text-n-slate-12 dark:text-n-slate-11 mb-2"
                    >
                      Reply Style
                    </label>
                    <select
                      v-model="formData.replyStyle"
                      class="w-full px-3 py-2 border border-n-weak dark:border-n-slate-6 rounded-lg bg-white dark:bg-n-alpha-2 text-n-slate-12 dark:text-n-slate-11 focus:border-n-blue-8 dark:focus:border-n-blue-9"
                    >
                      <option value="icon">Icon (280x65)</option>
                      <option value="small">Small (280x85)</option>
                      <option value="large">Large (280x210)</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Right Panel - Time Slot Selection -->
          <div class="w-1/2 p-6 overflow-y-auto">
            <!-- Enhanced Date Navigation -->
            <div class="mb-6">
              <div class="flex items-center justify-between mb-4">
                <h3
                  class="text-lg font-medium text-n-slate-12 dark:text-n-slate-1"
                >
                  Select Date
                </h3>

                <!-- View Mode Toggle -->
                <div class="flex bg-n-alpha-2 dark:bg-n-alpha-3 rounded-lg p-1">
                  <button
                    class="px-3 py-1 text-xs font-medium rounded transition-colors"
                    :class="
                      viewMode === 'week'
                        ? 'bg-n-blue-9 text-white dark:bg-n-blue-10'
                        : 'text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9'
                    "
                    @click="switchViewMode('week')"
                  >
                    Week
                  </button>
                  <button
                    class="px-3 py-1 text-xs font-medium rounded transition-colors"
                    :class="
                      viewMode === 'month'
                        ? 'bg-n-blue-9 text-white dark:bg-n-blue-10'
                        : 'text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9'
                    "
                    @click="switchViewMode('month')"
                  >
                    Month
                  </button>
                </div>
              </div>

              <!-- Navigation Controls -->
              <div class="flex items-center justify-between mb-4">
                <button
                  class="flex items-center px-3 py-2 text-sm text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-3 rounded-lg transition-colors"
                  @click="
                    viewMode === 'week'
                      ? navigateWeek('prev')
                      : navigateMonth('prev')
                  "
                >
                  <svg
                    class="w-4 h-4 mr-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 19l-7-7 7-7"
                    />
                  </svg>
                  Previous
                </button>

                <div class="text-center">
                  <div
                    class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11"
                  >
                    {{
                      viewMode === 'week' ? currentWeekLabel : currentMonthLabel
                    }}
                  </div>
                  <button
                    class="text-xs text-n-blue-11 hover:text-n-blue-12 dark:text-n-blue-10 dark:hover:text-n-blue-9 transition-colors"
                    @click="goToToday"
                  >
                    Go to Today
                  </button>
                </div>

                <button
                  class="flex items-center px-3 py-2 text-sm text-n-slate-11 hover:text-n-slate-12 dark:text-n-slate-10 dark:hover:text-n-slate-9 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-3 rounded-lg transition-colors"
                  @click="
                    viewMode === 'week'
                      ? navigateWeek('next')
                      : navigateMonth('next')
                  "
                >
                  Next
                  <svg
                    class="w-4 h-4 ml-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </button>
              </div>

              <!-- Week View -->
              <div
                v-if="viewMode === 'week'"
                class="grid grid-cols-7 gap-1 mb-4"
              >
                <button
                  v-for="day in weekDays"
                  :key="day.date"
                  class="p-2 text-center rounded-lg transition-all duration-200 transform hover:scale-105"
                  :class="[
                    day.isSelected
                      ? 'bg-n-blue-9 text-white dark:bg-n-blue-10 shadow-lg scale-105'
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

              <!-- Month View -->
              <div v-if="viewMode === 'month'" class="mb-4">
                <!-- Month Header -->
                <div class="grid grid-cols-7 gap-1 mb-2">
                  <div
                    v-for="day in [
                      'Sun',
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                    ]"
                    :key="day"
                    class="p-2 text-center text-xs font-medium text-n-slate-11 dark:text-n-slate-10"
                  >
                    {{ day }}
                  </div>
                </div>

                <!-- Month Days -->
                <div class="grid grid-cols-7 gap-1">
                  <button
                    v-for="day in monthDays"
                    :key="day.date"
                    class="p-2 text-center rounded-lg transition-all duration-200 transform hover:scale-105 min-h-[40px]"
                    :class="[
                      day.isSelected
                        ? 'bg-n-blue-9 text-white dark:bg-n-blue-10 shadow-lg scale-105'
                        : day.isToday
                          ? 'bg-n-blue-2 text-n-blue-11 dark:bg-n-blue-3 dark:text-n-blue-10 border border-n-blue-6'
                          : day.hasSlots && !day.isPast && day.isCurrentMonth
                            ? 'bg-n-alpha-1 text-n-slate-11 hover:bg-n-alpha-2 dark:bg-n-alpha-2 dark:text-n-slate-10 dark:hover:bg-n-alpha-3'
                            : day.isCurrentMonth
                              ? 'bg-n-alpha-1 text-n-slate-9 cursor-not-allowed dark:bg-n-alpha-2 dark:text-n-slate-8 opacity-50'
                              : 'text-n-slate-8 dark:text-n-slate-9 opacity-30 cursor-not-allowed',
                    ]"
                    :disabled="
                      !day.hasSlots || day.isPast || !day.isCurrentMonth
                    "
                    @click="selectDate(day.date)"
                  >
                    <div class="text-sm">{{ day.displayDate }}</div>
                  </button>
                </div>
              </div>
            </div>

            <!-- Available Time Slots -->
            <div class="mb-6">
              <div class="flex items-center justify-between mb-4">
                <h3
                  class="text-lg font-medium text-n-slate-12 dark:text-n-slate-1"
                >
                  Available Slots
                </h3>
                <div class="flex items-center space-x-2">
                  <div class="text-sm text-n-slate-11 dark:text-n-slate-10">
                    {{ selectedSlotsData.length }} / {{ formData.maxSlots }}
                    selected
                  </div>
                  <div class="flex space-x-1">
                    <div
                      class="w-3 h-3 bg-n-green-8 rounded-full"
                      title="Available"
                    />
                    <div
                      class="w-3 h-3 bg-n-ruby-8 rounded-full"
                      title="Unavailable"
                    />
                    <div
                      class="w-3 h-3 bg-n-blue-8 rounded-full"
                      title="Selected"
                    />
                  </div>
                </div>
              </div>

              <div v-if="availableSlots.length === 0" class="text-center py-8">
                <div class="text-n-slate-11 dark:text-n-slate-10 text-sm">
                  No available time slots for this date
                </div>
                <div class="text-xs text-n-slate-9 dark:text-n-slate-8 mt-1">
                  Try selecting a different date or adjusting business hours
                </div>
              </div>

              <div
                v-else
                class="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto"
              >
                <button
                  v-for="(slot, index) in availableSlots"
                  :key="slot.id"
                  class="flex items-center justify-between p-3 rounded-lg border transition-all duration-200 transform"
                  :class="[
                    slot.selected
                      ? 'border-n-green-8 bg-n-green-2 text-n-green-11 dark:border-n-green-9 dark:bg-n-green-3 dark:text-n-green-10 scale-105 shadow-md'
                      : slot.available
                        ? 'border-n-weak bg-white hover:border-n-strong hover:bg-n-alpha-1 text-n-slate-11 dark:border-n-slate-6 dark:bg-n-alpha-2 dark:hover:bg-n-alpha-3 dark:text-n-slate-10 hover:scale-102 hover:shadow-sm'
                        : 'border-n-weak bg-n-alpha-1 text-n-slate-9 cursor-not-allowed dark:border-n-slate-7 dark:bg-n-alpha-3 dark:text-n-slate-8 opacity-50',
                    focusedSlotIndex === index &&
                      'ring-2 ring-n-blue-8 dark:ring-n-blue-9',
                  ]"
                  :disabled="!slot.available"
                  :aria-label="`Time slot ${slot.displayTime} to ${slot.displayEndTime}, ${slot.available ? 'available' : 'unavailable'}`"
                  @click="toggleSlot(slot)"
                  @mouseenter="hoveredSlot = slot.id"
                  @mouseleave="hoveredSlot = null"
                >
                  <div class="flex-1">
                    <div class="text-sm font-medium">
                      {{ slot.displayTime }} - {{ slot.displayEndTime }}
                    </div>
                    <div class="text-xs text-current opacity-75">
                      {{ slot.duration }}min
                    </div>
                  </div>

                  <!-- Status Indicator -->
                  <div class="flex-shrink-0 ml-2">
                    <div
                      class="w-3 h-3 rounded-full transition-colors duration-200"
                      :class="
                        slot.selected
                          ? 'bg-n-green-9 dark:bg-n-green-10'
                          : slot.available
                            ? 'bg-n-blue-8 dark:bg-n-blue-9'
                            : 'bg-n-ruby-8 dark:bg-n-ruby-9'
                      "
                    />
                  </div>
                </button>
              </div>
            </div>

            <!-- Selected Slots Summary -->
            <div v-if="selectedSlotsData.length > 0" class="mb-6">
              <h3
                class="text-lg font-medium text-n-slate-12 dark:text-n-slate-1 mb-3"
              >
                Selected Time Slots
              </h3>
              <div class="space-y-2">
                <div
                  v-for="slot in selectedSlotsData"
                  :key="slot.key"
                  class="flex items-center justify-between p-3 bg-n-green-1 dark:bg-n-green-2 border border-n-green-6 dark:border-n-green-7 rounded-lg"
                >
                  <div>
                    <div
                      class="text-sm font-medium text-n-green-11 dark:text-n-green-10"
                    >
                      {{ format(new Date(slot.date), 'MMM d, yyyy') }}
                    </div>
                    <div class="text-sm text-n-green-10 dark:text-n-green-9">
                      {{ slot.displayTime }} - {{ slot.displayEndTime }} ({{
                        slot.duration
                      }}min)
                    </div>
                  </div>
                  <button
                    class="p-1 text-n-green-10 hover:text-n-green-11 dark:text-n-green-9 dark:hover:text-n-green-10 rounded transition-colors"
                    aria-label="Remove time slot"
                    @click="toggleSlot(slot)"
                  >
                    <svg
                      class="w-4 h-4"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M6 18L18 6M6 6l12 12"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>

            <!-- Quick Actions -->
            <div class="mb-6">
              <h3
                class="text-lg font-medium text-n-slate-12 dark:text-n-slate-1 mb-3"
              >
                Quick Actions
              </h3>
              <div class="grid grid-cols-2 gap-2">
                <button
                  class="p-3 text-left border border-n-weak dark:border-n-slate-6 rounded-lg hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 transition-colors"
                  @click="clearAllSelections"
                >
                  <div
                    class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11"
                  >
                    Clear All
                  </div>
                  <div class="text-xs text-n-slate-10 dark:text-n-slate-9">
                    Remove all selections
                  </div>
                </button>
                <button
                  class="p-3 text-left border border-n-weak dark:border-n-slate-6 rounded-lg hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 transition-colors"
                  :disabled="!isFormValid"
                  @click="previewTimePickerData"
                >
                  <div
                    class="text-sm font-medium text-n-slate-12 dark:text-n-slate-11"
                  >
                    Preview
                  </div>
                  <div class="text-xs text-n-slate-10 dark:text-n-slate-9">
                    See how it looks
                  </div>
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div
          class="flex items-center justify-between p-6 border-t border-n-weak dark:border-n-slate-6 bg-n-alpha-1 dark:bg-n-alpha-2 flex-shrink-0"
        >
          <div
            class="flex items-center space-x-2 text-sm text-n-slate-11 dark:text-n-slate-10"
          >
            <svg
              class="w-4 h-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span>
              Timezone: {{ timezone }} ({{
                formData.timezoneOffset > 0 ? '+' : ''
              }}{{ formData.timezoneOffset / 60 }}h)
            </span>
          </div>

          <div class="flex space-x-3">
            <button
              class="px-4 py-2 text-n-slate-11 dark:text-n-slate-10 hover:text-n-slate-12 dark:hover:text-n-slate-9 transition-colors"
              @click="closeModal"
            >
              Cancel
            </button>
            <button
              class="px-4 py-2 border border-n-blue-9 dark:border-n-blue-10 text-n-blue-9 dark:text-n-blue-10 rounded-lg hover:bg-n-blue-1 dark:hover:bg-n-blue-2 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
              :disabled="!isFormValid"
              @click="saveTimePickerData"
            >
              Create Only
            </button>
            <button
              class="px-6 py-2 bg-n-blue-9 dark:bg-n-blue-10 text-white dark:text-n-slate-12 rounded-lg hover:bg-n-blue-10 dark:hover:bg-n-blue-11 transition-all duration-200 transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
              :disabled="!isFormValid"
              @click="saveAndSendTimePickerData"
            >
              Create & Send
            </button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>
