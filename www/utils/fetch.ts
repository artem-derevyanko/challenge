import axios from 'axios';
import { readFile } from 'fs/promises';
import { join } from 'path';

export async function getJSONFromDifferentSources<T>(path: string): Promise<T | null> {
  try {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      const { data } = await axios.get(path);

      return data;
    }

    return JSON.parse(await readFile(join(process.cwd(), path), 'utf-8'));
  } catch (err) {
    return null;
  }
}
