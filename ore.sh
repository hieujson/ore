#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root privileges."
    echo "Please try 'sudo -i' command to switch to root user and then run this script again."
    exit 1
fi

function install_node() {

# Update the system and install necessary packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
echo "Installing necessary tools and dependencies..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

# Install Rust and Cargo
echo "Installing Rust and Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# Install Solana CLI
echo "Installing Solana CLI..."
sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"

# Check if solana-keygen is in the PATH
if ! command -v solana-keygen &> /dev/null; then
    echo "Adding Solana CLI to PATH"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Create Solana keypair
echo "Creating Solana keypair..."
solana-keygen new --derivation-path m/44'/501'/0'/0' --force | tee solana-keygen-output.txt

# Display prompt to confirm backup
echo "Please make sure you have backed up the mnemonic and private key shown above."
echo "Deposit SOL to pubkey for mining gas fees."

echo "After backup, please enter 'yes' to continue:"

read -p "" user_confirmation

if [[ "$user_confirmation" == "yes" ]]; then
    echo "Backup confirmed. Proceeding with the script..."
else
    echo "Script terminated. Please ensure you have backed up your information before running the script again."
    exit 1
fi

# Install Ore CLI
echo "Installing Ore CLI..."
cargo install ore-cli

# Check and add Solana path to .bashrc if not already added
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# Check and add Cargo path to .bashrc if not already added
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# Apply changes
source ~/.bashrc

# Get user input for RPC URL or use default
read -p "Enter custom RPC URL, recommend using a free Quicknode or alchemy SOL rpc(default is https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# Get user input for threads or use default
read -p "Enter the number of threads to use for mining (default is 4): " custom_threads
THREADS=${custom_threads:-4}

# Get user input for priority fee or use default
read -p "Enter the priority fee for transactions (default is 1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# Start mining using screen and Ore CLI
session_name="ore"
echo "Starting mining, session name is $session_name ..."

start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Process exited abnormally, waiting for restart' >&2; sleep 1; done"
screen -dmS "$session_name" bash -c "$start"

echo "Mining process has been started in a screen session named $session_name in the background."
echo "Use 'screen -r $session_name' command to reconnect to this session."

}

# View node synchronization status
# Restore Solana wallet and start mining
function export_wallet() {
    # Update system and install necessary packages
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo "Installing necessary tools and dependencies..."
    sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
    check_and_install_dependencies
    
    echo "Restoring Solana wallet..."
    # Prompt user for mnemonic input
    echo "Paste/enter your mnemonic below, separated by spaces, will not display the braille"

    # Restore wallet using mnemonic
    solana-keygen recover 'prompt:?key=0/0' --force

    echo "Wallet has been restored."
    echo "Please ensure your wallet address has sufficient SOL for transaction fees."

# Check and add Solana path to .bashrc if not already added
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# Check and add Cargo path to .bashrc if not already added
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# Apply changes
source ~/.bashrc


    # Get user input for RPC URL or use default
    read -p "Enter custom RPC URL, recommend using a free Quicknode or alchemy SOL rpc(default is https://api.mainnet-beta.solana.com): " custom_rpc
    RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

    # Get user input for threads or use default
    read -p "Enter the number of threads to use for mining (default is 4): " custom_threads
    THREADS=${custom_threads:-4}

    # Get user input for priority fee or use default
    read -p "Enter the priority fee for transactions (default is 1): " custom_priority_fee
    PRIORITY_FEE=${custom_priority_fee:-1}

    # Start mining using screen and Ore CLI
    session_name="ore"
    echo "Starting mining, session name is $session_name ..."

    start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Process exited abnormally, waiting for restart' >&2; sleep 1; done"
    screen -dmS "$session_name" bash -c "$start"

    echo "Mining process has been started in a screen session named $session_name in the background."
    echo "Use 'screen -r $session_name' command to reconnect to this session."
}

function check_and_install_dependencies() {
    # Check if Rust and Cargo are installed
    if ! command -v cargo &> /dev/null; then
        echo "Rust and Cargo are not installed, installing..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        source $HOME/.cargo/env
    else
        echo "Rust and Cargo are installed."
    fi

    # Check if Solana CLI is installed
    if ! command -v solana-keygen &> /dev/null; then
        echo "Solana CLI is not installed, installing..."
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.4/install)"
    else
        echo "Solana CLI is installed."
    fi

    # Check if Ore CLI is installed
    if ! cargo install ore-cli --version | grep ore-cli &> /dev/null; then
        echo "Ore CLI is not installed, installing..."
        cargo install ore-cli
    else
        echo "Ore CLI is installed."
    fi

        export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        export PATH="$HOME/.cargo/bin:$PATH"
}

