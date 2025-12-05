import * as types from '../mutation-types'
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

// Simulando uma chamada a API aqui por enquanto
// TODO: Passar isso para um arquivo só pra AclAPI
async function getACL() {
    const aclmock = {
        time_privado: false,
        direcionar_conversa: false,
    }
    setTimeout(() => {

    }, 2000)
    return Promise(aclmock)
}

// O que acontece na nossa store, é o estado dela, como os dados estão em um momento. Não pode alterar direto, tem que usar as actions
const state = {
    time_privado: false,
    direcionar_conversa: false
}

export const getters = {
    getTimePrivado: $state => $state.can_view_sidebar
}

export const actions = {
    fetchAcl: async ({ commit }) => {
        try {
            const res = await getACL()
            commit(types.default.SET_ACL, res.data)
        } catch (error) {
            throw error
        }
    }
}

export const mutations = {
    [types.default.SET_ACL]($state, data) {
        $state = {
            ...data
        }
    }
}

export default {
    namespaced: true,
    state,
    getters,
    actions,
    mutations
}