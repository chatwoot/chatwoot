<script setup>
import { ref, onMounted, computed } from 'vue';
import { useStore } from 'vuex';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const showEditModal = ref(false);
const selectedAgent = ref(null);

const agentList = computed(() => store.getters['agents/getAgents'])
const currentUser = computed(() => store.getters['getCurrentUser'])
const filteredAgents = computed(() => agentList.value.filter(a => a.id !== currentUser.value.id))
const userACL = computed(() => store.getters['acl/getUserACL'])

const editingACL = ref({})
const aclDescriptions = {
    'time_privado': 'Habilita a visualização de todas as opções de filtros disponíveis para equipes quando ativado.',
    'side_panel': 'Habilita a visualização completa das opções no menu lateral esquerdo quando ativado.',
    'direcionar_conversa': 'Habilita as ações de conversa para atribuição a equipes ou usuários quando ativado.'
}

function openEditPopup(agent) {
    selectedAgent.value = agent;
    showEditModal.value = true;
    console.log("Agente escolhido = ", agent)
    store.dispatch('acl/fetchEditingAcl', agent.id)
        .then(() => {
            // Faz uma copia local pro editingACL
            editingACL.value = {...store.getters['acl/getEditingACL']}
        })
}

function saveACL() {
    const userId = selectedAgent.value.id
    console.log("Salvando ACL ", userId, editingACL.value)
    store.dispatch('acl/updateAcl', {userId, newAcl: editingACL.value})
        .then(() => {
            closeEditModal()
        })
}

function closeEditModal() {
    showEditModal.value = false;
    selectedAgent.value = null;
}

onMounted(() => {
  store.dispatch('agents/get');
  //store.dispatch('acl/fetchAcl', currentUser.value.id);
});
</script>

<template>
    <div class="flex flex-col p-4 h-full w-full">
        <h1 class="text-xl font-medium mb-4">ACL</h1>
        <p class="text-sm text-n-slate-11 mb-6">Gerenciamento de permissões</p>
        <div class="overflow-hidden border border-n-weak rounded-lg shadow-sm flex-grow w-full">
            <table class="w-full divide-y divide-n-weak">
                <thead class="bg-n-solid-3">
                    <tr>
                        <th scope="col" class="py-3 px-4 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                            Usuário
                        </th>
                        <th scope="col" class="py-3 px-4 text-left text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                            Editar ACL
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-n-solid-2 divide-y divide-n-weak text-n-slate-11">
                    <tr v-for="(agent) in filteredAgents" :key="agent.email" class="hover:bg-n-solid-3 transition-colors">
                        <td class="py-4 px-4">
                            <div class="flex flex-row items-center gap-4">
                                <!-- <Avatar
                                    :src="agent.thumbnail"
                                    :name="agent.name"
                                    :status="agent.availability_status"
                                    :size="40"
                                    hide-offline-status
                                    rounded-full
                                /> -->
                                <div class="min-w-0">
                                    <span class="block font-medium capitalize truncate">
                                        {{ agent.name }}
                                    </span>
                                    <span class="text-sm text-n-slate-10 truncate">{{ agent.email }}</span>
                                </div>
                            </div>
                        </td>
                        <td class="py-4 px-4">
                            <div class="flex justify-end gap-1">
                                <Button
                                    v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                                    icon="i-lucide-pen"
                                    slate
                                    xs
                                    faded
                                    @click="openEditPopup(agent)"
                                />
                                <!-- <Button
                                    v-if="showDeleteAction(agent)"
                                    v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
                                    icon="i-lucide-trash-2"
                                    xs
                                    ruby
                                    faded
                                    :is-loading="loading[agent.id]"
                                    @click="openDeletePopup(agent, index)"
                                /> -->
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Modal para editar permissões -->
    <div v-if="showEditModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div class="bg-n-solid-1 rounded-lg p-6 w-96 shadow-lg">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-medium">Editar ACL</h2>
                <button @click="closeEditModal" class="text-n-slate-11 hover:text-n-slate-12">
                    <span class="i-lucide-x text-lg"></span>
                </button>
            </div>
            <div class="mb-4">
                <p>Editar acl modal</p>
                <p v-if="selectedAgent" class="text-sm text-n-slate-11">
                    Editando permissões para: {{ selectedAgent.name }}
                </p>
                <form>
                    <div
                        v-for="(value, key) in userACL"
                        :key="key"
                        class="flex items-center space-x-3 py-1"
                    >
                        <input
                        v-if="key !== 'exibir_acl'"
                        type="checkbox"
                        :id="key"
                        v-model="editingACL[key]"
                        class="rounded text-indigo-600 focus:ring-indigo-500"
                        />
                        <label :for="key" v-if="key !== 'exibir_acl'">{{ key.replace('_', ' ') }}</label>
                        <span
                            v-if="key !== 'exibir_acl'"
                            v-tooltip="aclDescriptions[key] || 'Sem descrição'"
                            class="i-lucide-info text-xs text-n-slate-10 cursor-pointer"
                        >
                        </span>
                    </div>
                </form>
            </div>
            <div class="flex justify-end gap-2">
                <Button @click="closeEditModal" slate>Cancelar</Button>
                <Button primary @click="saveACL">Salvar</Button>
            </div>
        </div>
    </div>
</template>
