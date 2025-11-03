-- ╔════════════════════════════════════════════════════════╗
-- ║  vCore Framework - Complete Database Installation     ║
-- ║  Version: 2.0.0                                        ║
-- ║  MySQL 5.7+ / MariaDB 10.3+                            ║
-- ╚════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════
-- DATABASE CONFIGURATION
-- ════════════════════════════════════════════════════════

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET time_zone = '+00:00';

-- ════════════════════════════════════════════════════════
-- CORE TABLES
-- ════════════════════════════════════════════════════════

-- Players Table (Main player data)
CREATE TABLE IF NOT EXISTS `players` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(255) NOT NULL,
    `steam` VARCHAR(255) DEFAULT NULL,
    `discord` VARCHAR(255) DEFAULT NULL,
    `license` VARCHAR(255) NOT NULL,
    `ip` VARCHAR(50) DEFAULT NULL,
    
    -- Identity
    `identity` LONGTEXT DEFAULT NULL COMMENT 'JSON: firstName, lastName, dob, sex, nationality, height, bloodType',
    `contact` TEXT DEFAULT NULL COMMENT 'JSON: phone, email',
    
    -- Financial
    `currencies` TEXT DEFAULT NULL COMMENT 'JSON: cash, bank, crypto, gold, chips',
    `bank_account` VARCHAR(50) DEFAULT NULL,
    
    -- Profession System
    `profession` TEXT DEFAULT NULL COMMENT 'JSON: primary profession data',
    `secondary_professions` TEXT DEFAULT NULL COMMENT 'JSON: array of secondary professions',
    `profession_history` TEXT DEFAULT NULL COMMENT 'JSON: historical profession data',
    
    -- Organization System
    `organization` TEXT DEFAULT NULL COMMENT 'JSON: current organization',
    `organization_history` TEXT DEFAULT NULL COMMENT 'JSON: historical organization data',
    
    -- Skill & Progression
    `skills` TEXT DEFAULT NULL COMMENT 'JSON: skill levels and XP',
    `achievements` TEXT DEFAULT NULL COMMENT 'JSON: unlocked achievements',
    `statistics` TEXT DEFAULT NULL COMMENT 'JSON: playtime, deaths, kills, etc',
    
    -- Reputation
    `reputation` TEXT DEFAULT NULL COMMENT 'JSON: faction reputation values',
    
    -- Status
    `status` TEXT DEFAULT NULL COMMENT 'JSON: hunger, thirst, stress, energy, hygiene',
    
    -- Location
    `position` TEXT DEFAULT NULL COMMENT 'JSON: x, y, z, heading',
    `bucket` INT(11) DEFAULT 0,
    
    -- Metadata
    `metadata` LONGTEXT DEFAULT NULL COMMENT 'JSON: fingerprint, walletId, callsign, phoneData',
    
    -- Inventory
    `inventory` LONGTEXT DEFAULT NULL COMMENT 'JSON: player inventory items',
    `max_weight` INT(11) DEFAULT 30000,
    
    -- Licenses
    `licenses` TEXT DEFAULT NULL COMMENT 'JSON: driver, weapon, business, etc',
    
    -- Settings
    `settings` TEXT DEFAULT NULL COMMENT 'JSON: voice, hud, notifications',
    
    -- Session
    `session` TEXT DEFAULT NULL COMMENT 'JSON: login info, playtime, IP history',
    
    -- Timestamps
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`),
    KEY `identifier` (`identifier`),
    KEY `steam` (`steam`),
    KEY `discord` (`discord`),
    KEY `license` (`license`),
    KEY `last_login` (`last_login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- SESSION MANAGEMENT
-- ════════════════════════════════════════════════════════

