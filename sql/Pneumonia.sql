with pbmi as (
	select * from mimiciv_derived.first_day_height h
inner join mimiciv_derived.first_day_weight w
on h.subject_id = w.subject_id and h.stay_id = w.stay_id
),

patient as (
	with ttemp as (select micu.subject_id,
mdv.stay_id, mdv.ventilation_status,
EXTRACT(EPOCH FROM (mdv.endtime - mdv.starttime)) as duration
from mimiciv_derived.ventilation as mdv
inner join mimiciv_icu.icustays as micu on micu.stay_id = mdv.stay_id
where ventilation_status = 'InvasiveVent')
	select subject_id, stay_id, ventilation_status, SUM(duration) as duration 
	from ttemp
	group by subject_id, stay_id, ventilation_status
),

ttable as (
	WITH AGGR_TABLE AS (
		select ce.subject_id, ce.stay_id, ce.charttime, count(ce.subject_id) as num_turn from mimiciv_icu.chartevents ce
		left join mimiciv_icu.icustays icu
		on ce.stay_id = icu.stay_id
		WHERE itemid = 224082
		GROUP BY ce.subject_id, ce.stay_id, ce.charttime
	), 
	AGGR_BY_DATE as (
		SELECT aggt.subject_id, aggt.stay_id, date(aggt.charttime) as date_field, sum(aggt.num_turn) as total_turn
		FROM AGGR_TABLE aggt 
		GROUP BY aggt.subject_id, aggt.stay_id, date(aggt.charttime)
	),
	SUM_TURN_BY_STAY_ID AS (
		SELECT aggt_date.subject_id, aggt_date.stay_id, SUM(aggt_date.total_turn) as sum_total_turn
		FROM AGGR_BY_DATE aggt_date
		GROUP BY aggt_date.subject_id, aggt_date.stay_id
	)
	SELECT by_stay_id.subject_id, by_stay_id.stay_id, icu.los, sum_total_turn, (by_stay_id.sum_total_turn/icu.los) as daily_turn_rate 
	FROM SUM_TURN_BY_STAY_ID by_stay_id
	LEFT JOIN mimiciv_icu.icustays icu
	ON icu.subject_id = by_stay_id.subject_id
	AND icu.stay_id = by_stay_id.stay_id
),

octable as (
	WITH AGGR_TABLE AS (
		select ce.subject_id, ce.stay_id, ce.charttime, count(ce.subject_id) as num_oc from mimiciv_icu.chartevents ce
		left join mimiciv_icu.icustays icu
		on ce.stay_id = icu.stay_id
		WHERE itemid = 226168
		GROUP BY ce.subject_id, ce.stay_id, ce.charttime
	), 
	AGGR_BY_DATE as (
		SELECT aggt.subject_id, aggt.stay_id, date(aggt.charttime) as date_field, sum(aggt.num_oc) as total_oc
		FROM AGGR_TABLE aggt 
		GROUP BY aggt.subject_id, aggt.stay_id, date(aggt.charttime)
	),
	SUM_TURN_BY_STAY_ID AS (
		SELECT aggt_date.subject_id, aggt_date.stay_id, SUM(aggt_date.total_oc) as sum_total_oc
		FROM AGGR_BY_DATE aggt_date
		GROUP BY aggt_date.subject_id, aggt_date.stay_id
	)
	SELECT by_stay_id.subject_id, by_stay_id.stay_id, icu.los, sum_total_oc, (by_stay_id.sum_total_oc/icu.los) as daily_oc_rate 
	FROM SUM_TURN_BY_STAY_ID by_stay_id
	LEFT JOIN mimiciv_icu.icustays icu
	ON icu.subject_id = by_stay_id.subject_id
	AND icu.stay_id = by_stay_id.stay_id
),

dadm as (
	select distinct on(subject_id) subject_id, race, insurance from mimiciv_hosp.admissions
),

dpatients as (
	select distinct on(subject_id) subject_id, gender, anchor_age, anchor_year, anchor_year_group from mimiciv_hosp.patients
)

select h.subject_id, h.stay_id, h.height/100 as height_admit,
w.weight_admit, w.weight_admit / power(h.height/100, 2) as BMI,
patient.ventilation_status, patient.duration as ventilation_duration,
ttable.los, ttable.sum_total_turn, ttable.daily_turn_rate,
octable.sum_total_oc, octable.daily_oc_rate,
dadm.race, dadm.insurance,
aps.sapsii_prob,
dpatients.gender, dpatients.anchor_age, dpatients.anchor_year, dpatients.anchor_year_group

from mimiciv_derived.first_day_height h
inner join mimiciv_derived.first_day_weight w
on h.subject_id = w.subject_id and h.stay_id = w.stay_id
inner join patient
on patient.subject_id = h.subject_id and patient.stay_id = h.stay_id
inner join octable
on octable.subject_id = h.subject_id and octable.stay_id = h.stay_id
inner join ttable
on ttable.subject_id = h.subject_id and ttable.stay_id = h.stay_id
inner join dadm
on dadm.subject_id = h.subject_id
inner join mimiciv_derived.sapsii aps
on aps.subject_id = h.subject_id and aps.stay_id = h.stay_id
inner join dpatients
on dpatients.subject_id = h.subject_id