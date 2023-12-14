




select 
parent_branch_id
, Parent_branch_name
, broker_name
, broker_id


from warehouse.vwBrokerProfile as bp
left join infinity.BrokersBranches as bb
on bb.branch_id = bp.parent_branch_id
and bb.archive = 'no'








select 
*
from warehouse.vwBrokerProfile as bp
where branch_id = 30346




select * from infinity.BrokersBranches
where branch_id = 71654






where branch_id in (
                select 
                branch_id
                from infinity.BrokersBranches as bb
                where parent_id is NULL
                and [status] = 'active'
                )






select top 100 *  from infinity.commissionlines
where br_branch_name like ('%Murdoch%')





select 
bb.branch_id
, bb.name
, bb.[type]
, bb.[status]
, bb.email
, c.company_name
, s.trading_name
, p.trading_name
, bb.branch_start_date
, bb.created as branch_created_on
from infinity.BrokersBranches as bb
left join infinity.Companies as c
    on c.company_id = bb.company_id
    and c.archive = 'no'
left join infinity.SoleTraders as s
    on s.soletrader_id = bb.soletrader_id
    and s.archive = 'no'
left join infinity.Partnerships as p
    on p.partnership_id = bb.partnership_id
    and p.archive = 'no'
where bb.[status] = 'active'





select
branch_id
, branch_company_name
, sum(current_balance) as Trail_book
from warehouse.vwCommissionTransactions
where commission_type = 'Trail'
and format(commission_date,'yyyyMM') = '202311'
group by 
branch_id
, branch_company_name






select 
bb.email
from infinity.BrokersBranches as bb
left join infinity.Companies as c
    on c.company_id = bb.company_id
    and c.archive = 'no'
left join infinity.SoleTraders as s
    on s.soletrader_id = bb.soletrader_id
    and s.archive = 'no'
left join infinity.Partnerships as p
    on p.partnership_id = bb.partnership_id
    and p.archive = 'no'

where bb.branch_id = 9498
and bb.[status] = 'active'




select * from warehouse.vwBrokerProfile as bp
left join infinity.BrokerServices as bs
on bs.broker_id = bp.broker_id
where bs.archive = 'no'
and bs.access_commission_now = 'yes'



