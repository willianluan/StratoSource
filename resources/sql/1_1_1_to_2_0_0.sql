CREATE TABLE `admin_unittestrun` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `apex_class_id` varchar(20) NOT NULL,
    `batch_time` datetime NOT NULL,
    `class_name` varchar(200) NOT NULL,
    `branch_id` integer NOT NULL,
    `tests` integer NOT NULL,
    `failures` integer NOT NULL
)
;
ALTER TABLE `admin_unittestrun` ADD CONSTRAINT `branch_id_refs_id_12a55123` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`);
CREATE TABLE `admin_unittestrunresult` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `test_run_id` integer NOT NULL,
    `start_time` datetime NOT NULL,
    `end_time` datetime NOT NULL,
    `method_name` varchar(200) NOT NULL,
    `outcome` varchar(50) NOT NULL,
    `message` varchar(255)
)
;
ALTER TABLE `admin_unittestrunresult` ADD CONSTRAINT `test_run_id_refs_id_f7f75e3e` FOREIGN KEY (`test_run_id`) REFERENCES `admin_unittestrun` (`id`);
CREATE TABLE `admin_unittestschedule` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `branch_id` integer NOT NULL,
    `cron_enabled` bool NOT NULL,
    `cron_type` varchar(1) NOT NULL,
    `cron_interval` integer NOT NULL,
    `cron_start` varchar(5) NOT NULL
)
;
ALTER TABLE `admin_unittestschedule` ADD CONSTRAINT `branch_id_refs_id_ea872c18` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`);
CREATE INDEX `admin_unittestrun_d862f5bb` ON `admin_unittestrun` (`batch_time`);
CREATE INDEX `admin_unittestrun_d56253ba` ON `admin_unittestrun` (`branch_id`);
CREATE INDEX `admin_unittestrunresult_d15d4316` ON `admin_unittestrunresult` (`test_run_id`);
CREATE INDEX `admin_unittestschedule_d56253ba` ON `admin_unittestschedule` (`branch_id`);
COMMIT;
