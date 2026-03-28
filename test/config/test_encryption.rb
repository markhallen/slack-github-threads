# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/config/encryption'

class TestEncryption < Minitest::Spec
  describe Config::Encryption do
    let(:passphrase) { 'test-passphrase-123' }
    let(:plaintext) { 'Hello, encrypted world!' }

    describe '.encrypt and .decrypt' do
      it 'round-trips plaintext correctly' do
        encrypted = Config::Encryption.encrypt(plaintext, passphrase)
        decrypted = Config::Encryption.decrypt(encrypted, passphrase)

        assert_equal plaintext, decrypted
      end

      it 'handles multi-line YAML content' do
        yaml_content = <<~YAML
          projects:
            - name: Test Project
              slack_team_id: T12345
              slack_bot_token: xoxb-test-token
              github_token: ghp_testtoken123
        YAML

        encrypted = Config::Encryption.encrypt(yaml_content, passphrase)
        decrypted = Config::Encryption.decrypt(encrypted, passphrase)

        assert_equal yaml_content, decrypted
      end

      it 'produces different ciphertext each time due to random salt' do
        encrypted1 = Config::Encryption.encrypt(plaintext, passphrase)
        encrypted2 = Config::Encryption.encrypt(plaintext, passphrase)

        refute_equal encrypted1, encrypted2
      end

      it 'produces valid Base64 output' do
        encrypted = Config::Encryption.encrypt(plaintext, passphrase)

        assert_match(%r{\A[A-Za-z0-9+/]+=*\z}, encrypted)
      end

      it 'handles empty string' do
        encrypted = Config::Encryption.encrypt('', passphrase)
        decrypted = Config::Encryption.decrypt(encrypted, passphrase)

        assert_equal '', decrypted
      end
    end

    describe 'wrong passphrase' do
      it 'raises DecryptionError' do
        encrypted = Config::Encryption.encrypt(plaintext, passphrase)
        assert_raises(Config::Encryption::DecryptionError) do
          Config::Encryption.decrypt(encrypted, 'wrong-passphrase')
        end
      end
    end

    describe 'corrupted data' do
      it 'raises DecryptionError for tampered ciphertext' do
        encrypted = Config::Encryption.encrypt(plaintext, passphrase)
        # Tamper with the encoded blob
        tampered = encrypted.reverse
        assert_raises(Config::Encryption::DecryptionError) do
          Config::Encryption.decrypt(tampered, passphrase)
        rescue ArgumentError
          # Base64 decode failure is also acceptable
          raise Config::Encryption::DecryptionError, 'corrupted'
        end
      end
    end
  end
end
