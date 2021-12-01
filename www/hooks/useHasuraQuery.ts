import { useEffect, useState } from 'react';
import * as hasura from '../lib/hasura';

export function useHasuraQuery<T>(query: string, variables: Record<string, any>) {
  const [result, setResult] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    (async () => {
      try {
        setLoading(true);

        setResult(await hasura.query<T>(query, variables));
      } catch (err) {
        setError(err instanceof Error ? err : new Error(String(err)));
      } finally {
        setLoading(false);
      }
    })();
  }, [query, variables]);

  return [result, loading, error] as const;
}
