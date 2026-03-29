# frozen_string_literal: true

require 'openssl'
require 'securerandom'
require 'base64'

module Config
  module Encryption
    SALT_LENGTH = 32
    IV_LENGTH = 12
    AUTH_TAG_LENGTH = 16
    KEY_LENGTH = 32
    ITERATIONS = 100_000
    CIPHER = 'aes-256-gcm'

    class DecryptionError < StandardError; end

    def self.encrypt(plaintext, passphrase)
      salt = SecureRandom.random_bytes(SALT_LENGTH)
      key = derive_key(passphrase, salt)

      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.encrypt
      cipher.key = key
      iv = cipher.random_iv

      ciphertext = cipher.update(plaintext) + cipher.final
      auth_tag = cipher.auth_tag

      blob = salt + iv + auth_tag + ciphertext
      Base64.strict_encode64(blob)
    end

    MIN_BLOB_LENGTH = SALT_LENGTH + IV_LENGTH + AUTH_TAG_LENGTH

    def self.decrypt(encoded_blob, passphrase)
      blob = Base64.strict_decode64(encoded_blob)
      raise DecryptionError, 'Data too short — file may be corrupted' if blob.bytesize < MIN_BLOB_LENGTH

      salt = blob[0, SALT_LENGTH]
      iv = blob[SALT_LENGTH, IV_LENGTH]
      auth_tag = blob[SALT_LENGTH + IV_LENGTH, AUTH_TAG_LENGTH]
      ciphertext = blob[(SALT_LENGTH + IV_LENGTH + AUTH_TAG_LENGTH)..]

      key = derive_key(passphrase, salt)

      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.auth_tag = auth_tag

      cipher.update(ciphertext) + cipher.final
    rescue OpenSSL::Cipher::CipherError, ArgumentError
      raise DecryptionError, 'Decryption failed — wrong passphrase or corrupted data'
    end

    def self.derive_key(passphrase, salt)
      OpenSSL::KDF.pbkdf2_hmac(
        passphrase,
        salt: salt,
        iterations: ITERATIONS,
        length: KEY_LENGTH,
        hash: 'SHA256'
      )
    end
    private_class_method :derive_key
  end
end