function start() {
# Get user input for RPC URL or use default
read -p "Enter custom RPC URL, recommend using a free Quicknode or alchemy SOL rpc(default is https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# Get user input for threads or use default
read -p "Enter the number of threads to use for mining (default is 4): " custom_threads
THREADS=${custom_threads:-4}

# Get user input for priority fee or use default
read -p "Enter the priority fee for transactions (default is 1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# Start mining using screen and Ore CLI
session_name="ore"
echo "Starting mining, session name is $session_name ..."

start="while true; do ore --rpc $RPC_URL --keypair ~/.config/solana/id.json --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo 'Process exited abnormally, waiting for restart' >&2; sleep 1; done"
screen -dmS "$session_name" bash -c "$start"

echo "Mining process has been started in a screen session named $session_name in the background."
echo "Use 'screen -r $session_name' command to reconnect to this session."

}

# Query rewards
function view_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json rewards
}

# Claim rewards
function claim_rewards() {
    ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id.json claim
}


function check_logs() {
    screen -r ore
}


function multiple() {
#!/bin/bash

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
echo "Installing necessary tools and dependencies..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen
check_and_install_dependencies
    

# Check and add Solana path to .bashrc if not already added
grep -qxF 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc

# Check and add Cargo path to .bashrc if not already added
grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

# Apply changes
source ~/.bashrc

# Prompt user to input RPC configuration address
read -p "Enter RPC configuration address: " rpc_address

# Prompt user to input number of wallet configuration files to generate
read -p "Enter the number of wallets you want to run: " count

# Base session name
session_base_name="ore"

# Start command template, use variables to substitute rpc address
start_command_template="while true; do ore --rpc $rpc_address --keypair ~/.config/solana/idX.json --priority-fee 1 mine --threads 4; echo 'Process exited abnormally, waiting for restart' >&2; sleep 1; done"

# Ensure .solana directory exists
mkdir -p ~/.config/solana

# Loop to create configuration files and start mining processes
for (( i=1; i<=count; i++ ))
do
    # Prompt user to input private key
    echo "Enter private key for id${i}.json (format is a JSON array containing 64 digits):"
    read -p "Private Key: " private_key

    # Generate configuration file path
    config_file=~/.config/solana/id${i}.json

    # Write private key directly to configuration file
    echo $private_key > $config_file

    # Check if configuration file is successfully created
    if [ ! -f $config_file ]; then
        echo "Failed to create id${i}.json, please check if the private key is correct and try again."
        exit 1
    fi

    # Generate session name
    session_name="${session_base_name}_${i}"

    # Replace configuration file name and RPC address in start command
    start_command=${start_command_template//idX/id${i}}

    # Print start message
    echo "Starting mining, session name is $session_name ..."

    # Start mining process in the background using screen
    screen -dmS "$session_name" bash -c "$start_command"

    # Print mining process start message
    echo "Mining process has been started in a screen session named $session_name in the background."
    echo "Use 'screen -r $session_name' command to reconnect to this session."
done

}

function check_multiple() {
# Prompt user to enter start and end numbers, separated by space
echo -n "Enter start and end numbers, separated by space. For example, if you've run 10 wallet addresses, enter 1 10: "
read -a range

# Get start and end numbers
start=${range[0]}
end=${range[1]}

# Execute loop
for i in $(seq $start $end); do
  ore --rpc https://api.mainnet-beta.solana.com --keypair ~/.config/solana/id$i.json --priority-fee 1 rewards
done

}

# Main menu
function main_menu() {
    while true; do
        clear
        echo "Script and tutorial are written by Twitter user @y95277777, free and open source, do not trust charging"
        echo "================================================================"
        echo "Node Community Telegram Group: https://t.me/niuwuriji"
        echo "Node Community Telegram Channel: https://t.me/niuwuriji"
        echo "To exit the script, press ctrl c on your keyboard to exit"
        echo "Please select an action:"
        echo "1. Install a new node"
        echo "2. Import wallet and run"
        echo "3. Start running individually"
        echo "4. View mining earnings"
        echo "5. Claim mining earnings"
        echo "6. Check node running status"
        echo "7. Run multiple wallets on a single machine, need to prepare json private key by yourself"
        echo "8. Run multiple wallets on a single machine, check rewards"
        read -p "Enter option (1-7): " OPTION

        case $OPTION in
        1) install_node ;;
        2) export_wallet ;;
        3) start ;;
        4) view_rewards ;;
        5) claim_rewards ;;
        6) check_logs ;;
        7) multiple ;; 
        8) check_multiple ;; 
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display main menu
main_menu
