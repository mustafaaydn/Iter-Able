#| Removes the first element satisfying the predicate, if any. Without any
#| predicate, the very first element is skipped.
#`{
    # Without an argument, equivalent to `.skip`
    >>> [1, 2, 3, 0, 4, 5].&remove-first
    (2, 3, 0, 4, 5).Seq

    # Remove the first nonnegative element (and only that)
    >>> (-2, -8, 5, 12, 0).&remove-first(* >= 0)
    (-2, -8, 12, 0).Seq

    # If there is no "bad" element, yield back as is
    >>> remove-first [10, 20, 30], &is-prime
    (10, 20, 30).Seq

    # String invocants as well as regex predicates are accepted as well
    >>> "fi rst whitespace is gone".&remove-first(/ \s /)
    "first whitespace is gone"
}
unit module Remove-First;

use nqp;

my class RemoveFirst does Iterator {
    has Mu $!iter;              #= Passed iterator
    has &!pred;                 #= Predicate

    has int $!already-removed;  #= State: removed the first yet?

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
            # No; have the first removed yet?
            nqp::if($!already-removed,
                    # Yes; yield as is
                    $next,
                    # No; does this satisfy the predicate?
                    nqp::if(&!pred($next),
                            # Yes; flag on and move to the next one
                            nqp::stmts(
                                ($!already-removed = 1),
                                self.pull-one
                            ),
                            # No; yield as is
                            $next
                    )
            )
        )
    }

    method is-lazy { $!iter.is-lazy }
    method Seq     { Seq.new(self)  }
}

our proto remove-first(\ist, &pred?) is export {
    # When no predicate is supplied, remove 0th
    without &pred {
        given ist {
            when Iterable:D { return ist.skip(1) }
            when Str:D      { return ist ?? ist.substr(1) !! "" }
            when Iterator:D { ist.skip-one; return ist }
        }
    }
    {*}
}

multi remove-first(Iterable:D \it, &pred --> Seq:D) {
    Seq.new: RemoveFirst.new: it.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi remove-first(Iterator:D \it, &pred --> RemoveFirst:D) {
    RemoveFirst.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi remove-first(Str:D \st, &pred --> Str:D) {
    join "", Seq.new: RemoveFirst.new: st.comb.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}
