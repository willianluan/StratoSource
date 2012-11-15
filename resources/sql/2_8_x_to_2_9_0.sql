ALTER TABLE `admin_branch` ADD COLUMN `enabled` bool NOT NULL;

ALTER TABLE `admin_releasetask` ADD COLUMN `user_id` integer;
ALTER TABLE `admin_releasetask` ADD COLUMN `story_id` integer;
ALTER TABLE `admin_releasetask` CHANGE COLUMN `release_id` `release_id` integer;

ALTER TABLE `admin_releasetask` ADD CONSTRAINT `user_id_refs_id_7dc124f2` FOREIGN KEY (`user_id`) REFERENCES `admin_salesforceuser` (`id`);
ALTER TABLE `admin_releasetask` ADD CONSTRAINT `story_id_refs_id_c249e70e` FOREIGN KEY (`story_id`) REFERENCES `admin_story` (`id`);

CREATE INDEX `admin_releasetask_fbfc09f1` ON `admin_releasetask` (`user_id`);
CREATE INDEX `admin_releasetask_f5ae222e` ON `admin_releasetask` (`story_id`);

INSERT INTO `admin_configsetting` (`key`, `value`, `type`, `allow_delete`, `masked`) VALUES ('calendar.host','localhost',0,0);

