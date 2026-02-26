const express = require('express');
const app = express();
let memoryLeakCollector = []; // Simulates unbounded cache growth
// Health check endpoint
app.get('/health', (req, res) => {
res.status(200).send('OK');
});
// Claims processing endpoint (leaks 15MB RAM per request)
app.get('/process-claim', (req, res) => {
// Simulating heavy AI processing by leaking 15MB of RAM per request
const claimData = new Array(15 * 1024 * 1024).fill('REDACTED_CLAIM_DATA');
memoryLeakCollector.push(claimData);
console.log(`[${new Date().toISOString()}] Current Heap: ${(process.memoryUsage().heapUsed / 1024 / 1024).toFixed(2)} MB`);
res.send('Claim sent to AI processing engine...');
});
// Kafka event producer endpoint (Phase 4)
app.post('/emit-claim-event', (req, res) => {
// TODO: You'll wire this to Kafka in Phase 4
console.log('Claim event emitted (not connected to Kafka yet)');
res.send('Event queued');
});
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
console.log(`Claims Processor running on port ${PORT}`);
});