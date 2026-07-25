<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Draggable from 'vuedraggable';
import Button from 'dashboard/components-next/button/Button.vue';
import { useStoreGetters } from 'dashboard/composables/store';
import {
  useUISettings,
  DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
  SIDEBAR_SECTION_ATTRIBUTE_TYPE,
  attributeCategorySlug,
  SYSTEM_CATEGORY_SLUG,
} from 'dashboard/composables/useUISettings';

const { t } = useI18n();
const getters = useStoreGetters();
const {
  conversationSidebarItemsOrder,
  conversationSidebarVisibleItems,
  isConversationSidebarItemVisible,
  toggleConversationSidebarItemVisibility,
  resetConversationSidebarVisibility,
  isConversationSidebarCategoryVisible,
  toggleConversationSidebarCategoryVisibility,
  reorderConversationSidebarCategories,
  conversationSidebarCategoryOrder,
  setConversationSidebarItemsOrder,
} = useUISettings();

const isOpen = ref(false);
const dragging = ref(false);
const sections = ref(
  conversationSidebarItemsOrder.value.map(item => ({ ...item }))
);
/** Local category lists keyed by section name (mutated by Draggable). */
const categoryRows = ref({});

const attributesByType = attributeType =>
  getters['attributes/getAttributesByModel'].value(attributeType) || [];

const buildCategoriesForType = attributeType => {
  const groups = new Map();
  attributesByType(attributeType).forEach(attribute => {
    const label = (attribute?.category || '').trim();
    const slug = attributeCategorySlug(label);
    const key = label || '__uncategorized__';
    if (!groups.has(key)) {
      groups.set(key, {
        key,
        slug,
        title: label || t('CUSTOM_ATTRIBUTES.UNCATEGORIZED'),
      });
    }
  });

  const list = [...groups.values()];

  // Conversation metadata (browser, IP, …) always exposed as System under info.
  if (attributeType === 'conversation_attribute') {
    list.unshift({
      key: '__system__',
      slug: SYSTEM_CATEGORY_SLUG,
      title: t('CUSTOM_ATTRIBUTES.SYSTEM'),
    });
  }

  if (list.length <= 1) return [];

  const savedOrder = conversationSidebarCategoryOrder(attributeType);
  return list.sort((a, b) => {
    if (savedOrder.length) {
      const aPos = savedOrder.indexOf(a.slug);
      const bPos = savedOrder.indexOf(b.slug);
      if (aPos !== -1 || bPos !== -1) {
        if (aPos === -1) return 1;
        if (bPos === -1) return -1;
        return aPos - bPos;
      }
    }
    if (a.key === '__system__') return -1;
    if (b.key === '__system__') return 1;
    if (a.key === '__uncategorized__') return 1;
    if (b.key === '__uncategorized__') return -1;
    return a.title.localeCompare(b.title);
  });
};

const syncFromSettings = () => {
  if (dragging.value) return;
  sections.value = conversationSidebarItemsOrder.value.map(item => ({
    ...item,
  }));
  const rows = {};
  Object.entries(SIDEBAR_SECTION_ATTRIBUTE_TYPE).forEach(
    ([sectionName, attributeType]) => {
      rows[sectionName] = buildCategoriesForType(attributeType);
    }
  );
  categoryRows.value = rows;
};

const visibleCount = computed(
  () =>
    sections.value.filter(item =>
      conversationSidebarVisibleItems.value.includes(item.name)
    ).length
);

const sectionLabel = name => {
  const key = `CONVERSATION.SIDEBAR.MENU.${name}`;
  const translated = t(key);
  return translated === key ? name : translated;
};

const toggleMenu = () => {
  if (!isOpen.value) syncFromSettings();
  isOpen.value = !isOpen.value;
};

const closeMenu = () => {
  isOpen.value = false;
};

const onSectionDragEnd = () => {
  dragging.value = false;
  setConversationSidebarItemsOrder(sections.value.map(item => ({ ...item })));
};

const onToggleSection = name => {
  toggleConversationSidebarItemVisibility(name);
};

const onToggleCategory = (sectionName, slug) => {
  const attributeType = SIDEBAR_SECTION_ATTRIBUTE_TYPE[sectionName];
  if (!attributeType) return;
  const allSlugs = (categoryRows.value[sectionName] || []).map(c => c.slug);
  toggleConversationSidebarCategoryVisibility(attributeType, slug, allSlugs);
};

const onCategoryDragEnd = sectionName => {
  const attributeType = SIDEBAR_SECTION_ATTRIBUTE_TYPE[sectionName];
  if (!attributeType) return;
  const order = (categoryRows.value[sectionName] || []).map(c => c.slug);
  reorderConversationSidebarCategories(attributeType, order);
};

