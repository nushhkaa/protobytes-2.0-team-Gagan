<?php
header('Content-Type: application/json');

// Database config
include 'db_config.php';

// Step 2: Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// // Success response
// echo json_encode(["status" => "unauthorized access", "msg" => "Only authorized users can access this app.
// Contact the admin if you believe you should have access."]);
// $conn->close();
// exit;

// Get POST data
$username = isset($_POST['username']) ? trim($_POST['username']) :
            (isset($_GET['username']) ? trim($_GET['username']) : '');

if (empty($username)) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing username']);
    exit;
}

// Prepare and execute query
$stmt = $conn->prepare("SELECT balance FROM user_info WHERE username = ?");
$stmt->bind_param('s', $username);
$stmt->execute();
$stmt->bind_result($balance);

if ($stmt->fetch()) {
    echo json_encode(['username' => $username, 'balance' => $balance]);
} else {
    http_response_code(404);
    echo json_encode(['error' => 'User not found']);
}

$stmt->close();
$conn->close();
?>
