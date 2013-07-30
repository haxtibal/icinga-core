-- -----------------------------------------
-- upgrade path for Icinga IDOUtils 1.10.0
--
-- run it as icinga database user from whithin current directory
-- sqlplus icinga@<instance> @ oracle-upgrade-1.10.0.sql

-- -----------------------------------------
-- Copyright (c) 2013 Icinga Development Team (http://www.icinga.org)
--
-- Please check http://docs.icinga.org for upgrading information!
-- -----------------------------------------
set sqlprompt "&&_USER@&&_CONNECT_IDENTIFIER SQL>"
set pagesize 200;
set linesize 200;
set heading on;
set echo on;
set feedback on;

define ICINGA_VERSION=1.10.0

-- --------------------------------------------------------
-- warning: edit this script to define existing tablespaces
-- this particular step can be skipped safely if no new
-- table or index included
-- --------------------------------------------------------
/* set real TBS names on which you have quota, no checks are implemented!*/
define DATATBS='ICINGA_DATA1';
define LOBTBS='ICINGA_LOB1';
define IDXTBS='ICINGA_IDX1';

/* load defines from file, if any */
@icinga_defines.sql

/* script will be terminated on the first error */
whenever sqlerror exit failure
spool oracle-upgrade-&&ICINGA_VERSION..log

-- -----------------------------------------
-- #4363 deprecate enable_sla
-- -----------------------------------------

-- DROP TABLE slahistory;

-- -----------------------------------------
-- #1883 expanded values 
-- -----------------------------------------

ALTER TABLE hosts ADD notes_expanded varchar2(1024);
ALTER TABLE hosts ADD notes_url_expanded varchar2(1024);
ALTER TABLE hosts ADD action_url_expanded varchar2(1024);
ALTER TABLE hosts ADD icon_image_expanded varchar2(1024);

ALTER TABLE services ADD notes_expanded varchar2(1024);
ALTER TABLE services ADD notes_url_expanded varchar2(1024);
ALTER TABLE services ADD action_url_expanded varchar2(1024);
ALTER TABLE services ADD icon_image_expanded varchar2(1024);

-- -----------------------------------------
-- #4482 deprecate timedevent* tables
-- -----------------------------------------

DROP INDEX timedevents_i_id_idx;
DROP INDEX timedeventq_i_id_idx;
DROP INDEX timedevents_time_id_idx;
DROP INDEX timedeventq_time_id_idx;
DROP INDEX timed_e_q_event_type_idx;
DROP INDEX timed_e_q_sched_time_idx;
DROP INDEX timed_e_q_object_id_idx;
DROP INDEX timed_e_q_rec_ev_id_idx;
DROP INDEX timed_e_event_type_idx;
DROP INDEX timed_e_object_id_idx;
DROP INDEX timed_e_rec_ev_idx;

DROP SEQUENCE seq_timedeventqueue;
DROP SEQUENCE seq_timedevents;

DROP TABLE timedevents;
DROP TABLE timedeventqueue;


-- -----------------------------------------
-- finally update dbversion
-- -----------------------------------------

MERGE INTO dbversion
	USING DUAL ON (name='idoutils')
	WHEN MATCHED THEN
		UPDATE SET version='&&ICINGA_VERSION', modify_time=CURRENT_TIMESTAMP
	WHEN NOT MATCHED THEN
		INSERT (id, name, version, create_time, modify_time) VALUES ('1', 'idoutils', '&&ICINGA_VERSION', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
commit;

/* last check */
select object_name,object_type,status  from user_objects where status !='VALID';

/* goodbye */
spool off 
exit;
