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
    return axios.post(`${this.baseUrl().replace('/voice', '')}/contacts/${contactId}/call`);
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

  // Get call status
  getCallStatus(callSid) {
    if (!callSid) {
      throw new Error('Call SID is required to get call status');
    }

    return axios.get(`${this.url}/call_status`, {
      params: { call_sid: callSid },
    });
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
    
    console.log('Calling join_call API endpoint with payload:', payload);

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
    console.log(`Requesting token for inbox ID: ${inboxId} at URL: ${this.url}/tokens`);
    
    // Log the base URL for debugging
    console.log(`Base URL: ${this.baseUrl()}`);
    
    // Check if inboxId is valid
    if (!inboxId) {
      console.error('No inbox ID provided for token request');
      return Promise.reject(new Error('Inbox ID is required'));
    }
    
    // Add more request details to help debugging
    return axios.post(`${this.url}/tokens`, { inbox_id: inboxId }, {
      headers: { 'Content-Type': 'application/json' },
    }).catch(error => {
      // Extract useful error details for debugging
      const errorInfo = {
        status: error.response?.status,
        statusText: error.response?.statusText,
        data: error.response?.data,
        url: `${this.url}/tokens`,
        inboxId,
      };
      
      console.error('Token request error details:', errorInfo);
      
      // Try to extract a more useful error message from the HTML response if it's a 500 error
      if (error.response?.status === 500 && typeof error.response.data === 'string') {
        // Look for specific error patterns in the HTML
        const htmlData = error.response.data;
        
        // Check for common Ruby/Rails error patterns
        const nameMatchResult = htmlData.match(/<h2>(.*?)<\/h2>/);
        const detailsMatchResult = htmlData.match(/<pre>([\s\S]*?)<\/pre>/);
        
        const errorName = nameMatchResult ? nameMatchResult[1] : null;
        const errorDetails = detailsMatchResult ? detailsMatchResult[1] : null;
        
        if (errorName || errorDetails) {
          const enhancedError = new Error(`Server error: ${errorName || 'Internal Server Error'}`);
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
      console.log('Device already initialized, current state:', deviceState);
      
      // If the device is in a bad state, destroy and reinitialize
      if (deviceState === 'error' || deviceState === 'unregistered') {
        console.log('Device is in a bad state, destroying and reinitializing...');
        try {
          this.device.destroy();
        } catch (e) {
          console.log('Error destroying device:', e);
        }
        this.device = null;
        this.initialized = false;
      } else {
        // Device is in a good state, return it
        return this.device;
      }
    }
    
    // Device needs to be initialized or reinitialized
    try {
      console.log(`Starting Twilio Device initialization for inbox: ${inboxId}`);
      
      // Import the Twilio Voice SDK
      let Device;
      try {
        // We know the package is installed via package.json
        const { Device: TwilioDevice } = await import('@twilio/voice-sdk');
        Device = TwilioDevice;
        console.log('✓ Twilio Voice SDK imported successfully');
      } catch (importError) {
        console.error('✗ Failed to import Twilio Voice SDK:', importError);
        throw new Error(`Failed to load Twilio Voice SDK: ${importError.message}`);
      }
      
      // Validate inbox ID
      if (!inboxId) {
        throw new Error('Inbox ID is required to initialize the Twilio Device');
      }
      
      // Step 1: Get a token from the server
      console.log(`Requesting Twilio token for inbox: ${inboxId}`);
      let response;
      try {
        response = await this.getToken(inboxId);
        console.log(`✓ Token response received with status: ${response.status}`);
      } catch (tokenError) {
        console.error('✗ Token request failed:', tokenError);
        
        // Enhanced error handling for token requests
        if (tokenError.details) {
          // If we already have extracted details from the error, include those
          console.error('Token error details:', tokenError.details);
          throw new Error(`Failed to get token: ${tokenError.message}`);
        }
        
        // Check for specific HTTP error status codes
        if (tokenError.response) {
          const status = tokenError.response.status;
          const data = tokenError.response.data;
          
          if (status === 401) {
            throw new Error('Authentication error: Please check your Twilio credentials');
          } else if (status === 403) {
            throw new Error('Permission denied: You don\'t have access to this inbox');
          } else if (status === 404) {
            throw new Error('Inbox not found or does not have voice capability');
          } else if (status === 500) {
            throw new Error('Server error: The server encountered an error processing your request. Check your Twilio configuration.');
          } else if (data && data.error) {
            throw new Error(`Server error: ${data.error}`);
          }
        }
        
        throw new Error(`Failed to get token: ${tokenError.message}`);
      }
      
      // Validate token response
      if (!response.data || !response.data.token) {
        console.error('✗ Invalid token response data:', response.data);
        
        // Check if we have an error message in the response
        if (response.data && response.data.error) {
          throw new Error(`Server did not return a valid token: ${response.data.error}`);
        } else {
          throw new Error('Server did not return a valid token');
        }
      }
      
      // Check for warnings about missing TwiML App SID
      if (response.data.warning) {
        console.warn('⚠️ Twilio Voice Warning:', response.data.warning);
        
        if (!response.data.has_twiml_app) {
          console.error(
            '🚨 IMPORTANT: Missing TwiML App SID. Browser-based calling requires a ' +
            'TwiML App configured in Twilio Console. Set the Voice Request URL to: ' +
            response.data.twiml_endpoint
          );
        }
      }
      
      // Extract token data
      const { token, identity, voice_enabled, account_sid } = response.data;
      
      // Log diagnostic information
      console.log(`✓ Token data received for identity: ${identity}`);
      console.log(`✓ Voice enabled: ${voice_enabled}`);
      console.log(`✓ Twilio Account SID available: ${!!account_sid}`);
      
      // Log the TwiML endpoint that will be used
      if (response.data.twiml_endpoint) {
        console.log(`✓ TwiML endpoint: ${response.data.twiml_endpoint}`);
      } else {
        console.warn('⚠️ No TwiML endpoint found in token response');
      }
      
      // Check if voice is enabled
      if (!voice_enabled) {
        throw new Error('Voice is not enabled for this inbox. Check your Twilio configuration.');
      }
      
      // Step 2: Create Twilio Device
      const deviceOptions = {
        // Use absolute minimal options - less is more for audio compatibility
        allowIncomingWhileBusy: true, // Allow incoming calls while already on a call
        debug: true, // Enable debug logging
        warnings: true, // Show warnings in console
        // The prebuilt hold music usually interrupts the actual call
        disableAudioContextSounds: true, // Disable browser audio context for sounds
      };
      
      console.log('Creating Twilio Device with options:', deviceOptions);
      
      try {
        this.device = new Device(token, deviceOptions);
        console.log('✓ Twilio Device created successfully');
      } catch (deviceError) {
        console.error('✗ Failed to create Twilio Device:', deviceError);
        throw new Error(`Failed to create Twilio Device: ${deviceError.message}`);
      }
      
      // Step 3: Set up event listeners with enhanced error handling
      this._setupDeviceEventListeners(inboxId);
      
      // Step 4: Register the device with Twilio
      console.log('Registering Twilio Device...');
      try {
        await this.device.register();
        console.log('✓ Twilio Device registered successfully');
        this.initialized = true;
        return this.device;
      } catch (registerError) {
        console.error('✗ Failed to register Twilio Device:', registerError);
        
        // Handle specific registration errors
        if (registerError.message && registerError.message.includes('token')) {
          throw new Error('Invalid Twilio token. Check your account credentials.');
        } else if (registerError.message && registerError.message.includes('permission')) {
          throw new Error('Missing microphone permission. Please allow microphone access.');
        }
        
        throw new Error(`Failed to register device: ${registerError.message}`);
      }
    } catch (error) {
      // Clear device and initialized flag in case of error
      this.device = null;
      this.initialized = false;
      
      console.error('Failed to initialize Twilio Device:', error);
      
      // Create a detailed error with context for debugging
      const enhancedError = new Error(`Twilio Device initialization failed: ${error.message}`);
      enhancedError.originalError = error;
      enhancedError.inboxId = inboxId;
      enhancedError.timestamp = new Date().toISOString();
      enhancedError.browserInfo = {
        userAgent: navigator.userAgent,
        hasGetUserMedia: !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia),
      };
      
      // Add specific advice for known error cases
      if (error.message.includes('permission')) {
        enhancedError.advice = 'Please ensure your browser allows microphone access.';
      } else if (error.message.includes('token')) {
        enhancedError.advice = 'Check your Twilio credentials in the Voice channel settings.';
      } else if (error.message.includes('TwiML')) {
        enhancedError.advice = 'Set up a valid TwiML app in your Twilio console and configure it in the inbox settings.';
      } else if (error.message.includes('configuration')) {
        enhancedError.advice = 'Review your Voice inbox configuration to ensure all required fields are completed.';
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
      console.log('✓ Twilio Device registered with Twilio servers');
    });
    
    this.device.on('unregistered', () => {
      console.log('⚠️ Twilio Device unregistered from Twilio servers');
    });
    
    this.device.on('tokenWillExpire', () => {
      console.log('⚠️ Twilio token is about to expire, refreshing...');
      this.getToken(inboxId)
        .then(newTokenResponse => {
          if (newTokenResponse.data && newTokenResponse.data.token) {
            console.log('✓ Successfully obtained new token');
            this.device.updateToken(newTokenResponse.data.token);
          } else {
            console.error('✗ Failed to get a valid token for renewal');
          }
        })
        .catch(tokenError => {
          console.error('✗ Error refreshing token:', tokenError);
        });
    });
    
    this.device.on('incoming', connection => {
      console.log('📞 Incoming call received via Twilio Device');
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
        connectionInfo: this.activeConnection ? {
          parameters: this.activeConnection.parameters,
          status: this.activeConnection.status && this.activeConnection.status(),
          direction: this.activeConnection.direction,
        } : 'No active connection',
        deviceState: this.device.state,
        browserInfo: {
          userAgent: navigator.userAgent,
          platform: navigator.platform
        },
        timestamp: new Date().toISOString()
      };
      
      console.error('❌ DETAILED Twilio Device Error:', errorDetails);
      
      // Provide helpful troubleshooting tips based on error code
      switch (error.code) {
        case 31000:
          console.error('⚠️ Error 31000: General Error. This could be an authentication, configuration, or network issue.');
          console.error('31000 Error Details:', {
            sdp: error.sdp || 'No SDP data',
            callState: error.call ? error.call.state : 'No call state',
            connectionState: error.connection ? error.connection.state : 'No connection state',
            peerConnectionState: error.peerConnection ? error.peerConnection.iceConnectionState : 'No ICE state',
            message: error.message,
            twilioError: error,
            info: error.info || 'No additional info',
            solution: 'Check Twilio account status, SDP negotiations, and network connectivity'
          });
          
          // Create a network diagnostic to check connectivity
          fetch('https://status.twilio.com/api/v2/status.json')
            .then(response => response.json())
            .then(data => {
              console.log('Twilio service status check:', data);
            })
            .catch(statusError => {
              console.error('Failed to check Twilio status:', statusError);
            });
          break;
        case 31002:
          console.error('⚠️ Error 31002: Permission Denied. Your browser microphone is blocked or unavailable.');
          break;
        case 31003:
          console.error('⚠️ Error 31003: TwiML App Error. Your TwiML application does not exist or is misconfigured.');
          break;
        case 31005:
          console.error('⚠️ Error 31005: Error sent from gateway in HANGUP. This usually means the TwiML endpoint is not reachable or returning invalid TwiML.');
          console.error('Additional details for 31005:', {
            activeConnection: this.activeConnection ? 'Yes' : 'No',
            deviceState: this.device ? this.device.state : 'No device',
            params: this.activeConnection ? this.activeConnection.parameters : 'No params',
            twimlEndpoint: this.activeConnection && this.activeConnection.parameters ? 
              this.activeConnection.parameters.To : 'Unknown endpoint',
            hangupReason: error.hangupReason || 'Unknown',  // Capture hangup reason
            message: error.message,
            description: error.description,
            customMessage: error.customMessage,
            originalError: error.originalError ? JSON.stringify(error.originalError) : 'None'
          });
          
          // Make a test HTTP request to the TwiML endpoint to check if it's accessible
          fetch('/api/v1/accounts/' + (this.activeConnection?.parameters?.account_id || 'current') + '/voice/twiml_for_client')
            .then(response => {
              console.log('TwiML endpoint accessibility test result:', {
                status: response.status,
                ok: response.ok,
                statusText: response.statusText
              });
            })
            .catch(fetchError => {
              console.error('Failed to reach TwiML endpoint:', fetchError);
            });
          break;
        case 31008:
          console.error('⚠️ Error 31008: Connection Error. The call could not be established.');
          break;
        case 31204:
          console.error('⚠️ Error 31204: ICE Connection Failed. WebRTC connection failure, check firewall settings.');
          break;
        default:
          console.error(`⚠️ Unspecified error with code ${error.code}: ${error.message}`);
      }
    });
    
    this.device.on('connect', connection => {
      console.log('📞 Call connected');
      this.activeConnection = connection;
      this._setupConnectionEventListeners(connection);
    });
    
    this.device.on('disconnect', () => {
      console.log('📞 Call disconnected');
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
              numberOfOutputs: context.destination.numberOfOutputs
            }
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
          active: tracks.some(track => track.enabled && track.readyState === 'live'),
          tracks: tracks.map(track => ({
            id: track.id,
            label: track.label,
            enabled: track.enabled,
            muted: track.muted,
            readyState: track.readyState,
            constraints: track.getConstraints()
          }))
        };
      }
      
      return { 
        audioContext: audioInfo, 
        microphone: microphoneInfo,
        speakersMuted: typeof window.speechSynthesis !== 'undefined' ? 
          window.speechSynthesis.speaking === false : 'unknown'
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
          hasGetUserMedia: !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia),
          activeAudioStream: !!window.activeAudioStream,
          activeAudioTracks: window.activeAudioStream ? 
            window.activeAudioStream.getAudioTracks().length : 0
        }
      };
      
      console.error('❌ DETAILED Connection Error with Audio Diagnostics:', connectionErrorDetails);
    });
    
    connection.on('mute', isMuted => {
      console.log(`📞 Call ${isMuted ? 'muted' : 'unmuted'}`);
    });
    
    connection.on('accept', () => {
      // Enhanced logging for accept event with audio diagnostics
      const diagnostics = getAudioDiagnostics();
      
      console.log('📞 Call accepted with audio diagnostics:', {
        connectionParameters: connection.parameters,
        status: connection.status && connection.status(),
        audioDiagnostics: diagnostics,
        activeAudioStream: window.activeAudioStream ? {
          active: window.activeAudioStream.active,
          id: window.activeAudioStream.id,
          trackCount: window.activeAudioStream.getTracks().length
        } : 'No active stream'
      });
      
      // AUDIO HEALTH CHECK AFTER CONNECTION
      setTimeout(() => {
        console.log('🔊 AUDIO HEALTH CHECK:', {
          connectionActive: this.activeConnection === connection,
          connectionState: connection.status && connection.status(),
          audioTracks: window.activeAudioStream ? 
            window.activeAudioStream.getAudioTracks().map(track => ({
              label: track.label,
              enabled: track.enabled,
              readyState: track.readyState,
              muted: track.muted
            })) : 'No active stream',
          // Device state after 5 seconds
          deviceState: this.device ? this.device.state : 'No device'
        });
      }, 5000);
    });
    
    connection.on('disconnect', () => {
      console.log('📞 Call disconnected', {
        disconnectCause: connection.parameters ? connection.parameters.DisconnectCause : 'Unknown',
        finalStatus: connection.status && connection.status(),
        audioDiagnostics: getAudioDiagnostics()
      });
      this.activeConnection = null;
    });
    
    connection.on('reject', () => {
      console.log('📞 Call rejected', {
        rejectCause: connection.parameters ? connection.parameters.DisconnectCause : 'Unknown',
        audioDiagnostics: getAudioDiagnostics()
      });
      this.activeConnection = null;
    });
    
    // Additional event for warning messages
    connection.on('warning', warning => {
      console.warn('⚠️ Connection Warning:', warning);
    });
    
    // Listen for TwiML processing events
    connection.on('twiml-processing', twiml => {
      console.log('📄 Processing TwiML:', twiml);
    });
    
    // Enhanced audio events for debugging
    if (typeof connection.on === 'function') {
      try {
        // Check for volume events
        connection.on('volume', (inputVolume, outputVolume) => {
          // Log only significant volume changes to avoid console spam
          if (Math.abs(inputVolume) > 50 || Math.abs(outputVolume) > 50) {
            console.log(`🔊 Volume change - Input: ${inputVolume}, Output: ${outputVolume}`);
          }
        });
        
        // Check for media stream events if supported
        if (typeof connection.getRemoteStream === 'function') {
          const remoteStream = connection.getRemoteStream();
          if (remoteStream) {
            console.log('✅ Remote audio stream available:', {
              active: remoteStream.active,
              id: remoteStream.id,
              tracks: remoteStream.getTracks().map(t => ({
                kind: t.kind,
                enabled: t.enabled,
                readyState: t.readyState
              }))
            });
          } else {
            console.warn('⚠️ No remote audio stream available');
          }
        }
      } catch (e) {
        console.warn('Error setting up enhanced audio events:', e);
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
    
    // Log the exact conference ID received
    console.log('Connecting to conference with params:', conferenceParams);
    console.log('⭐ CONFERENCE ID VALUE:', conferenceParams.To);
    console.log('⭐ CONFERENCE ID FORMAT CHECK:', 
                conferenceParams.To && 
                conferenceParams.To.startsWith('conf_account_') && 
                conferenceParams.To.includes('_conv_') ? 
                'CORRECT ✅' : 'INCORRECT ❌');
    
    try {
      // IMPORTANT: Do NOT try to register if already registered
      // Only check state is ready
      if (this.device.state !== 'ready' && this.device.state !== 'registered') {
        console.warn('Twilio device not in ready state:', this.device.state);
        // Don't try to register again if already registered
      }
      
      // SUPER MINIMAL PARAMETER APPROACH - explicitly construct the parameters
      // using exactly the format expected by Twilio
      const params = {};
      
      // The 'To' parameter MUST be capitalized for Twilio and is required
      params.To = conferenceParams.To;
      
      // The account_id is needed for server-side routing
      params.account_id = conferenceParams.account_id;
      
      // ENSURE the conference ID is exactly in the format we expect
      // conf_account_{account_id}_conv_{conversationId}
      if (!params.To || !params.To.startsWith('conf_account_') || !params.To.includes('_conv_')) {
        console.error(`CRITICAL ERROR: Conference ID format is incorrect: '${params.To}'`);
        console.error('Expected format: conf_account_{account_id}_conv_{conversationId}');
        throw new Error('Invalid conference ID format. Expected conf_account_{account_id}_conv_{conversationId}');
      }
      
      // MOST CRITICAL DEBUG OUTPUT - this is exactly what we're sending to Twilio
      console.log(`⭐⭐⭐ CONNECTING TO CONFERENCE: Conference name='${params.To}', account_id=${params.account_id}`);
      
      // IMPORTANT: Do NOT modify the conference name - use exactly what was passed
      // This ensures we use the exact same conference name as created on the server side
      
      // Connect to the conference - different Twilio SDK versions return different types
      try {
        // SIMPLIFIED APPROACH - Just use standard params with capitalized 'To'
        // No extra URL parameters or fancy options
        console.log(`⭐⭐⭐ Connecting to conference '${params.To}' with params:`, params);
        
        const connection = this.device.connect(params);
        
        // Save the connection to our instance
        this.activeConnection = connection;
        
        // Check what kind of connection object we have (Promise vs older non-Promise style)
        if (connection && typeof connection.then === 'function') {
          // It's a Promise - newer Twilio SDK version
          console.log('Using Promise-based Twilio connection - handling async');
          
          // Return the connection object but also set up Promise handling
          connection.then(resolvedConnection => {
            console.log('WebRTC Promise connection resolved successfully');
            this.activeConnection = resolvedConnection;
            
            // Try to add listeners if this version supports it
            try {
              if (typeof resolvedConnection.on === 'function') {
                resolvedConnection.on('accept', () => {
                  console.log('✅ Conference connection accepted via Promise');
                });
              }
            } catch (listenerError) {
              console.warn('Could not add listeners to Promise connection:', listenerError);
            }
          }).catch(connError => {
            console.error('WebRTC Promise connection error:', connError);
          });
        } else {
          // It's a synchronous connection - older Twilio SDK
          console.log('Successfully initiated synchronous connection to conference');
        }
        
        return connection;
      } catch (connectError) {
        console.error('Error during device.connect():', connectError);
        throw connectError;
      }
    } catch (error) {
      console.error('Error connecting to conference:', error);
      throw error;
    }
  }
  
  // End a client call
  endClientCall() {
    console.log('Attempting to end WebRTC call');
    
    // Check if we have an active connection
    if (this.activeConnection) {
      try {
        // Try to disconnect - handle both Promise and non-Promise interfaces
        if (typeof this.activeConnection.disconnect === 'function') {
          console.log('Using Connection.disconnect() method');
          this.activeConnection.disconnect();
        } else {
          // In modern Twilio SDK, might need to use the device
          console.log('Connection.disconnect not available, using Device');
          if (this.device && typeof this.device.disconnectAll === 'function') {
            this.device.disconnectAll();
          }
        }
        
        this.activeConnection = null;
        return true;
      } catch (error) {
        console.error('Error disconnecting WebRTC call:', error);
        // Reset connection anyway
        this.activeConnection = null;
        return false;
      }
    } else if (this.device) {
      // Try disconnecting all calls from the device even if no active connection
      try {
        if (typeof this.device.disconnectAll === 'function') {
          this.device.disconnectAll();
          return true;
        }
      } catch (error) {
        console.error('Error disconnecting device calls:', error);
      }
    }
    
    return false;
  }
  
  // Mute/unmute a client call
  setMute(isMuted) {
    console.log(`Attempting to ${isMuted ? 'mute' : 'unmute'} WebRTC call`);
    
    if (this.activeConnection) {
      try {
        // Check if the mute function exists
        if (typeof this.activeConnection.mute === 'function') {
          this.activeConnection.mute(isMuted);
          console.log(`Call ${isMuted ? 'muted' : 'unmuted'} successfully`);
          return true;
        } else {
          console.warn('Connection.mute method not available');
          return false;
        }
      } catch (error) {
        console.error('Error muting/unmuting WebRTC call:', error);
        return false;
      }
    }
    
    console.warn('No active connection to mute/unmute');
    return false;
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
      hasGetUserMedia: !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia),
    };
    
    const deviceInfo = this.device ? {
      state: this.device.state,
      isInitialized: this.initialized,
      capabilities: this.device.capabilities || {},
      isBusy: this.device.isBusy || false,
      audio: {
        isAudioSelectionSupported: this.device.isAudioSelectionSupported || false
      }
    } : { state: 'not_initialized' };
    
    const connectionInfo = this.activeConnection ? {
      status: this.activeConnection.status(),
      isMuted: this.activeConnection.isMuted(),
      direction: this.activeConnection.direction,
      parameters: this.activeConnection.parameters,
    } : { status: 'no_connection' };
    
    return {
      timestamp: new Date().toISOString(),
      browser: browserInfo,
      device: deviceInfo,
      connection: connectionInfo
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
