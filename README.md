# herd-wp-setup

A tiny Bash utility to automate the local setup of a new WordPress site using WP-CLI and Laravel Herd.

## Features

- Creates a project folder under a configured base path
- Downloads WordPress via WP-CLI
- Secures the local site with `herd secure`
- Creates a MySQL database
- Generates `wp-config.php`
- Runs the WordPress installer with your chosen admin credentials

## Requirements
- Laravel Herd installed and configured
  - Install: https://herd.laravel.com/docs/macos/getting-started/installation
  - Ensure your base projects directory is added to Herd
- WP-CLI installed and available in your PATH
  - Install: https://wp-cli.org/
- MySQL server running and accessible
  - The script uses the `mysql` client. You can use DBngin, Homebrew MySQL, or another local server
  - Default connection in the script points to `127.0.0.1:3307` with user `root` and empty password (adjust as needed)
- OpenSSL (for generating an admin password when not provided)

## Configuration
This script uses simple variables at the top of `herd-wp-setup.sh`. Edit these to suit your environment before running, or pass CLI flags where supported.

- `BASE_PATH`: Base folder where sites are created (must be registered in Herd)
  - Default: `/Users/roelmagdaleno/Code/WordPress`
- Database:
  - `DB_USER` (default: `root`)
  - `DB_PASSWORD` (default: empty)
  - `DB_HOST` (default: `127.0.0.1`)
  - `DB_PORT` (default: `3307`)

## Usage

Make the script executable (first time only):

```
chmod +x herd-wp-setup.sh
```

Run the script. You can provide CLI arguments or follow the interactive prompts.

Supported options:
- `--name`       Site name (e.g., "WPB Plugins"). Used to derive domain, folder, and DB name
- `--username`   WordPress admin username (default prompted; falls back to `admin`)
- `--email`      WordPress admin email (default prompted; falls back to `admin@<domain>.test`)
- `--password`   WordPress admin password (if omitted, you’ll be prompted and can auto-generate)

Examples:
```
# Fully interactive
./herd-wp-setup.sh

# Provide only the site name (other values prompted)
./herd-wp-setup.sh --name "My WP Site"

# Non-interactive install with explicit admin credentials
./herd-wp-setup.sh \
  --name "Acme Blog" \
  --username acme_admin \
  --email admin@acme.test \
  --password "S3cureP@ss!"
```

What the script will do:
- Convert the site name to a domain (lowercase, spaces → dashes). Example: "Acme Blog" → `acme-blog.test`
- Create a folder at `${BASE_PATH}/acme-blog`
- `wp core download`
- `herd secure` to ensure a local TLS cert
- Create a MySQL database named `acme_blog`
- `wp config create` with the DB connection
- `wp core install` with the provided or prompted admin credentials

## Troubleshooting
- WP-CLI not found: Ensure `wp` is installed and in your PATH
- Herd not found: Install Laravel Herd and confirm `herd` is in your PATH
- MySQL connection issues:
  - Verify host and port match your server (defaults to 127.0.0.1:3307)
  - Confirm user/password permissions to create databases
- Folder already exists: The script aborts if the target directory exists
- Certificate issues: Run `herd secure` manually in the site directory if needed
