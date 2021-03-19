create type pi_digit as
(
    seq_num bigint,
    val_num smallint
);

create function calcpi(bigint)
returns setof pi_digit
as $body$
declare
    digit_count alias for $1;
    digit_num digit_count%type;
    slice_count digit_count%type;
begin
    -- a number of slices that produce next digit
    slice_count := digit_count / 10 * 3;
    -- create an internal working set; fill starting values
    drop table if exists calcpi_internal_data;
    create temporary table calcpi_internal_data (gen_num bigint)
        inherits (pi_digit)
        constraint calcpi_internal_data_idx primary key (seq_num)
        on commit drop;
    insert into calcpi_internal_data 
        select seq_num, 2 from generate_series(slice_count - 1, 0, -1);
    -- digit loop
    for digit_num in 1..digit_count loop

    end loop;
end
$body$
language plpgsql
