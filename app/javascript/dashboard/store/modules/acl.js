import * as types from '../mutation-types'
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

// Simulando uma chamada a API aqui por enquanto
// TODO: Passar isso para um arquivo só pra AclAPI
function getACL() {
    const aclmock = {
        time_privado: true,
        direcionar_conversa: false,
    }
    return aclmock
}

// O que acontece na nossa store, é o estado dela, como os dados estão em um momento. Não pode alterar direto, tem que usar as actions
const state = {
    time_privado: false,
    direcionar_conversa: false
}

export const getters = {
    getTimePrivado: $state => $state.time_privado,
    getDirecionarConversa: $state => $state.direcionar_conversa
}

export const actions = {
    fetchAcl: ({ commit }) => {
        console.log("CHAMOU A ACTION fetchAcl")
        try {
            const res = getACL()
            commit(types.default.SET_ACL, res)
        } catch (error) {
            throw error
        }
    }
}

export const mutations = {
    [types.default.SET_ACL]($state, data) { // Troca cada membro do state individualmente
        Object.keys(data).forEach(key => {
            $state[key] = data[key]
        })
    }
}

export default {
    namespaced: true,
    state,
    getters,
    actions,
    mutations
}