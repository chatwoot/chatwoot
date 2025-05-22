# PR #1: Logo and Brand Colors Update

## Description
This PR updates the Chatwoot interface with custom branding elements including new logo files and a custom color scheme. It replaces the "Chatwoot" branding with "YourBrand" and updates the color scheme to use a blue-purple (#4263EB) as the primary color.

## Changes
- Added custom logo SVG files (regular, thumbnail, and dark mode versions)
- Created custom favicon and icon files for browser tabs and Apple devices
- Created CSS override file for custom brand colors
- Updated the installation configuration to use the new brand assets
- Modified meta tags and theme colors in the application layout
- Added CSS link to load custom brand styles

## Testing Methodology
1. Visual inspection of the dashboard with the new logo and color scheme
2. Verified correct color application on buttons, links, and UI components
3. Tested in both light and dark modes
4. Confirmed logo displays correctly on all pages
5. Verified favicon appears correctly in browser tabs

## UI Screenshots
![YourBrand Logo](public/brand-assets/custom/logo.svg)
![YourBrand Thumbnail](public/brand-assets/custom/logo_thumbnail.svg)

## Notes
- The custom color scheme uses #4263EB as the primary color
- Custom logos are stored in the public/brand-assets/custom directory
- Color overrides are implemented through CSS variables
- This PR only handles the visual brand identity. The "Captain" to "AIAgent" rebrand will be handled in a separate PR 