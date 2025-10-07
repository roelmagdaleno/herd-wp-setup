#!/bin/bash

# A script to automate the setup of a local WordPress site using WP-CLI and Laravel Herd.
# It creates a project folder, downloads WordPress, sets up the database, configures wp-config.php,
# and installs WordPress with specified admin credentials.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory for accessing stubs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STUBS_DIR="${SCRIPT_DIR}/stubs"

# Configuration
# Base path where WordPress sites will be created. The base path must be registered in Herd.
# Change this to your desired base path.
# Can be overridden via environment variable `HERD_WP_BASE_PATH`.
BASE_PATH=""

# Database configuration
# Adjust these as necessary. Ensure the MySQL user has permissions to create databases.
# Can be overridden via environment variables.
DB_USER="root"
DB_PASSWORD=""
DB_HOST="127.0.0.1"
DB_PORT="3307"

# Parse command line arguments
SITE_NAME=""
ADMIN_USER=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""
ENV_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            SITE_NAME="$2"
            shift 2
            ;;
        --username)
            ADMIN_USER="$2"
            shift 2
            ;;
        --email)
            ADMIN_EMAIL="$2"
            shift 2
            ;;
        --password)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--name SITE_NAME] [--username USERNAME] [--email EMAIL] [--password PASSWORD] [--env-file PATH]"
            exit 1
            ;;
    esac
done

# Load environment variables from file
# Priority: 1. Specified --env-file, 2. ~/.herd-wp-setup.env, 3. Default values
if [ -n "$ENV_FILE" ]; then
    # Use specified env file
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    else
        echo -e "${RED}Error: Specified env file not found: $ENV_FILE${NC}"
        exit 1
    fi
elif [ -f "$HOME/.herd-wp-setup.env" ]; then
    # Use default env file in home directory
    source "$HOME/.herd-wp-setup.env"
fi

# Apply environment variables (only if not already set by CLI args or defaults)
BASE_PATH="${HERD_WP_BASE_PATH:-$BASE_PATH}"
DB_USER="${HERD_WP_DB_USER:-$DB_USER}"
DB_PASSWORD="${HERD_WP_DB_PASSWORD:-$DB_PASSWORD}"
DB_HOST="${HERD_WP_DB_HOST:-$DB_HOST}"
DB_PORT="${HERD_WP_DB_PORT:-$DB_PORT}"

# Set default admin values from env if not provided via CLI
ADMIN_USER="${ADMIN_USER:-$HERD_WP_DEFAULT_ADMIN_USER}"
ADMIN_EMAIL="${ADMIN_EMAIL:-$HERD_WP_DEFAULT_ADMIN_EMAIL}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-$HERD_WP_DEFAULT_ADMIN_PASSWORD}"

echo -e "${GREEN}=== WordPress Site Setup ===${NC}\n"

# Check if WP-CLI is installed
if ! command -v wp &> /dev/null; then
    echo -e "${RED}Error: WP-CLI is not installed.${NC}"
    echo "Install it from: https://wp-cli.org/"
    exit 1
fi

# Check if mysql client is installed
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}Error: MySQL client is not installed.${NC}"
    exit 1
fi

# Check if herd is installed
if ! command -v herd &> /dev/null; then
    echo -e "${RED}Error: Laravel Herd is not installed.${NC}"
    echo "Install it from: https://herd.laravel.com/docs/macos/getting-started/installation"
    exit 1
fi

# Check if herd-mailer.php stub exists
if [ ! -f "${STUBS_DIR}/herd-mailer.php" ]; then
    echo -e "${YELLOW}Warning: herd-mailer.php not found in stubs directory.${NC}"
    echo "Expected location: ${STUBS_DIR}/herd-mailer.php"
fi

# Prompt for site name
if [ -z "$SITE_NAME" ]; then
    read -p "Enter site name (e.g., WPB Plugins): " SITE_NAME
fi

if [ -z "$SITE_NAME" ]; then
    echo -e "${RED}Error: Site name cannot be empty.${NC}"
    exit 1
fi

