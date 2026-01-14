const express = require('express');

const app = express();
app.use(express.json());

// Cloud Run structured logging utility
const logger = {
  // Get trace context from Cloud Run request headers
  getTraceContext(req) {
    const traceHeader = req.get('X-Cloud-Trace-Context');
    if (!traceHeader) return {};

    const [trace] = traceHeader.split('/');
    const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.PROJECT_ID;

    return projectId && trace
      ? { 'logging.googleapis.com/trace': `projects/${projectId}/traces/${trace}` }
      : {};
  },

  // Format log entry for Cloud Logging
  log(severity, message, additionalFields = {}, req = null) {
    const entry = {
      severity,
      message,
      timestamp: new Date().toISOString(),
      ...additionalFields,
      ...(req ? this.getTraceContext(req) : {}),
    };
    console.log(JSON.stringify(entry));
  },

  debug(message, fields = {}, req = null) {
    this.log('DEBUG', message, fields, req);
  },

  info(message, fields = {}, req = null) {
    this.log('INFO', message, fields, req);
  },

  warning(message, fields = {}, req = null) {
    this.log('WARNING', message, fields, req);
  },

  error(message, fields = {}, req = null) {
    this.log('ERROR', message, fields, req);
  },
};

// Parse Pub/Sub message
function parsePubSubMessage(body) {
  if (!body.message) {
    throw new Error('Invalid Pub/Sub message format: missing message field');
  }

  const message = body.message;
  const data = message.data
    ? JSON.parse(Buffer.from(message.data, 'base64').toString('utf-8'))
    : null;

  return {
    messageId: message.messageId,
    publishTime: message.publishTime,
    attributes: message.attributes || {},
    data,
    subscription: body.subscription,
  };
}

// Health check endpoint
app.get('/health', (req, res) => {
  logger.debug('Health check requested', {}, req);
  res.status(200).json({ status: 'healthy' });
});

// Pub/Sub push endpoint
app.post('/', async (req, res) => {
  const startTime = Date.now();

  try {
    // Parse the Pub/Sub message
    const pubsubMessage = parsePubSubMessage(req.body);

    logger.info('Received Pub/Sub message', {
      messageId: pubsubMessage.messageId,
      subscription: pubsubMessage.subscription,
      attributes: pubsubMessage.attributes,
    }, req);

    // Process the message (implement your business logic here)
    await processMessage(pubsubMessage, req);

    const duration = Date.now() - startTime;
    logger.info('Message processed successfully', {
      messageId: pubsubMessage.messageId,
      durationMs: duration,
    }, req);

    // Return 200 to acknowledge the message
    res.status(200).json({
      status: 'success',
      messageId: pubsubMessage.messageId,
    });

  } catch (error) {
    const duration = Date.now() - startTime;

    logger.error('Failed to process message', {
      error: error.message,
      stack: error.stack,
      durationMs: duration,
    }, req);

    // Return 500 to trigger retry (or 400 for non-retryable errors)
    const statusCode = isRetryableError(error) ? 500 : 400;
    res.status(statusCode).json({
      status: 'error',
      error: error.message,
    });
  }
});

// Example message processor
async function processMessage(pubsubMessage, req) {
  const { messageId, data, attributes } = pubsubMessage;

  logger.debug('Processing message data', {
    messageId,
    dataType: typeof data,
    attributeKeys: Object.keys(attributes),
  }, req);

  // Simulate processing time
  await new Promise(resolve => setTimeout(resolve, 100));

  // Example: Handle different event types
  const eventType = attributes.eventType || 'unknown';

  switch (eventType) {
    case 'user.created':
      logger.info('Processing user creation event', { messageId, eventType }, req);
      break;
    case 'order.completed':
      logger.info('Processing order completion event', { messageId, eventType }, req);
      break;
    default:
      logger.warning('Unknown event type received', { messageId, eventType }, req);
  }

  return { processed: true };
}

// Determine if error is retryable
function isRetryableError(error) {
  // Non-retryable errors (return 400)
  const nonRetryableErrors = [
    'Invalid Pub/Sub message format',
    'ValidationError',
    'SyntaxError',
  ];

  return !nonRetryableErrors.some(msg =>
    error.message.includes(msg) || error.name === msg
  );
}

// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  logger.info('Server started', {
    port: PORT,
    nodeVersion: process.version,
    environment: process.env.NODE_ENV || 'development',
  });
});
