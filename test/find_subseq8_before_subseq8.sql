-- Function: find_subseq8_before_subseq8
--  Find a first 8-elements subsequnce of digits in the sequnce
--  of digits of Pi number, that is located just before a given 
--  8-elements sunsequnce
-- Params:
--  $1 (noname)     - a number of digits in the PI number
--                    that will be considered as sequence of digits
--                    to be searched in.
--  $2 (src_seq)    - input 8-elements subsequence
--  $3 (dst_seq)    - output 8-elements subsequence
--  $4 (dst_pos)    - the position, from which the output subsequnce
--                    in the PI number is started from.
create or replace function find_subseq8_before_subseq8(in bigint, src_seq inout text, dst_seq out text, dst_pos out bigint)
as $body$
-- accumulate digits of the PI number under the CTE
with pi_data as
(
select 
    -- select the seq number, the digit and the following 15 digit after it
    x.seq, 
    x.val as p1, 
    lead(x.val, 1) over(order by x.seq) as p2, 
    lead(x.val, 2) over(order by x.seq) as p3, 
    lead(x.val, 3) over(order by x.seq) as p4, 
    lead(x.val, 4) over(order by x.seq) as p5, 
    lead(x.val, 5) over(order by x.seq) as p6, 
    lead(x.val, 6) over(order by x.seq) as p7, 
    lead(x.val, 7) over(order by x.seq) as p8, 
    lead(x.val, 8) over(order by x.seq) as s1, 
    lead(x.val, 9) over(order by x.seq) as s2, 
    lead(x.val, 10) over(order by x.seq) as s3, 
    lead(x.val, 11) over(order by x.seq) as s4, 
    lead(x.val, 12) over(order by x.seq) as s5, 
    lead(x.val, 13) over(order by x.seq) as s6, 
    lead(x.val, 14) over(order by x.seq) as s7, 
    lead(x.val, 15) over(order by x.seq) as s8 
from
    -- select from the function which is computed a PI digits
    calcpi($1) as x
)
select
    -- output source subseq, finded subseq and its position
    src_seq,
    p1::text || p2::text || p3::text || p4::text || 
    p5::text || p6::text || p7::text || p8::text as dst_seq,
    (seq - 1) as dst_pos
from 
    pi_data
where
    -- search source subseq starting from second element of original sequence;
    -- calcpi() returns all digits including the integral part equals "3"
    (s1::text || s2::text || s3::text || s4::text || 
    s5::text || s6::text || s7::text || s8::text) = src_seq
    and
    seq > 1;
$body$
language sql;
