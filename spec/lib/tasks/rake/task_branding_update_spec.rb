require 'rake'
require 'rails_helper'

# The environment seeds the brand and the super admin edits it: a run of the task at container
# start must not undo what an operator saved on the Branding page.
RSpec.describe Rake::Task do
  subject(:task) { described_class['branding:update'] }

  before do
    described_class.clear
    Chatwoot::Application.load_tasks
    ConfigLoader.new.process
    allow($stdout).to receive(:puts)
  end

  def value_of(name)
    InstallationConfig.find_by!(name: name).value
  end

  def save_on_the_branding_page(values)
    values.each { |name, value| InstallationConfig.find_by!(name: name).update!(value: value) }
    InstallationConfig.create!(name: 'BRANDING_EDITED_IN_SUPER_ADMIN', value: true, locked: false)
  end

  it 'writes the brand from the environment while the Branding page was never saved' do
    with_modified_env BRAND_NAME: 'Acme', DISPLAY_MANIFEST: 'false' do
      task.invoke
    end

    expect(value_of('BRAND_NAME')).to eq('Acme')
    expect(value_of('DISPLAY_MANIFEST')).to be(false)
    expect(value_of('INSTALLATION_NAME')).to eq('Chatwoot')
  end

  # A value the operator saved equal to its default is theirs too: comparing against the
  # default cannot tell it from a key nobody touched.
  it 'leaves the whole brand alone once the Branding page was saved, defaults included' do
    save_on_the_branding_page('BRAND_NAME' => 'Saved in the super admin', 'DISPLAY_MANIFEST' => true)

    with_modified_env BRAND_NAME: 'From the environment', DISPLAY_MANIFEST: 'false' do
      task.invoke
    end

    expect(value_of('BRAND_NAME')).to eq('Saved in the super admin')
    expect(value_of('DISPLAY_MANIFEST')).to be(true)
  end

  it 'applies the environment again with BRANDING_FORCE, and hands the brand back to it' do
    save_on_the_branding_page('BRAND_NAME' => 'Saved in the super admin')

    with_modified_env BRAND_NAME: 'From the environment', BRANDING_FORCE: 'true' do
      task.invoke
    end

    expect(value_of('BRAND_NAME')).to eq('From the environment')
    expect(InstallationConfig.find_by(name: 'BRANDING_EDITED_IN_SUPER_ADMIN')).to be_nil
  end
end
