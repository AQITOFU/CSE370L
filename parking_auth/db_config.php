<?php
// Change these to match your local XAMPP/WAMP/local MySQL setup
$db_host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "parking_management";

$conn = mysqli_connect($db_host, $db_user, $db_pass, $db_name);

if (!$conn) {
    die("Database connection failed: " . mysqli_connect_error());
}
?>
