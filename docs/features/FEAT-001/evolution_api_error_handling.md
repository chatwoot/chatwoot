# Evolution API Error Handling Enhancement

## Overview

This document describes the enhanced error handling system implemented for the Evolution API WhatsApp integration in Chatwoot. The improvements transform generic 422 errors into specific, actionable error responses with proper HTTP status codes and error contexts.

## Enhanced Error Types

### 1. Service Unavailable (503)
- **Error Code**: `EVOLUTION_SERVICE_UNAVAILABLE`
- **Triggers**: Evolution API service is down or unreachable
- **Message**: "Evolution API service is currently unavailable. Please check your service configuration and try again."

### 2. Authentication Error (401)
- **Error Code**: `EVOLUTION_AUTH_FAILED`
- **Triggers**: Invalid API key or authentication failures
- **Message**: "Authentication with Evolution API failed. Please verify your API key and credentials."

### 3. Network Timeout (504)
- **Error Code**: `EVOLUTION_NETWORK_TIMEOUT`
- **Triggers**: Connection timeouts, read timeouts, or network delays
- **Message**: "Connection to Evolution API timed out. Please check your network connection and try again."

### 4. Instance Conflict (409)
- **Error Code**: `EVOLUTION_INSTANCE_EXISTS`
- **Triggers**: Attempting to create an instance with a name that already exists
- **Message**: "An instance with the name '{instance_name}' already exists. Please choose a different name."

### 5. Invalid Configuration (400)
- **Error Code**: `EVOLUTION_INVALID_CONFIG`
- **Triggers**: Missing required parameters, invalid URL format, or configuration errors
- **Message**: "Invalid Evolution API configuration: {details}"

### 6. Instance Creation Failed (422)
- **Error Code**: `EVOLUTION_INSTANCE_CREATION_FAILED`
- **Triggers**: Evolution API returns validation errors during instance creation
- **Message**: "Failed to create Evolution API instance: {reason}"

### 7. Connection Refused (503)
- **Error Code**: `EVOLUTION_CONNECTION_REFUSED`
- **Triggers**: Network connection refused or DNS resolution failures
- **Message**: "Unable to connect to Evolution API. Please verify the service URL and ensure the service is running."

## Error Response Format

All Evolution API errors now return a consistent JSON structure:

```json
{
  "error": "Human-readable error message",
  "error_code": "EVOLUTION_ERROR_CODE",
  "status": 400,
  "timestamp": "2023-12-20T10:30:00Z"
}
```

In development environments, additional debug information is included:

```json
{
  "error": "Human-readable error message",
  "error_code": "EVOLUTION_ERROR_CODE",
  "status": 400,
  "timestamp": "2023-12-20T10:30:00Z",
  "details": {
    "exception_class": "CustomExceptions::Evolution::InvalidConfiguration",
    "data": { "instance_name": "test-instance" }
  }
}
```

## Implementation Components

### 1. Custom Exception Classes
- **File**: `lib/custom_exceptions/evolution.rb`
- **Purpose**: Defines specific exception types for different error scenarios
- **Features**:
  - Inherits from `CustomExceptions::Base`
  - Provides proper HTTP status codes
  - Includes localized error messages
  - Supports error codes for frontend handling

### 2. Enhanced Manager Service
- **File**: `app/services/evolution/manager_service.rb`
- **Improvements**:
  - Input validation with detailed error messages
  - HTTP timeout configuration (30s total, 10s connection, 20s read)
  - Comprehensive error mapping for different HTTP status codes
  - Network error handling (timeouts, connection refused, DNS errors)
  - Structured logging for debugging

### 3. Improved Controller
- **File**: `app/controllers/api/v1/accounts/channels/evolution_channels_controller.rb`
- **Enhancements**:
  - Specific error handling for Evolution exceptions
  - Structured error response format
  - Database validation error handling
  - Debug information in non-production environments
  - Enhanced logging for troubleshooting

### 4. Localization
- **File**: `config/locales/en.yml`
- **Addition**: Complete error message translations under `errors.evolution`

## Error Flow

1. **Request Processing**: Controller validates basic parameters
2. **Service Validation**: Manager service validates inputs and URL format
3. **HTTP Request**: Service makes request with timeout configuration
4. **Response Processing**: Service maps HTTP status codes to specific exceptions
5. **Error Handling**: Controller catches exceptions and returns structured responses
6. **Frontend Integration**: Frontend can use error codes for specific user guidance

## Timeout Configuration

The service implements the following timeout strategy:
- **Connection Timeout**: 10 seconds (time to establish connection)
- **Read Timeout**: 20 seconds (time to read response)
- **Total Timeout**: 30 seconds (maximum total request time)

## Logging Enhancements

All Evolution API interactions are now logged with:
- **Info Level**: Successful operations and validation steps
- **Error Level**: All failure scenarios with detailed context
- **Debug Information**: HTTP request/response details
- **Instance Context**: Always includes instance name for traceability

## Testing

Comprehensive RSpec tests cover:
- All exception types and their properties
- Manager service error handling scenarios
- Controller error response formatting
- Network error simulation
- HTTP status code mapping
- Edge cases and unexpected errors

## Usage Examples

### Frontend Error Handling
```javascript
// Frontend can now handle specific error codes
if (error.error_code === 'EVOLUTION_SERVICE_UNAVAILABLE') {
  showServiceUnavailableMessage();
} else if (error.error_code === 'EVOLUTION_AUTH_FAILED') {
  redirectToConfigurationPage();
}
```

### Backend Exception Raising
```ruby
# Service can raise specific exceptions
raise CustomExceptions::Evolution::NetworkTimeout.new(instance_name: name)
```

## Migration from Previous Implementation

The enhancement maintains backward compatibility while providing:
- More specific error messages instead of generic "Request failed with status code 422"
- Proper HTTP status codes for different error types
- Structured error responses for frontend consumption
- Enhanced debugging capabilities
- Better user experience with actionable error messages

## Future Enhancements

1. **Health Check Endpoint**: Add preliminary service availability check
2. **Retry Logic**: Implement intelligent retry for transient failures
3. **Circuit Breaker**: Add circuit breaker pattern for service protection
4. **Metrics**: Add error rate and response time monitoring
5. **Rate Limiting**: Implement request rate limiting for API protection