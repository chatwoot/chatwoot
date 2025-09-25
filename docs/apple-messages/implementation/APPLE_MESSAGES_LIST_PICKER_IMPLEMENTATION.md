# Apple Messages List Picker Implementation Guide

This guide explains how to properly implement the Apple Messages List Picker with image support in Chatwoot.

## Overview

The Apple Messages List Picker allows users to select from a list of options with optional images. It supports:
- Multiple list items with titles and subtitles
- Images for individual list items
- Header image for the received message
- Customizable received and reply message styling

## UI Implementation

### 1. Accessing the List Picker

1. Navigate to an Apple Messages for Business conversation
2. Click the **Apple Messages button** (mobile device icon) in the reply area
3. Select the **"List Picker"** tab in the modal

### 2. Configuring the Received Message

The received message appears at the top of the Apple Messages interface:

```javascript
// Configuration fields:
- Title: "Please select an option" (default)
- Subtitle: Optional subtitle text
- Header Image: Select from uploaded images (optional)
- Style: "icon", "small", or "large"
```

**Header Image Selection:**
- Upload images first in the Images section
- Select an image from the "Header Image" dropdown
- The selected image will appear in the received message header

### 3. Adding Images

Images can be used for both list items and the received message header:

1. **Upload Images:**
   - Click "Add Image" in the Images section
   - Select image files (JPG, PNG supported)
   - Images are automatically assigned identifiers: `image_0`, `image_1`, etc.

2. **Image Management:**
   - View image previews with original filenames
   - Remove images using the "Remove" button
   - Images are processed as base64 data for transmission

### 4. Configuring List Items

Each list item can have:
- **Title:** Main option text
- **Subtitle:** Description text
- **Image:** Select from uploaded images using the dropdown

**Image Association:**
- Each list item can reference an uploaded image
- Use the image dropdown to select which image to display
- Images are referenced by their identifier (`image_0`, `image_1`, etc.)

### 5. Reply Message Configuration

Configure how the reply appears when a user selects an option:

```javascript
// Configuration fields:
- Title: "Selected: ${item.title}" (supports variables)
- Subtitle: Optional reply subtitle
- Style: "icon", "small", or "large"
- Image Title: Optional image title
- Image Subtitle: Optional image subtitle
```

## Technical Implementation

### Frontend Structure

The List Picker data structure:

```javascript
const listPickerData = {
  // Received message configuration
  received_title: "Please select an option",
  received_subtitle: "",
  received_image_identifier: "image_0", // References images array
  received_style: "icon",
  
  // Images array
  images: [
    {
      identifier: "image_0",
      data: "base64_encoded_image_data",
      description: "original_filename.jpg"
    }
  ],
  
  // List sections and items
  sections: [
    {
      title: "Options",
      multiple_selection: false,
      items: [
        {
          title: "Option 1",
          subtitle: "Description 1",
          imageIdentifier: "image_0" // References images array
        }
      ]
    }
  ],
  
  // Reply message configuration
  reply_title: "Selected: ${item.title}",
  reply_subtitle: "",
  reply_style: "icon"
}
```

### Backend Processing

The backend processes the List Picker through several components:

1. **Controller:** `MessagesController` validates and permits parameters
2. **MessageBuilder:** Creates the message with content_attributes
3. **ContentAttributeValidator:** Validates the Apple Messages structure
4. **SendListPickerService:** Builds the Apple MSP-compliant payload

### Apple MSP Output Format

The final Apple Messages payload structure:

```json
{
  "sourceId": "source_identifier",
  "destinationId": "destination_identifier",
  "v": 1,
  "type": "interactive",
  "interactiveData": {
    "bid": "com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension",
    "data": {
      "requestIdentifier": "uuid",
      "mspVersion": "1.0",
      "listPicker": {
        "sections": [
          {
            "title": "Options",
            "multipleSelection": false,
            "order": 0,
            "listPickerItem": [
              {
                "identifier": "uuid",
                "title": "Option 1",
                "subtitle": "Description 1",
                "imageIdentifier": "image_0",
                "order": 0
              }
            ]
          }
        ]
      },
      "images": [
        {
          "identifier": "image_0",
          "data": "base64_encoded_image_data",
          "description": "original_filename.jpg"
        }
      ]
    },
    "receivedMessage": {
      "title": "Please select an option",
      "subtitle": "",
      "imageIdentifier": "image_0",
      "style": "icon"
    },
    "replyMessage": {
      "title": "Selected: ${item.title}",
      "subtitle": "",
      "style": "icon"
    }
  }
}
```

