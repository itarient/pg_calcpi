create type digit as
(
    seq bigint,
    val smallint
);

create function calcpi(bigint)
returns setof digit
as $body$
declare
    digit_count alias for $1;
    digit_num digit_count%type;
    slice_count digit_count%type;
    slice_num record;
    carryover integer;
    sum integer;
    q integer;
    r integer;
    pi_digit digit;
begin
    -- a number of slices that produce next digit
    slice_count := digit_count / 10 * 3;
    -- create an internal working set; fill starting values
    drop table if exists calcpi_internal_data;
    create temporary table calcpi_internal_data
        (
            gen boolean,
            seq bigint,
            val smallint,
            constraint calcpi_internal_data_idx primary key (gen, seq)
        )
        on commit drop;
    insert into calcpi_internal_data 
        select true, gs, 2 from generate_series(slice_count - 1, 0, -1) as gs;
    -- digit loop
    for digit_num in 1..digit_count 
    loop
        carryover := 0;
        sum := 0;
        -- slice loop
        for slice_num in 
            select cid.* from calcpi_internal_data as cid
                order by cid.seq desc
        loop
            q := (slice_num.val * 10 + carryover) / (slice_num.seq * 2 + 1);
            r := (slice_num.val * 10 + carryover) % (slice_num.seq * 2 + 1);
            carryover := q * slice_num.seq;
            update calcpi_internal_data
                set gen = not(slice_num.gen), val = r
                where gen = slice_num.gen and seq = slice_num.seq;
        end loop;
        -- force update visibility map
        pi_digit.seq = digit_num;
        pi_digit.val = sum / 10;
        return next pi_digit;
    end loop;
    drop table calcpi_internal_data;
    return;
end
$body$
language plpgsql;
