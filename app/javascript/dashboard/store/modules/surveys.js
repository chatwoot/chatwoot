import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SurveysAPI from '../../api/surveys';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  questions: {},
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
    isFetchingQuestions: false,
    isCreatingQuestion: false,
    isDeletingQuestion: false,
    isUpdatingQuestion: false,
  },
};

export const getters = {
  getSurveys($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getSurvey: $state => surveyId => {
    const [survey] = $state.records.filter(
      record => record.id === Number(surveyId)
    );
    return survey || {};
  },
  getQuestions: $state => surveyId => {
    return $state.questions[surveyId] || [];
  },
  getActiveSurvey: $state => inboxId => {
    return $state.records.find(survey => survey.inbox_id === inboxId);
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_SURVEY_UI_FLAG, { isFetching: true });
    try {
      const response = await SurveysAPI.get();
      commit(types.SET_SURVEYS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, surveyId) => {
    commit(types.SET_SURVEY_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await SurveysAPI.show(surveyId);
      commit(types.ADD_SURVEY, response.data);
      if (response.data.questions) {
        commit(types.SET_SURVEY_QUESTIONS, {
          surveyId,
          questions: response.data.questions,
        });
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isFetchingItem: false });
    }
  },

  create: async ({ commit }, surveyData) => {
    commit(types.SET_SURVEY_UI_FLAG, { isCreating: true });
    try {
      const response = await SurveysAPI.create(surveyData);
      commit(types.ADD_SURVEY, response.data);
      // Add questions to state if present
      if (response.data.questions) {
        commit(types.SET_SURVEY_QUESTIONS, {
          surveyId: response.data.id,
          questions: response.data.questions,
        });
      }
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isCreating: false });
    }
    return null;
  },

  update: async ({ commit }, { id, ...surveyData }) => {
    commit(types.SET_SURVEY_UI_FLAG, { isUpdating: true });
    try {
      const response = await SurveysAPI.update(id, surveyData);
      commit(types.EDIT_SURVEY, response.data);
      // Update questions in state if present
      if (response.data.questions) {
        commit(types.SET_SURVEY_QUESTIONS, {
          surveyId: id,
          questions: response.data.questions,
        });
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_SURVEY_UI_FLAG, { isDeleting: true });
    try {
      await SurveysAPI.delete(id);
      commit(types.DELETE_SURVEY, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isDeleting: false });
    }
  },

  getQuestions: async ({ commit }, surveyId) => {
    commit(types.SET_SURVEY_UI_FLAG, { isFetchingQuestions: true });
    try {
      const response = await SurveysAPI.getQuestions(surveyId);
      commit(types.SET_SURVEY_QUESTIONS, {
        surveyId,
        questions: response.data,
      });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isFetchingQuestions: false });
    }
  },

  createQuestion: async ({ commit }, { surveyId, questionData }) => {
    commit(types.SET_SURVEY_UI_FLAG, { isCreatingQuestion: true });
    try {
      const response = await SurveysAPI.createQuestion(surveyId, questionData);
      commit(types.ADD_SURVEY_QUESTION, { surveyId, question: response.data });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isCreatingQuestion: false });
    }
    return null;
  },

  updateQuestion: async (
    { commit },
    { surveyId, questionId, questionData }
  ) => {
    commit(types.SET_SURVEY_UI_FLAG, { isUpdatingQuestion: true });
    try {
      const response = await SurveysAPI.updateQuestion(
        surveyId,
        questionId,
        questionData
      );
      commit(types.EDIT_SURVEY_QUESTION, {
        surveyId,
        question: response.data,
      });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isUpdatingQuestion: false });
    }
  },

  deleteQuestion: async ({ commit }, { surveyId, questionId }) => {
    commit(types.SET_SURVEY_UI_FLAG, { isDeletingQuestion: true });
    try {
      await SurveysAPI.deleteQuestion(surveyId, questionId);
      commit(types.DELETE_SURVEY_QUESTION, { surveyId, questionId });
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_SURVEY_UI_FLAG, { isDeletingQuestion: false });
    }
  },
};

export const mutations = {
  [types.SET_SURVEY_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_SURVEY]: MutationHelpers.setSingleRecord,
  [types.SET_SURVEYS]: MutationHelpers.set,
  [types.EDIT_SURVEY]: MutationHelpers.update,
  [types.DELETE_SURVEY]: MutationHelpers.destroy,

  [types.SET_SURVEY_QUESTIONS]($state, { surveyId, questions }) {
    $state.questions = {
      ...$state.questions,
      [surveyId]: questions,
    };
  },
  [types.ADD_SURVEY_QUESTION]($state, { surveyId, question }) {
    const existingQuestions = $state.questions[surveyId] || [];
    $state.questions = {
      ...$state.questions,
      [surveyId]: [...existingQuestions, question],
    };
  },
  [types.EDIT_SURVEY_QUESTION]($state, { surveyId, question }) {
    const questions = $state.questions[surveyId] || [];
    const index = questions.findIndex(q => q.id === question.id);
    if (index !== -1) {
      questions[index] = question;
      $state.questions = {
        ...$state.questions,
        [surveyId]: [...questions],
      };
    }
  },
  [types.DELETE_SURVEY_QUESTION]($state, { surveyId, questionId }) {
    const questions = $state.questions[surveyId] || [];
    $state.questions = {
      ...$state.questions,
      [surveyId]: questions.filter(q => q.id !== questionId),
    };
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
