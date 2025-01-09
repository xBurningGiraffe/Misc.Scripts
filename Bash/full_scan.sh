#!/usr/bin/env bash

################################################################################
# nfull_scan.sh
#
# Description:
#   A modular script to perform network scans, DNS lookups, SSL assessments,
#   and Akamai presence detection. It integrates nmap, dig, sslyze (via Docker),
#   and traceroute to generate comprehensive reports in CSV format or display
#   them in the terminal.
#
# Usage:
#   ./full_scan.sh -i <input_file> [ -o <output_csv> ] [options]
#
# Options:
#   -a, --all          Run all functions: nmap, dig, sslyze, akamai
#   -n, --nmap         Perform nmap scanning only
#   -d, --dig          Perform reverse DNS lookups only
#   -s, --sslyze       Perform sslyze scans only
#   -t, --akamai       Perform Akamai detection via traceroute
#   -i, --input        Specify input file with subnets or IPs
#   -o, --output       Specify output CSV file (optional)
#   -h, --help         Display help information
#
# Example:
#   ./full_scan.sh -i subnets.txt -o results.csv -a
#   ./full_scan.sh -i subnets.txt -n -d
#   ./full_scan.sh -i subnets.txt -o results.csv -t
################################################################################

# Exit immediately if a command exits with a nonzero status, and treat unset variables as an error.
set -o errexit
set -o pipefail
set -o nounset

# Global Variables
INPUT_FILE=""
OUTPUT_CSV=""
PORTS="80,443,8080,8443"
RUN_ALL=false
RUN_NMAP=false
RUN_DIG=false
RUN_SSLYZE=false
RUN_AKAMAI=false
MANUAL_SNI=false
SNI_DOMAIN=""

# Associative arrays to store data
declare -A OPEN_PORTS_MAP
declare -A DOMAINS_MAP
declare -A SSL_COMPLIANCE_MAP
declare -A SSL_ISSUES_MAP
declare -A AKAMAI_MAP

# Function: Display Help
show_help() {
    echo "Description:"
    echo "  A modular script to perform network scans, DNS lookups, SSL assessments,"
    echo "  and Akamai presence detection. It integrates nmap, dig, sslyze (via Docker),"
    echo "  and traceroute to generate comprehensive reports in CSV format or display"
    echo "  them in the terminal."
    echo ""
    echo "Usage:"
    echo "  $0 -i <input_file> [ -o <output_csv> ] [options]"
    echo ""
    echo "Options:"
    echo "  -a, --all          Run all functions: nmap, dig, sslyze, akamai"
    echo "  -n, --nmap         Perform nmap scanning only"
    echo "  -d, --dig          Perform reverse DNS lookups only"
    echo "  -s, --sslyze       Perform sslyze scans only"
    echo "  -t, --akamai       Perform Akamai detection via traceroute"
    echo "  -i, --input        Specify input file with subnets or IPs"
    echo "  -o, --output       Specify output CSV file (optional)"
    echo "  -h, --help         Display this help information"
    echo ""
    echo "Example:"
    echo "  $0 -i subnets.txt -o results.csv -a"
    echo "  $0 -i subnets.txt -n -d"
    echo "  $0 -i subnets.txt -o results.csv -t"
}

# Function: Initialize Output (CSV or Terminal)
initialize_output() {
    if [[ -n "$OUTPUT_CSV" ]]; then
        # Initialize CSV with headers based on selected functions
        local headers="IP Address"
        [[ "$RUN_DIG" == true || "$RUN_ALL" == true ]] && headers+=",Domain"
        [[ "$RUN_NMAP" == true || "$RUN_ALL" == true ]] && headers+=",Open Ports"
        [[ "$RUN_SSLYZE" == true || "$RUN_ALL" == true ]] && headers+=",SSL Compliance Status,Compliance Issues"
        [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]] && headers+=",Akamai Detected (Y/N)"
        echo "$headers" > "$OUTPUT_CSV"
    else
        # Initialize terminal output with headers
        local headers="IP Address"
        [[ "$RUN_DIG" == true || "$RUN_ALL" == true ]] && headers+=",Domain"
        [[ "$RUN_NMAP" == true || "$RUN_ALL" == true ]] && headers+=",Open Ports"
        [[ "$RUN_SSLYZE" == true || "$RUN_ALL" == true ]] && headers+=",SSL Compliance Status,Compliance Issues"
        [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]] && headers+=",Akamai Detected (Y/N)"
        echo "$headers"
        echo "--------------------------------------------------------------------------------------------------------"
    fi
}

