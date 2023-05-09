import argparse
import re
import subprocess

def get_ips_and_ports(nmap_file):
    ip_port_pattern = re.compile(r'(\d+\.\d+\.\d+\.\d+)\s+([0-9]+)/')
    ips_and_ports = []

    with open(nmap_file, 'r') as file:
        for line in file:
            match = ip_port_pattern.search(line)
            if match:
                ip = match.group(1)
                port = match.group(2)
                ips_and_ports.append((ip, port))

    return ips_and_ports

def run_curl(ip, port, output_file):
    curl_command = f'curl -s -o {output_file} {ip}:{port}'
    subprocess.run(curl_command, shell=True)

def main(nmap_file, output_file):
    ips_and_ports = get_ips_and_ports(nmap_file)

    with open(output_file, 'w') as file:
        for ip, port in ips_and_ports:
            file.write(f'IP: {ip}, Port: {port}\n')
            run_curl(ip, port, output_file)
            file.write('\n')

    print(f"Results written to '{output_file}'.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Retrieve IPs and open ports from an nmap file and run curl for each IP and port combination.')
    parser.add_argument('nmap_file', help='Path to the nmap file')
    parser.add_argument('output_file', help='Path to the output file')
    args = parser.parse_args()

    main(args.nmap_file, args.output_file)
