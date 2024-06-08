#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display the logo
display_logo() {
    clear
    echo -e "${CYAN}"
    echo "=========================="
    echo "      HighTables"
    echo "=========================="
    echo -e "${NC}"
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    local valid_ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    if [[ $ip =~ $valid_ip_regex ]]; then
        return 0
    else
        echo -e "${RED}Invalid IP address format. Please enter a valid IP address.${NC}"
        return 1
    fi
}

# Function to validate port
validate_port() {
    local port=$1
    if [[ $port -ge 1 && $port -le 65535 ]]; then
        return 0
    else
        echo -e "${RED}Invalid port number. Please enter a port number between 1 and 65535.${NC}"
        return 1
    fi
}

# Function to validate port range
validate_port_range() {
    local range=$1
    local valid_range_regex="^([0-9]{1,5}):([0-9]{1,5})$"
    if [[ $range =~ $valid_range_regex ]]; then
        local start_port=${BASH_REMATCH[1]}
        local end_port=${BASH_REMATCH[2]}
        if [[ $start_port -ge 1 && $start_port -le 65535 && $end_port -ge 1 && $end_port -le 65535 && $start_port -le $end_port ]]; then
            return 0
        else
            echo -e "${RED}Invalid port range. Please enter a valid port range between 1 and 65535.${NC}"
            return 1
        fi
    else
        echo -e "${RED}Invalid port range format. Please enter a port range in the format start:end.${NC}"
        return 1
    fi
}

# Function to validate transport protocol
validate_transport() {
    local transport=$1
    if [[ $transport == "tcp" || $transport == "udp" ]]; then
        return 0
    else
        echo -e "${RED}Invalid transport protocol. Please enter 'tcp' or 'udp'.${NC}"
        return 1
    fi
}

# Function to add a single IP and port rule
add_single_rule() {
    display_logo
    while true; do
        read -p "Enter destination IP: " dest_ip
        validate_ip $dest_ip && break
    done
    while true; do
        read -p "Enter source port: " src_port
        validate_port $src_port && break
    done
    while true; do
        read -p "Enter destination port: " dst_port
        validate_port $dst_port && break
    done
    while true; do
        read -p "Enter transport protocol (tcp/udp): " transport
        validate_transport $transport && break
    done
    sudo iptables -A INPUT -p $transport --sport $src_port --dport $dst_port -d $dest_ip -j ACCEPT
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
    echo -e "${GREEN}Rule added and saved successfully.${NC}"
    read -p "Press Enter to continue..."
}

# Function to add a port range rule
add_range_rule() {
    display_logo
    while true; do
        read -p "Enter destination IP: " dest_ip
        validate_ip $dest_ip && break
    done
    while true; do
        read -p "Enter source port range (format: start:end): " src_port_range
        validate_port_range $src_port_range && break
    done
    while true; do
        read -p "Enter destination port range (format: start:end): " dst_port_range
        validate_port_range $dst_port_range && break
    done
    while true; do
        read -p "Enter transport protocol (tcp/udp): " transport
        validate_transport $transport && break
    done
    sudo iptables -A INPUT -p $transport --sport $src_port_range --dport $dst_port_range -d $dest_ip -j ACCEPT
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
    echo -e "${GREEN}Rule added and saved successfully.${NC}"
    read -p "Press Enter to continue..."
}

# Function to view and remove rules
view_remove_rules() {
    display_logo
    echo -e "${BLUE}Current iptables rules:${NC}"
    sudo iptables -L --line-numbers -n -v
    echo -e "${YELLOW}Enter the chain (INPUT/FORWARD/OUTPUT) and the rule number to delete, separated by space, or press Enter to skip:${NC}"
    read -p "> " chain rule_number
    if [[ ! -z "$chain" && ! -z "$rule_number" ]]; then
        echo -e "${RED}Are you sure you want to delete the rule $rule_number from chain $chain? (y/n)${NC}"
        read -p "> " confirm
        if [[ "$confirm" == "y" ]]; then
            sudo iptables -D $chain $rule_number
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
            echo -e "${GREEN}Rule deleted and saved successfully.${NC}"
        else
            echo -e "${CYAN}No rule deleted.${NC}"
        fi
    else
        echo -e "${CYAN}No rule deleted.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Function to delete all rules
delete_all_rules() {
    display_logo
    echo -e "${RED}Are you sure you want to delete all rules? (y/n)${NC}"
    read -p "> " confirm
    if [[ "$confirm" == "y" ]]; then
        sudo iptables -F
        sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
        echo -e "${RED}All rules deleted and changes saved successfully.${NC}"
    else
        echo -e "${CYAN}No rules deleted.${NC}"
    fi
    read -p "Press Enter to continue..."
}

# Main menu
while true; do
    display_logo
    echo -e "${MAGENTA}"
    echo "1) Add rule for single IP and ports"
    echo "2) Add rule for IP and port ranges"
    echo "3) View and remove rules"
    echo "4) Delete all rules"
    echo "5) Exit"
    echo -e "${NC}"
    read -p "Choose an option: " choice

    case $choice in
        1) add_single_rule ;;
        2) add_range_rule ;;
        3) view_remove_rules ;;
        4) delete_all_rules ;;
        5) exit 0 ;;
        *) echo -e "${RED}Invalid option, please try again.${NC}" ;;
    esac
done
