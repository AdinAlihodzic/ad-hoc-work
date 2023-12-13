



-- use this script to run month end reporting for finance - in particular the echoice portfolio


---- 	Settlement Numbers
		
select 		
format(dateadd(month,-1,commission_date),'yyyyMM') as settlement_month		
, case when branch_id = 49900 then 'eChoice'		
		when group_id = 6348 then 'Finsure' 
		else 'Loankit' end as Loan_Group
, sum(case when Settlements_Flag = 'True' then original_balance else 0 end) as settlements		
, sum(case when loanbook_flag = 'True' then current_balance else 0 end) as Loanbook		
, sum(case when commission_type = 'trail' then current_balance else 0 end) as trailbook		
		
from warehouse.vwCommissionTransactions				
group by 		
format(dateadd(month,-1,commission_date),'yyyyMM')		
, case when branch_id = 49900 then 'eChoice'		
		when group_id = 6348 then 'Finsure' 
		else 'Loankit' end
;







-- More detailed view of settlements vs draw downs	
select 		
format(dateadd(month,-1,commission_date),'yyyyMM') as settlement_month		
, case when branch_id = 49900 then 'eChoice'		
		when group_id = 6348 then 'Finsure' 
		else 'Loankit' end as Loan_Group	
, branch_model_name
, sum(case when Settlements_Flag = 'True' then original_balance else 0 end) as settlements		
, sum(case when loanbook_flag = 'True' then current_balance else 0 end) as Loanbook		
, sum(case when commission_type = 'trail' and lender_type <> 'insurance' then current_balance else 0 end) as TrailBook		
--original/current balance opposite
-- , sum(case when Settlements_Flag = 'True' then current_balance else 0 end) as settlements_curr
-- , sum(case when loanbook_flag = 'True' then original_balance else 0 end) as Loanbook_orig
-- , sum(case when commission_type = 'trail' and lender_type <> 'insurance' then original_balance else 0 end) as TrailBook_orig
, sum(fee_charged_incl_gst) as fees_charged_inc_gst
from warehouse.vwCommissionTransactions		
group by 		
format(dateadd(month,-1,commission_date),'yyyyMM')		
, case when branch_id = 49900 then 'eChoice'		
		when group_id = 6348 then 'Finsure' 
		else 'Loankit' end
, branch_model_name
;		
		
	




-- eChoice Branch RCTI
select * from infinity.BranchRCTIs		
where branch_id = 49900		
and run_date in (		
'29520_Wed_Nov_29_2023',
'3173_Tue_Nov_28_2023'
)

		
	-- eChoice Referrer RCTI	
select * from infinity.ReferrerRCTI		
where run_date in (		
'29520_Wed_Nov_29_2023',
'3173_Tue_Nov_28_2023'
)	
and branch_id = 49900		
		



-- eChoice Referrer Transactions - to determine how much finsure earns form each trail loan in eChoice branch
select 		
format(cast(commission_date as date),'yyyyMM') as commission_month		
, case when branch_id = 49900 then 'echoice referrer' else '' end as referrer_type		
, case when branch_id = 49900 and referrer_name = 'Finsure' then 'Finsure Referrer' else 'echoice referrer' end as sub_referrer_type		
, comm_type		
, case when comm_amt < 0 then 'clawback' else 'Non-Clawback' end 	as clawback_flag	
, sum(comm_amt_paid_to_referrer_excl_gst) as comm_amt_paid_to_referrer_excl_gst		
, sum(comm_amt_paid_to_referrer_gst) as comm_amt_paid_to_referrer_gst		
, sum(comm_amt_paid_to_referrer_incl_gst) as comm_amt_paid_to_referrer_incl_gst		
from infinity.ReferrerTransactions		
where run_date in (		
'29520_Wed_Nov_29_2023',
'3173_Tue_Nov_28_2023'
)		
and branch_id = 49900		
group by 		
format(cast(commission_date as date),'yyyyMM')		
, case when branch_id = 49900 then 'echoice referrer' else '' end		
, case when branch_id = 49900 and referrer_name = 'Finsure' then 'Finsure Referrer' else 'echoice referrer' end		
, comm_type		
, case when comm_amt < 0 then 'clawback' else 'Non-Clawback' end 		
order by 1,2,3,4,5	
		




