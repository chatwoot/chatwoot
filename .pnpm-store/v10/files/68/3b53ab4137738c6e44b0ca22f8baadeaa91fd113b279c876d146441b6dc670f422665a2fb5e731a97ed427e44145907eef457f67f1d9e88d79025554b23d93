<script lang="ts" setup>
import { useDebounce, useFocus } from '@vueuse/core'
import { computed, ref, watch } from 'vue'
import { Icon } from '@iconify/vue'
import * as flexsearch from 'flexsearch'
import charset from 'flexsearch/dist/module/lang/latin/advanced.js'
import language from 'flexsearch/dist/module/lang/en.js'
import type { ClientCommand } from '@histoire/shared'
import { registeredCommands } from 'virtual:$histoire-commands'
import { useStoryStore } from '../../stores/story'
import BaseEmpty from '../base/BaseEmpty.vue'
import type { SearchResult, SearchResultType, Story, Variant } from '../../types'
import { builtinCommands, getCommandContext } from '../../util/commands.js'
import { useCommandStore } from '../../stores/command.js'
import { useSelection } from '../../util/select.js'
import SearchItem from './SearchItem.vue'
import { onUpdate, searchData } from './search-title-data'
import type { SearchData } from './types'

const DocSearchData = () => import('./search-docs-data')