# Function: Perform nmap scan
run_nmap() {
    echo "Starting Nmap scan..."
    while IFS= read -r SUBNET || [ -n "$SUBNET" ]; do
        # Trim whitespace and skip empty/comment lines
        SUBNET=$(echo "$SUBNET" | xargs)
        [[ -z "$SUBNET" || "$SUBNET" =~ ^# ]] && continue

        echo "Scanning $SUBNET with Nmap..."
        NMAP_OUTPUT=$(nmap -Pn -p "$PORTS" "$SUBNET" -oG - 2>/dev/null)

        # Parse nmap output
        while IFS= read -r LINE; do
            if [[ $LINE =~ ^Host: ]]; then
                HOST_IP=$(echo "$LINE" | awk '{print $2}')
                PORTS_FIELD=$(echo "$LINE" | sed -n 's/.*Ports: \(.*\)/\1/p')
                [ -z "$PORTS_FIELD" ] && continue
                OPEN_PORTS=$(echo "$PORTS_FIELD" \
                    | grep -oE "[0-9]+/open" \
                    | cut -d'/' -f1 \
                    | paste -sd "," -)
                [ -n "$OPEN_PORTS" ] && OPEN_PORTS_MAP["$HOST_IP"]="$OPEN_PORTS"
            fi
        done <<< "$NMAP_OUTPUT"
    done < "$INPUT_FILE"
    echo "Nmap scan completed."
}

# Function: Perform reverse DNS lookups using dig
run_dig_lookup() {
    echo "Starting DNS lookups..."
    for IP in "${!OPEN_PORTS_MAP[@]}"; do
        echo "Resolving domain for IP: $IP"
        PTR_RECORDS=$(dig -x "$IP" +short | sed 's/\.$//')
        if [ -z "$PTR_RECORDS" ]; then
            DOMAINS_MAP["$IP"]="N/A"
        else
            DOMAINS_MAP["$IP"]=$(echo "$PTR_RECORDS" | paste -sd ";" -)
        fi
    done
    echo "DNS lookups completed."
}

# Function: Run sslyze via Docker and parse output
run_sslyze_scans() {
    echo "Starting SSLyze scans..."
    for IP in "${!OPEN_PORTS_MAP[@]}"; do
        DOMAIN="${DOMAINS_MAP[$IP]}"
        # Determine whether to scan via domain or IP
        if [ "$DOMAIN" == "N/A" ]; then
            # Scan via IP
            echo "No domain found for IP: $IP. Scanning SSL via IP."
            scan_ssl_via_ip "$IP"
        else
            # Scan via each associated domain
            IFS=';' read -ra DOMAIN_ARRAY <<< "$DOMAIN"
            for DOMAIN_ITEM in "${DOMAIN_ARRAY[@]}"; do
                DOMAIN_ITEM=$(echo "$DOMAIN_ITEM" | xargs)
                echo "Scanning SSL for domain: $DOMAIN_ITEM"
                scan_ssl_via_domain "$IP" "$DOMAIN_ITEM"
            done
        fi
    done
    echo "SSLyze scans completed."
}

# Function: Scan SSL via Domain (with SNI)
scan_ssl_via_domain() {
    local IP="$1"
    local DOMAIN="$2"
    local SSLSCAN_OUTPUT
    local COMPLIANCE_STATUS
    local COMPLIANCE_ISSUES=""

    # Run sslyze via Docker with sudo and capture output
    SSLSCAN_OUTPUT=$(sudo docker run --rm nablac0d3/sslyze "$DOMAIN" 2>&1) || SSLSCAN_OUTPUT="Error: sslyze failed."

    # Check if sslyze ran successfully
    if [[ "$SSLSCAN_OUTPUT" == Error:* ]]; then
        COMPLIANCE_STATUS="Error"
        COMPLIANCE_ISSUES="sslyze failed to run."
    else
        # Extract Compliance Status
        COMPLIANCE_STATUS=$(echo "$SSLSCAN_OUTPUT" | grep -E "^$DOMAIN:443: " | awk -F' - ' '{print $2}')
        [ -z "$COMPLIANCE_STATUS" ] && COMPLIANCE_STATUS="Unknown"

        # Extract Compliance Issues
        COMPLIANCE_ISSUES=$(echo "$SSLSCAN_OUTPUT" | awk '/COMPLIANCE AGAINST MOZILLA TLS CONFIGURATION/{flag=1; next} /^$/{flag=0} flag' | sed 's/^[[:space:]]*//')
        if [[ -z "$COMPLIANCE_ISSUES" ]]; then
            COMPLIANCE_ISSUES="None"
        else
            COMPLIANCE_ISSUES=$(echo "$COMPLIANCE_ISSUES" | tr '\n' '; ' | sed 's/[[:space:]]*$//')
        fi
    fi

    # Store results in associative arrays
    if [[ -z "${SSL_COMPLIANCE_MAP[$IP]}" ]]; then
        SSL_COMPLIANCE_MAP["$IP"]="$COMPLIANCE_STATUS"
        SSL_ISSUES_MAP["$IP"]="$COMPLIANCE_ISSUES"
    else
        SSL_COMPLIANCE_MAP["$IP"]+=", $COMPLIANCE_STATUS"
        SSL_ISSUES_MAP["$IP"]+=", $COMPLIANCE_ISSUES"
    fi
}

# Function: Scan SSL via IP (without SNI or with optional SNI)
scan_ssl_via_ip() {
    local IP="$1"
    local SSLSCAN_OUTPUT
    local COMPLIANCE_STATUS
    local COMPLIANCE_ISSUES=""

    if [ "$MANUAL_SNI" == true ] && [ -n "$SNI_DOMAIN" ]; then
        # Run sslyze via Docker with manual SNI
        echo "Running sslyze with manual SNI: $SNI_DOMAIN"
        SSLSCAN_OUTPUT=$(sudo docker run --rm nablac0d3/sslyze \
            --sslyze-options "sni=$SNI_DOMAIN" \
            "$IP" 2>&1) || SSLSCAN_OUTPUT="Error: sslyze failed."
    else
        # Run sslyze via Docker without SNI
        SSLSCAN_OUTPUT=$(sudo docker run --rm nablac0d3/sslyze "$IP" 2>&1) || SSLSCAN_OUTPUT="Error: sslyze failed."
    fi

    # Check if sslyze ran successfully
    if [[ "$SSLSCAN_OUTPUT" == Error:* ]]; then
        COMPLIANCE_STATUS="Error"
        COMPLIANCE_ISSUES="sslyze failed to run."
    else
        # Extract Compliance Status
        # Attempt to extract based on IP:443
        COMPLIANCE_STATUS=$(echo "$SSLSCAN_OUTPUT" | grep -E "^$IP:443: " | awk -F' - ' '{print $2}')
        [ -z "$COMPLIANCE_STATUS" ] && COMPLIANCE_STATUS="Unknown"

        # Extract Compliance Issues
        COMPLIANCE_ISSUES=$(echo "$SSLSCAN_OUTPUT" | awk '/COMPLIANCE AGAINST MOZILLA TLS CONFIGURATION/{flag=1; next} /^$/{flag=0} flag' | sed 's/^[[:space:]]*//')
        if [[ -z "$COMPLIANCE_ISSUES" ]]; then
            COMPLIANCE_ISSUES="None"
        else
            COMPLIANCE_ISSUES=$(echo "$COMPLIANCE_ISSUES" | tr '\n' '; ' | sed 's/[[:space:]]*$//')
        fi
    fi

    # Store results in associative arrays
    if [[ -z "${SSL_COMPLIANCE_MAP[$IP]}" ]]; then
        SSL_COMPLIANCE_MAP["$IP"]="$COMPLIANCE_STATUS"
        SSL_ISSUES_MAP["$IP"]="$COMPLIANCE_ISSUES"
    else
        SSL_COMPLIANCE_MAP["$IP"]+=", $COMPLIANCE_STATUS"
        SSL_ISSUES_MAP["$IP"]+=", $COMPLIANCE_ISSUES"
    fi
}

# Function: Perform Akamai Detection via Traceroute using GNU Parallel
run_akamai_detection() {
    echo "Starting Akamai detection via traceroute..."

    # Check if GNU Parallel is installed
    if ! command -v parallel &> /dev/null; then
        echo "[ERROR] GNU Parallel is not installed. Please install it to perform Akamai detection."
        exit 1
    fi

    # Function to perform traceroute and detect Akamai for a single IP
    traceroute_check() {
        local IP="$1"
        echo "Performing traceroute for IP: $IP"

        # Run traceroute with a timeout to prevent hanging (e.g., 30 seconds)
        TRACEROUTE_OUTPUT=$(timeout 30 traceroute "$IP" 2>/dev/null || echo "Error: traceroute failed.")

        if echo "$TRACEROUTE_OUTPUT" | grep -iq 'akamai'; then
            AKAMAI_MAP["$IP"]="Y"
        else
            AKAMAI_MAP["$IP"]="N"
        fi
    }

    export -f traceroute_check
    export -A AKAMAI_MAP

    # Run traceroute checks in parallel (e.g., 10 jobs at a time)
    parallel -j 10 traceroute_check ::: "${!OPEN_PORTS_MAP[@]}"

    echo "Akamai detection completed."
}

# Function: Populate Output (CSV or Terminal)
populate_output() {
    echo "Populating results..."

    for IP in "${!OPEN_PORTS_MAP[@]}"; do
        DOMAIN="${DOMAINS_MAP[$IP]:-N/A}"
        OPEN_PORTS="${OPEN_PORTS_MAP[$IP]:-N/A}"
        SSL_STATUS="${SSL_COMPLIANCE_MAP[$IP]:-N/A}"
        SSL_ISSUES="${SSL_ISSUES_MAP[$IP]:-N/A}"
        AKAMAI_DETECTED="${AKAMAI_MAP[$IP]:-N/A}"

        if [[ -n "$OUTPUT_CSV" ]]; then
            # Prepare fields for CSV
            DOMAIN_ESCAPED=$(echo "$DOMAIN" | sed 's/"/""/g')
            SSL_ISSUES_ESCAPED=$(echo "$SSL_ISSUES" | sed 's/"/""/g')

            # Enclose fields with potential commas in double quotes
            if [[ "$RUN_DIG" == true || "$RUN_ALL" == true ]]; then
                if [[ "$RUN_SSLYZE" == true || "$RUN_ALL" == true ]]; then
                    if [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]]; then
                        echo "$IP,\"$DOMAIN_ESCAPED\",\"$OPEN_PORTS\",\"$SSL_STATUS\",\"$SSL_ISSUES_ESCAPED\",\"$AKAMAI_DETECTED\"" >> "$OUTPUT_CSV"
                    else
                        echo "$IP,\"$DOMAIN_ESCAPED\",\"$OPEN_PORTS\",\"$SSL_STATUS\",\"$SSL_ISSUES_ESCAPED\"" >> "$OUTPUT_CSV"
                    fi
                else
                    if [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]]; then
                        echo "$IP,\"$DOMAIN_ESCAPED\",\"$OPEN_PORTS\",\"$AKAMAI_DETECTED\"" >> "$OUTPUT_CSV"
                    else
                        echo "$IP,\"$DOMAIN_ESCAPED\",\"$OPEN_PORTS\"" >> "$OUTPUT_CSV"
                    fi
                fi
            else
                if [[ "$RUN_SSLYZE" == true || "$RUN_ALL" == true ]]; then
                    if [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]]; then
                        echo "$IP,\"$OPEN_PORTS\",\"$SSL_STATUS\",\"$SSL_ISSUES_ESCAPED\",\"$AKAMAI_DETECTED\"" >> "$OUTPUT_CSV"
                    else
                        echo "$IP,\"$OPEN_PORTS\",\"$SSL_STATUS\",\"$SSL_ISSUES_ESCAPED\"" >> "$OUTPUT_CSV"
                    fi
                else
                    if [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]]; then
                        echo "$IP,\"$OPEN_PORTS\",\"$AKAMAI_DETECTED\"" >> "$OUTPUT_CSV"
                    else
                        echo "$IP,\"$OPEN_PORTS\"" >> "$OUTPUT_CSV"
                    fi
                fi
            fi
        else
            # Prepare fields for terminal
            printf "%-15s" "$IP"
            if [[ "$RUN_DIG" == true || "$RUN_ALL" == true ]]; then
                printf " | %-30s" "$DOMAIN"
            fi
            if [[ "$RUN_NMAP" == true || "$RUN_ALL" == true ]]; then
                printf " | %-15s" "$OPEN_PORTS"
            fi
            if [[ "$RUN_SSLYZE" == true || "$RUN_ALL" == true ]]; then
                printf " | %-25s | %-100s" "$SSL_STATUS" "$SSL_ISSUES"
            fi
            if [[ "$RUN_AKAMAI" == true || "$RUN_ALL" == true ]]; then
                printf " | %-20s" "$AKAMAI_DETECTED"
            fi
            echo
        fi
    done

    echo "Results population completed."
}

