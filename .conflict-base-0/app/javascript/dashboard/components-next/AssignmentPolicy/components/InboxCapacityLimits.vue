<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';

const props = defineProps({
  inboxList: {
    type: Array,
    default: () => [],
  },
  isFetching: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['delete', 'add', 'update']);

const inboxCapacityLimits = defineModel('inboxCapacityLimits', {
  type: Array,
  default: () => [],
});

const { t } = useI18n();

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY';
const DEFAULT_CONVERSATION_LIMIT = 10;
const MIN_CONVERSATION_LIMIT = 1;
const MAX_CONVERSATION_LIMIT = 100000;

const selectedInboxIds = computed(
  () => new Set(inboxCapacityLimits.value.map(limit => limit.inboxId))
);

const availableInboxes = computed(() =>
  props.inboxList.filter(
    inbox => inbox && !selectedInboxIds.value.has(inbox.id)
  )
);

const isLimitValid = limit => {
  return (
    limit.conversationLimit >= MIN_CONVERSATION_LIMIT &&
    limit.conversationLimit <= MAX_CONVERSATION_LIMIT
  );
};

const inboxMap = computed(
  () => new Map(props.inboxList.map(inbox => [inbox.id, inbox]))
);

const handleAddInbox = inbox => {
  emit('add', {
    inboxId: inbox.id,
    conversationLimit: DEFAULT_CONVERSATION_LIMIT,
  });
};

const handleRemoveLimit = limitId => {
  emit('delete', limitId);
};

const handleLimitChange = limit => {
  if (isLimitValid(limit)) {
    emit('update', limit);
  }
};

const getInboxName = inboxId => {
  return inboxMap.value.get(inboxId)?.name || '';
};
</script>

<template>
  <div class="py-4 flex-col flex gap-3">
    <div class="flex items-center w-full gap-8 justify-between pt-1 pb-3">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.LABEL`) }}
      </label>

      <AddDataDropdown
        :label="t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.ADD_BUTTON`)"
        :search-placeholder="
          t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.SELECT_INBOX`)
        "
        :items="availableInboxes"
        @add="handleAddInbox"
      />
    </div>

    <div
      v-if="isFetching"
      class="flex items-center justify-center py-3 w-full text-n-slate-11"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!inboxCapacityLimits.length"
      class="custom-dashed-border flex items-center justify-center py-6 w-full"
    >
      <span class="text-sm text-n-slate-11">
        {{ t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.EMPTY_STATE`) }}
      </span>
    </div>

    <div v-else class="flex-col flex gap-3">
      <div
        v-for="(limit, index) in inboxCapacityLimits"
        :key="limit.id || `temp-${index}`"
        class="flex flex-col xs:flex-row items-stretch gap-3"
      >
        <div
          class="flex items-center rounded-lg outline-1 outline cursor-not-allowed text-n-slate-11 outline-n-weak py-2.5 px-3 text-sm w-full min-w-0"
          :title="getInboxName(limit.inboxId)"
        >
          <span class="truncate min-w-0">
            {{ getInboxName(limit.inboxId) }}
          </span>
        </div>

        <div class="flex items-center gap-3 w-full xs:w-auto">
          <div
            class="py-2.5 px-3 rounded-lg gap-2 outline outline-1 flex-1 xs:flex-shrink-0 flex items-center min-w-0"
            :class="[
              !isLimitValid(limit) ? 'outline-n-ruby-8' : 'outline-n-weak',
            ]"
          >
            <label
              class="text-sm text-n-slate-12 ltr:pr-2 rtl:pl-2 truncate min-w-0 flex-shrink"
              :title="
                t(
                  `${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.MAX_CONVERSATIONS`
                )
              "
            >
              {{
                t(
                  `${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.MAX_CONVERSATIONS`
                )
              }}
            </label>

            <div class="h-5 w-px bg-n-weak" />

            <input
              v-model.number="limit.conversationLimit"
              type="number"
              :min="MIN_CONVERSATION_LIMIT"
              :max="MAX_CONVERSATION_LIMIT"
              class="reset-base bg-transparent focus:outline-none min-w-16 w-24 text-sm flex-shrink-0"
              :class="[
                !isLimitValid(limit)
                  ? 'placeholder:text-n-ruby-9 !text-n-ruby-9'
                  : 'placeholder:text-n-slate-10 text-n-slate-12',
              ]"
              :placeholder="
                t(`${BASE_KEY}.FORM.INBOX_CAPACITY_LIMIT.FIELD.SET_LIMIT`)
              "
              @blur="handleLimitChange(limit)"
            />
          </div>

          <Button
            type="button"
            slate
            icon="i-lucide-trash"
            class="flex-shrink-0"
            @click="handleRemoveLimit(limit.id)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
