WITH
  mails_by_month AS (  -- extract sent month
    SELECT
      DATE(
        EXTRACT(YEAR FROM DATE_ADD(s.date, INTERVAL es.sent_date DAY)),
        EXTRACT(MONTH FROM DATE_ADD(s.date, INTERVAL es.sent_date DAY)),
        1) AS sent_month,
      DATE_ADD(s.date, INTERVAL es.sent_date DAY) AS sent_date,
      es.id_account,
      es.id_message
    FROM `DA.email_sent` es
    JOIN `DA.account_session` acs
      ON es.id_account = acs.account_id
    JOIN `DA.session` s
      ON acs.ga_session_id = s.ga_session_id
  ),

  mials_sent_date AS ( -- calculate percentages, first and last sent date
    SELECT
      sent_month,
      id_account,
      ROUND(
        (
          COUNT(id_message)
            OVER (PARTITION BY id_account, sent_month)
          / COUNT(id_message)
            OVER (PARTITION BY sent_month))
          * 100,
        6) AS sent_msg_percent_from_this_month,
      MIN(sent_date)
        OVER (PARTITION BY id_account, sent_month) AS first_sent_date,
      MAX(sent_date)
        OVER (PARTITION BY id_account, sent_month) AS last_sent_date
    FROM
      mails_by_month
  )
SELECT DISTINCT
  sent_month,
  id_account,
  sent_msg_percent_from_this_month,
  first_sent_date,
  last_sent_date
FROM
  mials_sent_date
ORDER BY
  sent_month DESC
