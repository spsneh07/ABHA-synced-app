const express = require('express');
const bodyParser = require('body-parser');
const cryptoUtil = require('./crypto_utils');

const app = express();
app.use(bodyParser.json());

// In a real application, you would store these in a Database (e.g. MongoDB/Firebase)
// We use in-memory maps here for the demo webhook routing
const consentRequests = new Map(); // consentRequestId -> status
const activeConsents = new Map();  // consentId -> details
const keyPairs = new Map();        // transactionId -> { publicKey, privateKey, nonce }

// =========================================================================
// ABDM HIU WEBHOOK ENDPOINTS (PHASE 3)
// =========================================================================

// 1. ABDM calls this when a Consent Request is successfully initialized
app.post('/v0.5/consent-requests/on-init', (req, res) => {
    const { consentRequest, error } = req.body;
    if (error) {
        console.error('Consent Request Error:', error);
    } else {
        console.log(`Consent Request Initialized: ${consentRequest.id}`);
        consentRequests.set(consentRequest.id, 'PENDING');
    }
    // ABDM Webhooks must be acknowledged instantly with 202 Accepted
    res.status(202).send(); 
});

// 2. ABDM calls this when the Patient APPROVES or DENIES the consent on their phone
app.post('/v0.5/consents/hiu/notify', (req, res) => {
    const { notification } = req.body;
    console.log(`Consent Status Update: ${notification.status} for Consent ID: ${notification.consentRequestId}`);
    
    if (notification.status === 'GRANTED') {
        notification.consentArtefacts.forEach(artefact => {
            activeConsents.set(artefact.id, { status: 'GRANTED', ...artefact });
            console.log(`Consent Artefact Generated: ${artefact.id}`);
            
            // ACTION: Your backend should now trigger /v0.5/health-information/cm/request
            // to actually ask for the health records. You must generate your DH Keys here!
            const keys = cryptoUtil.generateKeyPair();
            const nonce = cryptoUtil.extractBase64FromPem(require('crypto').randomBytes(32).toString('base64'));
            
            // Store keys mapped to a transaction ID so we can decrypt it later
            const transactionId = 'txn-' + Date.now();
            keyPairs.set(transactionId, { ...keys, nonce: nonce });
            
            console.log(`Ready to request data for transaction: ${transactionId}`);
        });
    }
    res.status(202).send();
});

// 3. ABDM calls this to actually PUSH the encrypted FHIR records to your server!
app.post('/v0.5/health-information/hiu/on-request', (req, res) => {
    const { hiRequest, hiTransfer, error } = req.body;
    
    if (error) {
        console.error('Data Transfer Error:', error);
        return res.status(202).send();
    }

    console.log(`Received encrypted data for Transaction: ${hiRequest.transactionId}`);
    
    // Retrieve the keys we generated when we requested this data
    const keys = keyPairs.get(hiRequest.transactionId);
    if (!keys) {
        console.error('Keys not found for this transaction!');
        return res.status(202).send();
    }

    try {
        // Iterate over the encrypted FHIR data and decrypt it
        const decryptedRecords = [];
        hiTransfer.data.entries.forEach(entry => {
            const encryptedData = entry.content;
            
            // Assuming entry comes with Sender's Key and Nonce (Standard ABDM format)
            const senderPublicKey = entry.dhPublicKey.keyValue;
            const senderNonce = entry.nonce;

            const decryptedJson = cryptoUtil.decryptData(
                encryptedData,
                keys.privateKeyBase64,
                senderPublicKey,
                senderNonce,
                keys.nonce
            );

            console.log('\n--- DECRYPTED FHIR RECORD ---');
            console.log(decryptedJson);
            decryptedRecords.push(JSON.parse(decryptedJson));
        });

        // ACTION: Save decryptedRecords to your Database or push them to the Flutter app via FCM!

    } catch (e) {
        console.error('Failed to decrypt ABDM payload:', e);
    }

    res.status(202).send();
});

// Simple API for the Flutter app to query if records are ready
app.get('/api/records/:transactionId', (req, res) => {
    // In production, fetch from DB. 
    res.json({ status: 'Records decrypted successfully in backend' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`ABDM HIU Webhook Server running on port ${PORT}`);
    console.log(`Expose this port using ngrok (e.g. 'ngrok http 3000') and update your ABDM Sandbox Webhook URL!`);
});