-- DE fIle 	
		
select * from infinity.DEFile	
where run_date in (		
'29520_Wed_Nov_29_2023',
'3173_Tue_Nov_28_2023'
)		
		
		

	


		
		
-- Fee Transaction information
select 		
format(commission_date,'yyyyMM')	
, run_date
, agent_type
, fee_type
, sum(amount_inc_gst)	fee_amount
from infinity.multipleFeeAssigned		
where format(commission_date,'yyyyMM') in ('202311')		
and agent_type in ('branch','group')		
group by 
format(commission_date,'yyyyMM')	
, run_date
, agent_type
, fee_type


-- check other fees are correct e.g. software etc.. 
select 
run_date
, sum(hvgFees_plus_gst) hvgFees_plus_gst
, sum(software_fees_plus_gst) software_fees_plus_gst
, sum(flat_fees_plus_gst) flat_fees_plus_gst
, sum(sms_fee_plus_gst) sms_fee_plus_gst
, sum(complianceFee_plus_gst) complianceFee_plus_gst
, sum(wh_fees_plus_gst) wh_fees_plus_gst
from infinity.branchRecords
where run_date in (
'28302_Tue_Oct_31_2023','16239_Mon_Oct_30_2023')
group by 
run_date




--- Analysis of month end financials 

select 
run_date
, sum(total_comm_received) total_received
, sum(branch_paid_amt_incl_gst + broker_paid_amt_incl_gst + referrer_amt_calc_incl_gst) total_payout
, sum(branch_opening_balance) branch_opening_balance
, sum(branch_closing_balance) branch_closing_balance
, sum(total_branch_fee_charged_incl_gst) total_branch_fee_charged_incl_gst
from infinity.branchRCTIs
where run_date in ('28302_Tue_Oct_31_2023','16239_Mon_Oct_30_2023')
group by 
run_date




select
cm_run_date
, sum(case when gstComm=0 then cm_commission_amt_plus_gst * 1.1 else cm_commission_amt_plus_gst end) gst_corrected
from infinity.commissionlines
where cm_run_date in ('28302_Tue_Oct_31_2023','16239_Mon_Oct_30_2023')
group by 
cm_run_date




select 
run_date
, sum(commission_amount_gst + commission_amount_minus_gst) as comm_plus_gst
, sum(processed_comm_amt_incl_gst) as processed_comm
from infinity.CommissionTransactions
where run_date in ('28302_Tue_Oct_31_2023','16239_Mon_Oct_30_2023')
group by 
run_date




select * from infinity.executiveCommRecords
where run_date in ('28302_Tue_Oct_31_2023','16239_Mon_Oct_30_2023')




		
select 		
format(commission_date,'yyyyMM')		
, sum(complianceFee_plus_gst)		complianceFee_plus_gst
, sum(software_fees_plus_gst)	software_fees_plus_gst	
, sum(hvgFees_plus_gst)		hvgFees_plus_gst
, sum(sms_fee_plus_gst)		sms_fee_plus_gst
, sum(flat_fees_plus_gst)		flat_fees_plus_gst
from infinity.branchRecords		
where format(commission_date,'yyyyMM') >=202211	
group by 		
format(commission_date,'yyyyMM')		
		
order by 1		
		
		
		

		
select 		
*		
from infinity.branchRecords		
where run_date in (		
'8904_Wed_Jun_29_2022',		
'23967_Tue_Jun_28_2022'		
)		
and branch_id = 49900		
		
		
		
		
select 		
*		
from infinity.ReferrerTransactions		
where run_date in ('5002_Tue_Aug_30_2022')		
and branch_id = 49900		
		
		
		
select 		
*		
from infinity.ReferrerRCTI		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and branch_id = 49900		
		
		
		
		
select * from [infinity].[referrer_commission_rec]		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and branch_id = 49900		
		
		
		
select * from [infinity].[referrerRecords]		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and branch_id = 49900		
		
		
		
select * from [infinity].[ReferrerTransactions]		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and branch_id = 49900		
		
		
		
select * from infinity.FeeTransactions		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and branch_id = 49900		
		
		
		
		
		
		
select * from [BusinessIntelligence].[vwNG_Apps_TimeTo_Conditional]		
		
		
		
		
select 		
*		
from infinity.FeeTransactions		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and fee_type = 'AFCA'		
		
		
		
		
select 		
sum(cm_settled_amount)		
from infinity.commissionlines		
where cm_run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and branch_id = 54309		
and cm_commType = 'upfront'		
		
