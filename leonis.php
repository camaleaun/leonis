<?php

if ( ! class_exists( 'WP_CLI' ) ) {
	return;
}

$fervidum_leonis_autoloader = dirname( __FILE__ ) . '/vendor/autoload.php';
if ( file_exists( $fervidum_leonis_autoloader ) ) {
	require_once $fervidum_leonis_autoloader;
}

WP_CLI::add_command( 'leonis', 'Leonis' );
WP_CLI::add_command( 'scaffolf project', array( 'Leonis', 'create' ) );
