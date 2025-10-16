<script>
import { mapGetters, mapActions } from 'vuex';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'VoiceAgentsIndex',
  components: {
    Button,
    Spinner,
  },
  setup() {
    const router = useRouter();
    return { router, showAlert: useAlert };
  },
  computed: {
    ...mapGetters('vapiAgents', ['getVapiAgents', 'getUIFlags']),
    vapiAgents() {
      return this.getVapiAgents;
    },
    uiFlags() {
      return this.getUIFlags;
    },
    isFetching() {
      return this.uiFlags.isFetching;
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
    isDeleting() {
      return this.uiFlags.isDeleting;
    },
  },
  mounted() {
    this.fetchVapiAgents();
  },
  methods: {
    ...mapActions('vapiAgents', ['get', 'update', 'delete']),
    fetchVapiAgents() {
      this.get();
    },
    navigateToNew() {
      this.router.push({ name: 'vapi_agents_new' });
    },
    editAgent(agent) {
      this.router.push({ name: 'vapi_agents_edit', params: { id: agent.id } });
    },
    async toggleActive(agent) {
      try {
        await this.update({
          id: agent.id,
          active: !agent.active,
        });
        this.showAlert(
          agent.active
            ? this.$t('VOICE_AGENTS.MESSAGES.DEACTIVATED')
            : this.$t('VOICE_AGENTS.MESSAGES.ACTIVATED')
        );
      } catch (error) {
        this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.UPDATE_ERROR'));
      }
    },
    async deleteAgent(agent) {
      if (
        !window.confirm(
          this.$t('VOICE_AGENTS.MESSAGES.DELETE_CONFIRM', { name: agent.name })
        )
      ) {
        return;
      }

      try {
        await this.delete(agent.id);
        this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.DELETED'));
      } catch (error) {
        this.showAlert(this.$t('VOICE_AGENTS.MESSAGES.DELETE_ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
          {{ $t('VOICE_AGENTS.LIST.TITLE') }}
        </h1>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">
          {{ $t('VOICE_AGENTS.LIST.DESCRIPTION') }}
        </p>
      </div>
      <div>
        <Button
          variant="solid"
          size="sm"
          icon="i-lucide-plus"
          @click="navigateToNew"
        >
          {{ $t('VOICE_AGENTS.LIST.NEW_BUTTON') }}
        </Button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isFetching" class="flex justify-center py-8">
      <Spinner size="medium" />
    </div>

    <!-- Empty State -->
    <div v-else-if="!vapiAgents.length" class="text-center py-12">
      <div
        class="mx-auto w-24 h-24 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mb-4"
      >
        <i class="i-lucide-phone-call text-4xl text-slate-400" />
      </div>
      <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-2">
        {{ $t('VOICE_AGENTS.LIST.EMPTY_STATE') }}
      </h3>
      <p class="text-slate-600 dark:text-slate-400 mb-6">
        {{ $t('VOICE_AGENTS.LIST.EMPTY_STATE_DESCRIPTION') }}
      </p>
      <Button variant="solid" @click="navigateToNew">
        {{ $t('VOICE_AGENTS.LIST.NEW_BUTTON') }}
      </Button>
    </div>

    <!-- Agents List -->
    <div v-else class="grid gap-4">
      <div
        v-for="agent in vapiAgents"
        :key="agent.id"
        class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-6"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-3 mb-2">
              <h3
                class="text-lg font-medium text-slate-900 dark:text-slate-100"
              >
                {{ agent.name }}
              </h3>
              <span
                class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                :class="[
                  agent.active
                    ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                    : 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-200',
                ]"
              >
                {{
                  agent.active
                    ? $t('VOICE_AGENTS.STATUS.ACTIVE')
                    : $t('VOICE_AGENTS.STATUS.INACTIVE')
                }}
              </span>
            </div>

            <div class="space-y-1 text-sm text-slate-600 dark:text-slate-400">
              <div v-if="agent.inbox" class="flex items-center gap-2">
                <i class="i-lucide-mailbox w-4 h-4" />
                <span
                  >{{ $t('VOICE_AGENTS.FORM.INBOX') }}:
                  {{ agent.inbox.name }}</span
                >
              </div>
              <div v-if="agent.phone_number" class="flex items-center gap-2">
                <i class="i-lucide-phone w-4 h-4" />
                <span>{{ agent.phone_number }}</span>
              </div>
              <div class="flex items-center gap-2">
                <i class="i-lucide-id-card w-4 h-4" />
                <span
                  >{{ $t('VOICE_AGENTS.FORM.VAPI_AGENT_ID') }}:
                  {{ agent.vapi_agent_id }}</span
                >
              </div>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              :icon="agent.active ? 'i-lucide-eye-off' : 'i-lucide-eye'"
              :loading="isUpdating"
              @click="toggleActive(agent)"
            >
              {{
                agent.active
                  ? $t('VOICE_AGENTS.ACTIONS.DEACTIVATE')
                  : $t('VOICE_AGENTS.ACTIONS.ACTIVATE')
              }}
            </Button>
            <Button
              variant="ghost"
              size="sm"
              icon="i-lucide-edit"
              @click="editAgent(agent)"
            >
              {{ $t('VOICE_AGENTS.ACTIONS.EDIT') }}
            </Button>
            <Button
              variant="ghost"
              size="sm"
              icon="i-lucide-trash-2"
              :loading="isDeleting"
              class="text-red-600 hover:text-red-700"
              @click="deleteAgent(agent)"
            >
              {{ $t('VOICE_AGENTS.ACTIONS.DELETE') }}
            </Button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
