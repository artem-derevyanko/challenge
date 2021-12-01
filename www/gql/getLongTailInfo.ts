import { LongTailInfo } from '../domain/LongTail';

export const getLongTailInfoQuery = `
  query getLongTailByJsonId($tail: String!) {
    long_tails(where: { tail: { _eq: $tail } }) {
      json_id
      tail
    }
  }
`;

export interface GetLongTailInfoVariables {
  tail: string;
}

export interface GetLongTailInfoResult {
  long_tails: LongTailInfo[];
}
