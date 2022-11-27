const updateSurvey = ({ uuid, data }) => ({
  url: `/public/api/v1/csat_survey/${uuid}`,
  data,
});

const getSurvey = ({ uuid }) => ({
  url: `/public/api/v1/csat_survey/${uuid}`,
});

const getInbox = ({ id }) => ({
  url: `/public/api/v1/inboxes/${id}`,
});


export default {
  getSurvey,
  updateSurvey,
  getInbox
};
