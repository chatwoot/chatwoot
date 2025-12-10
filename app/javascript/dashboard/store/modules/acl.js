import * as types from '../mutation-types'
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';

import ApiClient from '../../api/ApiClient';

class AclAPI extends ApiClient {
    constructor() {
        super('acl', { accountScoped: true })
    }

    get() {

    }
}

//TODO: Agora chamar realmente a API do chatwoot virti custom
//TODO: Jogar essas chamadas de API para um arquivo diferente, botando aqui agora só pra ser fácil de ver
const mock_acls = [
    {
        userId: 1,
        time_privado: false,
        direcionar_conversa: false,
        side_panel: false
    },
    {
        userId: 2,
        time_privado: false,
        direcionar_conversa: false,
        side_panel: true
    },
    {
        userId: 3,
        time_privado: true,
        direcionar_conversa: true,
        side_panel: true
    }
]

function getACL(userId) {
    //const userId = 1 // TODO: Pegar o ID do usuário logado mesmo
    //console.log("objeto window = ", window)
    const userACL = {
        time_privado: true,
        direcionar_conversa: true,
        side_panel: true
    }
    console.log("USER ID => ", userId)
    if (userId) {
        const foundAcl = mock_acls.find(acl => acl.userId === userId)
        if (foundAcl) {
            console.log(`ACL que retornaria para o usuario ${userId} = ${JSON.stringify(foundAcl)}`)
            return foundAcl
        }
    }
    console.log(`ACL que retornaria para o usuario ${userId} = ${userACL}`)
    return userACL
}

function getAllACLs() {
    return mock_acls
}

// O que acontece na nossa store, é o estado dela, como os dados estão em um momento. Não pode alterar direto, tem que usar as actions
const state = {
    // TODO: Tirar isso aqui e botar um objeto de user. 
    time_privado: false,
    direcionar_conversa: false,
    side_panel: false,
    userACL: {
        time_privado: true,
        direcionar_conversa: true,
        side_panel: true
    }
}

export const getters = {
    getTimePrivado: $state => $state.time_privado,
    getDirecionarConversa: $state => $state.direcionar_conversa,
    getSidePanel: $state => $state.side_panel,
    getUserACL: $state => $state.userACL
}

export const actions = {
    fetchAcl: ({ commit }, userId) => {
        console.log(userId)
        console.log("CHAMOU A ACTION fetchAcl")
        try {
            const res = getACL(userId)
            commit(types.default.SET_ACL, res)
        } catch (error) {
            throw error
        }
    },

    fetchAllAcls: ({ commit }) => {
        const allACLS = getAllACLs()
        return allACLS
    }
}

export const mutations = {
    [types.default.SET_ACL]($state, data) { // Troca cada membro do state individualmente
        const { userId, ...aclData } = data
        $state.userACL = { ...aclData }
        // Object.keys(data).forEach(key => {
        //     $state[key] = data[key]
        // })
    }
}

export default {
    namespaced: true,
    state,
    getters,
    actions,
    mutations
}