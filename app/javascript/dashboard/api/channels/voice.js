/* global axios */
import ApiClient from '../ApiClient';

class VoiceAPI extends ApiClient {
  constructor() {
    // Use 'voice' as the resource with accountScoped: true
    super('voice', { accountScoped: true });

    // Client-side Twilio device
    this.device = null;
    this.activeConnection = null;
    this.initialized = false;
  }

  // Initiate a call to a contact
  initiateCall(contactId) {
    if (!contactId) {
      throw new Error('Contact ID is required to initiate a call');
    }

    // Based on the route definition, the correct URL path is /api/v1/accounts/{accountId}/contacts/{contactId}/call
    // The endpoint is defined in the contacts namespace, not voice namespace
    return axios.post(
      `${this.baseUrl().replace('/voice', '')}/contacts/${contactId}/call`
    );
  }

  // End an active call
  endCall(callSid, conversationId) {
    if (!conversationId) {
      throw new Error('Conversation ID is required to end a call');
    }

    if (!callSid) {
      throw new Error('Call SID is required to end a call');
    }

    // Validate call SID format - Twilio call SID starts with 'CA' or 'TJ'
    if (!callSid.startsWith('CA') && !callSid.startsWith('TJ')) {
      throw new Error(
        'Invalid call SID format. Expected Twilio call SID starting with CA or TJ.'
      );
    }

    return axios.post(`${this.url}/end_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
      id: conversationId,
    });
  }

  // End the client-side WebRTC call connection
  endClientCall() {
    try {
      if (this.activeConnection) {
        this.activeConnection.disconnect();
        this.activeConnection = null;
      }

      if (this.device && this.device.state === 'busy') {
        this.device.disconnectAll();
      }
    } catch (error) {
      // Clear the connection reference even if disconnect failed
      this.activeConnection = null;
      throw error;
    }
  }

  // Join an incoming call as an agent (join the conference)
  // This is used for the WebRTC client-side setup, not for phone calls anymore
  joinCall(params) {
    // Check if we have individual parameters or a params object
    const conversationId = params.conversation_id || params.conversationId;
    const callSid = params.call_sid || params.callSid;
    const accountId = params.account_id;

    if (!conversationId) {
      throw new Error('Conversation ID is required to join a call');
    }

    if (!callSid) {
      throw new Error('Call SID is required to join a call');
    }

    // Build request payload with proper naming convention
    const payload = {
      call_sid: callSid,
      conversation_id: conversationId,
    };

    // Add account_id if provided
    if (accountId) {
      payload.account_id = accountId;
    }


    return axios.post(`${this.url}/join_call`, payload);
  }

  // Reject an incoming call as an agent (don't join the conference)
  rejectCall(callSid, conversationId) {
    if (!conversationId) {
      throw new Error('Conversation ID is required to reject a call');
    }

    if (!callSid) {
      throw new Error('Call SID is required to reject a call');
    }

    return axios.post(`${this.url}/reject_call`, {
      call_sid: callSid,
      conversation_id: conversationId,
    });
  }

  // Client SDK methods

  // Get a capability token for the Twilio Client
  getToken(inboxId) {
    // Check if inboxId is valid
    if (!inboxId) {
      return Promise.reject(new Error('Inbox ID is required'));
    }

    // Add more request details to help debugging
    return axios
      .post(
        `${this.url}/tokens`,
        { inbox_id: inboxId },
        {
          headers: { 'Content-Type': 'application/json' },
        }
      )
      .catch(error => {
        // Extract useful error details for debugging
        const errorInfo = {
          status: error.response?.status,
          statusText: error.response?.statusText,
          data: error.response?.data,
          url: `${this.url}/tokens`,
          inboxId,
        };


        // Try to extract a more useful error message from the HTML response if it's a 500 error
        if (
          error.response?.status === 500 &&
          typeof error.response.data === 'string'
        ) {
          // Look for specific error patterns in the HTML
          const htmlData = error.response.data;

          // Check for common Ruby/Rails error patterns
          const nameMatchResult = htmlData.match(/<h2>(.*?)<\/h2>/);
          const detailsMatchResult = htmlData.match(/<pre>([\s\S]*?)<\/pre>/);

          const errorName = nameMatchResult ? nameMatchResult[1] : null;
          const errorDetails = detailsMatchResult
            ? detailsMatchResult[1]
            : null;

          if (errorName || errorDetails) {
            const enhancedError = new Error(
              `Server error: ${errorName || 'Internal Server Error'}`
            );
            enhancedError.details = errorDetails;
            enhancedError.originalError = error;
            throw enhancedError;
          }
        }

        throw error;
      });
  }

  // Initialize the Twilio Device
  async initializeDevice(inboxId) {
    // If already initialized, return the existing device after checking its health
    if (this.initialized && this.device) {
      const deviceState = this.device.state;

      // If the device is in a bad state, destroy and reinitialize
      if (deviceState === 'error' || deviceState === 'unregistered') {
        // Device is in a bad state, destroying and reinitializing
        console.log('Device is in a bad state, destroying and reinitializing');
        try {
          this.device.destroy();
        } catch (e) {
          console.log('Error destroying device:', e);
        }
        this.device = null;
        this.initialized = false;
      } else {
        // Device is in a good state, return it
        console.log('Device is in a good state, returning existing device');
        return this.device;
      }
    }

    // Device needs to be initialized or reinitialized
    try {
      // Starting Twilio Device initialization
      console.log('Starting Twilio Device initialization');

      // Import the Twilio Voice SDK
      let Device;
      try {
        // We know the package is installed via package.json
        const { Device: TwilioDevice } = await import('@twilio/voice-sdk');
        Device = TwilioDevice;
      } catch (importError) {
        throw new Error(
          `Failed to load Twilio Voice SDK: ${importError.message}`
        );
      }

      // Validate inbox ID
      if (!inboxId) {
        throw new Error('Inbox ID is required to initialize the Twilio Device');
      }

      // Step 1: Get a token from the server
      let response;
      try {
        response = await this.getToken(inboxId);
        console.log('Token response received successfully');
      } catch (tokenError) {

        // Enhanced error handling for token requests
        if (tokenError.details) {
          // If we already have extracted details from the error, include those
          throw new Error(`Failed to get token: ${tokenError.message}`);
        }

        // Check for specific HTTP error status codes
        if (tokenError.response) {
          const status = tokenError.response.status;
          const data = tokenError.response.data;

          if (status === 401) {
            throw new Error(
              'Authentication error: Please check your Twilio credentials'
            );
          } else if (status === 403) {
            throw new Error(
              "Permission denied: You don't have access to this inbox"
            );
          } else if (status === 404) {
            throw new Error(
              'Inbox not found or does not have voice capability'
            );
          } else if (status === 500) {
            throw new Error(
              'Server error: The server encountered an error processing your request. Check your Twilio configuration.'
            );
          } else if (data && data.error) {
            throw new Error(`Server error: ${data.error}`);
          }
        }

        throw new Error(`Failed to get token: ${tokenError.message}`);
      }

      // Validate token response
      if (!response.data || !response.data.token) {

        // Check if we have an error message in the response
        if (response.data && response.data.error) {
          throw new Error(
            `Server did not return a valid token: ${response.data.error}`
          );
        } else {
          throw new Error('Server did not return a valid token');
        }
      }

      // Check for warnings about missing TwiML App SID
      if (response.data.warning) {

        if (!response.data.has_twiml_app) {
          // IMPORTANT: Missing TwiML App SID - requires configuration
        }
      }

      // Extract token data
      const { token, identity, voice_enabled, account_sid } = response.data;

      // Log diagnostic information

      // Log the TwiML endpoint that will be used
      if (response.data.twiml_endpoint) {
        console.log('TwiML endpoint configured:', response.data.twiml_endpoint);
      } else {
        console.log('No TwiML endpoint configured');
      }

      // Check if voice is enabled
      if (!voice_enabled) {
        throw new Error(
          'Voice is not enabled for this inbox. Check your Twilio configuration.'
        );
      }

      // Store the TwiML endpoint URL for later use
      this.twimlEndpoint = response.data.twiml_endpoint;

      // Step 2: Create Twilio Device with better options
      const deviceOptions = {
        // Use absolute minimal options - less is more for audio compatibility
        allowIncomingWhileBusy: true, // Allow incoming calls while already on a call
        debug: true, // Enable debug logging
        warnings: true, // Show warnings in console
        disableAudioContextSounds: true, // Disable browser audio context for sounds
        // Add explicit edge parameter - this helps avoid connectivity issues
        edge: ['ashburn', 'sydney', 'roaming'],
        // Explicitly set codec preferences
        codecPreferences: ['opus', 'pcmu'],
        // Add the account ID to any calls made by this device
        appParams: {
          account_id: response.data.account_id,
        },
      };


      try {
        this.device = new Device(token, deviceOptions);
      } catch (deviceError) {
        throw new Error(
          `Failed to create Twilio Device: ${deviceError.message}`
        );
      }

      // Step 3: Set up event listeners with enhanced error handling
      this._setupDeviceEventListeners(inboxId);

      // Step 4: Register the device with Twilio
      try {
        await this.device.register();
        this.initialized = true;
        return this.device;
      } catch (registerError) {

        // Handle specific registration errors
        if (registerError.message && registerError.message.includes('token')) {
          throw new Error(
            'Invalid Twilio token. Check your account credentials.'
          );
        } else if (
          registerError.message &&
          registerError.message.includes('permission')
        ) {
          throw new Error(
            'Missing microphone permission. Please allow microphone access.'
          );
        }

        throw new Error(`Failed to register device: ${registerError.message}`);
      }
    } catch (error) {
      // Clear device and initialized flag in case of error
      this.device = null;
      this.initialized = false;


      // Create a detailed error with context for debugging
      const enhancedError = new Error(
        `Twilio Device initialization failed: ${error.message}`
      );
      enhancedError.originalError = error;
      enhancedError.inboxId = inboxId;
      enhancedError.timestamp = new Date().toISOString();
      enhancedError.browserInfo = {
        userAgent: navigator.userAgent,
        hasGetUserMedia: !!(
          navigator.mediaDevices && navigator.mediaDevices.getUserMedia
        ),
      };

      // Add specific advice for known error cases
      if (error.message.includes('permission')) {
        enhancedError.advice =
          'Please ensure your browser allows microphone access.';
      } else if (error.message.includes('token')) {
        enhancedError.advice =
          'Check your Twilio credentials in the Voice channel settings.';
      } else if (error.message.includes('TwiML')) {
        enhancedError.advice =
          'Set up a valid TwiML app in your Twilio console and configure it in the inbox settings.';
      } else if (error.message.includes('configuration')) {
        enhancedError.advice =
          'Review your Voice inbox configuration to ensure all required fields are completed.';
      }

      throw enhancedError;
    }
  }

  // Helper method to set up device event listeners
  _setupDeviceEventListeners(inboxId) {
    if (!this.device) return;

    // Remove any existing listeners to prevent duplicates
    this.device.removeAllListeners();

    // Add standard event listeners
    this.device.on('registered', () => {
      console.log('Device registered successfully');
    });

    this.device.on('unregistered', () => {
      console.log('Device unregistered');
    });

    this.device.on('tokenWillExpire', () => {
      this.getToken(inboxId)
        .then(newTokenResponse => {
          if (newTokenResponse.data && newTokenResponse.data.token) {
            this.device.updateToken(newTokenResponse.data.token);
          } else {
          }
        })
        .catch(tokenError => {
          console.log('Failed to refresh token:', tokenError);
        });
    });

    this.device.on('incoming', connection => {
      this.activeConnection = connection;

      // Set up connection-specific events
      this._setupConnectionEventListeners(connection);
    });

    this.device.on('error', error => {
      // Enhanced error logging with full details
      const errorDetails = {
        code: error.code,
        message: error.message,
        description: error.description || 'No description',
        twilioErrorObject: error,
        connectionInfo: this.activeConnection
          ? {
              parameters: this.activeConnection.parameters,
              status:
                this.activeConnection.status && this.activeConnection.status(),
              direction: this.activeConnection.direction,
            }
          : 'No active connection',
        deviceState: this.device.state,
        browserInfo: {
          userAgent: navigator.userAgent,
          platform: navigator.platform,
        },
        timestamp: new Date().toISOString(),
      };


      // Provide helpful troubleshooting tips based on error code
      switch (error.code) {
        case 31000:
          console.log(
            '⚠️ Error 31000: General Error. This could be an authentication, configuration, or network issue.',
            {
              sdp: error.sdp || 'No SDP data',
              callState: error.call ? error.call.state : 'No call state',
              connectionState: error.connection
                ? error.connection.state
                : 'No connection state',
              peerConnectionState: error.peerConnection
                ? error.peerConnection.iceConnectionState
                : 'No ICE state',
              message: error.message,
              twilioError: error,
              info: error.info || 'No additional info',
              solution:
                'Check Twilio account status, SDP negotiations, and network connectivity',
            }
          );

          // Create a network diagnostic to check connectivity
          fetch('https://status.twilio.com/api/v2/status.json')
            .then(response => response.json())
            .then(data => {
            })
            .catch(statusError => {
              console.log('Failed to check Twilio status:', statusError);
            });
          break;
        case 31002:
          console.log(
            '⚠️ Error 31002: Permission Denied. Your browser microphone is blocked or unavailable.'
          );
          break;
        case 31003:
          console.log(
            '⚠️ Error 31003: TwiML App Error. Your TwiML application does not exist or is misconfigured.'
          );
          break;
        case 31005:
          console.log(
            '⚠️ Error 31005: Error sent from gateway in HANGUP. This usually means the TwiML endpoint is not reachable or returning invalid TwiML.',
            {
              activeConnection: this.activeConnection ? 'Yes' : 'No',
              deviceState: this.device ? this.device.state : 'No device',
              params: this.activeConnection
                ? this.activeConnection.parameters
                : 'No params',
              twimlEndpoint:
                this.activeConnection && this.activeConnection.parameters
                  ? this.activeConnection.parameters.To
                  : 'Unknown endpoint',
              hangupReason: error.hangupReason || 'Unknown', // Capture hangup reason
              message: error.message,
              description: error.description,
              customMessage: error.customMessage,
              originalError: error.originalError
                ? JSON.stringify(error.originalError)
                : 'None',
            }
          );
          break;
        case 31008:
          console.log(
            '⚠️ Error 31008: Connection Error. The call could not be established.'
          );
          break;
        case 31204:
          console.log(
            '⚠️ Error 31204: ICE Connection Failed. WebRTC connection failure, check firewall settings.'
          );
          break;
        default:
          console.log(
            `⚠️ Unspecified error with code ${error.code}: ${error.message}`
          );
      }
    });

    this.device.on('connect', connection => {
      this.activeConnection = connection;
      this._setupConnectionEventListeners(connection);
    });

    this.device.on('disconnect', () => {
      this.activeConnection = null;
    });
  }

  // Set up event listeners for the active connection with enhanced audio diagnostic logging
  _setupConnectionEventListeners(connection) {
    if (!connection) return;

    // Add advanced audio debug data
    const getAudioDiagnostics = () => {
      const audioContext = window.AudioContext || window.webkitAudioContext;
      let audioInfo = { supported: !!audioContext };

      try {
        if (audioContext) {
          const context = new audioContext();
          audioInfo = {
            ...audioInfo,
            sampleRate: context.sampleRate,
            state: context.state,
            baseLatency: context.baseLatency,
            outputLatency: context.outputLatency,
            destination: {
              maxChannelCount: context.destination.maxChannelCount,
              numberOfInputs: context.destination.numberOfInputs,
              numberOfOutputs: context.destination.numberOfOutputs,
            },
          };
          context.close();
        }
      } catch (e) {
        audioInfo.error = e.message;
      }

      // Check if microphone is accessible
      let microphoneInfo = { detected: false, active: false, tracks: [] };
      if (window.activeAudioStream) {
        const tracks = window.activeAudioStream.getAudioTracks();
        microphoneInfo = {
          detected: true,
          active: tracks.some(
            track => track.enabled && track.readyState === 'live'
          ),
          tracks: tracks.map(track => ({
            id: track.id,
            label: track.label,
            enabled: track.enabled,
            muted: track.muted,
            readyState: track.readyState,
            constraints: track.getConstraints(),
          })),
        };
      }

      return {
        audioContext: audioInfo,
        microphone: microphoneInfo,
        speakersMuted:
          typeof window.speechSynthesis !== 'undefined'
            ? window.speechSynthesis.speaking === false
            : 'unknown',
      };
    };

    connection.on('error', error => {
      // Significantly enhanced connection error logging with audio diagnostics
      const diagnostics = getAudioDiagnostics();

      const connectionErrorDetails = {
        code: error.code,
        message: error.message,
        description: error.description || 'No description',
        twilioErrorObject: error,
        connectionInfo: {
          parameters: connection.parameters,
          status: connection.status && connection.status(),
          direction: connection.direction,
        },
        deviceState: this.device ? this.device.state : 'No device',
        timestamp: new Date().toISOString(),
        // Audio diagnostics for troubleshooting
        audioDiagnostics: diagnostics,
        // Browser media permissions
        mediaPermissions: {
          hasGetUserMedia: !!(
            navigator.mediaDevices && navigator.mediaDevices.getUserMedia
          ),
          activeAudioStream: !!window.activeAudioStream,
          activeAudioTracks: window.activeAudioStream
            ? window.activeAudioStream.getAudioTracks().length
            : 0,
        },
      };

      console.log(
        '❌ DETAILED Connection Error with Audio Diagnostics:',
        connectionErrorDetails
      );
    });

    connection.on('mute', isMuted => {
      console.log('Connection mute status changed:', isMuted);
    });

    connection.on('accept', () => {
      // Enhanced logging for accept event with audio diagnostics
      const diagnostics = getAudioDiagnostics();

      console.log('Connection accepted with diagnostics:', {
        connectionParameters: connection.parameters,
        status: connection.status && connection.status(),
        audioDiagnostics: diagnostics,
        activeAudioStream: window.activeAudioStream
          ? {
              active: window.activeAudioStream.active,
              id: window.activeAudioStream.id,
              trackCount: window.activeAudioStream.getTracks().length,
            }
          : 'No active stream',
      });

      // AUDIO HEALTH CHECK AFTER CONNECTION
      setTimeout(() => {
        console.log('Audio health check after 5 seconds:', {
          connectionActive: this.activeConnection === connection,
          connectionState: connection.status && connection.status(),
          audioTracks: window.activeAudioStream
            ? window.activeAudioStream.getAudioTracks().map(track => ({
                label: track.label,
                enabled: track.enabled,
                readyState: track.readyState,
                muted: track.muted,
              }))
            : 'No active stream',
          // Device state after 5 seconds
          deviceState: this.device ? this.device.state : 'No device',
        });
      }, 5000);
    });

    connection.on('disconnect', () => {
      console.log('Connection disconnected:', {
        disconnectCause: connection.parameters
          ? connection.parameters.DisconnectCause
          : 'Unknown',
        finalStatus: connection.status && connection.status(),
        audioDiagnostics: getAudioDiagnostics(),
      });
      this.activeConnection = null;
    });

    connection.on('reject', () => {
      console.log('Connection rejected:', {
        rejectCause: connection.parameters
          ? connection.parameters.DisconnectCause
          : 'Unknown',
        audioDiagnostics: getAudioDiagnostics(),
      });
      this.activeConnection = null;
    });

    // Additional event for warning messages
    connection.on('warning', warning => {
      console.log('Connection warning:', warning);
    });

    // Listen for TwiML processing events
    connection.on('twiml-processing', twiml => {
      console.log('Processing TwiML:', twiml);
    });

    // Enhanced audio events for debugging
    if (typeof connection.on === 'function') {
      try {
        // Check for volume events
        connection.on('volume', (inputVolume, outputVolume) => {
          // Log only significant volume changes to avoid console spam
          if (Math.abs(inputVolume) > 50 || Math.abs(outputVolume) > 50) {
            console.log(
              `🔊 Volume change - Input: ${inputVolume}, Output: ${outputVolume}`
            );
          }
        });

        // Check for media stream events if supported
        if (typeof connection.getRemoteStream === 'function') {
          const remoteStream = connection.getRemoteStream();
          if (remoteStream) {
            console.log('Remote stream details:', {
              active: remoteStream.active,
              id: remoteStream.id,
              tracks: remoteStream.getTracks().map(t => ({
                kind: t.kind,
                enabled: t.enabled,
                readyState: t.readyState,
              })),
            });
          } else {
            console.log('No remote stream available');
          }
        }
      } catch (e) {
        console.log('Error setting up advanced audio events:', e);
      }
    }
  }

  // Make a call using the Twilio Client
  makeClientCall(params) {
    if (!this.device || !this.initialized) {
      throw new Error('Twilio Device not initialized');
    }

    this.activeConnection = this.device.connect(params);
    return this.activeConnection;
  }

  // Join a conference call using the Twilio Client
  joinClientCall(conferenceParams) {
    if (!this.device || !this.initialized) {
      throw new Error('Twilio Device not initialized');
    }

    try {
      // IMPORTANT: Do NOT try to register if already registered
      // Only check state is ready
      if (this.device.state !== 'ready' && this.device.state !== 'registered') {
        // Don't try to register again if already registered
      }

      // This is CRITICAL for Twilio - params must be formatted exactly right
      // and passed directly in the format Twilio expects
      const params = {
        // REQUIRED: Twilio Voice JS SDK expects 'To' parameter to be a properly formatted string
        To: `${conferenceParams.To}`,

        // Additional params for our server
        account_id: conferenceParams.account_id,
        is_agent: 'true',
      };

      // Check To parameter exists - fail if missing
      if (!params.To) {
        throw new Error('Missing To parameter for conference');
      }

      // Make sure 'To' is explicitly a string
      const stringifiedTo = String(params.To);
      console.log(
        '🎯 CRITICAL CONFERENCE CONNECTION: Connecting agent to conference with To=',
        stringifiedTo
      );

      // Follow Twilio documentation format - params should be nested under 'params' property
      console.log(
        '🎯 TRYING CONNECTION: Using documented format with params property'
      );

      // Just use the minimal required parameters
      const connection = this.device.connect({
        params: {
          To: stringifiedTo, // Conference ID
          is_agent: 'true', // Flag to indicate agent is joining
        },
      });

      console.log(
        '🎯 CONFERENCE CONNECTION RESULT:',
        connection ? 'Success' : 'Failed'
      );
      this.activeConnection = connection;

      if (connection && typeof connection.then === 'function') {
        // It's a Promise - newer Twilio SDK version
        connection
          .then(resolvedConnection => {
            this.activeConnection = resolvedConnection;
            try {
              if (typeof resolvedConnection.on === 'function') {
                resolvedConnection.on('accept', () => {
                  console.log('Promise connection accepted');
                });
              }
            } catch (listenerError) {
              console.log(
                'Could not add listeners to Promise connection:',
                listenerError
              );
            }
          })
          .catch(connError => {
            console.log('Connection error:', connError);
          });
      } else {
        // It's a synchronous connection - older Twilio SDK
      }
      return connection;
    } catch (error) {
      return null;
    }
  }

  // Get the status of the device with additional diagnostic info
  getDeviceStatus() {
    if (!this.device) {
      return 'not_initialized';
    }

    const deviceState = this.device.state;

    // Append a recommended action based on the state
    switch (deviceState) {
      case 'registered':
        return 'ready';
      case 'unregistered':
        return 'disconnected';
      case 'destroyed':
        return 'terminated';
      case 'busy':
        return 'busy';
      case 'error':
        return 'error';
      default:
        return deviceState;
    }
  }

  // Get comprehensive diagnostic information about the device and connection
  getDiagnosticInfo() {
    const browserInfo = {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      vendor: navigator.vendor,
      hasMediaDevices: !!navigator.mediaDevices,
      hasGetUserMedia: !!(
        navigator.mediaDevices && navigator.mediaDevices.getUserMedia
      ),
    };

    const deviceInfo = this.device
      ? {
          state: this.device.state,
          isInitialized: this.initialized,
          capabilities: this.device.capabilities || {},
          isBusy: this.device.isBusy || false,
          audio: {
            isAudioSelectionSupported:
              this.device.isAudioSelectionSupported || false,
          },
        }
      : { state: 'not_initialized' };

    const connectionInfo = this.activeConnection
      ? {
          status: this.activeConnection.status(),
          isMuted: this.activeConnection.isMuted(),
          direction: this.activeConnection.direction,
          parameters: this.activeConnection.parameters,
        }
      : { status: 'no_connection' };

    return {
      timestamp: new Date().toISOString(),
      browser: browserInfo,
      device: deviceInfo,
      connection: connectionInfo,
    };
  }

  // Get the status of the active connection
  getConnectionStatus() {
    if (!this.activeConnection) {
      return 'no_connection';
    }

    const status = this.activeConnection.status();

    // Translate connection statuses to more user-friendly terms
    switch (status) {
      case 'pending':
        return 'connecting';
      case 'open':
        return 'connected';
      case 'connecting':
        return 'connecting';
      case 'ringing':
        return 'ringing';
      case 'closed':
        return 'ended';
      default:
        return status;
    }
  }
}

export default new VoiceAPI();
