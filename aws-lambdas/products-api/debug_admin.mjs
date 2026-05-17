import { handler } from './index.mjs';

const event = {
  requestContext: {
    http: {
      method: 'POST',
      path: '/prod/admin/bills'
    }
  },
  body: JSON.stringify({
    config: { companyName: 'Test' },
    items: []
  })
};

handler(event).then(res => {
  console.log('Response:', JSON.stringify(res, null, 2));
}).catch(err => {
  console.error('Crash:', err);
});
