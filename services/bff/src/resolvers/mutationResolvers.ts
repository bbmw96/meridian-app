import axios from 'axios';
import { GraphQLError } from 'graphql';
import { z } from 'zod';
import type { MeridianContext } from '../index.js';

const INTELLIGENCE_URL = process.env.INTELLIGENCE_SERVICE_URL ?? 'http://localhost:8001';
const GATEWAY_URL = process.env.GATEWAY_URL ?? 'http://localhost:8080';

const CreativeInputSchema = z.object({
  format: z.enum(['static', 'video', 'text', 'email', 'social']),
  platform: z.string().min(1).max(50),
  industry: z.string().min(1).max(100),
  brand_name: z.string().min(1).max(100),
  tone: z.string().optional().default('professional'),
  keywords: z.array(z.string()).optional().default([]),
  template: z.enum(['aida', 'pas', 'bab']).optional(),
  constraints: z.record(z.string()).optional().default({}),
});

const AlertInputSchema = z.object({
  pair: z
    .string()
    .regex(/^[A-Z]{3}\/[A-Z]{3}$/, 'Pair must be in format ABC/XYZ'),
  threshold_rate: z.number().positive(),
  direction: z.enum(['ABOVE', 'BELOW']),
});

type AlertInput = z.infer<typeof AlertInputSchema>;
type CreativeInput = z.infer<typeof CreativeInputSchema>;

function mapMQLResultType(data: Record<string, unknown>, resultType: string): Record<string, unknown> {
  switch (resultType) {
    case 'scan_result':
      return {
        __typename: 'ScanResult',
        domain: (data['data'] as Record<string, unknown>)?.['domain'] ?? '',
        profile: data['data'] ?? {},
      };
    case 'opportunity_list':
      return {
        __typename: 'OpportunityListResult',
        opportunities: (data['data'] as Record<string, unknown>)?.['opportunities'] ?? [],
        count: ((data['data'] as Record<string, unknown>)?.['opportunities'] as unknown[])?.length ?? 0,
      };
    case 'creative_result':
      return {
        __typename: 'CreativeResult',
        creative: data['data'] ?? {},
      };
    case 'alert_result':
      return {
        __typename: 'AlertResult',
        alert: (data['data'] as Record<string, unknown>)?.['alert'] ?? {},
        message: (data['data'] as Record<string, unknown>)?.['message'] ?? 'Alert processed',
      };
    default:
      return {
        __typename: 'MessageResult',
        message: (data['message'] as string) ?? 'Query executed',
        data: data['data'] ?? null,
      };
  }
}

export const mutationResolvers = {
  Mutation: {
    generateCreative: async (
      _parent: unknown,
      args: { input: CreativeInput },
      _ctx: MeridianContext,
    ) => {
      const parseResult = CreativeInputSchema.safeParse(args.input);
      if (!parseResult.success) {
        throw new GraphQLError('Invalid creative input', {
          extensions: {
            code: 'BAD_USER_INPUT',
            issues: parseResult.error.issues,
          },
        });
      }

      const validated = parseResult.data;

      try {
        const response = await axios.post(
          `${INTELLIGENCE_URL}/generate-creative`,
          {
            format: validated.format,
            platform: validated.platform,
            industry: validated.industry,
            brand_name: validated.brand_name,
            tone: validated.tone,
            keywords: validated.keywords,
            template: validated.template ?? null,
            constraints: validated.constraints,
          },
          { timeout: 60_000 },
        );
        return response.data;
      } catch (err) {
        if (axios.isAxiosError(err)) {
          throw new GraphQLError(err.response?.data?.message ?? err.message, {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
        throw new GraphQLError('Creative generation service unavailable', {
          extensions: { code: 'UPSTREAM_ERROR' },
        });
      }
    },

    executeMQL: async (
      _parent: unknown,
      args: { query: string },
      _ctx: MeridianContext,
    ) => {
      if (!args.query || args.query.trim().length === 0) {
        throw new GraphQLError('MQL query cannot be empty', {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }

      if (args.query.length > 10_000) {
        throw new GraphQLError('MQL query must not exceed 10,000 characters', {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }

      try {
        const response = await axios.post(
          `${INTELLIGENCE_URL}/analyse`,
          { query: args.query },
          { timeout: 45_000 },
        );

        const data = response.data as Record<string, unknown>;
        const resultType = (data['result_type'] as string) ?? 'message_result';

        return mapMQLResultType(data, resultType);
      } catch (err) {
        if (axios.isAxiosError(err)) {
          throw new GraphQLError(err.response?.data?.message ?? err.message, {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
        throw new GraphQLError('MQL execution service unavailable', {
          extensions: { code: 'UPSTREAM_ERROR' },
        });
      }
    },

    createAlert: async (
      _parent: unknown,
      args: { input: AlertInput },
      ctx: MeridianContext,
    ) => {
      const parseResult = AlertInputSchema.safeParse(args.input);
      if (!parseResult.success) {
        throw new GraphQLError('Invalid alert input', {
          extensions: {
            code: 'BAD_USER_INPUT',
            issues: parseResult.error.issues,
          },
        });
      }

      const validated = parseResult.data;
      const userId = ctx.userId ?? 'anonymous';

      try {
        const response = await axios.post(
          `${INTELLIGENCE_URL}/alerts`,
          {
            user_id: userId,
            pair: validated.pair,
            threshold_rate: validated.threshold_rate,
            direction: validated.direction,
          },
          { timeout: 15_000 },
        );

        const rawId = (response.data as Record<string, unknown>)?.['id'] ?? `alert_${Date.now()}`;
        return {
          id: rawId,
          user_id: userId,
          pair: validated.pair,
          threshold_rate: validated.threshold_rate,
          direction: validated.direction,
          is_active: true,
          created_at: new Date().toISOString(),
          triggered_at: null,
        };
      } catch (err) {
        if (axios.isAxiosError(err)) {
          throw new GraphQLError(err.response?.data?.message ?? err.message, {
            extensions: { code: 'UPSTREAM_ERROR' },
          });
        }
        throw new GraphQLError('Alert service unavailable', {
          extensions: { code: 'UPSTREAM_ERROR' },
        });
      }
    },

    deleteAlert: async (
      _parent: unknown,
      args: { id: string },
      ctx: MeridianContext,
    ) => {
      if (!args.id || args.id.trim().length === 0) {
        throw new GraphQLError('Alert ID is required', {
          extensions: { code: 'BAD_USER_INPUT' },
        });
      }

      if (ctx.redis.status === 'ready') {
        try {
          await ctx.redis.del(`meridian:alert:${args.id}`);
        } catch {
          // Non-fatal
        }
      }

      return true;
    },
  },

  MQLResult: {
    __resolveType(obj: { __typename: string }) {
      return obj.__typename ?? 'MessageResult';
    },
  },
};
