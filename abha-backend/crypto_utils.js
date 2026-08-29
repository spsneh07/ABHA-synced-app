const crypto = require('crypto');

// ABDM Standard Encryption/Decryption Utility using X25519 and AES-256-GCM
class CryptoUtil {
  constructor() {
    this.curve = 'x25519';
    this.algorithm = 'aes-256-gcm';
  }

  // 1. Generate HIU Public/Private Key Pair
  generateKeyPair() {
    const { publicKey, privateKey } = crypto.generateKeyPairSync(this.curve, {
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    });
    
    // Extract base64 keys without PEM headers for ABDM
    const pubKeyBase64 = this.extractBase64FromPem(publicKey);
    const privKeyBase64 = this.extractBase64FromPem(privateKey);
    
    return { 
      publicKeyBase64: pubKeyBase64, 
      privateKeyBase64: privKeyBase64 
    };
  }

  // Extract pure Base64 from PEM headers
  extractBase64FromPem(pem) {
    const lines = pem.split('\n');
    let base64Str = '';
    for (let line of lines) {
      if (!line.includes('-----') && line.trim() !== '') {
        base64Str += line.trim();
      }
    }
    return base64Str;
  }

  // Generate Shared Secret using our Private Key and Sender's (HIP) Public Key
  generateSharedSecret(receiverPrivateKeyBase64, senderPublicKeyBase64) {
    const privateKey = crypto.createPrivateKey({
      key: Buffer.from(receiverPrivateKeyBase64, 'base64'),
      format: 'der',
      type: 'pkcs8'
    });

    const publicKey = crypto.createPublicKey({
      key: Buffer.from(senderPublicKeyBase64, 'base64'),
      format: 'der',
      type: 'spki'
    });

    return crypto.diffieHellman({
      privateKey: privateKey,
      publicKey: publicKey
    });
  }

  // 2. Decrypt the FHIR Payload
  decryptData(encryptedDataStr, receiverPrivateKeyBase64, senderPublicKeyBase64, senderNonceBase64, receiverNonceBase64) {
    const sharedSecret = this.generateSharedSecret(receiverPrivateKeyBase64, senderPublicKeyBase64);
    
    // HKDF to derive the actual AES Key
    // ABDM uses a specific HKDF derivation using the sender & receiver nonces
    const senderNonce = Buffer.from(senderNonceBase64, 'base64');
    const receiverNonce = Buffer.from(receiverNonceBase64, 'base64');
    const salt = Buffer.concat([senderNonce, receiverNonce]);
    
    // The derived key is 32 bytes (256 bits) for AES-256
    const derivedKey = crypto.hkdfSync('sha256', sharedSecret, salt, Buffer.alloc(0), 32);

    // Split encrypted data into ciphertext and auth tag
    const encryptedData = Buffer.from(encryptedDataStr, 'base64');
    const authTagLength = 16;
    
    // Note: ABDM prefixes an XOR of nonces as the IV. 
    // IV = SenderNonce XOR ReceiverNonce (last 12 bytes typically for GCM)
    const iv = Buffer.alloc(12);
    for (let i = 0; i < 12; i++) {
        iv[i] = senderNonce[senderNonce.length - 12 + i] ^ receiverNonce[receiverNonce.length - 12 + i];
    }

    const authTag = encryptedData.slice(encryptedData.length - authTagLength);
    const ciphertext = encryptedData.slice(0, encryptedData.length - authTagLength);

    const decipher = crypto.createDecipheriv(this.algorithm, derivedKey, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(ciphertext, undefined, 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}

module.exports = new CryptoUtil();
