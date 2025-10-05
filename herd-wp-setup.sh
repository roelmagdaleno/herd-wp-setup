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

# Configuration
# Base path where WordPress sites will be created. The base path must be registered in Herd.
# Change this to your desired base path.
BASE_PATH="/Users/roelmagdaleno/Code/WordPress"

# Database configuration
# Adjust these as necessary. Ensure the MySQL user has permissions to create databases.
# For now, I've created the database instance with DBngin, so all databases will be created under the same user.
DB_USER="root"
DB_PASSWORD=""
DB_HOST="127.0.0.1"
DB_PORT="3307"

# Parse command line arguments
SITE_NAME=""
ADMIN_USER=""
ADMIN_EMAIL=""
ADMIN_PASSWORD=""

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
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--name SITE_NAME] [--username USERNAME] [--email EMAIL] [--password PASSWORD]"
            exit 1
            ;;
    esac
done

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
echo -e "\n${GREEN}[1/6] Creating project folder...${NC}"
if [ -d "$FULL_PATH" ]; then
    echo -e "${RED}Error: Folder already exists: $FULL_PATH${NC}"
    exit 1
fi

mkdir -p "$FULL_PATH"
echo "✓ Folder created"

# Step 2: Download WordPress
echo -e "\n${GREEN}[2/6] Downloading WordPress...${NC}"
cd "$FULL_PATH"
wp core download

# Step 3: Herd secure
echo -e "\n${GREEN}[3/6] Configuring Laravel Herd...${NC}"
herd secure

# Step 4: Create database
echo -e "\n${GREEN}[4/6] Creating database...${NC}"
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
echo "✓ Database '$DB_NAME' created"

# Step 5: Create wp-config.php
echo -e "\n${GREEN}[5/6] Configuring WordPress...${NC}"
wp config create \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="${DB_HOST}:${DB_PORT}" \
    --dbcharset="utf8mb4" \
    --dbcollate="utf8mb4_unicode_ci"
echo "✓ wp-config.php created"

# Step 6: Install WordPress
echo -e "\n${GREEN}[6/6] Installing WordPress...${NC}"

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
