import { ref, onUnmounted } from 'vue';

export function useVoiceRecorder() {
  const isRecording = ref(false);
  const isPaused = ref(false);
  const duration = ref(0);
  const audioBlob = ref(null);
  const error = ref(null);

  let mediaRecorder = null;
  let audioChunks = [];
  let timerInterval = null;
  let stream = null;

  const formatDuration = seconds => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  const stopRecording = () => {
    if (mediaRecorder && mediaRecorder.state !== 'inactive') {
      mediaRecorder.stop();
    }
    if (stream) {
      stream.getTracks().forEach(t => t.stop());
      stream = null;
    }
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = null;
    }
    isRecording.value = false;
    isPaused.value = false;
  };

  const startRecording = async () => {
    try {
      audioBlob.value = null;
      audioChunks = [];
      duration.value = 0;
      error.value = null;

      stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaRecorder = new MediaRecorder(stream, {
        mimeType: MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
          ? 'audio/webm;codecs=opus'
          : 'audio/webm',
      });

      mediaRecorder.ondataavailable = e => {
        if (e.data.size > 0) audioChunks.push(e.data);
      };

      mediaRecorder.onstop = () => {
        const blob = new Blob(audioChunks, { type: 'audio/webm' });
        audioBlob.value = blob;
        audioChunks = [];
      };

      mediaRecorder.start();
      isRecording.value = true;

      timerInterval = setInterval(() => {
        duration.value += 1;
      }, 1000);
    } catch (e) {
      error.value = e.name === 'NotAllowedError'
        ? 'microphone_denied'
        : 'recording_failed';
      stopRecording();
    }
  };

  const cancelRecording = () => {
    audioChunks = [];
    audioBlob.value = null;
    stopRecording();
  };

  const toggleRecording = () => {
    if (isRecording.value) {
      stopRecording();
    } else {
      startRecording();
    }
  };

  onUnmounted(() => {
    stopRecording();
  });

  return {
    isRecording,
    isPaused,
    duration,
    audioBlob,
    error,
    formatDuration,
    startRecording,
    stopRecording,
    cancelRecording,
    toggleRecording,
  };
}