3340523.83		
		
;		
		
select 		
bank_name		
, lender_type		
, broker_name		
, sum(original_balance)		
from infinity.CommissionTransactions		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and broker_user_id = 7179		
and commission_type = 'upfront'		
group by 		
bank_name		
, lender_type		
, broker_name		
		
		
		
select 		
sum(original_balance)		
from infinity.CommissionTransactions		
where run_date in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
and broker_user_id = 7179		
and commission_type = 'upfront'		
		
		
		
		
		
		
		
select * from warehouse.vwLenders		
		
select * from [warehouse].[vwCommissionTransactions]		
where  in ('8904_Wed_Jun_29_2022','23967_Tue_Jun_28_2022')		
		
		
		
		
		
		
		
		
		
select 		
commission_month		
, sum(original_balance)		
from [warehouse].[vwCommissionTransactions]		
where commission_type = 'upfront'		
and bank_code = 'FMC'		
group by 		
commission_month		
		
		
		
		
select 		
commission_month		
, sum(original_balance)		
from [warehouse].[vwCommissionTransactions]		
where commission_type = 'upfront'		
group by 		
commission_month		
order by 1		
		
		
		
		
		
		
		
select 		
format(cm_commission_date,'yyyyMM')		
, bank_fullname		
, cm_bank_code		
, sum(cm_settled_amount)		
from infinity.commissionlines		
where cm_commType = 'upfront'		
group by 		
format(cm_commission_date,'yyyyMM')		
, bank_fullname		
, cm_bank_code		
		
		
		
		
		
		
		
		
		
-- 	
		
		
select 		
cm_run_date		
, bank_fullname		
, case when group_id = 6348 then 'Finsure' else 'Loankit' end as group_name		
, sum(cm_commission_amt_plus_gst) as commission_income_from_lender		
, sum(cm_remit_amount_branch) - sum(cm_payment_amt_plus_gst_broker) - (sum(cm_payment_amt_plus_gst_ref1) + sum(cm_payment_amt_plus_gst_ref2) + sum(cm_payment_amt_plus_gst_ref3)) eligable_payments_to_branch		
, sum(cm_payment_amt_plus_gst_broker) eligable_payments_to_broker		
, sum(cm_payment_amt_plus_gst_ref1) + sum(cm_payment_amt_plus_gst_ref2) + sum(cm_payment_amt_plus_gst_ref3) eligable_payments_to_referrer		
, sum(fast_fee)
from infinity.commissionlines		
where format(cm_commission_date,'yyyyMM') = '202208'		
group by 		
cm_run_date		
, bank_fullname		






-- lodgements and settlements and commission settlements 



select 
format(dateadd(month,-1,commission_date),'yyyyMM') as settlement_month		
, bank_name
, sum(case when Settlements_Flag = 'True' then original_balance else 0 end) as settlements		
, sum(case when loanbook_flag = 'True' then current_balance else 0 end) as Loanbook		
		
from warehouse.vwCommissionTransactions		
group by 		
format(dateadd(month,-1,commission_date),'yyyyMM')		
, bank_name
;		






select 
format(StatusDate,'yyyyMM') as year_month
, ApplicationType
, Status
, sum(LoanAmount)
from warehouse.vw_dwf_nextgen_loan_data_comb
where Status in ('Application Sent','Unconditionally Approved','Application Settled')
group by 
format(StatusDate,'yyyyMM')
, ApplicationType
, Status



select
branch_id
, name
from infinity.BrokersBranches
where archive = 'no'



select
distinct run_date  
from infinity.FeeTransactions
where run_date in ('14678_Mon_Oct_31_2022')	
and agent_type in ('branch','group')




select 
fee_type
, agent_type
, sum(amount_inc_gst)
from infinity.FeeTransactions
where run_date in ('17892_Fri_Oct_28_2022')	
and agent_type in ('branch','group')
group by 
fee_type
, agent_type



select * from infinity.CustomerFees as base
left join infinity.CustomerFeeTypes as t
on base.fee_type_id = t.fee_type_id
	and t.archive = 'no'
