{DEFAULT @cohort_subset_definition = 'cohort_subset_definition'}
{DEFAULT @cohort_definition = 'cohort_definition'}
{DEFAULT @cohort_subset_target = 'cohort_subset_target'}
{DEFAULT @include_constraints = TRUE}

DROP TABLE IF EXISTS @database_schema.@table_prefix@cohort_subset_definition {@include_constraints} ? {cascade};
CREATE TABLE @database_schema.@table_prefix@cohort_subset_definition (
    subset_definition_id integer primary key,
    subset_name varchar,
    json varchar
);

DROP TABLE IF EXISTS @database_schema.@table_prefix@cohort_subset_target {@include_constraints} ? {cascade};
CREATE TABLE @database_schema.@table_prefix@cohort_subset_target (
    subset_definition_id integer primary key,
    cohort_definition_id bigint NOT NULL, -- ID of target
    subset_cohort_definition_id bigint NOT NULL
    {@include_constraints} ? {
    ,
    CONSTRAINT subset_target_def
      FOREIGN KEY(subset_definition_id)
	    REFERENCES @database_schema.@cohort_subset_definition(subset_definition_id)
	        ON DELETE CASCADE,

    CONSTRAINT cohort_defintion_id
      FOREIGN KEY(COHORT_DEFINITION_ID)
	    REFERENCES @database_schema.@cohort_definition(COHORT_DEFINITION_ID)
	        ON DELETE CASCADE,

	 CONSTRAINT subset_cohort_definition_id
      FOREIGN KEY(subset_cohort_definition_id)
	    REFERENCES @database_schema.@cohort_definition(COHORT_DEFINITION_ID)
	        ON DELETE CASCADE
    }
);

ALTER TABLE @database_schema.@table_prefix@cohort_definition ADD COLUMN is_subset int DEFAULT 0;
ALTER TABLE @database_schema.@table_prefix@cohort_definition ADD COLUMN subset_parent bigint;

UPDATE @database_schema.@table_prefix@cohort_definition SET subset_parent = cohort_definition_id;
