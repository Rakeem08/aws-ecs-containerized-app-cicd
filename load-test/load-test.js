import http from 'k6/http'
import { check } from 'k6'

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '5m', target: 200 },
    { duration: '1m', target: 0 },
  ],
}

export default function () {
  const responses = http.batch([
    `${__ENV.BASE_URL}/`,
    `${__ENV.BASE_URL}/api`,
  ])

  check(responses[0], {
    'frontend returned 200': (response) => response.status === 200,
  })

  check(responses[1], {
    'backend returned 200': (response) => response.status === 200,
  })
}