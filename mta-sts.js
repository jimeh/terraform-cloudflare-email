addEventListener('fetch', (event) => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);

  if (url.pathname === '/.well-known/mta-sts.txt') {
    const response = await FILES.get('mta-sts.txt');

    if (response) {
      return new Response(response, { status: 200 });
    }
  }

  return new Response('Not found', { status: 404 });
}
