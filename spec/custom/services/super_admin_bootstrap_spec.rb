require 'rails_helper'

# Fork: first-boot Super Admin provisioning + baseline hardening.
# See custom/app/services/custom/super_admin_bootstrap.rb + docs/fork/SUPER_ADMIN.md.
RSpec.describe Custom::SuperAdminBootstrap do
  let(:logger) { Logger.new(nil) }

  def run(env)
    described_class.run(env: env, logger: logger)
  end

  describe 'creating the operator' do
    it 'provisions a confirmed Super Admin from env when none exists' do
      expect do
        run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1')
      end.to change { SuperAdmin.where(email: 'ops@company.com').count }.by(1)

      admin = SuperAdmin.find_by(email: 'ops@company.com')
      expect(admin.name).to eq('Platform Operator')
      expect(admin.confirmed?).to be(true)
    end

    it 'does nothing when the required env vars are absent' do
      expect { run({}) }.not_to change { SuperAdmin.count }
    end

    it 'is idempotent and does NOT reset an existing password by default' do
      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1')
      original = SuperAdmin.find_by(email: 'ops@company.com').encrypted_password

      expect do
        run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Different!9Pass')
      end.not_to change { SuperAdmin.count }
      expect(SuperAdmin.find_by(email: 'ops@company.com').encrypted_password).to eq(original)
    end

    it 'rotates the password when explicitly requested' do
      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1')
      original = SuperAdmin.find_by(email: 'ops@company.com').encrypted_password

      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Different!9Pass',
          'SUPER_ADMIN_ROTATE_PASSWORD' => 'true')

      expect(SuperAdmin.find_by(email: 'ops@company.com').encrypted_password).not_to eq(original)
    end

    it 'fails loud on a weak password rather than leaving no operator' do
      expect do
        run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'weak')
      end.to raise_error(/Super Admin bootstrap failed/)
      expect(SuperAdmin.find_by(email: 'ops@company.com')).to be_nil
    end
  end

  describe 'removing the insecure dev seed' do
    # The test DB may already carry the seeded john@acme.inc (db/seeds.rb), so
    # ensure-then-assert rather than create (which would collide on email).
    def ensure_seed_admin
      SuperAdmin.find_or_create_by!(email: described_class::SEED_ADMIN_EMAIL) do |u|
        u.name = 'John'
        u.password = 'Password1!'
        u.skip_confirmation!
      end
    end

    it 'deletes the john@acme.inc seed admin when opted in, keeping the real operator' do
      ensure_seed_admin

      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1',
          'SUPER_ADMIN_REMOVE_DEFAULT_SEED' => 'true')

      expect(SuperAdmin.exists?(email: described_class::SEED_ADMIN_EMAIL)).to be(false)
      expect(SuperAdmin.exists?(email: 'ops@company.com')).to be(true)
    end

    it 'leaves the seed admin untouched when not opted in' do
      ensure_seed_admin

      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1')

      expect(SuperAdmin.exists?(email: described_class::SEED_ADMIN_EMAIL)).to be(true)
    end
  end

  describe 'baseline hardening' do
    def set_signup(value)
      ic = InstallationConfig.find_or_initialize_by(name: 'ENABLE_ACCOUNT_SIGNUP')
      ic.value = value
      ic.save!
    end

    it 'disables public self-signup when requested' do
      set_signup('true')

      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1',
          'SUPER_ADMIN_DISABLE_SIGNUP' => 'true')

      expect(InstallationConfig.find_by(name: 'ENABLE_ACCOUNT_SIGNUP').value).to eq('false')
    end

    it 'does not touch signup config by default' do
      set_signup('true')

      run('SUPER_ADMIN_EMAIL' => 'ops@company.com', 'SUPER_ADMIN_PASSWORD' => 'Str0ng!Pass1')

      expect(InstallationConfig.find_by(name: 'ENABLE_ACCOUNT_SIGNUP').value).to eq('true')
    end
  end
end
