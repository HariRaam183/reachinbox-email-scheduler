import { Queue } from 'bullmq';
import IORedis from 'ioredis';
import env from './config.js';
export const redis = new IORedis(env.REDIS_URL, { maxRetriesPerRequest: null });
export const emailQueue = new Queue('emailQueue', { connection: redis, defaultJobOptions: { attempts: 3, backoff: { type: 'exponential', delay: 5000 }, removeOnComplete: 1000, removeOnFail: 5000 } });
