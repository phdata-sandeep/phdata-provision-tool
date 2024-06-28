CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_USERS_LOGIN_FAILURES()
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS '

BEGIN
LET res RESULTSET := (
      SELECT USER_NAME
FROM snowflake.account_usage.login_history
WHERE 
EVENT_TIMESTAMP >= dateadd(DAY, -1, current_timestamp())
AND IS_SUCCESS = ''NO''
GROUP BY USER_NAME
HAVING COUNT(*) > 5
);
RETURN TABLE(res);
END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_USERS_LOGIN_FAILURES_EMAIL()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE

  c1 CURSOR FOR WITH email_body AS (
                  WITH query_wrapper AS (
                        SELECT USER_NAME
FROM snowflake.account_usage.login_history
WHERE 
EVENT_TIMESTAMP >= dateadd(DAY, -1, current_timestamp())
AND IS_SUCCESS = ''NO''
GROUP BY USER_NAME
HAVING COUNT(*) > 5
                  ) 
                  SELECT TO_VARCHAR(OBJECT_CONSTRUCT(*)) AS all_rows_string FROM query_wrapper
            )
            SELECT listagg(all_rows_string, ''\\n\\n'') as email_body_text FROM email_body;
    subj varchar;
    msg varchar;
  BEGIN
      OPEN c1;
      FETCH c1 INTO msg;
      msg := ''TO VIEW THE OUTPUT OF THE ALERT, RUN: \\n CALL CDOPS_STATESTORE.MONITORING.SP_USERS_LOGIN_FAILURES();'' || ''\\n\\n OUTPUT OF ALERT:\\n'' || msg;
      subj := ''SNOWFLAKE ALERT - PRIORITY P2  - USERS_LOGIN_FAILURES - ACCOUNT PROD'' || current_account() || '' - '' || current_timestamp();
      call system$send_email(''RM_EMAIL_INT'',''consero@phdata.io'':subj,:msg);
  END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_USERS_WITHOUT_LOG_IN_FOR_90_DAYS()
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS '

BEGIN
LET res RESULTSET := (
      SELECT
	LOGIN_NAME,
	DISPLAY_NAME,
	EMAIL,
	LAST_SUCCESS_LOGIN
FROM
    SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE
    LAST_SUCCESS_LOGIN >= dateadd(DAY, -90, current_timestamp())
    AND DELETED_ON IS NULL
    AND DISABLED = FALSE
);
RETURN TABLE(res);
END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_USERS_WITHOUT_LOG_IN_FOR_90_DAYS_EMAIL()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE

  c1 CURSOR FOR WITH email_body AS (
                  WITH query_wrapper AS (
                        SELECT
	LOGIN_NAME,
	DISPLAY_NAME,
	EMAIL,
	LAST_SUCCESS_LOGIN
FROM
    SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE
    LAST_SUCCESS_LOGIN >= dateadd(DAY, -90, current_timestamp())
    AND DELETED_ON IS NULL
    AND DISABLED = FALSE
                  ) 
                  SELECT TO_VARCHAR(OBJECT_CONSTRUCT(*)) AS all_rows_string FROM query_wrapper
            )
            SELECT listagg(all_rows_string, ''\\n\\n'') as email_body_text FROM email_body;
    subj varchar;
    msg varchar;
  BEGIN
      OPEN c1;
      FETCH c1 INTO msg;
      msg := ''TO VIEW THE OUTPUT OF THE ALERT, RUN: \\n CALL CDOPS_STATESTORE.MONITORING.SP_USERS_WITHOUT_LOG_IN_FOR_90_DAYS();'' || ''\\n\\n OUTPUT OF ALERT:\\n'' || msg;
      subj := ''SNOWFLAKE ALERT - PRIORITY P2 - USERS_WITHOUT_LOG_IN_FOR_90_DAYS - ACCOUNT PROD '' || current_account() || '' - '' || current_timestamp();
      call SYSTEM$SEND_EMAIL(''RM_EMAIL_INT'',''consero@phdata.io'',:subj,:msg);
  END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_USERS_WITH_A_PASSWORD_SET()
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS '

