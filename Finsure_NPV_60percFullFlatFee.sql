
-- updated NPV ETL to reflect capture of 60% of total lfat fee (head broker + sub brokers) 



drop table #earliest_commission_date;

Declare @Commission_run_month as char(6);
Declare @number_of_days as int

set @Commission_run_month = '202311';
set @number_of_days= 31


-- what was the earliest commission date that we noticed on the loan
select cm_commRefID 
, cm_bank_code 
, min(cm_commission_date) as min_commission_date 
into #earliest_commission_date
from infinity.CommissionLines as a 
where format(cm_commission_date, 'yyyyMM') = @Commission_run_month
and a.cm_commType in ('upfront','trail') 
and a.lender_type <> 'insurance' 
group by
cm_commRefID 
, cm_bank_code;


drop table #NPV_data_input;

-- capped at 60% of total flat fee
select
npv.commission_id
, npv.loan_account_number
, npv.application_id
, npv.split_number
, npv.bank_code
, npv.bank_name
, npv.settlement_date
, npv.Loan_Tenure_months
, npv.original_balance
, npv.current_balance
, npv.Group_Name
, npv.branch_model_name
, npv.commission_date
, npv.fee_charged_excl_gst
, npv.flat_fee
, (case when sum(flat_fee_to_transactional) over (partition by branch_id order by commission_id)<=420 then flat_fee_to_transactional else 0 end) as flat_fee_to_transactional_new
, npv.branch_id
, npv.branch_company_name
, npv.broker_user_id
, npv.processed_comm_amt_incl_gst
, case when branch_model_name = 'flatfee' then flat_fee_per_traildollar * current_balance else 0 end as loan_level_flatfee
, lender_income_plus_flatfee
, npv.correct_payout_dollars
, coalesce(((npv.processed_comm_amt_incl_gst/nullif(npv.current_balance,0))/@number_of_days) * 365 * 100,0) as Lender_Rate
, case when branch_model_name = 'flatfee' then coalesce(((lender_income_plus_flatfee/nullif(npv.current_balance,0))/@number_of_days) * 365 * 100,0) else coalesce(((npv.processed_comm_amt_incl_gst/nullif(npv.current_balance,0))/@number_of_days) * 365 * 100,0) end as Lender_Rate_plus_flatfee
, coalesce((correct_payout_dollars)/nullif(lender_income_plus_flatfee,0),0) * 100 as Broker_Rate
into #NPV_data_input
from (
select
cm.commission_id
, cm.loan_account_number
, cm.application_id
, row_number() over (partition by cm.application_id order by cm.commission_id asc) as split_number
, cm.bank_code
, cm.bank_name
, cm.settlement_date
, DATEDIFF(MONTH,EOMONTH(case when cm.settlement_date is null or cast(cast(cm.settlement_date as date) as varchar) = '0000-00-00' then loan_start_dates.min_commission_date
		when cm.settlement_date > cm.commission_date then loan_start_dates.min_commission_date
		else cm.settlement_date end), EOMONTH(DATEADD(month,-1,cm.commission_date))) + 1 as Loan_Tenure_months
, cm.original_balance
, cm.current_balance
, case when cm.group_id = 6348 then 'Finsure' else 'Loankit' end as Group_Name
, cm.branch_model_name
, cast(cm.commission_date as date) as commission_date
, cm.fee_charged_excl_gst
, cm.flat_fee
, case when cm.branch_model_name = 'flatfee' and row_number() over (partition by cm.application_id order by cm.commission_id asc) = 1 then 5.50 else 0 end as flat_fee_to_transactional
, cm.branch_id
, cm.branch_company_name
, cm.broker_user_id
, cm.processed_comm_amt_incl_gst
, flat_fee_distribution.flat_fee_per_traildollar
, case when cm.branch_model_name = 'flatfee' then processed_comm_amt_incl_gst + coalesce(flat_fee_per_traildollar * current_balance,0) else processed_comm_amt_incl_gst end as lender_income_plus_flatfee
, case when cm.branch_id = '6644' then cm.paid_to_broker_incl_gst else cm.remitted_branch_incl_gst end as correct_payout_dollars
from infinity.CommissionTransactions as cm
left join #earliest_commission_date as loan_start_dates
		on cm.loan_account_number = loan_start_dates.cm_commRefID
		and cm.bank_code = loan_start_dates.cm_bank_code

left join (select base.branch_id
					, sum(base.current_balance) as total_br_book
					, max(flat_fee.total_flat_fee) as branch_flat_fee_60perc
					, coalesce(max(flat_fee.total_flat_fee)/nullif(sum(base.current_balance),0),0) as flat_fee_per_traildollar
					from infinity.CommissionTransactions as base
					left join (
								select branch_id
								, sum(flat_fees_plus_gst) * 0.6 as total_flat_fee
								from infinity.branchRecords as br
								where format(commission_date,'yyyyMM') = @Commission_run_month
								and branch_id <> '49900'
								group by branch_id
								) as flat_fee
								on base.branch_id = flat_fee.branch_id
					where format(commission_date,'yyyyMM') = @Commission_run_month
					and base.commission_type = 'trail'
					and base.branch_model_name = 'flatfee'
					and base.lender_type <> 'insurance'
					group by 
					base.branch_id
			) as flat_fee_distribution
			on flat_fee_distribution.branch_id = cm.branch_id

where format(cm.commission_date,'yyyyMM') = @Commission_run_month
        and cm.commission_type = 'trail'
        and cm.lender_type <> 'insurance'
		----
		and cm.branch_id <> '49900'
) as npv
;



select * from #NPV_data_input;
