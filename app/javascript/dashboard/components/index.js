/* eslint no-plusplus: 0 */
/* eslint-env browser */

import Spinner from 'shared/components/Spinner';
import Bar from './widgets/chart/BarChart';
import Code from './Code';
import LoadingState from './widgets/LoadingState';
import Modal from './Modal';
import ModalHeader from './ModalHeader';
import ReportStatsCard from './widgets/ReportStatsCard';
import SidemenuIcon from './SidemenuIcon';
import Spinner from './Spinner';
import SubmitButton from './buttons/FormSubmitButton';
import Tabs from './ui/Tabs/Tabs';
import TabsItem from './ui/Tabs/TabsItem';

const WootUIKit = {
  Bar,
  Code,
  LoadingState,
  Modal,
  ModalHeader,
  ReportStatsCard,
  SidemenuIcon,
  Spinner,
  SubmitButton,
  Tabs,
  TabsItem,
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
