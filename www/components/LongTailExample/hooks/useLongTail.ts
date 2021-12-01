import { useMemo } from 'react';

import { useHasuraQuery } from '../../../hooks/useHasuraQuery';
import {
  getLongTailQuery,
  GetLongTailResult,
  GetLongTailVariables,
} from '../../../gql/getLongTail';

export default function useLongTailQuery(tail: string) {
  const variables: GetLongTailVariables = useMemo(() => ({ tail }), [tail]);
  const [result, loading, error] = useHasuraQuery<GetLongTailResult>(getLongTailQuery, variables);

  return [result?.long_tail, loading, error] as const;
}
