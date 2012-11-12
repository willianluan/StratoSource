ALTER TABLE `admin_release` DROP FOREIGN KEY `branch_id_refs_id_7adb2fd5`;
ALTER TABLE `admin_release` DROP COLUMN `branch_id`;


CREATE TABLE `admin_deploymentpackage_deployable_objects` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `deploymentpackage_id` integer NOT NULL,
    `deployableobject_id` integer NOT NULL,
    UNIQUE (`deploymentpackage_id`, `deployableobject_id`)
);

ALTER TABLE `admin_deploymentpackage_deployable_objects` ADD CONSTRAINT `deployableobject_id_refs_id_6643b419` FOREIGN KEY (`deployableobject_id`) REFERENCES `admin_deployableobject` (`id`);

CREATE TABLE `admin_deploymentpackage` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `name` varchar(1000) NOT NULL,
    `release_id` integer NOT NULL,
    `date_added` datetime NOT NULL,
    `last_pushed` datetime,
    `source_environment_id` integer NOT NULL
);

ALTER TABLE `admin_deploymentpackage` ADD CONSTRAINT `release_id_refs_id_c9779edb` FOREIGN KEY (`release_id`) REFERENCES `admin_release` (`id`);
ALTER TABLE `admin_deploymentpackage` ADD CONSTRAINT `source_environment_id_refs_id_4ffc57c9` FOREIGN KEY (`source_environment_id`) REFERENCES `admin_branch` (`id`);
ALTER TABLE `admin_deploymentpackage_deployable_objects` ADD CONSTRAINT `deploymentpackage_id_refs_id_276f057` FOREIGN KEY (`deploymentpackage_id`) REFERENCES `admin_deploymentpackage` (`id`);

CREATE TABLE `admin_deploymentpushstatus` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `package_id` integer NOT NULL,
    `date_attempted` date NOT NULL,
    `log_output` varchar(20000) NOT NULL,
    `result` varchar(1) NOT NULL,
    `test_only` bool NOT NULL,
    `keep_package` bool NOT NULL,
    `target_environment_id` integer NOT NULL,
    `package_location` varchar(200)
);

ALTER TABLE `admin_deploymentpushstatus` ADD CONSTRAINT `target_environment_id_refs_id_36534d9e` FOREIGN KEY (`target_environment_id`) REFERENCES `admin_branch` (`id`);
ALTER TABLE `admin_deploymentpushstatus` ADD CONSTRAINT `package_id_refs_id_87a00896` FOREIGN KEY (`package_id`) REFERENCES `admin_deploymentpackage` (`id`);

CREATE INDEX `admin_deploymentpackage_b827d594` ON `admin_deploymentpackage` (`release_id`);
CREATE INDEX `admin_deploymentpackage_c370dd73` ON `admin_deploymentpackage` (`source_environment_id`);
CREATE INDEX `admin_deploymentpushstatus_f97c0bb9` ON `admin_deploymentpushstatus` (`package_id`);
CREATE INDEX `admin_deploymentpushstatus_8c6c66f` ON `admin_deploymentpushstatus` (`target_environment_id`);
