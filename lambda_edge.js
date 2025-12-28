'use strict';

exports.handler = (event, context, callback) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;

  // CloudFront 국가 코드 (예: KR, JP, US)
  const country = headers['cloudfront-viewer-country']
    ? headers['cloudfront-viewer-country'][0].value
    : 'US';

  let redirectUrl = '/en/index.html';

  if (country === 'KR') {
    redirectUrl = '/kr/index.html';
  } else if (country === 'JP') {
    redirectUrl = '/jp/index.html';
  }

  const response = {
    status: '302',
    statusDescription: 'Found',
    headers: {
      location: [{ key: 'Location', value: redirectUrl }]
    }
  };

  return callback(null, response);
};
