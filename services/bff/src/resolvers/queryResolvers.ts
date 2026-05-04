import axios from 'axios';
import { GraphQLError } from 'graphql';
import type { MeridianContext } from '../index.js';

const INTELLIGENCE_URL = process.env.INTELLIGENCE_SERVICE_URL ?? 'http://localhost:8001';
const GATEWAY_URL = process.env.GATEWAY_URL ?? 'http://localhost:8080';

const CACHE_TTL_DOMAIN = 300;
const CACHE_TTL_RATES = 30;
const CACHE_TTL_COMPETITORS = 600;
const CACHE_TTL_OPPORTUNITIES = 120;

async function cachedGet<T>(
  ctx: MeridianContext,
  cacheKey: string,
  ttl: number,
  fetcher: () => Promise<T>,
): Promise<T> {
  if (ctx.redis.status === 'ready') {
    try {
      const cached = await ctx.redis.get(cacheKey);
      if (cached) {
        return JSON.parse(cached) as T;
      }
    } catch {
      // Cache read failure is non-fatal
    }
  }

  const data = await fetcher();

  if (ctx.redis.status === 'ready') {
    try {
      await ctx.redis.setex(cacheKey, ttl, JSON.stringify(data));
    } catch {
      // Cache write failure is non-fatal
    }
  }

  return data;
}

export const queryResolvers = {
  Query: {
    scanDomain: async (
      _parent: unknown,
      args: { domain: string },
      ctx: MeridianContext,
    ) => {
      const cacheKey = `meridian:bff:scan:${args.domain}`;
      return cachedGet(ctx, cacheKey, CACHE_TTL_DOMAIN, async () => {
        try {
          const response = await axios.post(
            `${INTELLIGENCE_URL}/scan`,
            { domain: args.domain },
            { timeout: 30_000 },
          );
          return response.data;
        } catch (err) {
          if (axios.isAxiosError(err)) {
            const status = err.response?.status ?? 502;
            const message = err.response?.data?.message ?? err.message;
            throw new GraphQLError(message, {
              extensions: { code: status === 400 ? 'BAD_USER_INPUT' : 'UPSTREAM_ERROR', status },
            });
          }
          throw new GraphQLError('Domain scan service unavailable', {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
      });
    },

    getCompetitors: async (
      _parent: unknown,
      args: { domain: string; limit?: number },
      ctx: MeridianContext,
    ) => {
      const limit = Math.min(Math.max(args.limit ?? 10, 1), 50);
      const cacheKey = `meridian:bff:competitors:${args.domain}:${limit}`;
      return cachedGet(ctx, cacheKey, CACHE_TTL_COMPETITORS, async () => {
        try {
          const response = await axios.get(`${INTELLIGENCE_URL}/competitors`, {
            params: { domain: args.domain, limit },
            timeout: 20_000,
          });
          return response.data.competitors ?? [];
        } catch (err) {
          if (axios.isAxiosError(err)) {
            throw new GraphQLError(err.response?.data?.message ?? err.message, {
              extensions: { code: 'UPSTREAM_ERROR' },
            });
          }
          throw new GraphQLError('Competitor service unavailable', {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
      });
    },

    getRates: async (
      _parent: unknown,
      args: { pairs?: string[] },
      ctx: MeridianContext,
    ) => {
      const pairsParam = args.pairs?.join(',') ?? '';
      const cacheKey = `meridian:bff:rates:${pairsParam || 'default'}`;
      return cachedGet(ctx, cacheKey, CACHE_TTL_RATES, async () => {
        try {
          const response = await axios.get(`${GATEWAY_URL}/api/v1/currency/rates`, {
            params: pairsParam ? { pairs: pairsParam } : {},
            timeout: 10_000,
            headers: { Authorization: `Bearer ${process.env.INTERNAL_JWT_TOKEN ?? ''}` },
          });
          const ratesList = response.data.rates ?? [];
          return ratesList.map((r: Record<string, unknown>) => ({
            ...r,
            change_percent: r.change_percent ?? null,
            timestamp: r.timestamp ?? new Date().toISOString(),
          }));
        } catch (err) {
          if (axios.isAxiosError(err)) {
            throw new GraphQLError(err.response?.data?.message ?? err.message, {
              extensions: { code: 'UPSTREAM_ERROR' },
            });
          }
          throw new GraphQLError('Currency rate service unavailable', {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
      });
    },

    getOpportunities: async (
      _parent: unknown,
      args: {
        market?: string;
        geography?: string;
        minScore?: number;
        maxResults?: number;
      },
      ctx: MeridianContext,
    ) => {
      const cacheKey = `meridian:bff:opportunities:${args.market ?? ''}:${args.geography ?? ''}:${args.minScore ?? 50}`;
      return cachedGet(ctx, cacheKey, CACHE_TTL_OPPORTUNITIES, async () => {
        try {
          const response = await axios.post(
            `${INTELLIGENCE_URL}/opportunities`,
            {
              market: args.market ?? null,
              geography: args.geography ?? null,
              min_score: args.minScore ?? 50,
              max_results: args.maxResults ?? 20,
            },
            { timeout: 30_000 },
          );
          return response.data.opportunities ?? [];
        } catch (err) {
          if (axios.isAxiosError(err)) {
            throw new GraphQLError(err.response?.data?.message ?? err.message, {
              extensions: { code: 'UPSTREAM_ERROR' },
            });
          }
          throw new GraphQLError('Opportunity service unavailable', {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
      });
    },
  },
};
