import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 500,
  duration: "200s",
  thresholds: {
    http_req_duration: ["p(95)<2000"],
    http_req_failed: ["rate<0.05"],
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export default function () {
  const listRes = http.get(`${BASE_URL}/tasks.json`, { timeout: "10s" });
  check(listRes, {
    "GET /tasks.json is status 200": (r) => r.status === 200,
  });

  if (__VU === 1 && __ITER % 10 === 0) {
    const payload = JSON.stringify({
      task: {
        title: `Load Test Task ${__ITER}`,
        description: "Created under 500 VU load",
        completed: false,
      },
    });
    const params = { headers: { "Content-Type": "application/json" } };
    const createRes = http.post(`${BASE_URL}/tasks.json`, payload, params);
    check(createRes, {
      "POST /tasks.json is status 201": (r) => r.status === 201,
    });
  }

  const upRes = http.get(`${BASE_URL}/up`, { timeout: "10s" });
  check(upRes, {
    "GET /up is status 200": (r) => r.status === 200,
  });

  sleep(0.5);
}
