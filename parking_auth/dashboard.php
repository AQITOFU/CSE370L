<?php
session_start();
require "db_config.php";

// protect this page - if not logged in, kick back to login
if (!isset($_SESSION["user_id"])) {
    header("Location: login.php");
    exit();
}

// pull live availability per parking lot
$lots = [];
$sql = "SELECT pl.lot_id, pl.name, pl.address, pl.total_capacity,
               COUNT(s.spot_no) AS total_spots,
               SUM(CASE WHEN s.status = 'vacant' THEN 1 ELSE 0 END) AS vacant_spots
        FROM Parking_Lot pl
        LEFT JOIN Spot s ON s.lot_id = pl.lot_id
        GROUP BY pl.lot_id, pl.name, pl.address, pl.total_capacity";
$result = mysqli_query($conn, $sql);
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $lots[] = $row;
    }
}

// overall stats across all lots
$total_spots = 0;
$total_vacant = 0;
foreach ($lots as $lot) {
    $total_spots += (int) $lot["total_spots"];
    $total_vacant += (int) $lot["vacant_spots"];
}
$total_occupied = $total_spots - $total_vacant;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dashboard - Parking Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<div class="dash-wrapper">

    <div class="dash-header">
        <div>
            <h1>Welcome, <?php echo htmlspecialchars($_SESSION["full_name"]); ?></h1>
            <span class="role-badge"><?php echo htmlspecialchars($_SESSION["role"]); ?></span>
        </div>
        <a href="logout.php" class="logout-btn">Log Out</a>
    </div>

    <div class="stat-row">
        <div class="stat-card">
            <div class="stat-label">Total Spots</div>
            <div class="stat-value"><?php echo $total_spots; ?></div>
        </div>
        <div class="stat-card available">
            <div class="stat-label">Available Now</div>
            <div class="stat-value"><?php echo $total_vacant; ?></div>
        </div>
        <div class="stat-card occupied">
            <div class="stat-label">Occupied</div>
            <div class="stat-value"><?php echo $total_occupied; ?></div>
        </div>
    </div>

    <div class="lot-list">
        <h2>Parking Lots</h2>
        <?php if (empty($lots)): ?>
            <p style="color:#999; font-size:13px;">No parking lots found. Make sure full_schema.sql has been run.</p>
        <?php else: ?>
            <?php foreach ($lots as $lot): ?>
                <?php
                    $vacant = (int) $lot["vacant_spots"];
                    $total = (int) $lot["total_spots"];
                    $low = ($total > 0 && $vacant / $total < 0.2);
                ?>
                <div class="lot-row">
                    <div>
                        <div class="lot-name"><?php echo htmlspecialchars($lot["name"]); ?></div>
                        <div class="lot-address"><?php echo htmlspecialchars($lot["address"]); ?></div>
                    </div>
                    <div class="lot-avail <?php echo $low ? 'low' : ''; ?>">
                        <?php echo $vacant; ?> / <?php echo $total; ?> free
                    </div>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

    <div class="action-grid">
        <a href="#" class="action-card">
            <div class="action-icon">🚗</div>
            <div class="action-title">Reserve a Spot</div>
            <div class="action-desc">Book a parking spot in advance</div>
        </a>
        <a href="#" class="action-card">
            <div class="action-icon">🕒</div>
            <div class="action-title">My Sessions</div>
            <div class="action-desc">View your parking history</div>
        </a>
        <a href="#" class="action-card">
            <div class="action-icon">💳</div>
            <div class="action-title">Payments</div>
            <div class="action-desc">View and settle payments</div>
        </a>
        <?php if ($_SESSION["role"] === "admin"): ?>
        <a href="#" class="action-card">
            <div class="action-icon">🚧</div>
            <div class="action-title">Issue Citation</div>
            <div class="action-desc">Enforce parking rules</div>
        </a>
        <?php endif; ?>
    </div>

</div>
</body>
</html>
