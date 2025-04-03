{{ config(
    materialized='table'
) }}


SELECT
    COALESCE(t.date, ut.date) AS date,
    ci.created_at_datetime AS download_date,
    ci.date_issued AS account_issued_date,
    MIN(t.date) OVER (PARTITION BY t.sender_id) AS first_deposit_date,
    t.sender_first_name,
    t.sender_last_name,
    t.sender_email,
    t.sender_user_name, ci.status_from_cards,
    COALESCE(t.sender_id, ut.sender_id) AS sender_id,
    t.sender_phone_number,
    COALESCE(
    SAFE_CAST(t.sender_amount.integer AS FLOAT64),
    SAFE_CAST(t.sender_amount.float AS FLOAT64),
    SAFE_CAST(t.sender_amount.string AS FLOAT64)
) AS sender_amount,

    t.sender_name,
    DATE_DIFF( ci.date_issued, ci.created_at_datetime, DAY) AS Download_to_Account_Issued_in_days,
    DATE_DIFF(MIN(t.date) OVER (PARTITION BY t.sender_id), ci.date_issued, DAY) AS Account_Issued_to_1st_Deposit_in_days,
    DATE_DIFF(MIN(t.date) OVER (PARTITION BY t.sender_id), ci.created_at_datetime, DAY) AS Download_to_1st_Deposit_in_days,

    t.sender_reference,
    COALESCE(
        SAFE_CAST(t.fees.integer AS FLOAT64),
        t.fees.float
    ) AS fees,
    t.cash_advance_amount,
    COALESCE(SAFE_CAST(t.cash_advance_amount_owing.integer AS FLOAT64), t.cash_advance_amount_owing.float) AS cash_advance_amount_owing,
    COALESCE(SAFE_CAST(t.cash_advance_amount_paid.integer AS FLOAT64), t.cash_advance_amount_paid.float) AS cash_advance_amount_paid,
    COALESCE(SAFE_CAST(t.cash_advance_available_after.integer AS FLOAT64), t.cash_advance_available_after.float) AS cash_advance_available_after,
    COALESCE(SAFE_CAST(t.cash_advance_available_before.integer AS FLOAT64), t.cash_advance_available_before.float) AS cash_advance_available_before,
    t.cash_advance_fees,
    t.cash_advance_owed_after,
    COALESCE(t.cash_advance_fees_charged.float, SAFE_CAST(t.cash_advance_fees_charged.integer AS FLOAT64)) AS cash_advance_fees_charged,
    COALESCE(t.cash_advance_outstanding_amount.float, SAFE_CAST(t.cash_advance_outstanding_amount.integer AS FLOAT64)) AS cash_advance_outstanding_amount,
    COALESCE(t.cash_advance_owed_before.float, SAFE_CAST(t.cash_advance_owed_before.integer AS FLOAT64)) AS cash_advance_owed_before,
    COALESCE(t.cash_advance_total_owed.float, SAFE_CAST(t.cash_advance_total_owed.integer AS FLOAT64)) AS cash_advance_total_owed,
    t.cash_express_reference_id,
    t.cash_express_voucher_number,
    t.cash_express_voucher_status,
    t.voucher_code,
    t.refunded_by_id,
    t.refunded_by_name,
    t.refunded_by_phone_number,
    t.meter_number,
    t.reference,
    t.one_voucher_account_number,
    t.one_voucher_reference,
    t.one_voucher_serial_number,
    t.one_voucher_transaction_id,
    t.one_voucher_voucher_number,
    t.transaction_reference_id,
    t.receiver_account_number,
    COALESCE(SAFE_CAST(t.receiver_amount.integer AS FLOAT64), t.receiver_amount.float) AS receiver_amount,

    t.receiver_bank_id,
    t.receiver_bank_name,
    t.receiver_first_name,
    t.receiver_id,
     t.receiver_is_in_kasi,
    t.receiver_is_verified,
    t.receiver_last_name,
    t.receiver_name,
    t.receiver_phone_number,
    t.receiver_reference,
    t.receiver_user_name,
    t.electricity_voucher,


    COALESCE(t.merchant_id, ut.merchant_id) as merchant_id,
    t.franc_external_customer_id,
    t.franc_id,
    t.franc_reference,
    t.business_email,
    t.business_id,
    t.business_name,
    t.business_phone_number,
    COALESCE(t.state, ut.state) AS state,
    t.invoice_number,
     t.vault_id,
    used_credit,
    COALESCE(SAFE_CAST(t.debit.integer AS FLOAT64), t.debit.float, SAFE_CAST(ut.debit.integer AS FLOAT64), ut.debit.float) AS debit,
    COALESCE(SAFE_CAST(t.credit.integer AS FLOAT64), t.credit.float, SAFE_CAST(ut.credit AS FLOAT64)) AS credit,
    COALESCE(t.transaction_id, ut.transaction_id) AS transaction_id,
    COALESCE(t.transaction_type, ut.transaction_type) AS transaction_type,
    t.transaction_seen,
    t.goal_identifier,
    COALESCE(t.date_settled, ut.date_settled) AS date_settled,
    t.deposited_by,
    t.deposited_by_id,
    t.payment_reference,
    t.savings_id,
    t.savings_name,
    t.franc_transaction_id,
    t.transaction_redeemed,
    COALESCE(CAST(t.running_account_balance_before_payment.integer AS FLOAT64), t.running_account_balance_before_payment.float ) as running_account_balance_before_payment,
    COALESCE(CAST(t.running_account_balance_after_payment.integer AS FLOAT64), t.running_account_balance_after_payment.float) as running_account_balance_after_payment,
    ci.billing_account_type,
    CASE
        WHEN t.transaction_type = 'flexpay'
             AND (COALESCE(SAFE_CAST(t.credit.integer AS FLOAT64), t.credit.float) != 0)
        THEN 'Deposit'
        WHEN t.transaction_type = 'flexpay'
             AND (COALESCE(SAFE_CAST(t.debit.integer AS FLOAT64), t.debit.float) != 0)
        THEN 'Card Transactions Volume'

        WHEN t.transaction_type = 'invoice' THEN 'Deposit Volume'
        WHEN t.transaction_type = 'advance_payback' THEN 'Lending Repayment'
        WHEN t.transaction_type = 'advance_transfer' THEN 'Lending Volume'
        WHEN t.transaction_type = 'credit_transfer' THEN 'Lending Volume'
        WHEN t.transaction_type = 'salary' THEN 'Deposit'
        WHEN t.transaction_type = 'advance_issued' THEN 'Total Credit Limit'
        WHEN t.transaction_type = 'credit_payment' THEN 'Lending Revenue'
        WHEN t.transaction_type = 'card_replacement_at_branch' THEN 'Once-off Revenue'
        WHEN t.transaction_type = 'monthly_account_fee' THEN 'Subscription Revenue'
        WHEN t.transaction_type = 'account_deposit' THEN 'Deposit'
        WHEN t.transaction_type = 'one_voucher_redeem' THEN 'Deposit'
         WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type is null THEN 'Transfers'
        WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'PROFESSIONAL' THEN 'Transfers'
         WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'FREE' THEN 'Transfers'
        WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'BASIC'  THEN 'Transfers Revenue'
        WHEN t.transaction_type = 'absa_atm_deposit' THEN 'Deposit'
        WHEN t.transaction_type = 'kasi_to_kasi' THEN 'No Revenue (Transfers)'
        WHEN t.transaction_type = 'airtime_purchase' THEN 'VAS'
        WHEN t.transaction_type = 'pargo_card_order' THEN 'Other'
        WHEN t.transaction_type = 'one_voucher_purchase' THEN 'VAS'
        WHEN t.transaction_type = 'card_order_fee' THEN 'Once-off Revenue'
        WHEN t.transaction_type = 'electricity_purchase' THEN 'VAS'
        WHEN t.transaction_type = 'water_meter_purchase' THEN 'VAS'
        WHEN t.transaction_type = 'takealot' THEN 'VAS'
        WHEN t.transaction_type = 'card_replacement_with_pargo' THEN 'Once-off Revenue'
        WHEN t.transaction_type = 'card_replacement' THEN 'Once-off Revenue'
        WHEN t.transaction_type = 'card_replacement_fee' THEN 'Once-off Revenue'
        WHEN t.transaction_type = 'cash_express' THEN 'Volume Based Revenue'
        WHEN t.transaction_type = 'savings_deposit' THEN 'Investment'
        WHEN t.transaction_type = 'savings_cashout' THEN 'Investment Withdrawal'
        WHEN t.transaction_type = 'vault_deposit' THEN 'Investment'
        WHEN t.transaction_type = 'savings_auto_deposit' THEN 'Investment'
        WHEN t.transaction_type = 'vault_cashout' THEN 'Investment Withdrawal'
        ELSE 'Unknown'
    END AS transaction_category,
    CASE
        WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'BASIC' THEN 8.50
        WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'FREE' THEN 0.00
        WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'PROFESSIONAL' THEN 0.00
        ELSE 0.00
    END AS revenue_bank_eft,
    CASE
    -- For categories with volume-based revenue, subscription revenue, once-off revenue, and lending revenue
    WHEN t.transaction_type IN ("cash_express", "monthly_account_fee", "card_order_fee", "card_replacement_with_pargo", "card_replacement", "card_replacement-fee", "card_replacement_at_branch", "credit_payment")
    THEN COALESCE(SAFE_CAST(t.debit.integer AS FLOAT64), t.debit.float)

    -- For bank EFT transactions with a BASIC plan, assign a fixed value of 8.50
    WHEN t.transaction_type = 'bank_eft' AND ci.billing_account_type = 'BASIC' THEN 8.50
    -- Default case for other transactions
    ELSE 0
  END AS mrr_amount,
  CASE
  WHEN t.transaction_type IN ("airtime_purchase", "one_voucher_purchase", "electricity_purchase", "water_meter_purchase", "takealot")
  THEN COALESCE(SAFE_CAST(t.debit.integer AS FLOAT64), t.debit.float) * 0.025

  WHEN t.transaction_type = "one_voucher_redeem"
  THEN COALESCE(SAFE_CAST(t.credit.integer AS FLOAT64), t.credit.float) * 0.05

  ELSE 0  -- Ensure all cases are covered
END AS VAS_revenue

 FROM    `kasi-production.kasi_datainfra_firestore_export_from_gcs.transactions` AS t
FULL OUTER JOIN
    `kasi-production.kasi_datainfra_firestore_export_from_gcs.uncleared_transactions` AS ut
ON
    t.transaction_id = ut.transaction_id
LEFT JOIN `kasi-production.kasi_datainfra_all_tables.customers_info` AS ci
ON LOWER(t.sender_name) = LOWER(ci.full_name_source_customer_collection)
