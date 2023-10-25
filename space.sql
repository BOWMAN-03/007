--	--preview of all tables in this set
--select * from personnel
--select * from vessel
--select * from cost
--select * from fund


--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

	-- "HR" related section
	-- uses 2 tables


	--0. join + preview the data relevant to personnel
select top 3 * from clist
full join cscore
	on clist.ID = cscore.ID;

	-- 1. get highest 2 scoring cadets.... using cte+join.. casts tinyint to int
with cte_scores as (select pft, spvbt, cast(stage_3 as int) as 'stage1', cast(stage_2 as int) as 'stage2', cast(stage_1 as int) as 'stage3', ID as 'ID'
from Cscore)
select top 2 sum(clist.years_of_service) as Years_Served, clist.state as State, sum(pft) as PFT, sum(spvbt) as SPVBT, clist.name as Name, SUM(
	isnull(stage3,0)
	+ isnull(stage2,0)
	+ isnull(stage1,0)) as 'total score' 
from cte_scores
full outer join clist
	on clist.id = cte_scores.id
group by name, state
order by 'total score' desc;

	-- 2. get counts of how many cadets passed each stage of training/testing
select count(stage_1) as stage1, count(stage_2) as stage2, count(stage_3) as stage3
from Cscore;

	-- 3. accession from each department (army, navy, etc)
select service, count(service) as count
from clist
group by service;

	-- 4. get distribution of scores by gender (reworked of #1's query)
--with cte_scores as (select cast(stage_3 as int) as 'stage1', cast(stage_2 as int) as 'stage2', cast(stage_1 as int) as 'stage3', ID as 'ID'
--from Cscore)
--select gender, avg(
--	stage3) as stage3, avg(stage2) as stage2,
--	avg(stage1) as stage1 
--	from cte_scores
--full outer join clist
--on clist.id = cte_scores.id
--group by gender

	-- 4. revision that splits the #4 query into score ranges with counts.. uses triple cte to refine 3 columns into ranges and seperates them by gender
with cte_scores as
(select isnull(sum(stage_3),0) as 'stage1', isnull(sum(stage_2),0) as 'stage2',
	isnull(sum(stage_1),0) as 'stage3', cscore.id, gender as 'gender'
from Cscore
full outer join Clist
	on cscore.id = clist.id
group by cscore.id, gender),
cte_scores2 as
(select id, gender, sum(stage1 + stage2 + stage3) as totscore from cte_scores group by gender, id),
cte_scores3 as (select gender, case 
	when totscore between 0 and 49 then '0-49'
	when totscore between 50 and 99 then '50-99'
	when totscore between 100 and 149 then '100-149'
	when totscore between 150 and 199 then '150-199'
	when totscore between 200 and 249 then '200-249'
	when totscore between 250 and 300 then '250-300'
		end as  Score from cte_scores2)
select gender, score, count(score) as count from cte_scores3
group by score, gender;

	--5. get years of services, discluding non serving members
Select avg(years_of_service*1.00) as years_served
from clist
where years_of_service > 0;

	-- 6. get average age, total candidates, gender distribution count
Select count(id) as candidates, avg(age) as avg_age, 
    sum(case gender when 'Male' then 1 else 0 end) as Male,
    sum(case gender when 'Female' then 1 else 0 end) as Female
from clist;


--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

	-- Ship Construction Page
	-- uses 1 table

	-- 0. preview columns
select top 3 * from vessel;

	-- 1. progress over the weeks
select week, start_of_week, progress
from vessel;

	-- 2. systems tests compared to accidents
select week, systems_tests, accident
from vessel;

	-- 3. count of acccident and not weeks
select count(week) as weeks, accident
from vessel
group by accident;

	-- 4. find the higest percent increase in a day
select top 1 week, progress - lag(progress) over (order by week) as progress
from vessel
group by week, progress
order by progress desc;

	-- 5. most system test in a day
select top 1 week, systems_tests
from vessel
order by systems_tests desc;

	
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--	-- financial page
--	-- 3 tables


	-- preview 3 tables joined, noted duplicate columns
select top 3 *
from expend
full outer join fund
	on expend.week = fund.week
full outer join vessel
	on vessel.week = expend.week;


	-- 1. cost, funds, and runnings of each
select expend.week, expend.start_of_week, (equipment+expend.wages+medical+food+materials+vessel.wages) as cost, sum (equipment+expend.wages+medical+food+materials+vessel.wages) over ( 
order by expend.week) as running_cost, sum(government+other) over (order by expend.week) as running_funded
from expend
full join fund
	on expend.week = fund.week
full join vessel
	on vessel.week = expend.week;


	-- 2. funds remaining
select ( sum(government+other) - sum(equipment+expend.wages+medical+food+materials+vessel.wages)) as remaining
from expend
full join fund
	on expend.week = fund.week
full join vessel
	on vessel.week = expend.week;

	-- 3. select source of expenditures and with their percentage of the total costs
with cte_ex as (select 
sum(equipment) as equipment, sum(expend.wages) as staffing, sum(vessel.wages) as engineers, sum(materials) as material, sum(food) as food, sum(medical) as medical, sum(equipment+expend.wages+medical+food+materials+vessel.wages) as total
from expend
full join fund
	on expend.week = fund.week
full join vessel
	on vessel.week = expend.week)
select equipment, 100.00*equipment/total as equipment, staffing, 100.00*staffing/total as staffing, engineers, 100.00*engineers/total as engineers, food, 100.00*food/total as food, medical, 100.00*medical/total as medical, material, 100.00*equipment/total as material
from cte_ex;


	-- 4. find day with biggest donation (disclude week 1 on account of it being a starting allowance that would not be a weekly fund, but would be considered the initial funds)
select top 1 government+other as total_funding, week, start_of_week
from fund
where week <> 'week 01'
order by total_funding desc;


	-- 5. weeks "above water" (cum. funds are more than cum. cost)
with CTE_water as (select expend.week, expend.start_of_week, sum (equipment+expend.wages+medical+food+materials+vessel.wages) over ( 
order by expend.week) as running_cost, sum(government+other) over (order by expend.week) as running_funded
from expend
full join fund
	on expend.week = fund.week
full join vessel
	on vessel.week = expend.week)
select case
	when running_funded > running_cost then 'pass'
	when running_funded < running_cost then 'fail'
		end as 'y'
from CTE_water;

	-- 6. govt/other funding
with cte_funds as (
	select sum(government) as gov, sum(other) as oth, sum(other+government) as tot
	from fund)
select gov as government_total, 100.00*(1.00*gov/tot) as government_percent, oth as other_total, 100.00*oth/tot as other_percent
from cte_funds;

	---- 7. accidental repeat of #4... this uses slightly different query to achieve same result
	--select sum(government+other), start_of_week
	--from fund
	--where start_of_week <> '1960-01-04'
	--group by start_of_week
	--order by sum(government+other) desc;



--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

	--extra searches post

select * from clist

select state, count(state)
from clist
group by state
