# LiveIQ Branding Guide

This document explains how the custom branding was implemented and how to further customize the appearance of LiveIQ (modified Chatwoot).

## Branding Overview

The original Chatwoot branding was replaced with a custom "LiveIQ" branding that uses:
- **Primary Color**: Purple (#8A57DE)
- **Font**: Modern sans-serif typeface
- **Logo**: Network node visualization with "LiveIQ" text

## Branding Files

### Logo Files

The following SVG files were created/modified:

1. **Main Logo (Light Theme)**
   - File: `public/brand-assets/logo.svg`
   - Used in the header and login screens with light backgrounds

2. **Dark Theme Logo**
   - File: `public/brand-assets/logo_dark.svg`
   - Used in the header and login screens with dark backgrounds

3. **Logo Thumbnail/Icon**
   - File: `public/brand-assets/logo_thumbnail.svg`
   - Used for the favicon and other icon representations

### Color Scheme

The color scheme is defined in:
- File: `theme/colors.js`

The main brand color was changed to purple (#8A57DE), and the entire color palette was adjusted to use violet shades instead of blue.

## How to Customize Further

### Changing the Logo

1. Create your SVG logo files (recommended dimensions: 144×37px for the main logo and 38×38px for the thumbnail)
2. Replace the existing files in the `public/brand-assets/` directory
3. Make sure to create both light and dark versions for proper display in both themes

### Changing the Color Scheme

1. Open `theme/colors.js`
2. Find the `colors` object
3. Modify the color values:
   - Update the `woot` colors to match your brand palette
   - Change the `n.brand` property to your primary brand color

Example:

```javascript
// Change the primary brand color
n: {
  // ... other properties
  brand: '#YOUR_HEX_COLOR',
  // ... other properties
}
```

### Changing the Favicon

1. Generate favicons in multiple sizes using a tool like [favicon.io](https://favicon.io/)
2. Replace the files in the `public/` directory:
   - favicon-16x16.png
   - favicon-32x32.png
   - favicon-96x96.png
   - favicon-512x512.png

### Updating Application Name

1. Update the installation name in your environment configuration:
   - Set the `INSTALLATION_NAME` environment variable to "LiveIQ" or your desired name

## Examples

### SVG Logo Structure

The logos use a simple SVG structure:

```svg
<svg width="144" height="37" viewBox="0 0 144 37" fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Icon part of the logo -->
  <path d="..." fill="#8A57DE"/>
  <!-- More paths for the icon... -->
  
  <!-- Text part of the logo -->
  <path d="..." fill="#8A57DE"/>
  <!-- More paths for the text... -->
</svg>
```

### Color Configuration

The color configuration uses a combination of direct hex values and references to color libraries:

```javascript
// Primary brand colors
woot: {
  25: violet.violet2,
  50: violet.violet3,
  // ...and so on
}

// Brand color reference in design system
n: {
  // ...other properties
  brand: '#8A57DE',
  // ...other properties
}
```

## Browser Compatibility

The branding has been tested and confirmed to work on:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Best Practices

1. **Use SVG for Logos**: SVGs provide scalability without losing quality.
2. **Maintain Aspect Ratios**: Ensure your logos maintain the correct aspect ratios.
3. **Provide Dark Mode Versions**: Always create separate versions for dark mode.
4. **Keep File Sizes Small**: Optimize SVGs to keep file sizes small for faster loading.
5. **Test on Multiple Browsers**: Verify your branding looks consistent across different browsers.

## Color Palette Reference

| Element | Hex Color | Description |
|---------|-----------|-------------|
| Primary Brand | #8A57DE | Main purple brand color |
| Light Variant | #B57FFE | Lighter shade for dark backgrounds |
| Text on Light | #333333 | Text color on light backgrounds |
| Text on Dark | #FFFFFF | Text color on dark backgrounds |

## Accessibility Considerations

The color scheme has been chosen to maintain accessibility standards:
- Sufficient contrast ratio between text and background colors
- Distinctive colors that work for color-blind users
- Consistent visual hierarchy 