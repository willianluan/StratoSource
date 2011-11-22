ALTER TABLE `admin_delta` DROP FOREIGN KEY `user_change_id_refs_id_84225281`;

update `stratosource`.`admin_delta` set user_change_id = NULL;

drop TABLE `admin_userchange`;

CREATE TABLE `admin_salesforceuser` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `userid` varchar(20) NOT NULL,
    `name` varchar(100) NOT NULL,
    `email` varchar(100) NOT NULL
)
;

CREATE TABLE `admin_userchange` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `branch_id` integer NOT NULL,
    `apex_id` varchar(20),
    `apex_name` varchar(200) NOT NULL,
    `sfuser_id` integer NOT NULL,
    `batch_time` datetime NOT NULL,
    `last_update` datetime NOT NULL,
    `object_type` varchar(20) NOT NULL
)
;
ALTER TABLE `admin_userchange` ADD CONSTRAINT `branch_id_refs_id_d317d16e` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`);
ALTER TABLE `admin_userchange` ADD CONSTRAINT `sfuser_id_refs_id_ab886d32` FOREIGN KEY (`sfuser_id`) REFERENCES `admin_salesforceuser` (`id`);


ALTER TABLE `admin_delta` ADD CONSTRAINT `user_change_id_refs_id_84225281` FOREIGN KEY (`user_change_id`) REFERENCES `admin_userchange` (`id`);


