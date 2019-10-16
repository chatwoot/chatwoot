/* eslint no-plusplus: 0 */
/* eslint-env browser */

import Modal from './Modal';
import Thumbnail from './Thumbnail';
import Spinner from './Spinner';
import SubmitButton from './buttons/FormSubmitButton';
import Tabs from './ui/Tabs/Tabs';
import TabsItem from './ui/Tabs/TabsItem';
import LoadingState from './widgets/LoadingState';
import ReportStatsCard from './widgets/ReportStatsCard';
import Bar from './widgets/chart/BarChart';
import ModalHeader from './ModalHeader';

const WootUIKit = {
  Modal,
  Thumbnail,
  Spinner,
  SubmitButton,
  Tabs,
  TabsItem,
  LoadingState,
  ReportStatsCard,
  Bar,
  ModalHeader,
  install(Vue) {
    const keys = Object.keys(this);
    keys.pop(); // remove 'install' from keys
    let i = keys.length;
    while (i--) {
      Vue.component(`woot${keys[i]}`, this[keys[i]]);
    }
  },
};

if (typeof window !== 'undefined' && window.Vue) {
  window.Vue.use(WootUIKit);
}

export default WootUIKit;
