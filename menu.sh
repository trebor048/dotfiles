#!/usr/bin/env bash
set -euo pipefail

# =============================
# XMRig Menu (Multi-Coin) — English
# Repo: trebor048/dotfiles
# =============================

# Color text
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'


# File config
WALLET_FILE="$HOME/.xmrig_wallet"
POOL_FILE="$HOME/.xmrig_pool"
THREAD_FILE="$HOME/.xmrig_threads"
WORKER_FILE="$HOME/.xmrig_worker"
COIN_FILE="$HOME/.xmrig_coin"
ALGO_FILE="$HOME/.xmrig_algo"
TLS_FILE="$HOME/.xmrig_tls"

# Path to your built XMRig binary (adjust if different)
XMRIG_DIR="$HOME/xmrig/build"

# Default pool
DEFAULT_POOL="pool.hashvault.pro:80"

# Getter functions
get_wallet() { cat "$WALLET_FILE" 2>/dev/null || echo "Not set"; }
get_pool()   { cat "$POOL_FILE" 2>/dev/null   || echo "$DEFAULT_POOL"; }
get_threads(){ cat "$THREAD_FILE" 2>/dev/null || echo "Auto (default)"; }
get_worker() { cat "$WORKER_FILE" 2>/dev/null || echo "None (default)"; }
get_coin()   { cat "$COIN_FILE" 2>/dev/null   || echo "XMR"; }
get_algo()   { cat "$ALGO_FILE" 2>/dev/null   || echo "rx/0"; }
get_tls()    { cat "$TLS_FILE" 2>/dev/null    || echo "no"; }

while true; do
    clear
    echo -e "${CYAN}========== XMRig Menu (Multi-Coin) ==========${NC}"
    printf "${YELLOW}%-8s${NC}: %s\n" "Wallet"  "$(get_wallet)"
    printf "${YELLOW}%-8s${NC}: %s\n" "Pool"    "$(get_pool)"
    printf "${YELLOW}%-8s${NC}: %s\n" "Threads" "$(get_threads)"
    printf "${YELLOW}%-8s${NC}: %s\n" "Worker"  "$(get_worker)"
    printf "${YELLOW}%-8s${NC}: %s\n" "Coin"    "$(get_coin)"
    printf "${YELLOW}%-8s${NC}: %s\n" "Algo"    "$(get_algo)"
    printf "${YELLOW}%-8s${NC}: %s\n" "TLS"     "$(get_tls)"
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${GREEN}1.${NC} Change wallet address"
    echo -e "${GREEN}2.${NC} Change pool domain and port"
    echo -e "${GREEN}3.${NC} Set number of CPU threads"
    echo -e "${GREEN}4.${NC} Change worker name"
    echo -e "${GREEN}5.${NC} Change coin"
    echo -e "${GREEN}6.${NC} Change algorithm"
    echo -e "${GREEN}7.${NC} Use TLS (yes/no)"
    echo -e "${GREEN}8.${NC} Start mining"
    echo -e "${GREEN}9.${NC} Exit"
    echo -e "${CYAN}=============================================${NC}"
    read -p "Select an option [1-9]: " choice

    case $choice in
        1)
            read -p "Enter wallet address: " wallet
            echo -n "$wallet" > "$WALLET_FILE"
            ;;
        2)
            read -p "Enter pool domain and port (e.g., pool.hashvault.pro:80): " pool
            echo -n "$pool" > "$POOL_FILE"
            ;;
        3)
            max_threads=$(nproc)
            read -p "Enter number of threads (1-$max_threads), or press Enter for auto: " threads
            if [[ -z "${threads:-}" ]]; then
                rm -f "$THREAD_FILE"
                echo "Threads set to auto mode."
            elif [[ "$threads" =~ ^[0-9]+$ ]]; then
                (( threads > max_threads )) && threads=$max_threads
                echo -n "$threads" > "$THREAD_FILE"
            else
                echo "Invalid input."
            fi
            ;;
        4)
            read -p "Enter worker name (leave empty for default): " worker
            echo -n "$worker" > "$WORKER_FILE"
            ;;
        5)
            read -p "Enter coin symbol (e.g., XMR, DOGE, SHIB): " coin
            echo -n "$coin" > "$COIN_FILE"
            ;;
        6)
            read -p "Enter algorithm name (e.g., rx/0, ghostrider): " algo
            echo -n "$algo" > "$ALGO_FILE"
            ;;
        7)
            while true; do
                read -p "Use TLS? (yes/no): " tls
                if [[ "$tls" =~ ^(yes|no)$ ]]; then
                    echo -n "$tls" > "$TLS_FILE"
                    break
                else
                    echo "Please type exactly 'yes' or 'no'."
                fi
            done
            ;;
        8)
            wallet=$(get_wallet)
            pool=$(get_pool)
            threads=$(get_threads)
            worker=$(get_worker)
            coin=$(get_coin)
            algo=$(get_algo)
            tls=$(get_tls)

            if [[ "$wallet" == "Not set" || -z "$wallet" ]]; then
                echo "Wallet is not set. Please select option 1 first."
                read -n 1 -s -r -p "Press any key to continue..."
                continue
            fi

            echo ""
            echo "================================"
            echo " Starting XMRig Mining"
            echo "================================"
            echo " Repo   : trebor048/dotfiles"
            echo " Coin   : $coin"
            echo " Algo   : $algo"
            echo " Wallet : $wallet"
            echo " Pool   : $pool"
            echo " TLS    : $tls"
            echo " Worker : $worker"
            echo " Threads: $threads"
            echo "================================"
            sleep 1

            if [[ ! -x "$XMRIG_DIR/xmrig" ]]; then
                echo "XMRig binary not found at: $XMRIG_DIR/xmrig"
                echo "Build or adjust XMRIG_DIR, then try again."
                read -n 1 -s -r -p "Press any key to continue..."
                continue
            fi

            cd "$XMRIG_DIR"

            # Build the wallet field depending on pool style
            # For pools like unMineable, prepend coin and optionally add worker as wallet.Coin.Worker
            if [[ "$pool" == *"unmineable"* ]]; then
                if [[ -n "$worker" && "$worker" != "None (default)" ]]; then
                    wallet_full="${coin}:${wallet}.${worker}"
                else
                    wallet_full="${coin}:${wallet}"
                fi
            else
                if [[ -n "$worker" && "$worker" != "None (default)" ]]; then
                    wallet_full="${wallet}.${worker}"
                else
                    wallet_full="$wallet"
                fi
            fi

            [[ "$tls" == "yes" ]] && tls_flag="--tls" || tls_flag=""

            if [[ "$threads" == "Auto (default)" ]]; then
                ./xmrig -a "$algo" -o "$pool" -u "$wallet_full" -p x $tls_flag
            else
                ./xmrig -a "$algo" -o "$pool" -u "$wallet_full" -p x -t "$threads" $tls_flag
            fi

            read -n 1 -s -r -p "Press any key to return to menu..."
            ;;
        9)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1-9."
            read -n 1 -s -r -p "Press any key to continue..."
            ;;
    esac
done
