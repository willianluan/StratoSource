ALTER TABLE `admin_branch` ADD COLUMN
    `cron_enabled` bool NOT NULL;
update `admin_branch` set cron_enabled = 1;

