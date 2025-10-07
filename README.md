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

### Laravel Herd

[Install and configure Laravel Herd](https://herd.laravel.com/docs/macos/getting-started/installation) on your machine. Ensure your base WordPress projects directory is added to Herd.

### WP-CLI

Install [WP-CLI](https://wp-cli.org/) and ensure it's available in your terminal's PATH.

### MySQL

Ensure you have a local MySQL server running and accessible. The script uses the `mysql` client to create databases.

You can use databases created via [Herd Pro Services](https://herd.laravel.com/docs/macos/herd-pro-services/services), DBngin, Homebrew MySQL, or another local server.  

The default connection in the script points to:

- `DB_USER` = `root`
- `DB_PASSWORD` = (empty)
- `DB_HOST` = `127.0.0.1`
- `DB_PORT` = `3307`

### Other Dependencies

- OpenSSL (for generating an admin password when not provided)

## Configuration

This script uses simple variables at the top of `herd-wp-setup.sh`. Edit these to suit your environment before running.

### Path

This is the base folder where new WordPress sites will be created. It must be registered in Herd.

Default is `/Users/roelmagdaleno/Code/WordPress`, but change it to your own path.

### Database

Configure your local MySQL connection details:

- `DB_USER` (default: `root`)
- `DB_PASSWORD` (default: empty)
- `DB_HOST` (default: `127.0.0.1`)
- `DB_PORT` (default: `3307`)

## Mail

The script includes the `stubs/herd-mailer.php` must-use plugin that connects to Herd's Pro SMTP server for local email logging.

After running the script, the PHP file will be copied to the next path `wp-content/mu-plugins/herd-mailer.php` of the new WordPress site.

[Mail](https://herd.laravel.com/docs/macos/herd-pro-services/mail#wordpress) is part of Herd Pro Services.

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

```bash
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
- Move the `herd-mailer` plugin to the `mu-plugins` folder for local email logging
