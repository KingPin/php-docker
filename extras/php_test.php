<?php
/**
 * PHP Environment Test Script
 *
 * This single file script is designed to run in various PHP environments
 * (CLI, Apache, FPM) across different Docker containers (Alpine, Debian)
 * to provide a quick "health check" and environment overview.
 *
 * It automatically detects the SAPI (Server API) and formats the
 * output as plain text for CLI or simple HTML for web requests.
 *
 * Usage:
 * 1. CLI:
 * docker exec <container_name> php /path/to/php_test.php
 *
 * 2. Web (Apache/FPM):
 * - Copy this file to the web root (e.g., /var/www/html)
 * - Access it via your browser: http://localhost/php_test.php
 *
 * 3. CI/CD:
 * You can `curl` the web URL or use `docker exec` and `grep` the
 * output to assert that specific extensions are loaded or that
 * the PHP version is correct.
 *
 * Usage Examples (using ghcr.io/kingpin/php-docker images):
 *
 * 1. CLI (Alpine):
 * docker run --rm -v "$(pwd)/php_test.php:/app/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-cli-alpine php /app/php_test.php
 *
 * 2. CLI (v1 - Debian Bookworm):
 * docker run --rm -v "$(pwd)/php_test.php:/app/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-cli-bookworm php /app/php_test.php
 *
 * 3. CLI (v2 - Debian Trixie with s6-overlay):
 * docker run --rm -v "$(pwd)/php_test.php:/app/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-cli-trixie-v2 php /app/php_test.php
 * # Note: :bookworm-v2 also works (points to same Trixie-built image)
 *
 * 4. Web (Apache v1):
 * docker run --rm -d -p 8080:80 -v "$(pwd)/php_test.php:/var/www/html/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-apache-bookworm
 * # Then access: http://localhost:8080/php_test.php
 *
 * 5. Web (FPM v2 - via CLI to check environment):
 * # Note: Testing FPM properly requires a web server (like Nginx) configured to talk to it.
 * # This example just runs the CLI binary *inside* the FPM container to check extensions.
 * docker run --rm -v "$(pwd)/php_test.php:/app/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-fpm-trixie-v2 php /app/php_test.php
 *
 * 6. CI/CD (Example assertion - v1):
 * docker run --rm -v "$(pwd)/php_test.php:/app/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-cli-bookworm php /app/php_test.php | grep "SAPI: cli"
 *
 * 7. CI/CD (Example assertion - v2 with s6 check):
 * docker run --rm -v "$(pwd)/php_test.php:/app/php_test.php:ro" ghcr.io/kingpin/php-docker:8.3-cli-trixie-v2 php /app/php_test.php | grep "s6-overlay.*Detected"
 *
 * # Example with an existing container
 * docker exec <container_name> php /path/to/php_test.php
 *
 */

// --- Configuration ---
// Add any specific INI settings you want to check
$ini_settings_to_check = [
    'memory_limit',
    'max_execution_time',
    'upload_max_filesize',
    'post_max_size',
    'error_reporting',
    'display_errors',
    'date.timezone',
];
// --- End Configuration ---


// Determine SAPI and set content type for web
$sapi = php_sapi_name();
$is_cli = ($sapi === 'cli');

if (!$is_cli) {
    // Send HTML header for web environments
    header('Content-Type: text/html; charset=UTF-8');
    echo "<!DOCTYPE html>\n<html>\n<head><title>PHP Environment Test</title>";
    echo "<style>body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol'; background-color: #f4f4f4; color: #333; margin: 0; padding: 20px; } pre { background-color: #fff; border: 1px solid #ccc; border-radius: 8px; padding: 15px; overflow-x: auto; } h1 { color: #4a4a4a; border-bottom: 2px solid #eee; padding-bottom: 10px; } .section { margin-top: 20px; } .key { font-weight: bold; color: #005a9c; } .pass { color: green; } .fail { color: red; } </style>";
    echo "</head>\n<body>\n<h1>PHP Environment Test</h1>";
    // <pre> tag makes text output clean and readable in a browser
    echo "<pre>";
}

// Helper function for consistent output
function print_line($key, $value) {
    global $is_cli;
    $key_padded = str_pad($key, 25, ' ', STR_PAD_RIGHT);
    if ($is_cli) {
        echo $key_padded . ": " . $value . "\n";
    } else {
        echo "<span class='key'>$key_padded</span>: $value\n";
    }
}

// Helper for section headers
function print_header($title) {
    global $is_cli;
    $line = "--- " . $title . " ---";
    if ($is_cli) {
        echo "\n" . $line . "\n";
    } else {
        echo "\n<div class='section'><strong>" . htmlspecialchars($title) . "</strong></div>\n";
    }
}

// --- 1. Basic Information ---
print_header("Core Information");
print_line("Test Timestamp", date(DATE_RFC3339));
print_line("PHP Version", phpversion());
print_line("SAPI", $sapi);
print_line("Hostname", gethostname());
print_line("User", get_current_user() . " (UID: " . getmyuid() . ")");

// --- 2. OS Information ---
print_header("Operating System");
print_line("OS", php_uname('s')); // 's' = OS name
print_line("Release", php_uname('r')); // 'r' = release
print_line("Version", php_uname('v')); // 'v' = version
print_line("Machine Type", php_uname('m')); // 'm' = machine type