# Convert site name to domain format (lowercase, replace spaces with hyphens)
DOMAIN=$(echo "$SITE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
DB_NAME=$(echo "$DOMAIN" | sed 's/-/_/g')
FOLDER_NAME="$DOMAIN"
SITE_URL="https://${DOMAIN}.test"
FULL_PATH="${BASE_PATH}/${FOLDER_NAME}"

echo -e "\n${YELLOW}Configuration:${NC}"
echo "  Site Name: $SITE_NAME"
echo "  Domain: ${DOMAIN}.test"
echo "  Database: $DB_NAME"
echo "  Folder: $FOLDER_NAME"
echo "  Path: $FULL_PATH"
echo ""

read -p "Continue? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Aborted."
    exit 0
fi

# Step 1: Create folder
echo -e "\n${GREEN}[1/7] Creating project folder...${NC}"
if [ -d "$FULL_PATH" ]; then
    echo -e "${RED}Error: Folder already exists: $FULL_PATH${NC}"
    exit 1
fi

mkdir -p "$FULL_PATH"
echo "✓ Folder created"

# Step 2: Download WordPress
echo -e "\n${GREEN}[2/7] Downloading WordPress...${NC}"
cd "$FULL_PATH"
wp core download
echo "✓ WordPress downloaded"

# Step 3: Herd secure
echo -e "\n${GREEN}[3/7] Configuring Laravel Herd...${NC}"
herd secure
echo "✓ Herd configured"

# Step 4: Create database
echo -e "\n${GREEN}[4/7] Creating database...${NC}"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
echo "✓ Database '$DB_NAME' created"

# Step 5: Create wp-config.php
echo -e "\n${GREEN}[5/7] Configuring WordPress...${NC}"
wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="${DB_HOST}:${DB_PORT}" \
    --dbcharset="utf8mb4" \
    --dbcollate="utf8mb4_unicode_ci"
echo "✓ wp-config.php created"

# Step 6: Install WordPress
echo -e "\n${GREEN}[6/7] Installing WordPress...${NC}"

# Prompt for installation details if not provided
if [ -z "$ADMIN_USER" ]; then
    read -p "Admin username [admin]: " ADMIN_USER
fi
ADMIN_USER=${ADMIN_USER:-admin}

if [ -z "$ADMIN_EMAIL" ]; then
    read -p "Admin email [admin@${DOMAIN}.test]: " ADMIN_EMAIL
fi
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@${DOMAIN}.test}

# Prompt for password or generate random one
if [ -z "$ADMIN_PASSWORD" ]; then
    read -s -p "Admin password (leave empty for auto-generated): " ADMIN_PASSWORD_INPUT
    echo ""

    if [ -z "$ADMIN_PASSWORD_INPUT" ]; then
        ADMIN_PASSWORD=$(openssl rand -base64 12)
        PASSWORD_AUTO_GENERATED=true
    else
        ADMIN_PASSWORD="$ADMIN_PASSWORD_INPUT"
        PASSWORD_AUTO_GENERATED=false
    fi
else
    PASSWORD_AUTO_GENERATED=false
fi

wp core install \
    --url="$SITE_URL" \
    --title="$SITE_NAME" \
    --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASSWORD" \
    --admin_email="$ADMIN_EMAIL" \
    --skip-email

echo "✓ WordPress installed"

# Step 7: Install Herd Mailer mu-plugin
echo -e "\n${GREEN}[7/7] Installing Herd Mailer mu-plugin...${NC}"
MU_PLUGINS_DIR="${FULL_PATH}/wp-content/mu-plugins"

if [ -f "${STUBS_DIR}/herd-mailer.php" ]; then
    # Create mu-plugins directory if it doesn't exist
    if [ ! -d "$MU_PLUGINS_DIR" ]; then
        mkdir -p "$MU_PLUGINS_DIR"
        echo "✓ Created mu-plugins directory"
    fi

    # Copy herd-mailer.php to mu-plugins
    cp "${STUBS_DIR}/herd-mailer.php" "$MU_PLUGINS_DIR/"
    echo "✓ Herd Mailer installed"
else
    echo -e "${YELLOW}⚠ Skipped: herd-mailer.php not found${NC}"
fi

# Summary
echo -e "\n${GREEN}=== Installation Complete ===${NC}"
echo -e "${YELLOW}Site Details:${NC}"
echo "  URL: $SITE_URL"
echo "  Admin User: $ADMIN_USER"
echo "  Admin Password: $ADMIN_PASSWORD"
echo "  Admin Email: $ADMIN_EMAIL"
echo ""
echo -e "${YELLOW}Database:${NC}"
echo "  Name: $DB_NAME"
echo "  Host: ${DB_HOST}:${DB_PORT}"
echo ""

if [ "$PASSWORD_AUTO_GENERATED" = true ]; then
    echo -e "${RED}⚠️  Save the admin password somewhere safe!${NC}"
fi