BEGIN
LET res RESULTSET := (
      SELECT
  ''USER'' AS OBJECT_TYPE,
  NAME AS OBJECT_NAME,
  FIRST_NAME,
  LAST_NAME,
  LOGIN_NAME,
  CREATED_ON,
  HAS_PASSWORD
FROM
  SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE
  PASSWORD_LAST_SET_TIME >= dateadd(DAY, -1, current_timestamp())
  AND HAS_PASSWORD
  AND DISABLED = ''false''
  AND DELETED_ON IS NULL
);
RETURN TABLE(res);
END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_USERS_WITH_A_PASSWORD_SET_EMAIL()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE

  c1 CURSOR FOR WITH email_body AS (
                  WITH query_wrapper AS (
                        SELECT
  ''USER'' AS OBJECT_TYPE,
  NAME AS OBJECT_NAME,
  FIRST_NAME,
  LAST_NAME,
  LOGIN_NAME,
  CREATED_ON,
  HAS_PASSWORD
FROM
  SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE
  PASSWORD_LAST_SET_TIME >= dateadd(DAY, -30, current_timestamp())
  AND HAS_PASSWORD
  AND DISABLED = ''false''
  AND DELETED_ON IS NULL
                  ) 
                  SELECT TO_VARCHAR(OBJECT_CONSTRUCT(*)) AS all_rows_string FROM query_wrapper
            )
            SELECT listagg(all_rows_string, ''\\n\\n'') as email_body_text FROM email_body;
    subj varchar;
    msg varchar;
  BEGIN
      OPEN c1;
      FETCH c1 INTO msg;
      msg := ''TO VIEW THE OUTPUT OF THE ALERT, RUN: \\n CALL CDOPS_STATESTORE.MONITORING.SP_USERS_WITH_A_PASSWORD_SET();'' || ''\\n\\n OUTPUT OF ALERT:\\n'' || msg;
      subj := ''SNOWFLAKE ALERT - PRIORITY P2 - USERS_WITH_A_PASSWORD_SET - ACCOUNT PROD '' || current_account() || '' - '' || current_timestamp();
      call system$send_email(''RM_EMAIL_INT'',''consero@phdata.io'',:subj,:msg);
  END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_WAREHOUSES_WITHOUT_A_RESOURCE_MONITOR()
RETURNS TABLE ()
LANGUAGE SQL
EXECUTE AS OWNER
AS '

DECLARE
presql RESULTSET DEFAULT (show warehouses in account);

BEGIN
LET res RESULTSET := (
      SELECT 
    "name", 
    "auto_resume", 
    "auto_suspend" 
From TABLE(RESULT_SCAN(LAST_QUERY_ID())) 
WHERE
    "resource_monitor" = ''null''
);
RETURN TABLE(res);
END;
';
CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.MONITORING.SP_WAREHOUSES_WITHOUT_A_RESOURCE_MONITOR_EMAIL()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE

presql RESULTSET DEFAULT (show warehouses in account);

  c1 CURSOR FOR WITH email_body AS (
                  WITH query_wrapper AS (
                        SELECT 
    "name", 
    "auto_resume", 
    "auto_suspend" 
From TABLE(RESULT_SCAN(LAST_QUERY_ID())) 
WHERE
    "resource_monitor" = ''null''
                  ) 
                  SELECT TO_VARCHAR(OBJECT_CONSTRUCT(*)) AS all_rows_string FROM query_wrapper
            )
            SELECT listagg(all_rows_string, ''\\n\\n'') as email_body_text FROM email_body;
    subj varchar;
    msg varchar;
  BEGIN
      OPEN c1;
      FETCH c1 INTO msg;
      msg := ''TO VIEW THE OUTPUT OF THE ALERT, RUN: \\n CALL CDOPS_STATESTORE.MONITORING.SP_WAREHOUSES_WITHOUT_A_RESOURCE_MONITOR();'' || ''\\n\\n OUTPUT OF ALERT:\\n'' || msg;
      subj := ''SNOWFLAKE ALERT - PRIORITY P2 - WAREHOUSES_WITHOUT_A_RESOURCE_MONITOR - ACCOUNT PROD'' || current_account() || '' - '' || current_timestamp();
      call system$send_email(''RM_EMAIL_INT'',''consero@phdata.io'',:subj,:msg);
  END;
';
