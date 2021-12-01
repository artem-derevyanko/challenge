import { NextApiRequest, NextApiResponse } from 'next';
import * as hasura from '../../lib/hasura';

import { LongTail, LongTailInfo } from '../../domain/LongTail';
import { getJSONFromDifferentSources } from '../../utils/fetch';
import { getLongTailInfoQuery } from '../../gql/getLongTailInfo';

interface GetLongTailQueryResponse {
  long_tails: LongTailInfo[];
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  try {
    // TODO: Add checking secret key for security

    const { JSON_SOURCE_PATH } = process.env;
    if (!JSON_SOURCE_PATH) throw new Error('Source file is not defined');

    const { tail } = req.body.input;

    const response = await hasura.query<GetLongTailQueryResponse>(getLongTailInfoQuery, { tail });
    if (!response || !response.long_tails.length) throw new Error('Not Found');

    const jsonData = await getJSONFromDifferentSources<LongTail[]>(JSON_SOURCE_PATH);
    const longTail = jsonData?.find((item) => response.long_tails[0].json_id === item.id);
    if (!longTail) throw new Error('Not Found');

    return res.status(200).json(longTail);
  } catch (err) {
    return res.status(400).json({ message: 'Not Found' });
  }
}
