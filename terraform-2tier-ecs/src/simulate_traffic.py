#!/usr/bin/env python3
"""Generate controlled concurrent traffic against the funDevops application."""

import argparse
import concurrent.futures
import statistics
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter, defaultdict


ENDPOINTS = ("/health", "/", "/login")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request_once(base_url, endpoint, user_id, timeout):
    url = urllib.parse.urljoin(base_url.rstrip("/") + "/", endpoint.lstrip("/"))
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": f"funDevops-load-test/user-{user_id}",
            "Accept": "text/html,application/json",
            "Cache-Control": "no-cache",
        },
    )
    started = time.perf_counter()

    try:
        with urllib.request.build_opener(NoRedirect).open(
            request, timeout=timeout
        ) as response:
            status = response.status
            response.read()
            error = None
    except urllib.error.HTTPError as exc:
        # Redirects are expected for the protected home page.
        status = exc.code
        exc.read()
        error = None if 300 <= status < 400 else str(exc)
    except Exception as exc:
        status = 0
        error = str(exc)

    latency_ms = (time.perf_counter() - started) * 1000
    return endpoint, status, latency_ms, error


def percentile(values, percent):
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, int((percent / 100) * len(ordered)))
    return ordered[index]


def parse_args():
    parser = argparse.ArgumentParser(
        description="Simulate multiple users hitting health, home, and login."
    )
    parser.add_argument(
        "--url",
        default="https://tf2t.mansipandey.in/",
        help="Application base URL",
    )
    parser.add_argument(
        "--users",
        type=int,
        default=10,
        help="Maximum concurrent virtual users (default: 10)",
    )
    parser.add_argument(
        "--rps",
        type=int,
        default=15,
        help="Total requests per second across all endpoints (default: 15)",
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=30,
        help="Test duration in seconds (default: 30)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=10,
        help="Timeout for each request in seconds (default: 10)",
    )
    args = parser.parse_args()

    for name in ("users", "rps", "duration"):
        if getattr(args, name) < 1:
            parser.error(f"--{name} must be at least 1")
    if args.timeout <= 0:
        parser.error("--timeout must be greater than 0")
    if urllib.parse.urlparse(args.url).scheme not in ("http", "https"):
        parser.error("--url must start with http:// or https://")

    return args


def main():
    args = parse_args()
    total_requests = args.rps * args.duration
    results = []

    print(
        f"Target: {args.url}\n"
        f"Endpoints: {', '.join(ENDPOINTS)}\n"
        f"Users: {args.users} | Target RPS: {args.rps} | "
        f"Duration: {args.duration}s | Planned requests: {total_requests}\n"
    )

    started = time.perf_counter()
    futures = []

    try:
        with concurrent.futures.ThreadPoolExecutor(
            max_workers=args.users
        ) as executor:
            for second in range(args.duration):
                batch_started = started + second

                for request_number in range(args.rps):
                    global_number = second * args.rps + request_number
                    endpoint = ENDPOINTS[global_number % len(ENDPOINTS)]
                    user_id = (global_number % args.users) + 1
                    futures.append(
                        executor.submit(
                            request_once,
                            args.url,
                            endpoint,
                            user_id,
                            args.timeout,
                        )
                    )

                completed = sum(future.done() for future in futures)
                print(
                    f"\rScheduled {len(futures)}/{total_requests} requests "
                    f"({completed} completed)",
                    end="",
                    flush=True,
                )

                remaining = batch_started + 1 - time.perf_counter()
                if remaining > 0:
                    time.sleep(remaining)

            print("\nWaiting for in-flight requests...")
            for future in concurrent.futures.as_completed(futures):
                results.append(future.result())
    except KeyboardInterrupt:
        print("\nStopped by user; summarizing completed requests.")
        results.extend(future.result() for future in futures if future.done())

    elapsed = time.perf_counter() - started
    statuses = Counter(status for _, status, _, _ in results)
    errors = [error for _, _, _, error in results if error]

    print("\nResults")
    print(f"Completed: {len(results)} requests in {elapsed:.2f}s")
    print(f"Effective throughput: {len(results) / elapsed:.2f} requests/second")
    print(
        "HTTP statuses: "
        + ", ".join(
            f"{status or 'network-error'}={count}"
            for status, count in sorted(statuses.items())
        )
    )

    by_endpoint = defaultdict(list)
    for endpoint, _, latency_ms, _ in results:
        by_endpoint[endpoint].append(latency_ms)

    print("\nEndpoint latency")
    for endpoint in ENDPOINTS:
        latencies = by_endpoint[endpoint]
        if not latencies:
            continue
        print(
            f"  {endpoint:<8} count={len(latencies):<5} "
            f"avg={statistics.mean(latencies):7.1f}ms "
            f"p95={percentile(latencies, 95):7.1f}ms "
            f"max={max(latencies):7.1f}ms"
        )

    if errors:
        print(f"\nErrors: {len(errors)}")
        for message, count in Counter(errors).most_common(5):
            print(f"  {count}x {message}")


if __name__ == "__main__":
    main()
