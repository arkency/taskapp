import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 4,
  duration: '30s',
};

export default function() {
  http.get('http://localhost:3000/projects_collection');
  sleep(1);
}
