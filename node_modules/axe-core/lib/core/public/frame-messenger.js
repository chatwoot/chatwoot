import { respondable } from '../utils';

export default function frameMessenger(frameHandler) {
  respondable.updateMessenger(frameHandler);
}
