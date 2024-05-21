import dns.resolver
import time
import sys
import os

def test_dns_server_speed(dns_server, domain="google.com"):
    """
    Test the resolution speed of a domain using a specific DNS server.

    :param dns_server: The DNS server IP to test
    :param domain: The domain to resolve (default is google.com)
    :return: Resolution time in seconds, None if failed
    """
    resolver = dns.resolver.Resolver()
    resolver.nameservers = [dns_server]

    try:
        start_time = time.time()
        resolver.resolve(domain)
        end_time = time.time()
        return end_time - start_time
    except Exception as e:
        print(f"Error querying {dns_server}: {e}")
        return None

def main():
    if len(sys.argv) < 3:
        print("Usage: script_name.py [DNS servers (comma separated)] [Domain to test]")
        sys.exit(1)

    dns_servers = sys.argv[1].split(',')
    domain_to_test = sys.argv[2]

    # Add known DNS servers for comparison
    known_dns_servers = ["208.67.222.222", "208.67.220.220", "8.8.8.8", "8.8.4.4"]
    for server in known_dns_servers:
        if server not in dns_servers:
            dns_servers.append(server)

    results = {}
    for server in dns_servers:
        time_taken = test_dns_server_speed(server, domain_to_test)
        if time_taken is not None:
            results[server] = time_taken

    print("\nResults:")
    for server, speed in sorted(results.items(), key=lambda x: x[1]):
        print(f"{server} - {speed:.4f} seconds")

if __name__ == "__main__":
    main()
