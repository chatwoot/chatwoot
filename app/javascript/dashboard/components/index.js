/* eslint no-plusplus: 0 */
/* eslint-env browser */
import AvatarUploader from './widgets/forms/AvatarUploader.vue';
import Bar from './widgets/chart/BarChart';
import Button from './widgets/Button';
import Code from './Code';
import ColorPicker from './widgets/ColorPicker';
import DeleteModal from './widgets/modal/DeleteModal.vue';
import Input from './widgets/forms/Input.vue';
import Label from './widgets/Label.vue';
import LoadingState from './widgets/LoadingState';
import Modal from './Modal';
import ModalHeader from './ModalHeader';
import ReportStatsCard from './widgets/ReportStatsCard';
import SidemenuIcon from './SidemenuIcon';
import Spinner from 'shared/components/Spinner';
import SubmitButton from './buttons/FormSubmitButton';
import Tabs from './ui/Tabs/Tabs';
import TabsItem from './ui/Tabs/TabsItem';
import Thumbnail from './widgets/Thumbnail.vue';

const WootUIKit = {
  AvatarUploader,
  Bar,
  Button,
  Code,
  ColorPicker,
  DeleteModal,
  Input,
  LoadingState,
  Label,
  Modal,
  ModalHeader,
  ReportStatsCard,
  SidemenuIcon,
  Spinner,
  SubmitButton,
  Tabs,
  TabsItem,
  Thumbnail,
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
