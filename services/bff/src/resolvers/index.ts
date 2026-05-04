import { DateTimeResolver, JSONResolver } from 'graphql-scalars';
import { queryResolvers } from './queryResolvers.js';
import { mutationResolvers } from './mutationResolvers.js';

export const resolvers = {
  JSON: JSONResolver,
  DateTime: DateTimeResolver,
  ...queryResolvers,
  ...mutationResolvers,
};
