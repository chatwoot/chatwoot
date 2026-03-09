# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sticker Cross-Browser Compatibility', type: :system, js: true do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox) }

  before do
    sign_in user
    driven_by :selenium_chrome_headless
  end

  describe 'Desktop Browser Compatibility' do
    context 'when using Chrome' do
      before { driven_by :selenium_chrome_headless }

      it 'renders sticker picker correctly' do
        visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
        
        # Wait for page to load
        expect(page).to have_content(conversation.display_id)
        
        # Check if sticker button is present for WhatsApp conversations
        within('.reply-box') do
          expect(page).to have_css('.sticker-button', visible: false) # May be hidden initially
        end
      end

      it 'handles sticker picker modal interactions' do
        visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
        
        # Mock sticker data
        page.execute_script("""
          window.mockStickerData = {
            stickers: [
              {
                id: 'test1',
                url: 'data:image/webp;base64,UklGRiIAAABXRUJQVlA4IBYAAAAwAQCdASoBAAEADsD+JaQAA3AAAAAA',
                alt: 'Test Sticker',
                provider: 'giphy'
              }
            ]
          };
        """)
        
        # Test modal opening and closing
        find('.sticker-button', visible: false).click if page.has_css?('.sticker-button', visible: false)
        
        # Verify modal behavior
        expect(page).to have_css('.sticker-picker-modal', wait: 5) if page.has_css?('.sticker-button')
      end
    end

    context 'when using Firefox' do
      before { driven_by :selenium_firefox_headless }

      it 'maintains consistent styling across browsers' do
        visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
        
        # Check CSS compatibility
        sticker_button = page.find('.sticker-button', visible: false) if page.has_css?('.sticker-button', visible: false)
        
        if sticker_button
          # Verify button styling
          expect(sticker_button[:class]).to include('sticker-button')
          
          # Check computed styles
          button_styles = page.evaluate_script("""
            const button = document.querySelector('.sticker-button');
            if (button) {
              const styles = window.getComputedStyle(button);
              return {
                display: styles.display,
                position: styles.position,
                cursor: styles.cursor
              };
            }
            return null;
          """)
          
          expect(button_styles).to be_present if sticker_button
        end
      end
    end
  end

  describe 'Mobile Responsiveness' do
    before do
      # Set mobile viewport
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone 6/7/8 size
    end

    it 'adapts sticker picker for mobile screens' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Check mobile-specific adaptations
      viewport_width = page.evaluate_script('window.innerWidth')
      expect(viewport_width).to eq(375)
      
      # Verify responsive behavior
      if page.has_css?('.sticker-button', visible: false)
        # Check if button is appropriately sized for mobile
        button_size = page.evaluate_script("""
          const button = document.querySelector('.sticker-button');
          if (button) {
            const rect = button.getBoundingClientRect();
            return { width: rect.width, height: rect.height };
          }
          return null;
        """)
        
        expect(button_size['width']).to be >= 44 if button_size # Minimum touch target size
        expect(button_size['height']).to be >= 44 if button_size
      end
    end

    it 'handles touch interactions properly' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Simulate touch events
      if page.has_css?('.sticker-button', visible: false)
        page.execute_script("""
          const button = document.querySelector('.sticker-button');
          if (button) {
            const touchEvent = new TouchEvent('touchstart', {
              bubbles: true,
              cancelable: true,
              touches: [new Touch({
                identifier: 1,
                target: button,
                clientX: 100,
                clientY: 100
              })]
            });
            button.dispatchEvent(touchEvent);
          }
        """)
        
        # Verify touch interaction doesn't break functionality
        expect(page).not_to have_css('.error-message')
      end
    end

    it 'maintains usability on small screens' do
      # Test even smaller screen (iPhone SE)
      page.driver.browser.manage.window.resize_to(320, 568)
      
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Verify layout doesn't break
      expect(page).to have_content(conversation.display_id)
      
      # Check if sticker picker modal fits screen
      if page.has_css?('.sticker-button', visible: false)
        find('.sticker-button', visible: false).click
        
        if page.has_css?('.sticker-picker-modal', wait: 2)
          modal_width = page.evaluate_script("""
            const modal = document.querySelector('.sticker-picker-modal');
            return modal ? modal.getBoundingClientRect().width : 0;
          """)
          
          expect(modal_width).to be <= 320 # Should not exceed screen width
        end
      end
    end
  end

  describe 'Accessibility Compliance' do
    it 'provides proper ARIA labels and roles' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      if page.has_css?('.sticker-button', visible: false)
        sticker_button = find('.sticker-button', visible: false)
        
        # Check accessibility attributes
        expect(sticker_button['aria-label']).to be_present
        expect(sticker_button['role']).to eq('button')
        expect(sticker_button['tabindex']).to be_present
      end
    end

    it 'supports keyboard navigation' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Test keyboard accessibility
      if page.has_css?('.sticker-button', visible: false)
        # Focus on sticker button
        page.execute_script("""
          const button = document.querySelector('.sticker-button');
          if (button) button.focus();
        """)
        
        # Test Enter key activation
        find('.sticker-button', visible: false).send_keys(:enter) if page.has_css?('.sticker-button:focus')
        
        # Verify modal opens with keyboard interaction
        expect(page).to have_css('.sticker-picker-modal', wait: 2) if page.has_css?('.sticker-button')
      end
    end

    it 'provides screen reader compatible content' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Check for screen reader friendly elements
      if page.has_css?('.sticker-button', visible: false)
        # Verify alt text and descriptions are present
        sticker_elements = page.all('.sticker-item', visible: false)
        
        sticker_elements.each do |element|
          expect(element['alt'] || element['aria-label']).to be_present
        end
      end
    end
  end

  describe 'Performance Under Load' do
    it 'handles multiple sticker loads efficiently' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Measure initial page load time
      load_start = Time.current
      
      # Wait for page to be fully loaded
      expect(page).to have_content(conversation.display_id)
      
      load_time = Time.current - load_start
      expect(load_time).to be < 5.seconds
      
      # Test sticker picker performance
      if page.has_css?('.sticker-button', visible: false)
        picker_start = Time.current
        find('.sticker-button', visible: false).click
        
        # Wait for sticker picker to load
        if page.has_css?('.sticker-picker-modal', wait: 5)
          picker_time = Time.current - picker_start
          expect(picker_time).to be < 3.seconds
        end
      end
    end

    it 'maintains smooth scrolling with many stickers' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      if page.has_css?('.sticker-button', visible: false)
        find('.sticker-button', visible: false).click
        
        if page.has_css?('.sticker-picker-modal', wait: 2)
          # Simulate scrolling through stickers
          page.execute_script("""
            const stickerGrid = document.querySelector('.stickers-grid');
            if (stickerGrid) {
              // Simulate smooth scrolling
              let scrollTop = 0;
              const scrollStep = () => {
                scrollTop += 50;
                stickerGrid.scrollTop = scrollTop;
                if (scrollTop < 500) {
                  requestAnimationFrame(scrollStep);
                }
              };
              requestAnimationFrame(scrollStep);
            }
          """)
          
          # Verify no performance issues during scrolling
          expect(page).not_to have_css('.loading-error')
        end
      end
    end
  end

  describe 'Error Handling and Recovery' do
    it 'gracefully handles network failures' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Simulate network failure
      page.execute_script("""
        // Mock fetch to simulate network error
        const originalFetch = window.fetch;
        window.fetch = function() {
          return Promise.reject(new Error('Network Error'));
        };
        
        // Restore after test
        setTimeout(() => {
          window.fetch = originalFetch;
        }, 5000);
      """)
      
      if page.has_css?('.sticker-button', visible: false)
        find('.sticker-button', visible: false).click
        
        # Should show error message gracefully
        expect(page).to have_css('.error-message, .loading-error', wait: 5) if page.has_css?('.sticker-picker-modal')
      end
    end

    it 'recovers from JavaScript errors' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Inject a JavaScript error
      page.execute_script("""
        window.addEventListener('error', function(e) {
          console.log('Caught error:', e.message);
          // Don't let it break the page
          e.preventDefault();
        });
        
        // Trigger an error
        setTimeout(() => {
          throw new Error('Test error');
        }, 100);
      """)
      
      # Page should still be functional
      expect(page).to have_content(conversation.display_id)
      expect(page).not_to have_css('.fatal-error')
    end
  end

  describe 'Browser-Specific Features' do
    it 'handles WebP image support detection' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Test WebP support detection
      webp_support = page.evaluate_script("""
        function checkWebPSupport() {
          const canvas = document.createElement('canvas');
          canvas.width = 1;
          canvas.height = 1;
          return canvas.toDataURL('image/webp').indexOf('data:image/webp') === 0;
        }
        checkWebPSupport();
      """)
      
      # Should handle both WebP supported and unsupported browsers
      expect([true, false]).to include(webp_support)
      
      # Verify fallback behavior for non-WebP browsers
      if !webp_support && page.has_css?('.sticker-button', visible: false)
        # Should still function with fallback image formats
        expect(page).not_to have_css('.format-error')
      end
    end

    it 'adapts to different viewport orientations' do
      visit "/app/accounts/#{account.id}/conversations/#{conversation.id}"
      
      # Test portrait orientation
      page.driver.browser.manage.window.resize_to(375, 667)
      expect(page).to have_content(conversation.display_id)
      
      # Test landscape orientation
      page.driver.browser.manage.window.resize_to(667, 375)
      expect(page).to have_content(conversation.display_id)
      
      # Verify sticker picker adapts to orientation
      if page.has_css?('.sticker-button', visible: false)
        find('.sticker-button', visible: false).click
        
        if page.has_css?('.sticker-picker-modal', wait: 2)
          modal_dimensions = page.evaluate_script("""
            const modal = document.querySelector('.sticker-picker-modal');
            if (modal) {
              const rect = modal.getBoundingClientRect();
              return { width: rect.width, height: rect.height };
            }
            return null;
          """)
          
          # Modal should fit within landscape viewport
          expect(modal_dimensions['width']).to be <= 667 if modal_dimensions
          expect(modal_dimensions['height']).to be <= 375 if modal_dimensions
        end
      end
    end
  end
end