where customer_id = 6749
and charge_fee = 'yes'
and base.fee_type_id = 27




select * from infinity.commissionlines
where cm_commRefID = '6500649'
order by cm_commission_date desc


select * from warehouse.vwBrokerProfile







select
format(dateadd(month,-1,ct.commission_date),'yyyyMM') settlement_month
, bp.broker_TradingState
, bp.Parent_branch_name
, bp.broker_name
, DATEDIFF(month, bp.broker_DOB, GETDATE()) as Broker_Age_Months
, DATEDIFF(month, bp.broker_start_date, GETDATE()) as Broker_Tenure_Months
, num_brokers.number_active_brokers
, sum(ct.original_balance) as Settlement_amount
from warehouse.vwCommissionTransactions as ct
left join warehouse.vwBrokerProfile as bp
on ct.broker_id = bp.broker_id
left join (
			SELECT
					Parent_branch_name
					, parent_branch_id
					, count(broker_id) as number_active_brokers
					from warehouse.vwBrokerProfile as bp
					where demo_branch_account = 'NO'
					and staff_broker = 0
					and broker_status = 'active'
					group by 
					Parent_branch_name
					, parent_branch_id
					) as num_brokers
					on num_brokers.parent_branch_id = bp.parent_branch_id
where ct.Settlements_Flag = 'TRUE'
group by 
format(dateadd(month,-1,ct.commission_date),'yyyyMM')
, bp.broker_TradingState
, bp.Parent_branch_name
, bp.broker_name
, DATEDIFF(month, bp.broker_DOB, GETDATE())
, DATEDIFF(month, bp.broker_start_date, GETDATE())
, num_brokers.number_active_brokers





select
format(dateadd(month,-1,ct.cm_commission_date),'yyyyMM') settlement_month
, bp.Parent_branch_name
, bp.broker_name
, bp.broker_TradingState
, bp.broker_status
, sum(ct.cm_settled_amount) as Settlement_amount
from infinity.commissionlines as ct
left join warehouse.vwBrokerProfile as bp
on ct.cm_brokerid = bp.broker_user_id

group by 
format(dateadd(month,-1,ct.cm_commission_date),'yyyyMM')
, bp.Parent_branch_name
, bp.broker_name
, bp.broker_TradingState
, bp.broker_status



-- commercail settlements 
select
format(dateadd(month,-1,ct.cm_commission_date),'yyyy') settlement_year
, sum(ct.cm_settled_amount) as Settlement_amount
, sum(ct.cm_settled_amount)/count(distinct cm_brokerid) average_settlement_per_broker
, sum(ct.cm_settled_amount)/count(distinct cm_commRefID) average_settlement_per_month
, count(distinct cm_brokerid) as number_commercial_loan_writers
from infinity.commissionlines as ct
where format(dateadd(month,-1,ct.cm_commission_date),'yyyy') >= 2020
and lender_type = 'commercial'
group by 
format(dateadd(month,-1,ct.cm_commission_date),'yyyy')
order by 1




SELECT
Parent_branch_name
, parent_branch_id
, count(broker_id)
from warehouse.vwBrokerProfile as bp
where demo_branch_account = 'NO'
and staff_broker = 0
and broker_status = 'active'
group by 
Parent_branch_name
, parent_branch_id
order by 3 desc





select * from warehouse.vwWikiBrokerExtracts
where wiki_extract like ('%postcode falls under%')




select * from warehouse.vwBrokerProfile
where broker_user_id = 34076




select 
format(created,'yyyyMM') created_month
, count(*)
from infinity.applications
where draft = 'no'
and hide_record = 'no'
and archive = 'no'
group by 
format(created,'yyyyMM')




select
ct.cm_commission_date
, ct.bank_fullname
, ct.cm_commType as commission_type
, sum(ct.cm_commission_amt) as cm_commission_amt
, sum(ct.cm_commission_amt_plus_gst) as cm_commission_amt_plus_gst
, sum(ct.cm_fast_fee) as retained_commissions
, sum(ct.cm_fast_fee_plus_gst) as retained_commissions_plus_gst
, sum(ct.cm_commission_amt_plus_gst - ct.cm_fast_fee_plus_gst) as commission_expense_plus_gst
from infinity.commissionlines as ct
where format(ct.cm_commission_date,'yyyyMM') = '202311'
group by 
ct.cm_commission_date
, ct.bank_fullname
, ct.cm_commType













