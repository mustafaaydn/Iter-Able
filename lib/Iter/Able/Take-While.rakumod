#| Takes values from the iterable as long as =&pred= holds; once not,
#| stop. As it needs to look at the next value to decide when to stop,
#| it consumes one extra value as a side effect. That will be only
#| visible in /iterator/ inputs, though.
#`{
    # Negative value is a sentinel, so take up until that
    >>> (4, 7, 12, -3, 58, -1).&take-while(* >= 0)
    (4, 7, 12)

    # Until first whitespace
    >>> "until first whitespace".&take-while(/ \S /).raku
    "until"

    # Go till an "anomaly" occurs
    >>> (r1 => 7.13, r2 => 6.89, r3 => 7.90, r4 => 6.81).&take-while((*.value - 7).abs <= 0.2)
    (r1 => 7.13, r2 => 6.89)
}
unit module Take-While;

use nqp;

my class TakeWhile does Iterator {
    has Mu $!iter;  #= Passed iterator
    has &!pred;     #= Predicate

    method !SET-SELF($!iter, &!pred) { self }

    method new(\iterator, \pred) {
        nqp::create(self)!SET-SELF(iterator, pred)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; signal
            IterationEnd,
            # No, still has values; does it satisfy predicate?
            nqp::if(
                &!pred($next),
                # yes; yield
                $next,
                # no; stop
                IterationEnd
            )
        )
    }
    method is-lazy() { $!iter.is-lazy }
}

our proto take-while(\ist, &pred) is export {*}

multi take-while(Iterable \it, &pred) {
    Seq.new: TakeWhile.new: it.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi take-while(Iterator \it, &pred) {
    Seq.new: TakeWhile.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi take-while(Str \st, &pred) {
    join "", Seq.new: TakeWhile.new: st.comb.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}
