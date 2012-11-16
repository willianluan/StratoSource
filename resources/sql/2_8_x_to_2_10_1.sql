ALTER TABLE `admin_branch` ADD COLUMN `enabled` bool NOT NULL;

ALTER TABLE `admin_releasetask` ADD COLUMN `user_id` integer;
ALTER TABLE `admin_releasetask` ADD COLUMN `story_id` integer;
ALTER TABLE `admin_releasetask` CHANGE COLUMN `release_id` `release_id` integer;

ALTER TABLE `admin_releasetask` ADD CONSTRAINT `user_id_refs_id_7dc124f2` FOREIGN KEY (`user_id`) REFERENCES `admin_salesforceuser` (`id`);
ALTER TABLE `admin_releasetask` ADD CONSTRAINT `story_id_refs_id_c249e70e` FOREIGN KEY (`story_id`) REFERENCES `admin_story` (`id`);

CREATE INDEX `admin_releasetask_fbfc09f1` ON `admin_releasetask` (`user_id`);
CREATE INDEX `admin_releasetask_f5ae222e` ON `admin_releasetask` (`story_id`);

INSERT INTO `admin_configsetting` (`key`, `value`, `type`, `allow_delete`, `masked`) VALUES ('calendar.host','localhost','text',0,0);

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

CREATE TABLE `jqcalendar` (
  `Id` int(11) NOT NULL auto_increment,
  `Subject` varchar(1000) character set utf8 default NULL,
  `Location` varchar(200) character set utf8 default NULL,
  `Description` varchar(255) character set utf8 default NULL,
  `StartTime` datetime default NULL,
  `EndTime` datetime default NULL,
  `IsAllDayEvent` smallint(6) NOT NULL,
  `Color` varchar(200) character set utf8 default NULL,
  `release_id` int(11),
  `guid` varchar(45),
  `RecurringRule` varchar(500) character set utf8 default NULL,
  PRIMARY KEY  (`Id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

