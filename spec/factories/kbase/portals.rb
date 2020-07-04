FactoryBot.define do
  factory :kbase_portal, class: 'Kbase::Portal' do
    account_id { 1 }
    name { "MyString" }
    subdomain { "MyString" }
    custom_domain { "MyString" }
    show_author { false }
    logo { "MyString" }
    favicon { "MyString" }
    linkback_url { "MyString" }
    phone { "MyString" }
    bg_body_color { "MyString" }
    bg_header_color { "MyString" }
    bg_footer_color { "MyString" }
    bg_helpcenter_color { "MyString" }
    tab_bg_color { "MyString" }
    tab_active_color { "MyString" }
    portal_base_font { "MyString" }
    portal_base_color { "MyString" }
    portal_heading_font { "MyString" }
    portal_heading_color { "MyString" }
    link_text_color { "MyString" }
    link_text_hover_color { "MyString" }
    form_input_focus_glow_color { "MyString" }
    form_primary_btn_color { "MyString" }
  end
end
