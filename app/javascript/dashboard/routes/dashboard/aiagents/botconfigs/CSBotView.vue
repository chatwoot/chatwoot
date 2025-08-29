<template>
  <div class="w-full">
    <div class="pb-4">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25 mb-1">
        {{ $t('AGENT_MGMT.CSBOT.TICKET.HEADER') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-4">
        {{ $t('AGENT_MGMT.CSBOT.TICKET.HEADER_DESC') }}
      </p>
      <div class="border-b border-gray-200 dark:border-gray-700"></div>
    </div>
    
    <div class="space-y-6">
      <!-- Sidebar Navigation (always show) -->
      <div class="flex flex-row justify-stretch gap-2">
        <!-- Custom Tabs with SVG Icons -->
        <div class="flex flex-col gap-1 min-w-[200px] mr-4">
          <div
            v-for="tab in tabs"
            :key="tab.key"
            class="flex items-center gap-3 px-4 py-3 cursor-pointer rounded-lg transition-all duration-200 hover:bg-gray-50 dark:hover:bg-gray-800/50"
            :class="{
              'bg-woot-50 border-l-4 border-woot-500 text-woot-600 dark:bg-woot-900/50 dark:border-woot-400 dark:text-woot-400': tab.index === activeIndex,
              'text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200': tab.index !== activeIndex,
            }"
            @click="activeIndex = tab.index"
          >
            <span
              :class="[
                tab.icon,
                'w-5 h-5 transition-all duration-200',
                {
                  'text-woot-600 dark:text-woot-400': tab.index === activeIndex,
                  'text-gray-500 dark:text-gray-400': tab.index !== activeIndex,
                }
              ]"
            />
            <span class="text-sm">{{ tab.name }}</span>
          </div>
        </div>

        <div v-show="activeIndex === 0" class="w-full min-w-0">
          <GeneralTab :config="config" :data="data"/>
        </div>
        <div v-show="activeIndex === 1" class="w-full min-w-0">
          <FileKnowledgeSources :data="data" />
        </div>
        <div v-show="activeIndex === 2" class="w-full">
          <QnaKnowledgeSources :data="data" />
        </div>
        <div v-show="activeIndex === 3" class="w-full">
          <CategoryTab :data="data" />
        </div>
        <div v-show="activeIndex === 4" class="w-full">
          <PrioritiesTab :data="data" />
        </div>
        <div v-show="activeIndex === 5" class="w-full">
          <ProductCatalogTab :data="data" />
        </div>
      </div>

      <!-- Submit Button -->
      <!-- <div class="pt-6">
        <button
          class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
          @click="submitConfig"
        >
          {{ $t('AGENT_MGMT.FORM_CREATE.SUBMIT') }}
        </button>
      </div> -->
    </div>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import FileKnowledgeSources from '../knowledge-sources/FileKnowledgeSources.vue'
import QnaKnowledgeSources from '../knowledge-sources/QnaKnowledgeSources.vue'
import CategoryTab from './cs-bot-tabs/CategoryTab.vue'
import PrioritiesTab from './cs-bot-tabs/PrioritiesTab.vue'
import ProductCatalogTab from './cs-bot-tabs/ProductCatalogTab.vue'
import GeneralTab from './cs-bot-tabs/GeneralTab.vue'

const { t } = useI18n()

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
})

const config = reactive({
  ticketSystemActive: false,
  ticketCreateWhen: 'always'
})

const tabs = computed(() => [
  {
    key: '0',
    index: 0,
    name: t('AGENT_MGMT.CSBOT.TICKET.GENERAL_SETTINGS'),
    icon: 'i-lucide-settings',
  },
  {
    key: '1',
    index: 1,
    name: 'File',
    icon: 'i-lucide-folder',
  },
  {
    key: '2',
    index: 2,
    name: 'QnA',
    icon: 'i-lucide-help-circle',
  },
  {
    key: '3',
    index: 3,
    name: t('AGENT_MGMT.CSBOT.TICKET.CATEGORY_TITLE'),
    icon: 'i-lucide-tag',
  },
  {
    key: '4',
    index: 4,
    name: t('AGENT_MGMT.CSBOT.TICKET.PRIORITY_TITLE'),
    icon: 'i-lucide-star',
  },
  // {
  //   key: '5',
  //   index: 5,
  //   name: 'Catalog',
  //   icon: 'i-lucide-shopping-cart',
  // },
])

const activeIndex = ref(0)

// function submitConfig() {
//   console.log('Submitting config:', config)
//   // TODO: API call integration
// }
</script>

<style lang="css">
/* Custom tab styling for PNG icons */
.custom-tab {
  transition: all 0.2s ease-in-out;
}

.custom-tab:hover {
  background-color: #f8fafc;
}

.custom-tab.active {
  background-color: #f0f9ff;
  border-left: 4px solid #3b82f6;
}
</style>