import { emitter } from 'shared/helpers/mitt';
import store from '../store';
import router from '../router';
import {
  playNewCallNotificationInWidget,
  stopCallNotificationInWidget,
} from './WidgetAudioNotificationHelper';

// Event names
export const EVENTS = {
  INCOMING_CALL: 'incoming-call',
  CALL_ACCEPTED: 'call-accepted',
  CALL_REJECTED: 'call-rejected',
  CALL_ENDED: 'call-ended',
};

// Function to handle an incoming call
export const handleIncomingCall = async callAndCaller => {
  const { call_data } = callAndCaller;

  if (!call_data) {
    return false;
  }

  try {
    await store.dispatch('calls/receiveCall', callAndCaller);
    emitter.emit(EVENTS.INCOMING_CALL, callAndCaller);

    playNewCallNotificationInWidget();

    return true;
  } catch (error) {
    return false;
  }
};

// Function to accept a call
export const acceptCall = async call => {
  if (!call) {
    return;
  }

  try {
    await store.dispatch('calls/acceptCall', call);
    emitter.emit(EVENTS.CALL_ACCEPTED, call);
    stopCallNotificationInWidget();
    const currentRoute = router.currentRoute.value;
    if (currentRoute.name === 'incoming-call') {
      router.push({ name: 'messages' });
    }
  } catch (error) {}
};

// Function to reject a call
export const rejectCall = async call => {
  if (!call) {
    return;
  }

  try {
    store.dispatch('calls/rejectCall', call);
    emitter.emit(EVENTS.CALL_REJECTED, call);
    stopCallNotificationInWidget();
    const currentRoute = router.currentRoute.value;
    if (currentRoute.name === 'incoming-call') {
      router.push({ name: 'messages' });
    }
  } catch (error) {}
};

// Function to end a call
export const endCall = async call => {
  // NOTE: Only used during signaling handling, after signaling it will not be handled due to IFrame not supported on customer
  if (!call) {
    return;
  }

  try {
    // NOTE: The state is proper during signaling so this is never needed for now
    // await store.dispatch('calls/endCall', call);
    // emitter.emit(EVENTS.CALL_ENDED, call);
    stopCallNotificationInWidget();
    emitter.emit(EVENTS.CALL_ENDED, call);
    // Navigate back to previous route if on call view
    const currentRoute = router.currentRoute.value;
    if (currentRoute.name === 'incoming-call') {
      router.push({ name: 'messages' });
    }
  } catch (error) {}
};
