const { Kafka } = require('kafkajs');
const client = require('prom-client');
const express = require('express');
const app = express();

// Kafka configuration
const kafka = new Kafka({
  clientId: 'claims-processor',
  brokers: [process.env.KAFKA_BROKER || 'anaira-kafka-kafka-bootstrap.kafka:9092']
});

const producer = kafka.producer();

// Prometheus metrics
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  buckets: [0.5, 1, 1.5, 2, 3, 5]
});
// Collect default Node.js metrics
client.collectDefaultMetrics();

// Custom counter metric
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route'],
});

let memoryLeakCollector = []; // Simulates unbounded cache growth

// Health check endpoint
app.get('/health', (req, res) => {
  httpRequestCounter.inc({ method: 'GET', route: '/health' });
  res.status(200).send('OK');
});

// Claims processing endpoint (leaks 15MB RAM per request)
app.get('/process-claim', (req, res) => {

  const end = httpRequestDuration.startTimer();
  httpRequestCounter.inc({ method: 'GET', route: '/process-claim' });

  // Simulate heavy AI processing by leaking memory
  const claimData = new Array(15 * 1024 * 1024).fill('REDACTED_CLAIM_DATA');
  memoryLeakCollector.push(claimData);

  const heapMB = (process.memoryUsage().heapUsed / 1024 / 1024).toFixed(2);

  if (heapMB > 240) {
    console.log(`[${new Date().toISOString()}] ERROR: Memory usage critically high (${heapMB} MB)`);
  }

  console.log(`[${new Date().toISOString()}] Current Heap: ${(process.memoryUsage().heapUsed / 1024 / 1024).toFixed(2)} MB`);

  end();
  res.send('Claim sent to AI processing engine...');
});

// Kafka event producer endpoint
app.post('/emit-claim-event', async (req, res) => {

  try {

    await producer.send({
      topic: 'claim-submitted',
      messages: [
        {
          key: 'claim-123',
          value: JSON.stringify({
            claimId: "123",
            status: "submitted",
            timestamp: new Date().toISOString()
          })
        }
      ]
    });

    console.log("Claim event emitted to Kafka");

    res.send("Event queued in Kafka");

  } catch (error) {

    console.error("Kafka error:", error);

    res.status(500).send("Kafka publish failed");

  }

});

// Metrics endpoint
app.get('/metrics', async (req, res) => {

  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());

});

// Connect Kafka when app starts
async function connectKafka() {

  try {

    await producer.connect();
    console.log("Connected to Kafka");

  } catch (err) {

    console.error("Kafka connection error:", err);

  }

}

const PORT = process.env.PORT || 3000;

app.listen(PORT, async () => {

  console.log(`Claims Processor running on port ${PORT}`);

  await connectKafka();

});