select 
base.TheDate
, cast(getdate() as date) as upto_Date
, workingDays.NumberOfWorkingDays
, TotalLogins
, ValueInfinityApps
, ValueLodgments
, settlement_amount
from warehouse.vwCalenderTable as base
left join (
            select
            eomonth(cast(NG_StatHist_First_AppSent_StatusDateTime as date)) as lodgement_date
            , sum(NG_Appl_LoanAmount) as ValueLodgments
            , count(*) as Lodgements
            from warehouse.vwApplication_life_cycle as app
            where app.NG_StatHist_First_AppSent_Flag = 1
            group by 
            eomonth(cast(NG_StatHist_First_AppSent_StatusDateTime as date))
            ) as lodgements
            on lodgements.lodgement_date = base.TheDate
left join (
            select 
            eomonth(cast(ul.Created as date)) as LoginDate
            , count(*) as TotalLogins
            , count(distinct ul.user_individual_id) as DistinctBrokerLogins
            from infinity.UserLogins as ul
                INNER join infinity.Users as u
                on u.individual_id = ul.user_individual_id
                and u.archive = 'NO'
                and u.user_type = 'Broker'
            where ul.archive = 'NO'

            group by
            eomonth(cast(ul.Created as date))
            ) as InfinityLogins
            on InfinityLogins.LoginDate = base.TheDate
left join (
            select
            eomonth(cast(created as date)) as AppCreate_date
            , sum(NG_Appl_LoanAmount) as ValueInfinityApps
            , count(*) as InfinityApps
            from warehouse.vwApplication_life_cycle as app
            where hide_record = 'NO'
            and draft = 'NO'
            and archive = 'NO'
            group by 
            eomonth(cast(created as date))
            ) as infinityApps
            on infinityApps.AppCreate_date = base.TheDate

left join (
            select 
            eomonth(TheDate) as [Date]
            , count(*) as NumberOfWorkingDays
            from warehouse.vwCalenderTable
            where IsWeekend = 0
            and IsHoliday = 0
            group by eomonth(TheDate)
            ) as workingDays
            on workingDays.[Date] = base.TheDate

left join (
            select 
            eomonth(dateadd(month,-1,ct.commission_date)) as Settlement_Month
            , sum(ct.original_balance) as settlement_amount
            from warehouse.vwCommissionTransactions as ct
            where ct.Settlements_Flag = 'TRUE'
            group by 
            eomonth(dateadd(month,-1,ct.commission_date))
            ) as settl
            on settl.Settlement_Month = base.TheDate

where base.TheDate > '2018-01-01'
and eomonth(base.TheDate) <= eomonth(dateadd(month,-1,GETDATE()))
and workingDays.NumberOfWorkingDays is not null
order by base.TheDate 






select
format(created,'yyyyMM')
, lender_reference
, count(*)
, sum(amount)
from warehouse.vwApplication_life_cycle
group by 
format(created,'yyyyMM')
, lender_reference






select 
base.TheDate
, cast(getdate() as date) as upto_Date
, workingDays.NumberOfWorkingDays
, TotalLogins
, ValueInfinityApps
, ValueLodgments
, settlement_amount
from warehouse.vwCalenderTable as base
left join (
            select
            eomonth(cast(NG_StatHist_First_AppSent_StatusDateTime as date)) as lodgement_date
            , sum(NG_Appl_LoanAmount) as ValueLodgments
            , count(*) as Lodgements
            from warehouse.vwApplication_life_cycle as app
            where app.NG_StatHist_First_AppSent_Flag = 1
            group by 
            eomonth(cast(NG_StatHist_First_AppSent_StatusDateTime as date))
            ) as lodgements
            on lodgements.lodgement_date = base.TheDate
left join (
            select 
            eomonth(cast(ul.Created as date)) as LoginDate
            , count(*) as TotalLogins
            , count(distinct ul.user_individual_id) as DistinctBrokerLogins
            from infinity.UserLogins as ul
                INNER join infinity.Users as u
                on u.individual_id = ul.user_individual_id
                and u.archive = 'NO'
                and u.user_type = 'Broker'
            where ul.archive = 'NO'

            group by
            eomonth(cast(ul.Created as date))
            ) as InfinityLogins
            on InfinityLogins.LoginDate = base.TheDate
