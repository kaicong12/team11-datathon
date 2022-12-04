
	with ttemp as (select micu.subject_id,
mdv.stay_id, mdv.ventilation_status,
EXTRACT(EPOCH FROM (mdv.endtime - mdv.starttime)) as duration
from mimiciv_derived.ventilation as mdv
inner join mimiciv_icu.icustays as micu on micu.stay_id = mdv.stay_id
where ventilation_status = 'InvasiveVent')
	select subject_id, stay_id, ventilation_status, SUM(duration) as duration 
	from ttemp
	group by subject_id, stay_id, ventilation_status