## Key Implementation Details

### Image Identifier Matching

**Critical:** The `imageIdentifier` fields must reference actual identifiers in the `images` array:

```javascript
// ✅ Correct - References existing image
{
  "imageIdentifier": "image_0", // Matches images[0].identifier
  "images": [
    {"identifier": "image_0", "data": "..."}
  ]
}

// ❌ Incorrect - References non-existent image
{
  "imageIdentifier": "some_random_id", // No matching image
  "images": [
    {"identifier": "image_0", "data": "..."}
  ]
}
```

### Image Processing Pipeline

1. **Frontend Upload:** Images converted to base64 and stored in reactive data
2. **Identifier Generation:** Automatic assignment of `image_0`, `image_1`, etc.
3. **Association:** List items and received message reference images by identifier
4. **Transmission:** Complete structure sent to backend via API
5. **Validation:** Backend validates structure and processes images
6. **Apple MSP:** Service builds compliant payload for Apple Messages

### Supported Image Formats

- **JPEG** (.jpg, .jpeg)
- **PNG** (.png)
- **Base64 encoding** for transmission
- **Automatic resizing** and optimization

## Best Practices

### 1. Image Management
- Use descriptive filenames for better organization
- Keep image file sizes reasonable (< 1MB recommended)
- Test images on actual Apple Messages devices

### 2. Content Design
- Keep titles concise and clear
- Use subtitles for additional context
- Test with different screen sizes

### 3. User Experience
- Provide clear option descriptions
- Use images that enhance understanding
- Test the complete user flow

### 4. Testing
- Test on actual Apple Messages for Business devices
- Verify image display and selection functionality
- Check both received and reply message appearance

## Troubleshooting

### Images Not Displaying
1. Check that `imageIdentifier` matches an image in the `images` array
2. Verify images are properly base64 encoded
3. Ensure backend receives the complete `content_attributes` structure

### Backend Validation Errors
1. Check Rails strong parameters permit the required fields
2. Verify `ContentAttributeValidator` includes all necessary keys
3. Check server logs for specific validation errors

### Apple Messages Device Issues
1. Verify the Apple Messages for Business channel is properly configured
2. Check that the MSP payload structure matches Apple's specification
3. Test with different Apple Messages client versions

## Example Implementation

Here's a complete example of implementing a phone selection List Picker:

```javascript
// Frontend configuration
const phoneSelectionConfig = {
  received_title: "Choose your new iPhone",
  received_subtitle: "Select from our latest models",
  received_image_identifier: "image_0", // Header image
  received_style: "icon",
  
  images: [
    {
      identifier: "image_0",
      data: "base64_header_image",
      description: "apple_logo.jpg"
    },
    {
      identifier: "image_1", 
      data: "base64_iphone_15",
      description: "iphone_15.jpg"
    },
    {
      identifier: "image_2",
      data: "base64_iphone_15_pro", 
      description: "iphone_15_pro.jpg"
    }
  ],
  
  sections: [
    {
      title: "iPhone Models",
      multiple_selection: false,
      items: [
        {
          title: "iPhone 15",
          subtitle: "Starting at $799",
          imageIdentifier: "image_1"
        },
        {
          title: "iPhone 15 Pro", 
          subtitle: "Starting at $999",
          imageIdentifier: "image_2"
        }
      ]
    }
  ],
  
  reply_title: "You selected: ${item.title}",
  reply_subtitle: "Great choice!",
  reply_style: "icon"
}
```

This configuration will create a List Picker with:
- Apple logo as header image
- Two iPhone options with product images
- Clear pricing information
- Personalized reply message

## Conclusion

The Apple Messages List Picker provides a rich, interactive way to present options to users with full image support. By following this implementation guide, you can create engaging, visually appealing message experiences that work seamlessly across Apple Messages for Business.