const props = defineProps({
  shown: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits({
  close: () => true,
})

function close() {
  emit('close')
}

// Autofocus

const input = ref<HTMLInputElement>()
const { focused } = useFocus(input, {
  initialValue: true,
})

watch(() => props.shown, (value) => {
  if (value) {
    requestAnimationFrame(() => {
      focused.value = true
      input.value.select()
    })
  }
})

// Index

const searchInputText = ref('')
const rateLimitedSearch = useDebounce(searchInputText, 50)

const storyStore = useStoryStore()

let titleSearchIndex: flexsearch.Document<any, any>
let titleIdMap: SearchData['idMap']

function createIndex() {
  return new flexsearch.Document({
    preset: 'match',
    document: {
      id: 'id',
      index: [
        'text',
      ],
    },
    worker: true,
    charset,
    language,
    tokenize: 'forward',
  })
}

async function loadSearchIndex(data: SearchData) {
  titleSearchIndex = createIndex()

  for (const key of Object.keys(data.index)) {
    await titleSearchIndex.import(key, data.index[key])
  }

  titleIdMap = data.idMap
}

loadSearchIndex(searchData)
// Handle HMR
onUpdate((searchData) => {
  loadSearchIndex(searchData)
})

let docSearchIndex: flexsearch.Document<any, any>
let docIdMap: SearchData['idMap']

async function loadDocSearchIndex() {
  async function load(data: SearchData) {
    docSearchIndex = createIndex()

    for (const key of Object.keys(data.index)) {
      await docSearchIndex.import(key, data.index[key])
    }

    docIdMap = data.idMap

    if (rateLimitedSearch.value) {
      searchOnDocField(rateLimitedSearch.value)
    }
  }

  const searchDataModule = await DocSearchData()

  load(searchDataModule.searchData)
  // Handle HMR
  searchDataModule.onUpdate((searchData) => {
    load(searchData)
  })
}

loadDocSearchIndex()

// Search

const titleResults = ref<SearchResult[]>([])

watch(rateLimitedSearch, async (value) => {
  const list: SearchResult[] = []
  const raw = await titleSearchIndex.search(value)
  let rank = 0
  for (const field of raw) {
    for (const id of field.result) {
      const idMapData = titleIdMap[id]
      if (!idMapData) continue
      switch (idMapData.kind) {
        case 'story': {
          list.push(storyResultFactory(storyStore.getStoryById(idMapData.id), rank))
          rank++
          break
        }
        case 'variant': {
          const [storyId] = idMapData.id.split(':')
          const story = storyStore.getStoryById(storyId)
          const variant = storyStore.getVariantById(idMapData.id)
          list.push(variantResultFactory(story, variant, rank))
          rank++
          break
        }
      }
    }
  }
  titleResults.value = list
})

const docsResults = ref<SearchResult[]>([])

async function searchOnDocField(query: string) {
  if (docSearchIndex) {
    const list: SearchResult[] = []
    const raw = await docSearchIndex.search(query)
    let rank = 0
    for (const field of raw) {
      for (const id of field.result) {
        const idMapData = docIdMap[id]
        if (!idMapData) continue
        switch (idMapData.kind) {
          case 'story': {
            list.push(storyResultFactory(storyStore.getStoryById(idMapData.id), rank, 'docs'))
            rank++
            break
          }
        }
      }
    }
    docsResults.value = list
  }
}

watch(rateLimitedSearch, searchOnDocField)

function storyResultFactory(story: Story, rank: number, type: SearchResultType = 'title'): SearchResult {
  return {
    kind: 'story',
    rank,
    id: `story:${story.id}`,
    title: story.title,
    route: {
      name: 'story',
      params: {
        storyId: story.id,
      },
      query: {
        ...type === 'docs'
          ? { tab: 'docs' }
          : {},
      },
    },
    path: story.file.path.slice(0, -1),
    icon: story.icon,
    iconColor: story.iconColor,
  }
}

function variantResultFactory(story: Story, variant: Variant, rank: number, type: SearchResultType = 'title'): SearchResult {
  return {
    kind: 'variant',
    rank,
    id: `variant:${story.id}:${variant.id}`,
    title: variant.title,
    route: {
      name: 'story',
      params: {
        storyId: story.id,
      },
      query: {
        variantId: variant.id,
        ...type === 'docs'
          ? { tab: 'docs' }
          : {},
      },
    },
    path: [...story.file.path ?? [], story.title],
    icon: variant.icon,
    iconColor: variant.iconColor,
  }
}

// Commands

const allCommands = [
  ...builtinCommands,
  ...registeredCommands,
]

const commandResults = computed(() => {
  if (__HISTOIRE_DEV__) {
    const commandCtx = getCommandContext()
    const searchText = searchInputText.value.toLowerCase()
    return allCommands
      .filter(command => !command.showIf || command.showIf(commandCtx))
      .filter(command => command.label.toLowerCase().includes(searchText) || command.searchText?.toLowerCase().includes(searchText))
      .map(command => commandResultFactory(command, 0))
  }
  return []
})

const commandStore = useCommandStore()

function commandResultFactory(command: ClientCommand, rank: number): SearchResult {
  return {
    kind: 'command',
    rank,
    id: `_command:${command.id}`,
    title: command.label,
    icon: command.icon ?? 'carbon:chevron-right',
    onActivate: () => {
      commandStore.activateCommand(command)
    },
  }
}

// Results

const results = computed(() => {
  const list = [
    ...commandResults.value,
    ...titleResults.value,
  ]
  const seen = {}
  for (const r of titleResults.value) {
    seen[r.id] = true
  }
  for (const r of docsResults.value) {
    if (!seen[r.id]) {
      list.push(r)
    }
  }
  return list
})

// Selection

const {
  selectedIndex,
  selectNext,
  selectPrevious,
} = useSelection(results)
</script>

<template>
  <div
    class="histoire-search-pane htw-flex htw-items-center htw-gap-4 htw-pl-6 htw-border htw-border-transparent focus-visible:htw-border-primary-500"
    @click="focused = true"
  >
    <Icon
      icon="carbon:search"
      class="flex-none htw-w-4 htw-h-4"
    />

    <input
      ref="input"
      v-model="searchInputText"
      placeholder="Search for stories, variants..."
      class="htw-bg-transparent htw-w-full htw-flex-1 htw-pl-0 htw-pr-6 htw-py-4 htw-outline-none"
      @keydown.down.prevent="selectNext()"
      @keydown.up.prevent="selectPrevious()"
      @keydown.escape="close()"
    >
  </div>

  <BaseEmpty
    v-if="rateLimitedSearch && !results.length"
    class="no-animation"
  >
    No results
  </BaseEmpty>

  <div
    v-else-if="results.length"
    class="htw-max-h-[400px] htw-overflow-y-auto htw-rounded-b-lg"
  >
    <SearchItem
      v-for="(result, index) of results"
      :key="result.id"
      :result="result"
      :selected="index === selectedIndex"
      @close="close()"
    />
  </div>
</template>
