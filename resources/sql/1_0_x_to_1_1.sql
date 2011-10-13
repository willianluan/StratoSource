CREATE TABLE `admin_branchlog` (
    `id` integer AUTO_INCREMENT NOT NULL PRIMARY KEY,
    `lastlog` varchar(20000) NOT NULL,
    `branch_id` integer NOT NULL
)
;
ALTER TABLE `admin_branchlog` ADD CONSTRAINT `branch_id_refs_id_5f90c3fe` FOREIGN KEY (`branch_id`) REFERENCES `admin_branch` (`id`)
;
alter table `admin_branch` add column `run_status` varchar(1)
;
update `admin_branch` set `run_status`='u'
;
alter table `admin_branch` modify column `run_status` varchar(1) NOT NULL
;
