DROP TABLE `admin_unittestbatch`;
DROP TABLE `admin_unittestrun`;
DROP TABLE `admin_unittestrunresult`;

CREATE TABLE `admin_unittestbatch` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `batch_time` datetime NOT NULL,
    `branch_id` integer NOT NULL,
    `tests` integer NOT NULL,
    `failures` integer NOT NULL,
    `runtime` integer NOT NULL
)
;
ALTER TABLE `admin_unittestbatch` ADD CONSTRAINT `branch_id_refs_id_4204ee2a` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`);
CREATE TABLE `admin_unittestrun` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `apex_class_id` varchar(20) NOT NULL,
    `batch_id` integer NOT NULL,
    `class_name` varchar(200) NOT NULL,
    `branch_id` integer NOT NULL,
    `tests` integer NOT NULL,
    `failures` integer NOT NULL,
    `runtime` integer NOT NULL
)
;
ALTER TABLE `admin_unittestrun` ADD CONSTRAINT `batch_id_refs_id_5fc6ae08` FOREIGN KEY (`batch_id`) REFERENCES `admin_unittestbatch` (`id`);
ALTER TABLE `admin_unittestrun` ADD CONSTRAINT `branch_id_refs_id_12a55123` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`);
CREATE TABLE `admin_unittestrunresult` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `test_run_id` integer NOT NULL,
    `start_time` datetime NOT NULL,
    `end_time` datetime NOT NULL,
    `method_name` varchar(200) NOT NULL,
    `outcome` varchar(50) NOT NULL,
    `message` varchar(255),
    `runtime` integer NOT NULL
)
;
ALTER TABLE `admin_unittestrunresult` ADD CONSTRAINT `test_run_id_refs_id_f7f75e3e` FOREIGN KEY (`test_run_id`) REFERENCES `admin_unittestrun` (`id`);

