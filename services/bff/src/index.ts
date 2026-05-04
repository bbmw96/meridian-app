import 'dotenv/config';
import express from 'express';
import http from 'http';
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { json } from 'express';
import Redis from 'ioredis';

import { typeDefs } from './schema/typeDefs.js';
import { resolvers } from './resolvers/index.js';

const PORT = parseInt(process.env.PORT ?? '4000', 10);
const REDIS_URL = process.env.REDIS_URL ?? 'redis://localhost:6379';

export interface MeridianContext {
  redis: Redis;
  userId?: string;
}

async function bootstrap(): Promise<void> {
  const redis = new Redis(REDIS_URL, {
    lazyConnect: true,
    maxRetriesPerRequest: 3,
    retryStrategy: (times) => Math.min(times * 200, 3000),
  });

  try {
    await redis.connect();
    console.log('[BFF] Redis connected at', REDIS_URL);
  } catch (err) {
    console.warn('[BFF] Redis unavailable — caching disabled:', (err as Error).message);
  }

  const app = express();
  const httpServer = http.createServer(app);

  const server = new ApolloServer<MeridianContext>({
    typeDefs,
    resolvers,
    plugins: [ApolloServerPluginDrainHttpServer({ httpServer })],
    formatError: (formattedError, error) => {
      console.error('[BFF] GraphQL Error:', formattedError.message);
      return {
        message: formattedError.message,
        code: formattedError.extensions?.code ?? 'INTERNAL_SERVER_ERROR',
        path: formattedError.path,
      };
    },
    introspection: process.env.NODE_ENV !== 'production',
  });

  await server.start();

  app.get('/health', (_req, res) => {
    res.json({
      status: 'healthy',
      service: 'meridian-bff',
      timestamp: new Date().toISOString(),
      redis: redis.status === 'ready',
    });
  });

  app.use(
    '/graphql',
    json(),
    expressMiddleware(server, {
      context: async ({ req }): Promise<MeridianContext> => {
        const authHeader = req.headers.authorization ?? '';
        const userId = authHeader.startsWith('Bearer ')
          ? parseUserFromToken(authHeader.slice(7))
          : undefined;
        return { redis, userId };
      },
    }),
  );

  await new Promise<void>((resolve) => {
    httpServer.listen({ port: PORT }, resolve);
  });

  console.log(`[BFF] MERIDIAN GraphQL BFF ready at http://localhost:${PORT}/graphql`);
}

function parseUserFromToken(token: string): string | undefined {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return undefined;
    const payload = JSON.parse(Buffer.from(parts[1]!, 'base64url').toString('utf8'));
    return payload.user_id ?? payload.sub ?? undefined;
  } catch {
    return undefined;
  }
}

bootstrap().catch((err) => {
  console.error('[BFF] Fatal error during startup:', err);
  process.exit(1);
});
