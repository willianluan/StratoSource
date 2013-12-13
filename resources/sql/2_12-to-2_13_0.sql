
ALTER TABLE  `admin_branch` ADD COLUMN `config_cron_enabled` bool NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `config_cron_type` varchar(1) NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `config_run_status` varchar(1);
ALTER TABLE  `admin_branch` ADD COLUMN `config_cron_interval` integer NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `config_cron_start` varchar(5) NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `templ_cron_enabled` bool NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `templ_cron_type` varchar(1) NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `templ_run_status` varchar(1);
ALTER TABLE  `admin_branch` ADD COLUMN `templ_cron_interval` integer NOT NULL;
ALTER TABLE  `admin_branch` ADD COLUMN `templ_cron_start` varchar(5) NOT NULL;
