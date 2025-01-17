IF OBJECT_ID('tempdb..#concept_ancestor_grp', 'U') IS NOT NULL
	DROP TABLE #concept_ancestor_grp;

--HINT DISTRIBUTE_ON_KEY(descendant_concept_id)
create table #concept_ancestor_grp as
select
  ca1.ancestor_concept_id
  , ca1.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca1
inner join
(
  select
    c1.concept_id
    , c1.concept_name
    , c1.vocabulary_id
    , c1.domain_id
  from @cdm_database_schema.concept c1
  inner join @cdm_database_schema.concept_ancestor ca1
    on ca1.ancestor_concept_id = 441840 -- clinical finding
    and c1.concept_id = ca1.descendant_concept_id
  where
  (
    ca1.min_levels_of_separation > 2
  	or c1.concept_id in (433736, 433595, 441408, 72404, 192671, 137977, 434621, 437312, 439847, 4171917, 438555, 4299449, 375258, 76784, 40483532, 4145627, 434157, 433778, 258449, 313878)
  )
  and c1.concept_name not like '%finding'
  and c1.concept_name not like 'disorder of%'
  and c1.concept_name not like 'finding of%'
  and c1.concept_name not like 'disease of%'
  and c1.concept_name not like 'injury of%'
  and c1.concept_name not like '%by site'
  and c1.concept_name not like '%by body site'
  and c1.concept_name not like '%by mechanism'
  and c1.concept_name not like '%of body region'
  and c1.concept_name not like '%of anatomical site'
  and c1.concept_name not like '%of specific body structure%'
  and c1.domain_id = 'Condition'
) t1 on ca1.ancestor_concept_id = t1.concept_id
inner join @reference_schema.@outcome_cohort ocr ON (
    ocr.referent_concept_id = ca1.ancestor_concept_id and ocr.outcome_type = 2
)
inner join #cohorts_to_compute coc ON coc.cohort_definition_id = ocr.cohort_definition_id

;

--incident outcomes - requiring inpatient visit
insert into @cohort_database_schema.@cohort_table
(
  cohort_definition_id
  , subject_id
  , cohort_start_date
  , cohort_end_date
)
select
  ocr.cohort_definition_id
  , t1.person_id as subject_id
  , t1.cohort_start_date
  , t1.cohort_start_date as cohort_end_date
from
(
  select
    co1.person_id
    , ca1.ancestor_concept_id
    , min(co1.condition_start_date) as cohort_start_date
  from @cdm_database_schema.condition_occurrence co1
  inner join #concept_ancestor_grp ca1
    on co1.condition_concept_id = ca1.descendant_concept_id
  group by
    co1.person_id
    , ca1.ancestor_concept_id
) t1
inner join @reference_schema.@outcome_cohort ocr ON (
    ocr.referent_concept_id = t1.ancestor_concept_id AND ocr.outcome_type = 2
)
inner join #cohorts_to_compute coc ON ocr.cohort_definition_id = coc.cohort_definition_id
inner join
(
  select
    co1.person_id
    , ca1.ancestor_concept_id
    , min(vo1.visit_start_date) as cohort_start_date
  from @cdm_database_schema.condition_occurrence co1
  inner join @cdm_database_schema.visit_occurrence vo1
    on co1.person_Id = vo1.person_id
    and co1.visit_occurrence_id = vo1.visit_occurrence_id
  inner join #concept_ancestor_grp ca1
    on co1.condition_concept_id = ca1.descendant_concept_id
  group by
    co1.person_id
    , ca1.ancestor_concept_id
) t2
  on t1.person_id = t2.person_id
  and t1.ancestor_concept_id = t2.ancestor_concept_id
;

-- Add the cohorts we have just generated to the computed set
insert into #computed_o_cohorts (cohort_definition_id) select cohort_definition_id from #cohorts_to_compute;