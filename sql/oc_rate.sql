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