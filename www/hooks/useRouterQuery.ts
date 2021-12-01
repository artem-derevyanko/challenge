import { useRouter } from 'next/router';

export default function useRouterQuery(name: string) {
  const router = useRouter();
  const query = router.query[name];

  if (!query) return null;
  if (Array.isArray(query)) return query[0];

  return query;
}
