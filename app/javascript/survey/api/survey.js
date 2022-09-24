import endPoints from 'survey/api/endPoints';
import { API } from 'survey/helpers/axios';

const getSurveyDetails = async ({ uuid }) => {
  const urlData = endPoints.getSurvey({ uuid });
  return API.get(urlData.url, { params: urlData.params });
};

const updateSurvey = async ({ uuid, data }) => {
  const urlData = endPoints.updateSurvey({ data, uuid });
  await API.put(urlData.url, { ...urlData.data });
};

export { getSurveyDetails, updateSurvey };
