<script setup>
import { useI18n } from 'vue-i18n';
import {
  COMPONENT_ICONS,
  COMPONENT_LABELS,
} from 'dashboard/helper/whatsappFlowHelper';

const props = defineProps({
  screen: { type: Object, required: true },
  selectedIndex: { type: Number, default: null },
  // eslint-disable-next-line vue/no-unused-properties
  screens: { type: Array, required: true },
});

const emit = defineEmits(['select', 'remove', 'move', 'add']);

const { t } = useI18n();

function moveUp(index) {
  if (index > 0) emit('move', index, index - 1);
}

function moveDown(index) {
  if (index < props.screen.layout.children.length - 1) {
    emit('move', index, index + 1);
  }
}

function getComponentIcon(type) {
  return COMPONENT_ICONS[type] || 'i-lucide-box';
}

function getComponentLabel(type) {
  return COMPONENT_LABELS[type] || type;
}

function getComponentPreview(component) {
  if (component.text) return component.text;
  if (component.label) return component.label;
  if (component.src) return 'Image';
  return '';
}
</script>

<template>
  <div class="flex-1 overflow-y-auto p-6">
    <!-- Screen header -->
    <div class="mb-4">
      <div class="flex items-center gap-2 mb-2">
        <span class="i-lucide-smartphone size-5 text-n-slate-9" />
        <h2 class="text-sm font-semibold text-n-slate-12">
          {{ props.screen.title }}
        </h2>
        <span class="text-xs text-n-slate-9">({{ props.screen.id }})</span>
      </div>
    </div>

    <!-- Phone frame preview -->
    <div class="max-w-sm mx-auto">
      <div
        class="bg-white rounded-2xl shadow-lg border border-n-weak overflow-hidden"
      >
        <!-- Phone status bar -->
        <div class="bg-[#075E54] px-4 py-2 flex items-center gap-2">
          <span class="i-lucide-arrow-left size-4 text-white" />
          <span class="text-white text-sm font-medium flex-1">
            {{ props.screen.title }}
          </span>
        </div>

        <!-- Screen components -->
        <div class="p-4 space-y-3 min-h-[300px]">
          <div
            v-for="(child, index) in props.screen.layout.children"
            :key="child._id || index"
            class="group relative rounded-lg border-2 p-3 cursor-pointer transition-all"
            :class="[
              index === props.selectedIndex
                ? 'border-n-brand bg-n-brand-subtle/30'
                : 'border-transparent hover:border-n-weak',
            ]"
            @click="emit('select', index)"
          >
            <!-- Component icon + label -->
            <div class="flex items-center gap-2 mb-1">
              <span
                class="size-3.5 text-n-slate-9"
                :class="[getComponentIcon(child.type)]"
              />
              <span
                class="text-[10px] font-medium text-n-slate-9 uppercase tracking-wide"
              >
                {{ getComponentLabel(child.type) }}
              </span>
            </div>

            <!-- Component preview -->
            <div class="text-sm text-n-slate-12">
              <!-- Text components -->
              <template v-if="child.type === 'TextHeading'">
                <h3 class="text-lg font-bold">{{ child.text }}</h3>
              </template>
              <template v-else-if="child.type === 'TextSubheading'">
                <h4 class="text-base font-semibold">{{ child.text }}</h4>
              </template>
              <template v-else-if="child.type === 'TextBody'">
                <p>{{ child.text }}</p>
              </template>
              <template v-else-if="child.type === 'TextCaption'">
                <p class="text-xs text-n-slate-9">{{ child.text }}</p>
              </template>

              <!-- Image -->
              <template v-else-if="child.type === 'Image'">
                <div
                  class="bg-n-alpha-1 rounded-lg h-24 flex items-center justify-center"
                >
                  <img
                    v-if="child.src"
                    :src="child.src"
                    class="max-h-full rounded"
                    alt="Flow image"
                  />
                  <span v-else class="i-lucide-image size-8 text-n-slate-7" />
                </div>
              </template>

              <!-- Text Input -->
              <template v-else-if="child.type === 'TextInput'">
                <div
                  class="border border-n-weak rounded-lg px-3 py-2 bg-n-alpha-1"
                >
                  <span class="text-xs text-n-slate-9">{{ child.label }}</span>
                </div>
              </template>

              <!-- Text Area -->
              <template v-else-if="child.type === 'TextArea'">
                <div
                  class="border border-n-weak rounded-lg px-3 py-4 bg-n-alpha-1"
                >
                  <span class="text-xs text-n-slate-9">{{ child.label }}</span>
                </div>
              </template>

              <!-- Dropdown -->
              <template v-else-if="child.type === 'Dropdown'">
                <div
                  class="border border-n-weak rounded-lg px-3 py-2 bg-n-alpha-1 flex items-center justify-between"
                >
                  <span class="text-xs text-n-slate-9">{{ child.label }}</span>
                  <span class="i-lucide-chevron-down size-4 text-n-slate-7" />
                </div>
              </template>

              <!-- Radio buttons -->
              <template v-else-if="child.type === 'RadioButtonsGroup'">
                <div class="space-y-1">
                  <span class="text-xs text-n-slate-9">{{ child.label }}</span>
                  <div
                    v-for="opt in (child['data-source'] || []).slice(0, 3)"
                    :key="opt.id"
                    class="flex items-center gap-2"
                  >
                    <span class="size-3 rounded-full border border-n-weak" />
                    <span class="text-xs">{{ opt.title }}</span>
                  </div>
                </div>
              </template>

              <!-- Checkbox group -->
              <template v-else-if="child.type === 'CheckboxGroup'">
                <div class="space-y-1">
                  <span class="text-xs text-n-slate-9">{{ child.label }}</span>
                  <div
                    v-for="opt in (child['data-source'] || []).slice(0, 3)"
                    :key="opt.id"
                    class="flex items-center gap-2"
                  >
                    <span class="size-3 rounded border border-n-weak" />
                    <span class="text-xs">{{ opt.title }}</span>
                  </div>
                </div>
              </template>

              <!-- Date Picker -->
              <template v-else-if="child.type === 'DatePicker'">
                <div
                  class="border border-n-weak rounded-lg px-3 py-2 bg-n-alpha-1 flex items-center justify-between"
                >
                  <span class="text-xs text-n-slate-9">{{ child.label }}</span>
                  <span class="i-lucide-calendar size-4 text-n-slate-7" />
                </div>
              </template>

              <!-- Opt-in -->
              <template v-else-if="child.type === 'OptIn'">
                <div class="flex items-center gap-2">
                  <span class="size-4 rounded border border-n-weak" />
                  <span class="text-xs">{{ child.label }}</span>
                </div>
              </template>

              <!-- Footer (Submit button) -->
              <template v-else-if="child.type === 'Footer'">
                <div
                  class="bg-[#25D366] text-white text-center py-2 rounded-lg text-sm font-medium"
                >
                  {{ child.label }}
                </div>
              </template>

              <!-- Embedded Link -->
              <template v-else-if="child.type === 'EmbeddedLink'">
                <span class="text-n-brand underline text-sm">{{
                  child.text
                }}</span>
              </template>

              <!-- Fallback -->
              <template v-else>
                <span class="text-xs text-n-slate-9">{{
                  getComponentPreview(child)
                }}</span>
              </template>
            </div>

            <!-- Action buttons (visible on hover/selection) -->
            <div
              class="absolute top-1 right-1 flex items-center gap-0.5"
              :class="[
                index === props.selectedIndex
                  ? 'opacity-100'
                  : 'opacity-0 group-hover:opacity-100',
              ]"
            >
              <button
                v-if="index > 0"
                class="p-1 rounded text-n-slate-9 hover:bg-n-alpha-2"
                @click.stop="moveUp(index)"
              >
                <span class="i-lucide-chevron-up size-3" />
              </button>
              <button
                v-if="index < props.screen.layout.children.length - 1"
                class="p-1 rounded text-n-slate-9 hover:bg-n-alpha-2"
                @click.stop="moveDown(index)"
              >
                <span class="i-lucide-chevron-down size-3" />
              </button>
              <button
                class="p-1 rounded text-n-slate-9 hover:text-n-ruby-9"
                @click.stop="emit('remove', index)"
              >
                <span class="i-lucide-x size-3" />
              </button>
            </div>
          </div>
        </div>

        <!-- Add component button -->
        <div class="px-4 pb-4">
          <button
            class="w-full py-2 border-2 border-dashed border-n-weak rounded-lg text-sm text-n-slate-9 hover:border-n-brand hover:text-n-brand transition-colors flex items-center justify-center gap-2"
            @click="emit('add')"
          >
            <span class="i-lucide-plus size-4" />
            {{ t('WHATSAPP_FLOWS.CANVAS.ADD_COMPONENT') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
