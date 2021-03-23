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
    curr_gen boolean := true;
    carryover integer;
    sum integer;
    q integer;
    r integer;
    predigit integer;
    hold_digits digit[];
    hold_pos integer := 0;
    hold_num integer;
begin
    -- a number of slices that produce next digit
    slice_count := digit_count * 10 / 3;
    -- raise notice '(calcpi debug) slice_count = %', slice_count;
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
        select curr_gen, gs, 2 from generate_series(slice_count - 1, 0, -1) as gs;
    -- digit loop
    for digit_num in 1..digit_count 
    loop
        carryover := 0;
        sum := 0;
        -- generate next digit
        for slice_num in 
            select cid.* from calcpi_internal_data as cid
                where gen = curr_gen
                order by cid.seq desc
        loop
            sum := slice_num.val * 10 + carryover; 
            q := sum / (slice_num.seq * 2 + 1);
            if slice_num.seq = 0 then
                r := sum % 10;
            else
                r := sum % (slice_num.seq * 2 + 1);
            end if;
            carryover := q * slice_num.seq;
            update calcpi_internal_data
                set gen = not(slice_num.gen), val = r
                where gen = slice_num.gen and seq = slice_num.seq;
            -- raise notice '(calcpi debug) slice_num = %, sum = %, q = %, r = %', slice_num, sum, q, r;
        end loop;
        -- correct nect digit 
        predigit := sum / 10;
        if hold_pos < 1 then
            hold_pos := hold_pos + 1;
            hold_digits[hold_pos].seq := digit_num;
            hold_digits[hold_pos].val := predigit;
        else
            if predigit = 9 then
                hold_pos := hold_pos + 1;
                hold_digits[hold_pos].seq := digit_num;
                hold_digits[hold_pos].val := predigit;
            elsif predigit = 10 then
                predigit := 0;
                for hold_num in hold_pos..1 loop
                    if hold_digits[hold_num].val = 9 then
                        hold_digits[hold_num].val := 0;
                    else
                        hold_digits[hold_num].val := hold_digits[hold_num].val + 1;
                    end if;
                end loop;
                for hold_num in 1..hold_pos loop
                    return next hold_digits[hold_num];
                end loop;
                hold_pos := 1;
                hold_digits[hold_pos].seq := digit_num;
                hold_digits[hold_pos].val := predigit;
            else
                -- release holded!
                for hold_num in 1..hold_pos loop
                    return next hold_digits[hold_num];
                end loop;
                hold_pos := 1;
                hold_digits[hold_pos].seq := digit_num;
                hold_digits[hold_pos].val := predigit;
            end if;
        end if;
        -- next slice generation
        curr_gen := not(curr_gen);
    end loop;
    for hold_num in 1..hold_pos loop
        return next hold_digits[hold_num];
    end loop;
    drop table calcpi_internal_data;

    return;
end
$body$
language plpgsql;
