ALTER TABLE `admin_branch` add column
    `api_pod` varchar(10) NOT NULL;

CREATE TABLE `admin_userchange` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `branch_id` integer NOT NULL,
    `apex_id` varchar(20) NOT NULL,
    `apex_name` varchar(200) NOT NULL,
    `user_id` varchar(20) NOT NULL,
    `batch_time` datetime NOT NULL,
    `user_name` varchar(100) NOT NULL,
    `last_update` datetime NOT NULL
)
;
ALTER TABLE `admin_userchange` ADD CONSTRAINT `branch_id_refs_id_d317d16e` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`);

