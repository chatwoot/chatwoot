<script setup>
import { ref, computed, watch } from 'vue';
import { debounce } from '@chatwoot/utils';
import Avatar from 'next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import groupContactsAPI from 'dashboard/api/groupContacts';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  conversation: {
    type: Object,
    default: () => ({}),
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
  initialSearchQuery: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:show']);

const localShow = computed({
  get: () => props.show,
  set: value => emit('update:show', value),
});

const searchQuery = ref('');
const members = ref([]);
const currentPage = ref(1);
const totalCount = ref(0);
const isLoading = ref(false);
const hasLoadedOnce = ref(false);

const hasMorePages = computed(() => {
  return members.value.length < totalCount.value;
});

const isSearching = computed(() => searchQuery.value.trim().length > 0);

const primaryContactMatches = computed(() => {
  if (!isSearching.value) return true;
  const query = searchQuery.value.toLowerCase().trim();
  const name = props.contact.name?.toLowerCase() || '';
  const identifier = props.contact.identifier?.toLowerCase() || '';
  return name.includes(query) || identifier.includes(query);
});

const filteredMembers = computed(() => {
  if (!searchQuery.value.trim()) {
    return members.value;
  }
  const query = searchQuery.value.toLowerCase().trim();
  return members.value.filter(member => {
    const name = member.name?.toLowerCase() || '';
    const identifier = member.identifier?.toLowerCase() || '';
    return name.includes(query) || identifier.includes(query);
  });
});

const fetchGroupContacts = async (page = 1) => {
  if (!props.conversation.id) return;

  isLoading.value = true;
  try {
    const response = await groupContactsAPI.getGroupContacts(
      props.conversation.id,
      { page }
    );
    const { meta, payload } = response.data;
    totalCount.value = meta.count;
    currentPage.value = meta.current_page;

    if (page === 1) {
      members.value = payload;
    } else {
      members.value = [...members.value, ...payload];
    }
    hasLoadedOnce.value = true;
  } catch (error) {
    // Silently handle error
  } finally {
    isLoading.value = false;
  }
};

const loadMore = () => {
  if (!isLoading.value && hasMorePages.value) {
    fetchGroupContacts(currentPage.value + 1);
  }
};

const onClose = () => {
  localShow.value = false;
};

const onSearchInput = debounce(() => {
  // Search is done client-side on filtered members
}, 300);

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      // Set initial search query when modal opens
      searchQuery.value = props.initialSearchQuery || '';
      if (!hasLoadedOnce.value) {
        fetchGroupContacts(1);
      }
    }
  },
  { immediate: true }
);
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose">
    <div class="flex flex-col h-auto max-h-[600px]">
      <woot-modal-header
        :header-title="$t('CONVERSATION.GROUP.MEMBERS')"
        :header-content="
          $t('CONVERSATION.GROUP.MEMBER_COUNT', totalCount + 1, {
            n: totalCount + 1,
          })
        "
      />
      <div class="px-8 pb-8">
        <input
          v-model="searchQuery"
          type="text"
          class="w-full px-3 py-2 mb-4 text-sm border rounded-lg border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand"
          :placeholder="$t('CONVERSATION.GROUP.SEARCH_MEMBERS')"
          @input="onSearchInput"
        />

        <div class="max-h-[400px] overflow-y-auto space-y-2">
          <!-- No results message -->
          <div
            v-if="
              isSearching &&
              !primaryContactMatches &&
              filteredMembers.length === 0
            "
            class="py-8 text-center text-n-slate-10"
          >
            {{ $t('CONVERSATION.GROUP.NO_MEMBERS_FOUND') }}
          </div>

          <!-- Primary Contact (shown first if matches search) -->
          <div
            v-if="!isSearching || primaryContactMatches"
            class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-1 border border-n-weak"
          >
            <Avatar
              :src="contact.thumbnail"
              :name="contact.name"
              :size="32"
              rounded-full
            />
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-1">
                <span
                  class="text-sm font-medium truncate text-n-slate-12 capitalize"
                >
                  {{ contact.name }}
                </span>
                <span
                  v-tooltip="$t('CONVERSATION.GROUP.PRIMARY_CONTACT')"
                  class="i-lucide-star text-n-amber-9 text-xs"
                />
              </div>
              <span v-if="contact.identifier" class="text-xs text-n-slate-10">
                {{ contact.identifier }}
              </span>
            </div>
          </div>

          <!-- Group Members -->
          <template v-if="isLoading && !hasLoadedOnce">
            <div class="flex items-center justify-center py-8">
              <Spinner />
            </div>
          </template>
          <template v-else>
            <div
              v-for="member in filteredMembers"
              :key="member.id"
              class="flex items-center gap-3 p-2 rounded-lg bg-n-alpha-1 border border-n-weak"
            >
              <Avatar
                :src="member.thumbnail"
                :name="member.name"
                :size="32"
                rounded-full
              />
              <div class="flex-1 min-w-0">
                <span
                  class="text-sm font-medium truncate text-n-slate-12 capitalize block"
                >
                  {{ member.name }}
                </span>
                <span v-if="member.identifier" class="text-xs text-n-slate-10">
                  {{ member.identifier }}
                </span>
              </div>
            </div>
          </template>
        </div>

        <!-- Load More Button -->
        <div
          v-if="hasMorePages && !searchQuery"
          class="flex justify-center mt-4"
        >
          <button
            class="px-4 py-2 text-sm font-medium rounded-lg text-n-slate-12 bg-n-alpha-2 hover:bg-n-alpha-3 disabled:opacity-50"
            :disabled="isLoading"
            @click="loadMore"
          >
            <span v-if="isLoading" class="flex items-center gap-2">
              <Spinner size="small" />
              {{ $t('CONVERSATION.GROUP.LOAD_MORE') }}
            </span>
            <span v-else>{{ $t('CONVERSATION.GROUP.LOAD_MORE') }}</span>
          </button>
        </div>
      </div>
    </div>
  </woot-modal>
</template>
