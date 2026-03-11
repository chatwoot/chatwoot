<script setup>
import { ref, computed, toRef, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import {
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  findComponentByType,
} from 'dashboard/helper/templateHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { useI18n } from 'vue-i18n';

const TAB_RECENT = 0;
const TAB_FAVORITES = 1;
const TAB_ALL = 2;
const MAX_RECENT = 10;

const props = defineProps({
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSelect']);

const { t } = useI18n();
const store = useStore();
const query = ref('');
const isRefreshing = ref(false);
const activeTabIndex = ref(TAB_RECENT);
const favorites = ref([]);
const recentTemplates = ref([]);

const accountId = useMapGetter('getCurrentAccountId');

const favStorageKey = computed(
  () =>
    `${LOCAL_STORAGE_KEYS.FAVORITE_WA_TEMPLATES}::${accountId.value}::${props.inboxId}`
);
const recentStorageKey = computed(
  () =>
    `${LOCAL_STORAGE_KEYS.RECENT_WA_TEMPLATES}::${accountId.value}::${props.inboxId}`
);

const whatsAppTemplateMessages = useFunctionGetter(
  'inboxes/getFilteredWhatsAppTemplates',
  toRef(props, 'inboxId')
);

const loadFromStorage = () => {
  favorites.value =
    LocalStorage.get(favStorageKey.value) || [];
  recentTemplates.value =
    LocalStorage.get(recentStorageKey.value) || [];
};

const saveFavorites = () => {
  LocalStorage.set(favStorageKey.value, favorites.value);
};

const saveRecents = () => {
  LocalStorage.set(recentStorageKey.value, recentTemplates.value);
};

const isFavorite = template => {
  return favorites.value.some(
    f => f.name === template.name && f.language === template.language
  );
};

const toggleFavorite = (event, template) => {
  event.stopPropagation();
  const idx = favorites.value.findIndex(
    f => f.name === template.name && f.language === template.language
  );
  if (idx >= 0) {
    favorites.value.splice(idx, 1);
  } else {
    favorites.value.push({
      name: template.name,
      language: template.language,
    });
  }
  saveFavorites();
};

const addToRecent = template => {
  const entry = { name: template.name, language: template.language };
  recentTemplates.value = recentTemplates.value.filter(
    r => !(r.name === entry.name && r.language === entry.language)
  );
  recentTemplates.value.unshift(entry);
  if (recentTemplates.value.length > MAX_RECENT) {
    recentTemplates.value = recentTemplates.value.slice(0, MAX_RECENT);
  }
  saveRecents();
};

const matchesQuery = template =>
  template.name.toLowerCase().includes(query.value.toLowerCase());

const favoriteTemplates = computed(() =>
  whatsAppTemplateMessages.value.filter(
    tpl =>
      isFavorite(tpl) && matchesQuery(tpl)
  )
);

const recentTemplatesList = computed(() => {
  const all = whatsAppTemplateMessages.value;
  return recentTemplates.value
    .map(r => all.find(tpl => tpl.name === r.name && tpl.language === r.language))
    .filter(tpl => tpl && matchesQuery(tpl));
});

const allFilteredTemplates = computed(() =>
  whatsAppTemplateMessages.value.filter(matchesQuery)
);

const displayedTemplates = computed(() => {
  switch (activeTabIndex.value) {
    case TAB_FAVORITES:
      return favoriteTemplates.value;
    case TAB_RECENT:
      return recentTemplatesList.value;
    default:
      return allFilteredTemplates.value;
  }
});

const tabs = computed(() => [
  {
    label: t('WHATSAPP_TEMPLATES.PICKER.TABS.RECENT'),
    count: recentTemplates.value.length,
  },
  {
    label: t('WHATSAPP_TEMPLATES.PICKER.TABS.FAVORITES'),
    count: favorites.value.length,
  },
  {
    label: t('WHATSAPP_TEMPLATES.PICKER.TABS.ALL'),
    count: whatsAppTemplateMessages.value.length,
  },
]);

const emptyStateMessage = computed(() => {
  if (activeTabIndex.value === TAB_FAVORITES) {
    return t('WHATSAPP_TEMPLATES.PICKER.NO_FAVORITES');
  }
  if (activeTabIndex.value === TAB_RECENT) {
    return t('WHATSAPP_TEMPLATES.PICKER.NO_RECENT');
  }
  return '';
});

const getTemplateBody = template =>
  findComponentByType(template, COMPONENT_TYPES.BODY)?.text || '';

const getTemplateHeader = template =>
  findComponentByType(template, COMPONENT_TYPES.HEADER);

const getTemplateFooter = template =>
  findComponentByType(template, COMPONENT_TYPES.FOOTER);

const getTemplateButtons = template =>
  findComponentByType(template, COMPONENT_TYPES.BUTTONS);

const hasMediaContent = template => {
  const header = getTemplateHeader(template);
  return header && MEDIA_FORMATS.includes(header.format);
};

const onTabChanged = tab => {
  const index = tabs.value.findIndex(item => item.label === tab.label);
  activeTabIndex.value = index >= 0 ? index : TAB_ALL;
};

const onSelectTemplate = template => {
  addToRecent(template);
  emit('onSelect', template);
};

const refreshTemplates = async () => {
  isRefreshing.value = true;
  try {
    await store.dispatch('inboxes/syncTemplates', props.inboxId);
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.REFRESH_SUCCESS'));
  } catch (error) {
    useAlert(t('WHATSAPP_TEMPLATES.PICKER.REFRESH_ERROR'));
  } finally {
    isRefreshing.value = false;
  }
};

onMounted(loadFromStorage);

defineExpose({ addToRecent });
</script>

<template>
  <div class="w-full">
    <!-- Tabs -->
    <div class="mb-2.5">
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeTabIndex"
        @tab-changed="onTabChanged"
      />
    </div>

    <!-- Search + Refresh -->
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
      >
        <fluent-icon icon="search" class="text-n-slate-12" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
          autocomplete="off"
        />
      </div>
      <button
        :disabled="isRefreshing"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 disabled:opacity-50 disabled:cursor-not-allowed"
        :title="t('WHATSAPP_TEMPLATES.PICKER.REFRESH_BUTTON')"
        :aria-label="t('WHATSAPP_TEMPLATES.PICKER.REFRESH_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="text-n-slate-12 size-4"
          :class="{ 'animate-spin': isRefreshing }"
        />
      </button>
    </div>

    <!-- Template List -->
    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div
        v-for="(template, i) in displayedTemplates"
        :key="`${template.name}-${template.language}`"
      >
        <div
          class="relative group rounded-lg hover:bg-n-alpha-2 dark:hover:bg-n-solid-2"
        >
          <button
            class="block p-2.5 pr-10 w-full text-left rounded-lg cursor-pointer"
            @click="onSelectTemplate(template)"
          >
            <div>
              <div class="flex justify-between items-center mb-2.5">
                <p class="text-sm truncate mr-2">
                  {{ template.name }}
                </p>
                <span
                  class="inline-block shrink-0 px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
                >
                  {{ t('WHATSAPP_TEMPLATES.PICKER.LABELS.LANGUAGE') }}:
                  {{ template.language }}
                </span>
              </div>

              <!-- Header -->
              <div v-if="getTemplateHeader(template)" class="mb-3">
                <p class="text-xs font-medium text-n-slate-11">
                  {{ t('WHATSAPP_TEMPLATES.PICKER.HEADER') }}
                </p>
                <div
                  v-if="getTemplateHeader(template).format === 'TEXT'"
                  class="text-sm font-mono"
                >
                  {{ getTemplateHeader(template).text }}
                </div>
                <div
                  v-else-if="hasMediaContent(template)"
                  class="text-sm italic text-n-slate-11"
                >
                  {{
                    t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT', {
                      format: getTemplateHeader(template).format,
                    }) ||
                    `${getTemplateHeader(template).format} ${t('WHATSAPP_TEMPLATES.PICKER.MEDIA_CONTENT_FALLBACK')}`
                  }}
                </div>
              </div>

              <!-- Body -->
              <div>
                <p class="text-xs font-medium text-n-slate-11">
                  {{ t('WHATSAPP_TEMPLATES.PICKER.BODY') }}
                </p>
                <p class="text-sm font-mono">
                  {{ getTemplateBody(template) }}
                </p>
              </div>

              <!-- Footer -->
              <div v-if="getTemplateFooter(template)" class="mt-3">
                <p class="text-xs font-medium text-n-slate-11">
                  {{ t('WHATSAPP_TEMPLATES.PICKER.FOOTER') }}
                </p>
                <p class="text-sm font-mono">
                  {{ getTemplateFooter(template).text }}
                </p>
              </div>

              <!-- Buttons -->
              <div v-if="getTemplateButtons(template)" class="mt-3">
                <p class="text-xs font-medium text-n-slate-11">
                  {{ t('WHATSAPP_TEMPLATES.PICKER.BUTTONS') }}
                </p>
                <div class="flex flex-wrap gap-1 mt-1">
                  <span
                    v-for="button in getTemplateButtons(template).buttons"
                    :key="button.text"
                    class="px-2 py-1 text-xs rounded bg-n-slate-3 text-n-slate-12"
                  >
                    {{ button.text }}
                  </span>
                </div>
              </div>

              <div class="mt-3">
                <p class="text-xs font-medium text-n-slate-11">
                  {{ t('WHATSAPP_TEMPLATES.PICKER.CATEGORY') }}
                </p>
                <p class="text-sm">{{ template.category }}</p>
              </div>
            </div>
          </button>

          <!-- Favorite Star Button -->
          <button
            class="absolute top-2 right-2 flex items-center justify-center w-8 h-8 rounded-md transition-colors duration-150 hover:bg-n-alpha-3 dark:hover:bg-n-solid-3 focus-visible:ring-2 focus-visible:ring-n-brand focus-visible:outline-none"
            :aria-label="
              isFavorite(template)
                ? t('WHATSAPP_TEMPLATES.PICKER.REMOVE_FROM_FAVORITES')
                : t('WHATSAPP_TEMPLATES.PICKER.ADD_TO_FAVORITES')
            "
            @click="toggleFavorite($event, template)"
          >
            <i
              :class="[
                isFavorite(template)
                  ? 'i-ri-star-fill text-n-amber-9'
                  : 'i-ri-star-line text-n-slate-10 group-hover:text-n-slate-11',
              ]"
              class="size-5 transition-colors duration-150"
            />
          </button>
        </div>
        <hr
          v-if="i !== displayedTemplates.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-n-weak my-2.5 mx-auto max-w-[95%]"
        />
      </div>

      <!-- Empty States -->
      <div v-if="!displayedTemplates.length" class="py-8 text-center">
        <!-- Search with no results in All tab -->
        <div
          v-if="activeTabIndex === 0 && query && whatsAppTemplateMessages.length"
        >
          <p>
            {{ t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <!-- No templates at all -->
        <div
          v-else-if="activeTabIndex === 0 && !whatsAppTemplateMessages.length"
          class="space-y-4"
        >
          <p class="text-n-slate-11">
            {{ t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_AVAILABLE') }}
          </p>
        </div>
        <!-- Favorites/Recent empty or search miss -->
        <div v-else class="space-y-2">
          <Icon
            :icon="
              activeTabIndex === 1 ? 'i-ri-star-line' : 'i-lucide-clock'
            "
            class="size-8 text-n-slate-9 mx-auto"
          />
          <p class="text-n-slate-11 text-sm">
            {{ query ? `${t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND')} "${query}"` : emptyStateMessage }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
