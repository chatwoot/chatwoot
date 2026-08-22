<script setup>

import { computed, onMounted, ref } from 'vue';

import { useI18n } from 'vue-i18n';

import { useStore, useMapGetter } from 'dashboard/composables/store';

import { useAccount } from 'dashboard/composables/useAccount';

import { useMacroExecution } from 'dashboard/composables/useMacroExecution';

import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';



import Draggable from 'vuedraggable';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

import MacroItem from './MacroItem.vue';

import NextButton from 'dashboard/components-next/button/Button.vue';

import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';



const props = defineProps({

  conversationId: {

    type: [Number, String],

    required: true,

  },

});



const { t } = useI18n();

const store = useStore();

const { accountScopedUrl } = useAccount();

const { orderedMacros } = useOrderedMacros();

const {

  executingMacroId,

  execute,

  submitPendingAttributes,

  dismissPendingAttributes,

} = useMacroExecution();



const dragging = ref(false);

const collapsedFolders = ref({});

const resolveAttributesModalRef = ref(null);



const macros = useMapGetter('macros/getMacros');

const uiFlags = useMapGetter('macros/getUIFlags');



const folderGroups = computed(() => {

  const groups = new Map();

  orderedMacros.value.forEach(macro => {

    const folder = (macro.folder || '').trim();

    const key = folder || '__uncategorized__';

    if (!groups.has(key)) {

      groups.set(key, {

        key,

        label: folder || t('MACROS.UNCATEGORIZED'),

        macros: [],

      });

    }

    groups.get(key).macros.push(macro);

  });



  return [...groups.values()].sort((a, b) => {

    if (a.key === '__uncategorized__') return 1;

    if (b.key === '__uncategorized__') return -1;

    return a.label.localeCompare(b.label);

  });

});



const hasMultipleFolders = computed(() => folderGroups.value.length > 1);



const toggleFolder = key => {

  const currentlyCollapsed = collapsedFolders.value[key] ?? true;

  collapsedFolders.value = {

    ...collapsedFolders.value,

    [key]: !currentlyCollapsed,

  };

};



// Collapsed by default so agents open folders in order.

const isFolderCollapsed = key => collapsedFolders.value[key] ?? true;



const onDragEnd = () => {

  dragging.value = false;

};



const onExecuteMacro = macro => {

  const pending = execute(macro, props.conversationId);

  if (pending) {

    resolveAttributesModalRef.value?.open(

      pending.missing,

      pending.customAttributes

    );

  }

};



const onFolderOrderChange = (folderKey, newFolderMacros) => {

  const other = orderedMacros.value.filter(macro => {

    const key = (macro.folder || '').trim() || '__uncategorized__';

    return key !== folderKey;

  });

  orderedMacros.value = [...other, ...newFolderMacros];

};



onMounted(() => {

  store.dispatch('macros/get');

});

</script>



<template>

  <div>

    <div v-if="!uiFlags.isFetching && !macros.length" class="p-3">

      <p class="flex flex-col items-center justify-center h-full">

        {{ $t('MACROS.LIST.404') }}

      </p>

      <router-link :to="accountScopedUrl('settings/macros')">

        <NextButton

          faded

          xs

          icon="i-lucide-plus"

          class="mt-1"

          :label="$t('MACROS.HEADER_BTN_TXT')"

        />

      </router-link>

    </div>

    <div

      v-if="uiFlags.isFetching"

      class="flex items-center gap-2 justify-center p-6 text-n-slate-12"

    >

      <span class="text-sm">{{ $t('MACROS.LOADING') }}</span>

      <Spinner class="size-5" />

    </div>



    <template v-if="!uiFlags.isFetching && macros.length">

      <div v-if="hasMultipleFolders" class="flex flex-col gap-0.5">

        <div v-for="group in folderGroups" :key="group.key">

          <button

            type="button"

            class="flex w-full items-center gap-1.5 px-1.5 py-1.5 rounded-md text-start hover:bg-n-alpha-2"

            @click="toggleFolder(group.key)"

          >

            <span

              class="i-lucide-chevron-down size-3.5 text-n-slate-11 transition-transform shrink-0"

              :class="{ '-rotate-90': isFolderCollapsed(group.key) }"

            />

            <span class="text-sm font-normal text-n-slate-11 truncate">

              {{ group.label }}

              <span class="font-normal text-n-slate-10">

                ({{ group.macros.length }})

              </span>

            </span>

          </button>

          <Draggable

            v-show="!isFolderCollapsed(group.key)"

            :model-value="group.macros"

            animation="200"

            ghost-class="ghost"

            handle=".drag-handle"

            item-key="id"

            @update:model-value="value => onFolderOrderChange(group.key, value)"

            @start="dragging = true"

            @end="onDragEnd"

          >

            <template #item="{ element }">

              <MacroItem

                :key="element.id"

                :macro="element"

                :is-executing="executingMacroId === element.id"

                @execute="onExecuteMacro(element)"

              />

            </template>

          </Draggable>

        </div>

      </div>

      <Draggable

        v-else

        v-model="orderedMacros"

        class="p-1"

        animation="200"

        ghost-class="ghost"

        handle=".drag-handle"

        item-key="id"

        @start="dragging = true"

        @end="onDragEnd"

      >

        <template #item="{ element }">

          <MacroItem

            :key="element.id"

            :macro="element"

            :is-executing="executingMacroId === element.id"

            @execute="onExecuteMacro(element)"

          />

        </template>

      </Draggable>

    </template>

    <ConversationResolveAttributesModal

      ref="resolveAttributesModalRef"

      @submit="submitPendingAttributes"

      @close="dismissPendingAttributes"

    />

  </div>

</template>



<style scoped lang="scss">

.ghost {

  @apply opacity-50;

}

</style>


