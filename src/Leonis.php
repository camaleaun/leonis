<?php

use Composer\Composer;
use Composer\Config;
use Composer\Config\JsonConfigSource;
use Composer\DependencyResolver\Pool;
use Composer\Factory;
use Composer\IO\NullIO;
use Composer\Json\JsonFile;
use Composer\Package;
use Composer\Package\PackageInterface;
use Composer\Package\Version\VersionSelector;
use Composer\Repository\CompositeRepository;
use Composer\Repository\ComposerRepository;
use WP_CLI\Utils;
use WP_CLI\JsonManipulator;

/**
 * Command WP-CLI to manage environment development.
 *
 * ## EXAMPLES
 *
 *     # Create new project base file structure
 *     $ wp leonis create sample-name
 *     Success: Created project.
 *
 */
class Leonis {

	/**
	 * Create WordPress project file structure.
	 *
	 * ## OPTIONS
	 *
	 * <slug>
	 * : The name of project.
	 *
	 * [<path>]
	 * : The path to project.
	 *
	 * [--title=<title>]
	 * : The title of project.
	 *
	 * [--locale=<locale>]
	 * : Select which language you want to core download.
	 *
	 * [--theme]
	 * : With theme.
	 *
	 * [--plugin]
	 * : With plugin.
	 *
	 * [--both]
	 * : With both.
	 *
	 * [--force]
	 * : Overwrites existing files, if present.
	 *
	 * ## EXAMPLES
	 *
	 *     $ wp leonis create sample-name
	 *     Success: Created project.
	 *
	 * @when before_wp_load
	 * @subcommand
	 */
	public function create( $args, $assoc_args ) {
		$slug = $args[0];
		if ( ! preg_match( '/^[a-z][a-z0-9\-]*$/', $slug ) ) {
			WP_CLI::error( 'Invalid project slug specified. Project slugs can contain only lowercase alphanumeric characters or dashes, and start with a letter.' );
		}

		$path  = isset( $args[1] ) ? $args[1] : $slug;
		$force = Utils\get_flag_value( $assoc_args, 'force' );

		if ( Utils\basename( getcwd() ) === $slug ) {
			$path = '.';
		}

		if ( ! is_dir( $path ) ) {
			if ( ! is_writable( dirname( $path ) ) ) {
				WP_CLI::error( "Insufficient permission to create directory '{$path}'." );
			}

			WP_CLI::debug( "Creating directory '{$path}'." );
			if ( ! @mkdir( $path, 0777, true /*recursive*/ ) ) {
				$error = error_get_last();
				WP_CLI::error( "Failed to create directory '{$path}': {$error['message']}." );
			}
		} else {
			if ( ! is_writable( dirname( $path ) ) ) {
				WP_CLI::error( "Insufficient permission to create directory '{$path}'." );
			}
		}

		$extra_config         = WP_CLI::get_runner()->extra_config;
		$core_download        = isset( $extra_config['core download'] ) ? $extra_config['core download'] : null;
		$core_download_locale = isset( $core_download['locale'] ) ? $core_download['locale'] : null;

		$locale = Utils\get_flag_value( $assoc_args, 'locale', $core_download_locale );

		$defaults = array(
			'title'  => ucwords( str_replace( '-', ' ', $slug ) ),
			'locale' => $locale,
			'theme'  => false,
			'plugin' => false,
			'both'   => false,
		);
		$data     = array_merge(
			array(
				'slug' => $slug,
				'path' => $path,
			),
			$this->extract_args( $assoc_args, $defaults )
		);

		$data['readme_title'] = $data['title'] . "\n" . str_repeat( '=', strlen( $data['title'] ) );
		$data['camel_title']  = preg_replace( '/\s+/', '', $data['title'] );

		if ( ! $data['both'] && $data['theme'] && $data['plugin'] ) {
			$data['both'] = true;
		} elseif ( $data['both'] ) {
			$data['theme']  = true;
			$data['plugin'] = true;
		}

		$directory = ( '.' === $path ) ? '' : "$path/";

		$files_to_create = array(
			"{$directory}wp-cli.yml"      => self::mustache_render( 'wp-cli.mustache', $data ),
			"{$directory}.editorconfig"   => file_get_contents( self::get_template_path( '.editorconfig' ) ),
			"{$directory}.gitignore"      => self::mustache_render( '.gitignore.mustache', $data ),
			"{$directory}README.md"       => self::mustache_render( 'README.md.mustache', $data ),
			"{$directory}composer.json"   => self::composer_contents(),
			"{$directory}.phpcs.xml.dist" => self::mustache_render( '.phpcs.xml.dist.mustache', $data ),
		);

		$directory_bin = "{$directory}bin";

		if ( ! is_dir( $directory_bin ) ) {
			if ( ! is_writable( dirname( $directory_bin ) ) ) {
				WP_CLI::error( "Insufficient permission to create directory '{$directory_bin}'." );
			}

			WP_CLI::debug( "Creating directory '{$directory_bin}'." );
			if ( ! @mkdir( $directory_bin, 0777, true /*recursive*/ ) ) {
				$error = error_get_last();
				WP_CLI::error( "Failed to create directory '{$directory_bin}': {$error['message']}." );
			}
		}

		$files_to_create[ "{$directory_bin}/command.php" ] = self::mustache_render( 'command.php.mustache', $data );

		$files_written = $this->create_files( $files_to_create, $force, true );
		$skip_message  = 'All project files were skipped.';
		$directory     = '' === $directory ? '.' : rtrim( $directory, '/' );
		WP_CLI::success( "Created project files to '{$directory}'." );
	}

