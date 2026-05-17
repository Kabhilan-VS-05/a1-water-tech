import { handler } from './index.mjs';

const event = {
  requestContext: {
    http: {
      method: 'GET',
      path: '/prod/products'
    }
  }
};

handler(event).then(res => {
  console.log('Response:', JSON.stringify(res, null, 2));
}).catch(err => {
  console.error('Crash:', err);
});