const onReset = () => {
  resetConversationSidebarVisibility();
  sections.value = DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER.map(item => ({
    ...item,
  }));
  const rows = {};
  Object.entries(SIDEBAR_SECTION_ATTRIBUTE_TYPE).forEach(
    ([sectionName, attributeType]) => {
      rows[sectionName] = buildCategoriesForType(attributeType);
    }
  );
  categoryRows.value = rows;
};
</script>

<template>
  <div v-on-clickaway="closeMenu" class="relative">
    <Button
      v-tooltip="$t('CONVERSATION.SIDEBAR.MENU.TITLE')"
      icon="i-lucide-ellipsis-vertical"
      ghost
      xs
      :class="isOpen ? 'bg-n-alpha-2' : ''"
      @click.stop="toggleMenu"
    />
    <div
      v-if="isOpen"
      class="absolute z-50 ltr:right-0 rtl:left-0 top-full mt-1 w-72 rounded-xl border border-n-weak bg-n-alpha-3 dark:bg-n-solid-2 shadow-lg overflow-hidden"
      @click.stop
    >
      <div
        class="flex items-center justify-between gap-2 px-3 py-2 border-b border-n-weak"
      >
        <div class="min-w-0">
          <p class="mb-0 text-xs font-medium text-n-slate-12 truncate">
            {{ $t('CONVERSATION.SIDEBAR.MENU.TITLE') }}
          </p>
          <p class="mb-0 text-[11px] text-n-slate-11">
            {{
              $t('CONVERSATION.SIDEBAR.MENU.VISIBLE_COUNT', {
                count: visibleCount,
              })
            }}
            · {{ $t('CONVERSATION.SIDEBAR.MENU.ORDER_HINT') }}
          </p>
        </div>
        <Button
          ghost
          xs
          :label="$t('CONVERSATION.SIDEBAR.MENU.RESET')"
          @click="onReset"
        />
      </div>

      <Draggable
        v-model="sections"
        animation="200"
        ghost-class="opacity-50"
        handle=".section-drag-handle"
        item-key="name"
        class="max-h-80 overflow-y-auto py-1"
        @start="dragging = true"
        @end="onSectionDragEnd"
      >
        <template #item="{ element }">
          <div class="border-b border-n-weak/40 last:border-0">
            <div class="flex items-center gap-2 px-2 py-1.5 hover:bg-n-alpha-2">
              <span
                class="section-drag-handle i-lucide-grip-vertical size-3.5 shrink-0 text-n-slate-10 cursor-grab"
              />
              <label
                class="flex flex-1 items-center gap-2 min-w-0 cursor-pointer"
              >
                <input
                  type="checkbox"
                  class="rounded border-n-weak text-n-brand focus:ring-n-brand"
                  :checked="isConversationSidebarItemVisible(element.name)"
                  @change="onToggleSection(element.name)"
                />
                <span class="text-sm text-n-slate-12 truncate">
                  {{ sectionLabel(element.name) }}
                </span>
              </label>
            </div>

            <Draggable
              v-if="
                isConversationSidebarItemVisible(element.name) &&
                categoryRows[element.name]?.length
              "
              :list="categoryRows[element.name]"
              animation="200"
              ghost-class="opacity-50"
              handle=".category-drag-handle"
              item-key="slug"
              class="pb-1 pl-7 pr-2"
              @end="onCategoryDragEnd(element.name)"
            >
              <template #item="{ element: category }">
                <div
                  class="flex items-center gap-2 py-1 px-1 rounded-md hover:bg-n-alpha-2"
                >
                  <span
                    class="category-drag-handle i-lucide-grip-vertical size-3 shrink-0 text-n-slate-10 cursor-grab"
                  />
                  <label
                    class="flex flex-1 items-center gap-2 min-w-0 cursor-pointer"
                  >
                    <input
                      type="checkbox"
                      class="rounded border-n-weak text-n-brand focus:ring-n-brand"
                      :checked="
                        isConversationSidebarCategoryVisible(
                          SIDEBAR_SECTION_ATTRIBUTE_TYPE[element.name],
                          category.slug
                        )
                      "
                      @change="onToggleCategory(element.name, category.slug)"
                    />
                    <span class="text-xs text-n-slate-11 truncate">
                      {{ category.title }}
                    </span>
                  </label>
                </div>
              </template>
            </Draggable>
          </div>
        </template>
      </Draggable>

      <p
        v-if="!visibleCount"
        class="px-3 py-2 text-xs text-n-slate-11 border-t border-n-weak"
      >
        {{ $t('CONVERSATION.SIDEBAR.MENU.EMPTY') }}
      </p>
    </div>
  </div>
</template>
