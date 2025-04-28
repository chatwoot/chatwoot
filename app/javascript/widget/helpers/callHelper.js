import { emitter } from 'shared/helpers/mitt';
import store from '../store';
import router from '../router';
import { playNewMessageNotificationInWidget } from './WidgetAudioNotificationHelper';

// Event names
export const EVENTS = {
  INCOMING_CALL: 'incoming-call',
  CALL_ACCEPTED: 'call-accepted',
  CALL_REJECTED: 'call-rejected',
  CALL_ENDED: 'call-ended',
};

// Function to handle an incoming call
export const handleIncomingCall = async callAndCaller => {
  const { call_data, caller } = callAndCaller;

  if (!call_data) {
    console.error('No call provided in call data');
    return false;
  }

  try {
    emitter.emit(EVENTS.INCOMING_CALL, callAndCaller);

    await store.dispatch('calls/receiveCall', callAndCaller);

    return true;
  } catch (error) {
    console.error('Error handling incoming call:', error);
    return false;
  }
};

// Function to accept a call
export const acceptCall = async call => {
  if (!call) {
    console.error('No call provided to acceptCall');
    return;
  }

  try {
    await store.dispatch('calls/acceptCall', call);
    emitter.emit(EVENTS.CALL_ACCEPTED, call);

    const currentRoute = router.currentRoute.value;
    if (currentRoute.name === 'incoming-call') {
      router.push({ name: 'messages' });
      // await router.back().catch(() => {
      //   router.push({ name: 'home' });
      // });
    }
  } catch (error) {
    console.error('Error accepting call:', error);
  }
};

// Function to reject a call
export const rejectCall = async call => {
  if (!call) {
    console.error('No call provided to rejectCall');
    return;
  }

  try {
    await store.dispatch('calls/rejectCall', call);
    emitter.emit(EVENTS.CALL_REJECTED, call);

    const currentRoute = router.currentRoute.value;
    if (currentRoute.name === 'incoming-call') {
      router.push({ name: 'messages' });
      // await router.back().catch(() => {
      //   router.push({ name: 'home' });
      // });
    }
  } catch (error) {
    console.error('Error rejecting call:', error);
  }
};

// Function to end a call
export const endCall = async call => {
  // NOTE: Unused and Incomplete implementation due to Iframe support lack on customer
  if (!call) {
    console.error('No call provided to endCall');
    return;
  }

  try {
    await store.dispatch('calls/endCall', call);
    emitter.emit(EVENTS.CALL_ENDED, call);

    // Navigate back to previous route if on call view
    const currentRoute = router.currentRoute.value;
    if (currentRoute.name === 'incoming-call') {
      await router.back().catch(() => {
        router.push({ name: 'home' });
      });
    }
  } catch (error) {
    console.error('Error ending call:', error);
  }
};
