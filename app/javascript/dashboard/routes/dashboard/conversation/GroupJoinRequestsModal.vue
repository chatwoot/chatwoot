<script setup>
import { computed, ref, watch } from 'vue';
import conversationApi from 'dashboard/api/inbox/conversation';
import { useAlert } from 'dashboard/composables';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Modal from 'dashboard/components/Modal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['requestProcessed']);

const show = defineModel('show', { type: Boolean, default: false });

const requests = ref([]);
const searchQuery = ref('');
const isLoading = ref(false);
const processingParticipant = ref('');
const hasLoadedOnce = ref(false);

const requestIdentifier = request =>
  request.wa_id ||
  request.phone_number ||
  request.phoneNumber ||
  request.pn ||
  request.jid ||
  request.user_id ||
  request.lid ||
  '';

const requestName = request =>
  request.name || request.username || request.wa_id || request.user_id;

const requestSubtitle = request =>
  [request.username, request.wa_id, request.user_id, request.requested_at]
    .filter(Boolean)
    .join(' · ');

const matchesSearch = request => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return true;

  return [requestName(request), requestSubtitle(request)].some(value =>
    value?.toString().toLowerCase().includes(query)
  );
};

const filteredRequests = computed(() => requests.value.filter(matchesSearch));

const joinRequestsFrom = data =>
  data?.join_requests ||
  data?.requests ||
  data?.participants ||
  data?.data ||
  [];

const fetchJoinRequests = async () => {
  if (isLoading.value) return;

  isLoading.value = true;
  try {
    const { data } = await conversationApi.fetchGroupJoinRequests(
      props.conversationId
    );
    requests.value = joinRequestsFrom(data);
    hasLoadedOnce.value = true;
  } finally {
    isLoading.value = false;
  }
};

const processJoinRequest = async (request, action) => {
  const participant = requestIdentifier(request);
  if (!participant || processingParticipant.value) return;

  processingParticipant.value = participant;
  try {
    const { data } =
      action === 'approve'
        ? await conversationApi.approveGroupJoinRequests({
            conversationId: props.conversationId,
            participants: [participant],
          })
        : await conversationApi.rejectGroupJoinRequests({
            conversationId: props.conversationId,
            participants: [participant],
          });
    if (data.failed?.length) {
      useAlert(data.error || data.message || data.failed.join(', '));
      return;
    }

    requests.value = requests.value.filter(
      item => requestIdentifier(item) !== participant
    );
    emit('requestProcessed');
  } catch (error) {
    useAlert(error.response?.data?.error || error.message);
  } finally {
    processingParticipant.value = '';
  }
};

watch(
  () => show.value,
  value => {
    if (!value) return;

    searchQuery.value = '';
    fetchJoinRequests();
  }
);
</script>

<template>
  <Modal v-model:show="show" size="medium">
    <div class="flex max-h-[40rem] flex-col">
      <div class="border-b border-n-weak px-6 py-5">
        <h3 class="m-0 text-lg font-medium text-n-slate-12">
          {{ $t('CONVERSATION.GROUP.JOIN_REQUESTS') }}
        </h3>
        <p class="m-0 text-sm text-n-slate-10">
          {{
            $t('CONVERSATION.GROUP.JOIN_REQUESTS_COUNT', {
              count: requests.length,
            })
          }}
        </p>
      </div>

      <div class="flex flex-1 flex-col gap-3 overflow-hidden px-6 py-4">
        <input
          v-model.trim="searchQuery"
          type="text"
          class="w-full rounded-md border border-n-weak bg-n-background px-3 py-2 text-sm text-n-slate-12"
          :placeholder="$t('CONVERSATION.GROUP.SEARCH_JOIN_REQUESTS')"
        />

        <div class="flex-1 overflow-y-auto">
          <div
            v-if="isLoading && !hasLoadedOnce"
            class="flex items-center justify-center py-10"
          >
            <Spinner />
          </div>
          <div
            v-else-if="!filteredRequests.length"
            class="py-10 text-center text-sm text-n-slate-10"
          >
            {{ $t('CONVERSATION.GROUP.NO_JOIN_REQUESTS_FOUND') }}
          </div>
          <div v-else class="flex flex-col gap-2">
            <div
              v-for="request in filteredRequests"
              :key="requestIdentifier(request)"
              class="flex items-center gap-3 rounded-md border border-n-weak bg-n-alpha-1 p-2"
            >
              <Avatar
                :name="requestName(request)"
                :size="36"
                hide-offline-status
              />
              <span class="min-w-0 flex-1">
                <span
                  class="block truncate text-sm font-medium text-n-slate-12"
                >
                  {{ requestName(request) }}
                </span>
                <span
                  v-if="requestSubtitle(request)"
                  class="block truncate text-xs text-n-slate-10"
                >
                  {{ requestSubtitle(request) }}
                </span>
              </span>

              <Button
                :label="$t('CONVERSATION.GROUP.APPROVE_JOIN_REQUEST')"
                size="xs"
                faded
                teal
                :is-loading="
                  processingParticipant === requestIdentifier(request)
                "
                @click="processJoinRequest(request, 'approve')"
              />
              <Button
                :label="$t('CONVERSATION.GROUP.REJECT_JOIN_REQUEST')"
                size="xs"
                ghost
                ruby
                :disabled="!!processingParticipant"
                @click="processJoinRequest(request, 'reject')"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </Modal>
</template>
