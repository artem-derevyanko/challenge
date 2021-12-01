import useLongTailQuery from './hooks/useLongTail';

interface LongTailExampleProps {
  tail: string;
}

export const LongTailExample: React.FC<LongTailExampleProps> = ({ tail }) => {
  const [longTail, loading, error] = useLongTailQuery(tail);

  if (loading) return <div>Loading...</div>;
  if (!longTail || error) return <div>Selected long tail is not founded</div>;

  const { title, description } = longTail;
  return (
    <ul>
      <li>
        <b>Title:</b> {title}
      </li>
      <li>
        <b>Description:</b> {description}
      </li>
    </ul>
  );
};
