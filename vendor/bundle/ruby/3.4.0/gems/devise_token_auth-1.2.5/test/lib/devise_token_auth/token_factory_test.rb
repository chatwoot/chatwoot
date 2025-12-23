require 'test_helper'

class DeviseTokenAuth::TokenFactoryTest < ActiveSupport::TestCase
  describe 'TokenFactory module' do
    let(:tf) { DeviseTokenAuth::TokenFactory }
    let(:token_regexp) { /^[-_A-Za-z0-9]{22}$/ }

    it 'should be defined' do
      assert_equal(tf.present?, true)
      assert_kind_of(Module, tf)
    end

    describe 'interface' do
      let(:token_hash_cost_regexp) { /\$[\w]+\$([\d]+)\$/ }
      let(:lifespan) { 10 }
      let(:cost) { DeviseTokenAuth.token_cost }

      it '::secure_string' do
        assert_respond_to(tf, :secure_string)

        secure_string = tf.secure_string
        assert_equal(secure_string.size, 22)
        assert_match(token_regexp, secure_string)

        SecureRandom.stub(:urlsafe_base64, secure_string) do
          assert_equal(tf.secure_string, secure_string)
        end
      end

      it '::client' do
        assert_respond_to(tf, :client)

        client = tf.client
        assert_equal(client.size, 22)
        assert_match(token_regexp, client)

        secure_string = tf.secure_string
        tf.stub(:secure_string, secure_string) do
          assert_equal(tf.client, secure_string)
        end
      end

      it '::token' do
        assert_respond_to(tf, :token)

        token = tf.token
        assert_kind_of(String, token)
        assert_equal(token.size, 22)
        assert_match(token_regexp, token)

        secure_string = tf.secure_string
        tf.stub(:secure_string, secure_string) do
          assert_equal(tf.token, secure_string)
        end
      end

      it '::token_hash(args)' do
        assert_respond_to(tf, :token_hash)

        token_hash = tf.token_hash(tf.token)
        assert_equal(token_hash.size, 60)
        assert_kind_of(String, token_hash)

        token_cost = token_hash_cost_regexp.match(token_hash)[1].to_i
        assert_equal(token_cost, cost)

        cost = DeviseTokenAuth.token_cost == 4 ? 10 : 4
        token_hash = tf.token_hash(tf.token, cost)
        token_cost = token_hash_cost_regexp.match(token_hash)[1].to_i
        assert_equal(token_cost, cost)

        cost = nil
        token_hash = tf.token_hash(tf.token, cost)
        token_cost = token_hash_cost_regexp.match(token_hash)[1].to_i
        assert_equal(token_cost, DeviseTokenAuth.token_cost)
      end

      it '::expiry' do
        assert_respond_to(tf, :expiry)

        assert_kind_of(Integer, tf.expiry)
        assert tf.expiry > Time.now.to_i
      end

      it '::expiry(args)' do
        time = Time.now
        Time.stub(:now, time) do
          assert_equal(tf.expiry(lifespan), (time + lifespan).to_i)

          lifespan = nil
          assert_equal(tf.expiry(lifespan), (time + DeviseTokenAuth.token_lifespan).to_i)
        end
      end

      it '::create' do
        assert_respond_to(tf, :create)

        token = tf.create
        assert token
        token.members.each { |m| refute_nil token[m] }
      end

      it '::create(args)' do
        client = tf.client
        token = tf.create(client: client)
        assert_equal(token.client, client)

        time = Time.now
        Time.stub(:now, time) do
          token = tf.create(lifespan: lifespan)
          assert_equal(token.expiry, (time + lifespan).to_i)
        end

        token = tf.create(cost: cost)
        token_cost = token_hash_cost_regexp.match(token.token_hash)[1].to_i
        assert_equal(token_cost, cost)
      end

      it '::new' do
        assert_respond_to(tf, :new)

        token = tf.new
        token.each { |v| assert_nil v }
      end

      it '::valid_token_hash?' do
        assert_respond_to(tf, :valid_token_hash?)

        refute tf.valid_token_hash?('koskoskos')
        assert tf.valid_token_hash?(tf.create.token_hash)
      end

      it '::token_hash_is_token?' do
        assert_respond_to(tf, :token_hash_is_token?)

        token = tf.create
        refute tf.token_hash_is_token?(token.token_hash, 'koskoskos')
        refute tf.token_hash_is_token?('koskoskos', token.token)
        assert tf.token_hash_is_token?(token.token_hash, token.token)
      end
    end

    describe 'token object implements' do
      let(:object) { tf.create }

      it '#client' do
        assert_respond_to(object, :client)

        assert_kind_of(String, object.client)
        assert_equal(object.client.size, 22)
        assert_match(token_regexp, object.client)
      end

      it '#token' do
        assert_respond_to(object, :token)

        assert_kind_of(String, object.token)
        assert_equal(object.token.size, 22)
        assert_match(token_regexp, object.token)
      end

      it '#token_hash' do
        assert_respond_to(object, :token_hash)

        assert_kind_of(String, object.token_hash)
        assert_equal(object.token_hash.size, 60)
      end

      it '#expiry' do
        assert_respond_to(object, :expiry)
        assert_kind_of(Integer, object.expiry)
      end

      it '#clear!' do
        assert_respond_to(object, :clear!)

        assert object.clear!
        object.each { |v| assert_nil v }
      end

      it '#present?' do
        assert_respond_to(object, :present?)

        assert object.present?

        object.token = nil
        refute object.present?
      end
    end
  end
end
