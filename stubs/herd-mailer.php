<?php

/*
 * Plugin Name: Herd Mailer
 * Description: Configure PHPMailer to use Herd for local email testing.
 * Author: Roel Magdaleno
 * Version: 1.0.0
 */

/**
 * Configure PHPMailer to use Herd SMTP settings.
 *
 * The configuration data is based on Herd's default settings:
 * https://herd.laravel.com/docs/macos/guides/wordpress#test-emails
 *
 * Make sure to have Herd running locally to capture the emails.
 *
 * You can change the SMTP settings if you have customized your Herd setup.
 *
 * This plugin must live under the `wp-content/mu-plugins` directory.
 *
 * @since 1.0.0
 */
add_action( 'phpmailer_init', function( $phpmailer ) {
    $phpmailer->isSMTP();
    $phpmailer->Host     = '127.0.0.1';
    $phpmailer->SMTPAuth = true;
    $phpmailer->Port     = 2525;
    $phpmailer->Username = 'WordPress';
    $phpmailer->Password = '';
} );

