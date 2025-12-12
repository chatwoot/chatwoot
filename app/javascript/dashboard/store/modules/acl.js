/* global axios */

import * as types from '../mutation-types'
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

import ApiClient from '../../api/ApiClient';
// Classe para chamarmos a API. TODO: Mudar ela para o proprio arquivo.
class AclAPI extends ApiClient {
    constructor() {
        super('acl', { accountScoped: true })
    }

    baseUrl() {
        return ``;
    }

    get(id) {
        if (!id) {
            return axios.get(`${this.url}`)
        }
        return axios.get(`${this.url}/${id}`)
    }

    update(id, data) {
        return axios.patch(`${this.url}/${id}`, data)
    }

}

const state = {
    currentUserACL: {
        time_privado: false,
        direcionar_conversa: false,
        side_panel: false
    },
    editingACL: {

    }
}

export const getters = {
    getUserACL: $state => $state.currentUserACL,
    getEditingACL: $state => $state.editingACL
}

export const actions = {
    fetchAcl: async ({ commit }) => {
        try {
            const aclapi = new AclAPI()
            const result = await aclapi.get()
            commit(types.default.SET_ACL, { ...result.data, exibir_acl: true })
        } catch (e) {
            console.error(e)
            commit(types.default.SET_ACL, {
                "time_privado": true,
                "direcionar_conversa": true,
                "side_panel": true,
                "exibir_acl": false
            })
        }

    },

    fetchEditingAcl: async ({ commit }, userId) => {
        console.log("CHAMOU A ACTION fetchEditingACL COM USERID = ", userId)
        const aclapi = new AclAPI()
        const result = await aclapi.get(userId)
        console.log({ result })
        commit(types.default.SET_EDITING_ACL, result.data)
    },

    updateAcl: async ({ commit }, { userId, newAcl }) => {
        console.log(`Update ACL chamada com ${userId} e ${JSON.stringify(newAcl)}`)
        const aclapi = new AclAPI()
        const result = await aclapi.update(userId, newAcl)
        console.log({ result })
    }
}

export const mutations = {
    [types.default.SET_ACL]($state, data) { // Troca cada membro do state individualmente
        const { userId, ...aclData } = data
        $state.currentUserACL = { ...aclData }
        // Object.keys(data).forEach(key => {
        //     $state[key] = data[key]
        // })
    },

    [types.default.SET_EDITING_ACL]($state, data) {
        const { userId, ...aclData } = data
        $state.editingACL = { ...aclData }
    },

    [types.default.UPDATE_ACL]($state, aclData) {
        console.log("Trocando o state para ", aclData)
        $state.editingACL = { ...aclData }
    }
}

export default {
    namespaced: true,
    state,
    getters,
    actions,
    mutations
}
