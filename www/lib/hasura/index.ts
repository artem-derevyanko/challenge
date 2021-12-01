import axios from 'axios';
import getConfig from 'next/config';

interface HasuraResponse<T> {
  data: T;
  errors?: { message: string }[];
  message?: string;
}

export async function query<T, P extends HasuraResponse<T> = HasuraResponse<T>>(
  query: string,
  variables: Record<string, any>
) {
  try {
    const { serverRuntimeConfig, publicRuntimeConfig } = getConfig();
    const hasuraHost = serverRuntimeConfig.HASURA_HOST ?? publicRuntimeConfig.HASURA_HOST;

    const { data: result } = await axios.post<P>(`${hasuraHost}/v1/graphql`, {
      query,
      variables,
    });
    if (result.errors && result.errors.length) throw new Error(result.errors[0].message);

    return result.data;
  } catch (err) {
    // TODO: Handle different instances of errors

    throw err;
  }
}
