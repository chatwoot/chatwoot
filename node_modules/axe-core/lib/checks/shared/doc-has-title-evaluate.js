import { sanitize } from '../../commons/text';

function docHasTitleEvaluate() {
  var title = document.title;
  return !!sanitize(title);
}

export default docHasTitleEvaluate;
