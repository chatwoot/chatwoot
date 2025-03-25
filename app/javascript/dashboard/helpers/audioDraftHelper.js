import { LocalStorage } from 'shared/helpers/localStorage';

const AUDIO_STORAGE_KEY = 'draftRecordedAudio';

/**
 * Converts a Blob to a Base64 string
 * @param {Blob} blob - The blob to convert
 * @returns {Promise<string>} - A promise that resolves with the Base64 string
 */
export const blobToBase64 = blob => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
};

/**
 * Converts a Base64 string back to a Blob
 * @param {string} base64String - The Base64 string to convert
 * @returns {Blob} - The resulting Blob
 */
export const base64ToBlob = base64String => {
  const [header, base64] = base64String.split(',');
  const matches = header.match(/^data:([A-Za-z-+/]+);base64$/);

  if (!matches || matches.length !== 2) {
    throw new Error('Invalid base64 string format');
  }

  const contentType = matches[1];
  const binaryString = atob(base64);
  const bytes = new Uint8Array(
    [...binaryString].map(char => char.charCodeAt(0))
  );

  return new Blob([bytes], { type: contentType });
};

/**
 * Generates a storage key for a conversation's audio draft
 * @param {string} conversationId - The conversation ID
 * @param {string} replyType - The reply type (REPLY or NOTE)
 * @returns {string} - The storage key
 */
export const getAudioStorageKey = (conversationId, replyType) =>
  `audio-${conversationId}-${replyType}`;

/**
 * Saves the recorded audio to the draft storage
 * @param {string} conversationId - The conversation ID
 * @param {string} replyType - The reply type (REPLY or NOTE)
 * @param {Object} audioFile - The audio file object to save
 * @returns {Promise<void>}
 */
export const saveAudioToDraft = async (
  conversationId,
  replyType,
  audioFile
) => {
  try {
    if (!audioFile?.resource?.file) {
      return;
    }
    // Check if the audio file size exceeds the 5MB limit for localStorage
    // If it does, show an error message and do not save
    if (audioFile.resource.file.size > 5 * 1024 * 1024) {
      return;
    }

    const key = getAudioStorageKey(conversationId, replyType);

    // Convert audio blob to Base64
    const base64Audio = await blobToBase64(audioFile.resource.file);

    // Save audio metadata
    const audioData = {
      base64: base64Audio,
      thumb: audioFile.thumb,
      name: audioFile.resource.name,
      type: audioFile.resource.type,
      size: audioFile.resource.size,
      isPrivate: audioFile.isPrivate,
      timestamp: Date.now(),
    };

    LocalStorage.updateJsonStore(AUDIO_STORAGE_KEY, key, audioData);
  } catch (error) {
    // Error saving audio draft
  }
};

/**
 * Retrieves audio from draft storage
 * @param {string} conversationId - The conversation ID
 * @param {string} replyType - The reply type (REPLY or NOTE)
 * @returns {Promise<Object|null>} - The audio file object or null if not found
 */
export const getAudioFromDraft = (conversationId, replyType) => {
  try {
    const key = getAudioStorageKey(conversationId, replyType);
    const audioData = LocalStorage.getFromJsonStore(AUDIO_STORAGE_KEY, key);

    if (!audioData) {
      return null;
    }

    // Convert Base64 back to Blob
    const blob = base64ToBlob(audioData.base64);

    // Create a file from the blob
    const file = new File([blob], audioData.name, {
      type: audioData.type,
      lastModified: audioData.timestamp,
    });

    // Return the complete audio file object
    return {
      resource: {
        file,
        name: audioData.name,
        type: audioData.type,
        size: audioData.size,
      },
      isPrivate: audioData.isPrivate,
      thumb: audioData.thumb,
      isRecordedAudio: true,
    };
  } catch (error) {
    // Error retrieving audio draft

    return null;
  }
};

/**
 * Removes audio draft from storage
 * @param {string} conversationId - The conversation ID
 * @param {string} replyType - The reply type (REPLY or NOTE)
 */
export const removeAudioDraft = (conversationId, replyType) => {
  try {
    const key = getAudioStorageKey(conversationId, replyType);
    LocalStorage.deleteFromJsonStore(AUDIO_STORAGE_KEY, key);
  } catch (error) {
    // Error removing audio draft
  }
};
