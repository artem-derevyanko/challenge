import { LongTail } from '../domain/LongTail';

export const getLongTailQuery = `
  query getLongTail($tail: String!) {
    long_tail(tail: $tail) {
      id
      title
      description
    }
  }
`;

export interface GetLongTailVariables {
  tail: string;
}

export interface GetLongTailResult {
  long_tail: LongTail;
}