	protected function is_dir_empty( $dir ) {
		return is_dir( $dir ) && 2 === count( scandir( $dir ) );
	}

	/**
	 * Localizes the template path.
	 */
	private static function mustache_render( $template, $data = array() ) {
		return Utils\mustache_render( dirname( dirname( __FILE__ ) ) . "/templates/{$template}", $data );
	}

	/**
	 * Gets the template path based on installation type.
	 */
	private static function get_template_path( $template ) {
		$command_root  = Utils\phar_safe_path( dirname( __DIR__ ) );
		$template_path = "{$command_root}/templates/{$template}";

		if ( ! file_exists( $template_path ) ) {
			WP_CLI::error( "Couldn't find {$template}" );
		}

		return $template_path;
	}

	protected function create_files( $files_and_contents, $force ) {
		$wrote_files = array();

		foreach ( $files_and_contents as $filename => $contents ) {
			$should_write_file = $this->prompt_if_files_will_be_overwritten( $filename, $force );
			if ( ! $should_write_file ) {
				continue;
			}

			$bytes_written = file_put_contents( $filename, $contents );
			if ( ! $bytes_written ) {
				WP_CLI::error( "Error creating file: {$filename}" );
			} else {
				$wrote_files[] = $filename;
			}
		}
		return $wrote_files;
	}

	protected function prompt_if_files_will_be_overwritten( $filename, $force ) {
		$should_write_file = true;
		if ( ! file_exists( $filename ) ) {
			return true;
		}

		WP_CLI::warning( 'File already exists.' );
		WP_CLI::log( $filename );
		if ( ! $force ) {
			do {
				$question = 'Skip this file, or replace it with scaffolding?';
				$answer   = cli\prompt( $question, false, '[s/r]: ' );
			} while ( ! in_array( $answer, array( 's', 'r' ), true ) );
			$should_write_file = 'r' === $answer;
		}

		$outcome = $should_write_file ? 'Replacing' : 'Skipping';
		WP_CLI::log( $outcome . PHP_EOL );

		return $should_write_file;
	}

	protected function extract_args( $assoc_args, $defaults ) {
		$out = array();

		foreach ( $defaults as $key => $value ) {
			$out[ $key ] = Utils\get_flag_value( $assoc_args, $key, $value );
		}

		return $out;
	}

	protected static function composer_contents() {
		$requirements = array(
			'wp-cli/wp-cli-tests":^2.1',
		);

		$json_manipulator = new JsonManipulator( '{}' );
		foreach ( $requirements as $requirement ) {
			list( $name, $version ) = explode( ':', $requirement );
			$json_manipulator->addLink( 'require', $name, $version, false /*sortPackages*/, true /*caseInsensitive*/ );
		}
		$json_manipulator->addSubNode( 'scripts', 'phpcs', 'run-phpcs-tests' );

		return $json_manipulator->getContents();
	}
}