// Debian-specific version info
if (file_exists('/etc/debian_version')) {
    $debian_version = trim(file_get_contents('/etc/debian_version'));
    print_line("Debian Version", $debian_version);
}
if (file_exists('/etc/os-release')) {
    $os_release = parse_ini_file('/etc/os-release');
    if (isset($os_release['PRETTY_NAME'])) {
        print_line("OS Distribution", $os_release['PRETTY_NAME']);
    }
    if (isset($os_release['VERSION_CODENAME'])) {
        print_line("Debian Codename", $os_release['VERSION_CODENAME'] . " (" . ucfirst($os_release['VERSION_CODENAME']) . ")");
    }
}

// --- 3. Web Server Information (if applicable) ---
if (!$is_cli && isset($_SERVER['SERVER_SOFTWARE'])) {
    print_header("Web Server");
    print_line("Server Software", $_SERVER['SERVER_SOFTWARE']);
    print_line("Server Address", $_SERVER['SERVER_ADDR'] ?? 'N/A');
    print_line("Server Name", $_SERVER['SERVER_NAME'] ?? 'N/A');
    print_line("Document Root", $_SERVER['DOCUMENT_ROOT'] ?? 'N/A');
}

// --- 3a. Container Runtime Detection ---
print_header("Container Runtime");
$s6_init_exists = file_exists('/init');
$s6_config_exists = file_exists('/etc/s6-overlay') || file_exists('/etc/services.d');
if ($s6_init_exists || $s6_config_exists) {
    print_line("Image Variant", "v2 (with s6-overlay)");
    print_line("s6-overlay init", $s6_init_exists ? "Detected (/init present)" : "Not detected");
    print_line("s6 config dir", $s6_config_exists ? "Present" : "Not present");
} else {
    print_line("Image Variant", "v1 (legacy/compatible)");
    print_line("s6-overlay", "Not present (v1 image)");
}

// --- 4. Loaded Extensions ---
$extensions = get_loaded_extensions();
print_header("Loaded Extensions (" . count($extensions) . ")");
// Sort extensions alphabetically for easier reading
sort($extensions, SORT_STRING | SORT_FLAG_CASE);
echo implode(', ', $extensions) . "\n";

// --- 5. Common Extension Tests ---
print_header("Common Extension Checks");

// Check for PDO and its drivers
if (class_exists('PDO')) {
    $drivers = PDO::getAvailableDrivers();
    print_line("PDO", "Installed");
    print_line("PDO Drivers", empty($drivers) ? "None" : implode(', ', $drivers));
} else {
    print_line("PDO", "Not Installed");
}

// Check for other common extensions
print_line("JSON", function_exists('json_encode') ? "Installed" : "Not Installed");
print_line("XML (libxml)", function_exists('simplexml_load_string') ? "Installed" : "Not Installed");
print_line("BCMath", function_exists('bcadd') ? "Installed" : "Not Installed");
print_line("Ctype", function_exists('ctype_digit') ? "Installed" : "Not Installed");
print_line("Mbstring", function_exists('mb_strlen') ? "Installed" : "Not Installed");
print_line("OpenSSL", function_exists('openssl_encrypt') ? "Installed" : "Not Installed");

// --- 5a. Image-Specific Extensions (kingpin/php-docker) ---
print_header("Image-Specific Extensions");
print_line("GD", extension_loaded('gd') ? "Installed" : "Not Installed");
if (extension_loaded('imagick')) {
    $imagick_version = phpversion('imagick');
    print_line("ImageMagick (imagick)", "Installed (v{$imagick_version})");
} else {
    print_line("ImageMagick (imagick)", "Not Installed");
}
print_line("Redis", extension_loaded('redis') ? "Installed" : "Not Installed");
print_line("Memcached", extension_loaded('memcached') ? "Installed" : "Not Installed");
print_line("MongoDB", extension_loaded('mongodb') ? "Installed" : "Not Installed");
print_line("AMQP (RabbitMQ)", extension_loaded('amqp') ? "Installed" : "Not Installed");
print_line("Vips", extension_loaded('vips') ? "Installed" : "Not Installed");
print_line("Zip", extension_loaded('zip') ? "Installed" : "Not Installed");
print_line("YAML", extension_loaded('yaml') ? "Installed" : "Not Installed");
print_line("OPcache", extension_loaded('Zend OPcache') ? "Installed" : "Not Installed");

// --- 6. Key INI Settings ---
print_header("Key php.ini Settings");
foreach ($ini_settings_to_check as $setting) {
    print_line($setting, ini_get($setting));
}

// --- 7. Simple Test: Writable Directory ---
print_header("Filesystem Check");
$temp_dir = sys_get_temp_dir();
print_line("Temp Directory", $temp_dir);
print_line("Temp Dir Writable?", is_writable($temp_dir) ? "Yes" : "No");


// --- Final Output ---
if ($is_cli) {
    echo "\nScript execution complete.\n";
} else {
    echo "\n<div class='section pass'><strong>Script execution complete.</strong></div>";
    echo "</pre>\n</body>\n</html>";
}
