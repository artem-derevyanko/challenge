import type { NextPage } from 'next';
import { LongTailExample } from '../components/LongTailExample';

import useRouterQuery from '../hooks/useRouterQuery';

const LongTailPage: NextPage = () => {
  const tailQuery = useRouterQuery('tail')!;

  return <LongTailExample tail={tailQuery} />;
};

export async function getServerSideProps() {
  return {
    props: {},
  };
}

export default LongTailPage;
