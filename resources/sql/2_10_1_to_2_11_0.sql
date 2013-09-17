ALTER TABLE `admin_releasetask` add column `task_type` integer;
ALTER TABLE `admin_branch` add column `order` integer;

update admin_branch set `order` = 0;
update admin_releasetask set task_type = 100;