-- Active Sessions
CREATE TABLE IF NOT EXISTS `player_sessions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `session_id` BIGINT(20) NOT NULL,
    `identifier` VARCHAR(255) NOT NULL,
    `start_time` INT(11) NOT NULL,
    `last_update` INT(11) DEFAULT NULL,
    `ip` VARCHAR(50) DEFAULT NULL,
    `state` TEXT DEFAULT NULL COMMENT 'JSON: position, health, armor, vehicle',
    `is_active` TINYINT(1) DEFAULT 1,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `session_id` (`session_id`),
    KEY `citizenid` (`citizenid`),
    KEY `is_active` (`is_active`),
    FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Session Logs
CREATE TABLE IF NOT EXISTS `session_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `session_id` BIGINT(20) NOT NULL,
    `start_time` INT(11) NOT NULL,
    `end_time` INT(11) DEFAULT NULL,
    `duration` INT(11) DEFAULT NULL,
    `reason` VARCHAR(100) DEFAULT NULL COMMENT 'disconnect, logout, crash, kick',
    `metrics` TEXT DEFAULT NULL COMMENT 'JSON: ping, fps, packet loss',
    
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `start_time` (`start_time`),
    FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- FINANCIAL SYSTEM
-- ════════════════════════════════════════════════════════

-- Currency Transactions
CREATE TABLE IF NOT EXISTS `currency_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `type` VARCHAR(20) NOT NULL COMMENT 'add, remove, set, transfer',
    `currency` VARCHAR(20) NOT NULL COMMENT 'cash, bank, crypto, gold, chips',
    `amount` DECIMAL(15,2) NOT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `old_balance` DECIMAL(15,2) DEFAULT NULL,
    `new_balance` DECIMAL(15,2) DEFAULT NULL,
    `timestamp` INT(11) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `currency` (`currency`),
    KEY `type` (`type`),
    KEY `timestamp` (`timestamp`),
    FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bank Transfers
CREATE TABLE IF NOT EXISTS `bank_transfers` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `from_citizenid` VARCHAR(50) NOT NULL,
    `to_citizenid` VARCHAR(50) NOT NULL,
    `from_account` VARCHAR(50) NOT NULL,
    `to_account` VARCHAR(50) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `tax` DECIMAL(15,2) DEFAULT 0,
    `reason` VARCHAR(255) DEFAULT NULL,
    `timestamp` INT(11) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `from_citizenid` (`from_citizenid`),
    KEY `to_citizenid` (`to_citizenid`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- PROFESSION SYSTEM
-- ════════════════════════════════════════════════════════

-- Profession History
CREATE TABLE IF NOT EXISTS `profession_history` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `profession_name` VARCHAR(50) NOT NULL,
    `profession_label` VARCHAR(100) NOT NULL,
    `start_date` INT(11) NOT NULL,
    `end_date` INT(11) DEFAULT NULL,
    `final_level` INT(11) DEFAULT 0,
    `reason` VARCHAR(255) DEFAULT NULL COMMENT 'resigned, fired, promoted',
    
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `profession_name` (`profession_name`),
    FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Profession Salary Logs
CREATE TABLE IF NOT EXISTS `salary_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `profession` VARCHAR(50) NOT NULL,
    `amount` DECIMAL(15,2) NOT NULL,
    `timestamp` INT(11) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `profession` (`profession`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- ORGANIZATION SYSTEM
-- ════════════════════════════════════════════════════════

-- Organizations
CREATE TABLE IF NOT EXISTS `organizations` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `type` VARCHAR(20) NOT NULL COMMENT 'legal, illegal, government',
    `owner_citizenid` VARCHAR(50) NOT NULL,
    `balance` DECIMAL(15,2) DEFAULT 0,
    `members` TEXT DEFAULT NULL COMMENT 'JSON: array of members',
    `ranks` TEXT DEFAULT NULL COMMENT 'JSON: rank structure',
    `territories` TEXT DEFAULT NULL COMMENT 'JSON: controlled territories',
    `warehouses` TEXT DEFAULT NULL COMMENT 'JSON: storage locations',
    `reputation` INT(11) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `name` (`name`),
    KEY `owner_citizenid` (`owner_citizenid`),
    KEY `type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Organization Members
CREATE TABLE IF NOT EXISTS `organization_members` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `organization_id` INT(11) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `rank` VARCHAR(50) NOT NULL,
    `rank_level` INT(11) DEFAULT 0,
    `permissions` TEXT DEFAULT NULL COMMENT 'JSON: permissions array',
    `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `org_member` (`organization_id`, `citizenid`),
    KEY `citizenid` (`citizenid`),
    FOREIGN KEY (`organization_id`) REFERENCES `organizations` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- SKILL SYSTEM
-- ════════════════════════════════════════════════════════

-- Skill Progress Logs
CREATE TABLE IF NOT EXISTS `skill_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `skill` VARCHAR(50) NOT NULL,
    `old_level` INT(11) NOT NULL,
    `new_level` INT(11) NOT NULL,
    `xp_gained` INT(11) NOT NULL,
    `timestamp` INT(11) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `skill` (`skill`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- REPUTATION SYSTEM
-- ════════════════════════════════════════════════════════

-- Reputation Logs
CREATE TABLE IF NOT EXISTS `reputation_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `faction` VARCHAR(50) NOT NULL,
    `old_value` INT(11) NOT NULL,
    `new_value` INT(11) NOT NULL,
    `change` INT(11) NOT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `timestamp` INT(11) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `faction` (`faction`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- BAN SYSTEM
-- ════════════════════════════════════════════════════════

-- Bans
CREATE TABLE IF NOT EXISTS `bans` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(255) NOT NULL,
    `citizenid` VARCHAR(50) DEFAULT NULL,
    `steam` VARCHAR(255) DEFAULT NULL,
    `discord` VARCHAR(255) DEFAULT NULL,
    `license` VARCHAR(255) DEFAULT NULL,
    `ip` VARCHAR(50) DEFAULT NULL,
    `reason` TEXT DEFAULT NULL,
    `banned_by` VARCHAR(255) DEFAULT NULL,
    `expire` TIMESTAMP NULL DEFAULT NULL,
    `permanent` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `citizenid` (`citizenid`),
    KEY `expire` (`expire`),
    KEY `permanent` (`permanent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- ADMIN LOGS
-- ════════════════════════════════════════════════════════

-- Admin Actions
CREATE TABLE IF NOT EXISTS `admin_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `admin_citizenid` VARCHAR(50) NOT NULL,
    `admin_name` VARCHAR(255) NOT NULL,
    `action` VARCHAR(100) NOT NULL COMMENT 'kick, ban, setjob, givemoney, etc',
    `target_citizenid` VARCHAR(50) DEFAULT NULL,
    `target_name` VARCHAR(255) DEFAULT NULL,
    `details` TEXT DEFAULT NULL COMMENT 'JSON: action details',
    `timestamp` INT(11) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    KEY `admin_citizenid` (`admin_citizenid`),
    KEY `target_citizenid` (`target_citizenid`),
    KEY `action` (`action`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ════════════════════════════════════════════════════════
-- MIGRATION SYSTEM
-- ════════════════════════════════════════════════════════

-- Migrations
CREATE TABLE IF NOT EXISTS `migrations` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `version` VARCHAR(50) NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `executed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert initial migration record
INSERT INTO `migrations` (`version`, `name`) VALUES 
('2.0.0', 'initial_database_setup')
ON DUPLICATE KEY UPDATE version=version;

-- ════════════════════════════════════════════════════════
-- INDEXES FOR PERFORMANCE
-- ════════════════════════════════════════════════════════

-- Additional composite indexes for common queries
ALTER TABLE `players` 
    ADD INDEX `idx_search` (`identifier`, `steam`, `discord`),
    ADD INDEX `idx_active` (`last_login`, `created_at`);

ALTER TABLE `currency_logs` 
    ADD INDEX `idx_recent` (`citizenid`, `timestamp`),
    ADD INDEX `idx_type_currency` (`type`, `currency`);

ALTER TABLE `session_logs` 
    ADD INDEX `idx_duration` (`citizenid`, `duration`);

-- ════════════════════════════════════════════════════════
-- VIEWS FOR COMMON QUERIES
-- ════════════════════════════════════════════════════════

-- Active Players View
CREATE OR REPLACE VIEW `view_active_players` AS
SELECT 
    p.citizenid,
    p.identifier,
    JSON_UNQUOTE(JSON_EXTRACT(p.identity, '$.firstName')) as first_name,
    JSON_UNQUOTE(JSON_EXTRACT(p.identity, '$.lastName')) as last_name,
    JSON_UNQUOTE(JSON_EXTRACT(p.profession, '$.primary.name')) as profession,
    ps.session_id,
    ps.ip,
    ps.start_time,
    p.last_login
FROM players p
INNER JOIN player_sessions ps ON p.citizenid = ps.citizenid
WHERE ps.is_active = 1;

-- Wealth Leaderboard View
CREATE OR REPLACE VIEW `view_wealth_leaderboard` AS
SELECT 
    citizenid,
    JSON_UNQUOTE(JSON_EXTRACT(identity, '$.firstName')) as first_name,
    JSON_UNQUOTE(JSON_EXTRACT(identity, '$.lastName')) as last_name,
    CAST(JSON_UNQUOTE(JSON_EXTRACT(currencies, '$.cash')) AS DECIMAL(15,2)) + 
    CAST(JSON_UNQUOTE(JSON_EXTRACT(currencies, '$.bank')) AS DECIMAL(15,2)) as total_money
FROM players
ORDER BY total_money DESC
LIMIT 100;

-- ════════════════════════════════════════════════════════
-- STORED PROCEDURES
-- ════════════════════════════════════════════════════════

DELIMITER $$

-- Clean old session logs (older than 30 days)
CREATE PROCEDURE IF NOT EXISTS sp_cleanup_old_sessions()
BEGIN
    DELETE FROM session_logs 
    WHERE end_time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 30 DAY));
    
    DELETE FROM currency_logs 
    WHERE timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 90 DAY));
    
    DELETE FROM skill_logs 
    WHERE timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 90 DAY));
    
    DELETE FROM reputation_logs 
    WHERE timestamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 90 DAY));
END$$

-- Get player statistics
CREATE PROCEDURE IF NOT EXISTS sp_get_player_stats(IN p_citizenid VARCHAR(50))
BEGIN
    SELECT 
        p.*,
        COUNT(DISTINCT sl.id) as total_sessions,
        SUM(sl.duration) as total_playtime,
        AVG(sl.duration) as avg_session_duration,
        (SELECT COUNT(*) FROM currency_logs WHERE citizenid = p_citizenid) as total_transactions,
        (SELECT SUM(amount) FROM currency_logs WHERE citizenid = p_citizenid AND type = 'add') as total_earned,
        (SELECT SUM(amount) FROM currency_logs WHERE citizenid = p_citizenid AND type = 'remove') as total_spent
    FROM players p
    LEFT JOIN session_logs sl ON p.citizenid = sl.citizenid
    WHERE p.citizenid = p_citizenid
    GROUP BY p.id;
END$$

DELIMITER ;

-- ════════════════════════════════════════════════════════
-- EVENT SCHEDULER (Auto-cleanup)
-- ════════════════════════════════════════════════════════

SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS evt_cleanup_old_data
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
    CALL sp_cleanup_old_sessions();

-- ════════════════════════════════════════════════════════
-- FINAL SETUP
-- ════════════════════════════════════════════════════════

SET FOREIGN_KEY_CHECKS = 1;

-- Success message
SELECT 
    'vCore Framework Database Installation Complete!' as status,
    '2.0.0' as version,
    NOW() as installed_at;

-- Display table count
SELECT 
    COUNT(*) as total_tables,
    SUM(data_length + index_length) / 1024 / 1024 as size_mb
FROM information_schema.tables 
WHERE table_schema = DATABASE();