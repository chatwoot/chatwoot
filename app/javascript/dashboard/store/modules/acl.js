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
        return 'http://localhost:5050'; //TODO: Isso aqui é para teste local, mudar isso quando formos para homolog/prod
    }

    get(id) {
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
    fetchAcl: async ({ commit }, userId) => {
        console.log("CHAMOU A ACTION fetchAcl COM USER ID ", userId)
        try {
            const aclapi = new AclAPI()
            const result = await aclapi.get(userId)
            console.log({ result })
            commit(types.default.SET_ACL, result.data)
        } catch (error) {
            throw error
        }
    },

    fetchEditingAcl: async ({ commit }, userId) => {
        console.log("CHAMOU A ACTION fetchEditingACL COM USERID = ", userId)
        try {
            const aclapi = new AclAPI()
            const result = await aclapi.get(userId)
            console.log({ result })
            commit(types.default.SET_EDITING_ACL, result.data)
        } catch (error) {
            throw error
        }
    },

    updateAcl: async ({ commit }, { userId, newAcl }) => {
        console.log(`Update ACL chamada com ${userId} e ${JSON.stringify(newAcl)}`)
        try {
            const aclapi = new AclAPI()
            const result = await aclapi.update(userId, newAcl)
            console.log({ result })
        } catch (error) {
            throw error
        }
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
        const index = mock_acls.findIndex(acl => acl.userId === aclData.userId)
        if (index !== -1) mock_acls[index] = { userId: aclData.userId, ...aclData }
    }
}

export default {
    namespaced: true,
    state,
    getters,
    actions,
    mutations
}
