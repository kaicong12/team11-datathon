select * from mimiciv_derived.first_day_height h
inner join mimiciv_derived.first_day_weight w
on h.subject_id = w.subject_id and h.stay_id = w.stay_id