left join (
            select
            eomonth(cast(created as date)) as AppCreate_date
            , sum(NG_Appl_LoanAmount) as ValueInfinityApps
            , count(*) as InfinityApps
            from warehouse.vwApplication_life_cycle as app
            where hide_record = 'NO'
            and draft = 'NO'
            and archive = 'NO'
            group by 
            eomonth(cast(created as date))
            ) as infinityApps
            on infinityApps.AppCreate_date = base.TheDate
left join (
            select 
            eomonth(TheDate) as [Date]
            , count(*) as NumberOfWorkingDays
            from warehouse.vwCalenderTable
            where IsWeekend = 0
            and IsHoliday = 0
            group by eomonth(TheDate)
            ) as workingDays
            on workingDays.[Date] = base.TheDate
left join (
            select 
            eomonth(dateadd(month,-1,ct.commission_date)) as Settlement_Month
            , sum(ct.original_balance) as settlement_amount
            from warehouse.vwCommissionTransactions as ct
            where ct.Settlements_Flag = 'TRUE'
            group by 
            eomonth(dateadd(month,-1,ct.commission_date))
            ) as settl
            on settl.Settlement_Month = base.TheDate

where base.TheDate > '2018-01-01'
and eomonth(base.TheDate) <= eomonth(dateadd(month,-1,GETDATE()))
and workingDays.NumberOfWorkingDays is not null
order by base.TheDate 







select 
dateadd(day, - day(base.TheDate) + 1,base.TheDate) as TheDate
, cast(getdate() as date) as upto_Date
, workingDays.NumberOfWorkingDays
, TotalLogins
, ValueInfinityApps
, ValueLodgments
, settlement_amount
from warehouse.vwCalenderTable as base
left join (
            select
            eomonth(cast(NG_StatHist_First_AppSent_StatusDateTime as date)) as lodgement_date
            , sum(NG_Appl_LoanAmount) as ValueLodgments
            , count(*) as Lodgements
            from warehouse.vwApplication_life_cycle as app
            where app.NG_StatHist_First_AppSent_Flag = 1
            group by 
            eomonth(cast(NG_StatHist_First_AppSent_StatusDateTime as date))
            ) as lodgements
            on lodgements.lodgement_date = base.TheDate
left join (
            select 
            eomonth(cast(ul.Created as date)) as LoginDate
            , count(*) as TotalLogins
            , count(distinct ul.user_individual_id) as DistinctBrokerLogins
            from infinity.UserLogins as ul
                INNER join infinity.Users as u
                on u.individual_id = ul.user_individual_id
                and u.archive = 'NO'
                and u.user_type = 'Broker'
            where ul.archive = 'NO'

            group by
            eomonth(cast(ul.Created as date))
            ) as InfinityLogins
            on InfinityLogins.LoginDate = base.TheDate
left join (
            select
            eomonth(cast(created as date)) as AppCreate_date
            , sum(NG_Appl_LoanAmount) as ValueInfinityApps
            , count(*) as InfinityApps
            from warehouse.vwApplication_life_cycle as app
            where hide_record = 'NO'
            and draft = 'NO'
            and archive = 'NO'
            group by 
            eomonth(cast(created as date))
            ) as infinityApps
            on infinityApps.AppCreate_date = base.TheDate
left join (
            select 
            eomonth(TheDate) as [Date]
            , count(*) as NumberOfWorkingDays
            from warehouse.vwCalenderTable
            where IsWeekend = 0
            and IsHoliday = 0
            group by eomonth(TheDate)
            ) as workingDays
            on workingDays.[Date] = base.TheDate
left join (
            select 
            eomonth(dateadd(month,-1,ct.commission_date)) as Settlement_Month
            , sum(ct.original_balance) as settlement_amount
            from warehouse.vwCommissionTransactions as ct
            where ct.Settlements_Flag = 'TRUE'
            group by 
            eomonth(dateadd(month,-1,ct.commission_date))
            ) as settl
            on settl.Settlement_Month = base.TheDate

where base.TheDate > '2020-01-01'
and eomonth(base.TheDate) <= eomonth(GETDATE())
and workingDays.NumberOfWorkingDays is not null
order by base.TheDate 






