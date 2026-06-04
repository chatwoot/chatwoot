<script setup>
import { computed, ref, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import addDays from 'date-fns/addDays';
import DatePicker from 'vue-datepicker-next';
import {
  SHORTCUT_KEYS,
  getScheduleShortcuts,
  parseNaturalDate,
  formatFullDateTime,
} from 'dashboard/helper/scheduleDateShortcutHelpers';

const props = defineProps({
  modelValue: {
    type: Date,
    default: null,
  },
  dateTimeError: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const { t, locale } = useI18n();

const selectedKey = ref('');
const customText = ref('');
const parsedDate = ref(null);
const inputRef = ref(null);
const datePickerValue = ref(null);
const datePickerOpen = ref(false);

const isCustomMode = computed(() => selectedKey.value === SHORTCUT_KEYS.CUSTOM);

const shortcuts = computed(() =>
  getScheduleShortcuts(new Date(), locale.value)
);

const parsedPreview = computed(() => {
  if (!parsedDate.value) return '';
  return formatFullDateTime(parsedDate.value, locale.value);
});

const isParsedInPast = computed(() => {
  if (!parsedDate.value) return false;
  return parsedDate.value <= new Date();
});

const onSelectShortcut = shortcut => {
  selectedKey.value = shortcut.key;
  customText.value = '';
  parsedDate.value = null;
  datePickerOpen.value = false;
  emit('update:modelValue', shortcut.dateTime);
};

const onSelectCustom = () => {
  selectedKey.value = SHORTCUT_KEYS.CUSTOM;
  customText.value = '';
  parsedDate.value = null;
  datePickerOpen.value = false;
  emit('update:modelValue', null);
  nextTick(() => inputRef.value?.focus());
};

const onCustomInput = () => {
  const date = parseNaturalDate(customText.value, locale.value);
  parsedDate.value = date;
  emit('update:modelValue', date);
};

const openDatePicker = () => {
  datePickerValue.value = parsedDate.value || null;
  datePickerOpen.value = true;
};

const onDatePickerConfirm = value => {
  if (!value) return;
  parsedDate.value = value;
  customText.value = formatFullDateTime(value, locale.value);
  datePickerOpen.value = false;
  emit('update:modelValue', value);
};

const disableBeforeToday = date => date < addDays(new Date(), -1);

const disablePastTimes = date => {
  const now = new Date();
  now.setMinutes(now.getMinutes() - 1);
  return date < now;
};

// Sync local state when modelValue changes externally (edit mode or resetForm)
watch(
  () => props.modelValue,
  newValue => {
    if (!newValue) {
      if (!isCustomMode.value) {
        selectedKey.value = '';
      }
      if (!customText.value) {
        parsedDate.value = null;
      }
    } else if (!selectedKey.value) {
      selectedKey.value = SHORTCUT_KEYS.CUSTOM;
      parsedDate.value = newValue;
      customText.value = formatFullDateTime(newValue, locale.value);
    }
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div class="flex flex-col rounded-xl border border-n-weak bg-n-background">
      <button
        v-for="shortcut in shortcuts"
        :key="shortcut.key"
        type="button"
        class="flex items-center justify-between px-4 py-3 text-sm transition-colors border-b border-n-weak cursor-pointer first:rounded-t-xl"
        :class="
          selectedKey === shortcut.key
            ? 'bg-n-alpha-2 text-n-blue-text'
            : 'text-n-slate-12 hover:bg-n-alpha-1'
        "
        @click="onSelectShortcut(shortcut)"
      >
        <span :class="{ 'font-medium': selectedKey === shortcut.key }">
          {{ t(shortcut.labelI18nKey) }}
        </span>
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
        <span
          class="text-sm"
          :class="
            selectedKey === shortcut.key
              ? 'text-n-blue-text/70'
              : 'text-n-slate-9'
          "
        >
          {{ shortcut.detail }}
        </span>
      </button>

      <div
        class="flex flex-col gap-2 px-4 py-3 transition-colors rounded-b-xl"
        :class="
          isCustomMode ? 'bg-n-alpha-2' : 'cursor-pointer hover:bg-n-alpha-1'
        "
        @click="!isCustomMode && onSelectCustom()"
      >
        <div class="flex items-center gap-2 text-sm">
          <span
            class="i-lucide-keyboard size-4 shrink-0"
            :class="isCustomMode ? 'text-n-blue-text' : ''"
          />
          <span
            :class="
              isCustomMode ? 'text-n-blue-text font-medium' : 'text-n-slate-12'
            "
          >
            {{ t('SCHEDULED_MESSAGES.MODAL.SHORTCUTS.CUSTOM') }}
          </span>
        </div>

        <div v-if="isCustomMode" class="flex flex-col gap-2">
          <div class="flex items-center gap-1.5">
            <input
              ref="inputRef"
              v-model="customText"
              type="text"
              class="min-w-0 flex-1 !mb-0 rounded-lg border bg-n-background px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:ring-1"
              :class="
                dateTimeError
                  ? 'border-n-ruby-9 focus:ring-n-ruby-9'
                  : 'border-n-weak focus:border-n-blue-text focus:ring-n-blue-text'
              "
              :placeholder="
                t('SCHEDULED_MESSAGES.MODAL.CUSTOM_INPUT_PLACEHOLDER')
              "
              :aria-label="
                t('SCHEDULED_MESSAGES.MODAL.CUSTOM_INPUT_PLACEHOLDER')
              "
              @input="onCustomInput"
            />
            <div class="relative shrink-0 [&_.mx-datepicker]:!w-auto">
              <DatePicker
                v-model:value="datePickerValue"
                v-model:open="datePickerOpen"
                type="datetime"
                confirm
                :clearable="false"
                :editable="false"
                :show-second="false"
                :disabled-date="disableBeforeToday"
                :disabled-time="disablePastTimes"
                :confirm-text="t('SCHEDULED_MESSAGES.MODAL.SCHEDULE')"
                append-to-body
                @confirm="onDatePickerConfirm"
              >
                <template #input>
                  <button
                    type="button"
                    class="flex items-center justify-center self-stretch rounded-lg border border-n-weak px-2 py-2 text-n-slate-9 transition-colors hover:bg-n-alpha-1 hover:text-n-slate-12"
                    :title="t('SCHEDULED_MESSAGES.MODAL.DATEPICKER_TOOLTIP')"
                    @click="openDatePicker"
                  >
                    <span class="i-lucide-calendar size-3.5" />
                  </button>
                </template>
              </DatePicker>
            </div>
          </div>

          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <div
            v-if="parsedDate && !isParsedInPast"
            class="flex items-center gap-1.5 text-xs text-n-green-text"
          >
            <span class="i-lucide-check size-3.5 shrink-0" />
            <span>{{ parsedPreview }}</span>
          </div>

          <div
            v-else-if="parsedDate && isParsedInPast"
            class="flex items-center gap-1.5 text-xs text-n-amber-text"
          >
            <span class="i-lucide-alert-triangle size-3.5 shrink-0" />
            <span>{{ t('SCHEDULED_MESSAGES.MODAL.PARSED_DATE_IN_PAST') }}</span>
          </div>

          <div
            v-else-if="customText.length > 2 && !parsedDate"
            class="flex items-center gap-1.5 text-xs text-n-slate-9"
          >
            <span class="i-lucide-help-circle size-3.5 shrink-0" />
            <span>{{ t('SCHEDULED_MESSAGES.MODAL.CUSTOM_INPUT_HINT') }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
