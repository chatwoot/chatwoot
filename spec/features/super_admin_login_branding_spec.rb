require 'rails_helper'

RSpec.describe 'Super Admin Login Branding', type: :feature do
  let!(:super_admin) { create(:super_admin) }

  context 'when installation name is configured' do
    before do
      allow(GlobalConfig).to receive(:load).with('INSTALLATION_NAME', 'Admin').and_return('My Company')
    end

    it 'displays the installation name in the page title' do
      visit '/super_admin/sign_in'
      
      expect(page).to have_title('SuperAdmin | My Company')
    end

    it 'displays the installation name in logo alt text' do
      visit '/super_admin/sign_in'
      
      expect(page).to have_css('img[alt="My Company"]', count: 2)
    end

    it 'shows the correct logo sources' do
      visit '/super_admin/sign_in'
      
      expect(page).to have_css('img[src="/brand-assets/logo.svg"]')
      expect(page).to have_css('img[src="/brand-assets/logo_dark.svg"]')
    end
  end

  context 'when installation name is not configured' do
    before do
      allow(GlobalConfig).to receive(:load).with('INSTALLATION_NAME', 'Admin').and_return('Admin')
    end

    it 'falls back to "Admin" in the page title' do
      visit '/super_admin/sign_in'
      
      expect(page).to have_title('SuperAdmin | Admin')
    end

    it 'falls back to "Admin" in logo alt text' do
      visit '/super_admin/sign_in'
      
      expect(page).to have_css('img[alt="Admin"]', count: 2)
    end
  end
end