# Function: Parse Command-Line Arguments
parse_arguments() {
    # Use getopt for parsing
    PARSED_OPTIONS=$(getopt -n "$0" -o a,n,d,s,t,i:o:h --long all,nmap,dig,sslyze,akamai,input:,output:,help -- "$@")
    if [ $? -ne 0 ]; then
        show_help
        exit 1
    fi

    eval set -- "$PARSED_OPTIONS"

    while true; do
        case "$1" in
            -a|--all)
                RUN_ALL=true
                RUN_NMAP=true
                RUN_DIG=true
                RUN_SSLYZE=true
                RUN_AKAMAI=true
                shift
                ;;
            -n|--nmap)
                RUN_NMAP=true
                shift
                ;;
            -d|--dig)
                RUN_DIG=true
                shift
                ;;
            -s|--sslyze)
                RUN_SSLYZE=true
                shift
                ;;
            -t|--akamai)
                RUN_AKAMAI=true
                shift
                ;;
            -i|--input)
                INPUT_FILE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_CSV="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Invalid option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Main Execution Flow
main() {
    # Parse command-line arguments
    parse_arguments "$@"

    # Validate required arguments
    if [[ -z "$INPUT_FILE" ]]; then
        echo "Error: Input file is required."
        show_help
        exit 1
    fi

    # Check if input file exists
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: Input file '$INPUT_FILE' does not exist."
        exit 1
    fi

    # Initialize output (CSV or Terminal)
    initialize_output

    # Execute selected functions
    if [[ "$RUN_NMAP" == true ]]; then
        run_nmap
    fi

    if [[ "$RUN_DIG" == true ]]; then
        run_dig_lookup
    fi

    if [[ "$RUN_SSLYZE" == true ]]; then
        run_sslyze_scans
    fi

    if [[ "$RUN_AKAMAI" == true ]]; then
        run_akamai_detection
    fi

    # Populate output (CSV or Terminal)
    populate_output

    echo "All selected operations completed."
    if [[ -n "$OUTPUT_CSV" ]]; then
        echo "Results saved to '$OUTPUT_CSV'."
    fi
}

# Invoke main with all script arguments
main "$@"
