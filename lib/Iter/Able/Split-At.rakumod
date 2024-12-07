#| Split the iterable whenever the predicate holds. Doesn't include the
#| separators themselves in the output (even if at the edges, i.e., `:skip-empty`
#| behaviour of Str.split is exposed).
#`{
    # Split when hit 0 (0s disappear in the output)
    >>> [1, 2, 3, 0, 4, 5].&split-at(* == 0)
    ((1, 2, 3), (4, 5)).Seq

    # For strings, it's almost the same except :skip-empty is implied
    >>> "AsomeAthingA".&split-at(/:i <[aeiou]>/)
    ("s", "m", "th", "ng").Seq
}
unit module Split-At;

use nqp;

my class SplitAt does Iterator {
    has Mu $!iter;  #= Passed iterator
    has &!pred;     #= Predicate

    has $!group;    #= State: current group

    method !SET-SELF($!iter, &!pred) {
        $!group := nqp::create(IterationBuffer);
        self;
    }

    method new(\iterator, \pred) {
        nqp::create(self)!SET-SELF(iterator, pred)
    }

    method pull-one {
        my $rv;
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my \nekst := $!iter.pull-one), IterationEnd),
            nqp::if(
                nqp::elems($!group),
                nqp::stmts(
                    ($rv := nqp::clone($!group).List),
                    ($!group.clear),
                    $rv
                ),
                IterationEnd
            ),
            nqp::if(
                &!pred(nekst),
                nqp::unless(
                    nqp::elems($!group),
                    self.pull-one,
                    nqp::stmts(
                        ($rv := nqp::clone($!group).List),
                        ($!group.clear),
                        $rv,
                    ),
                ),
                nqp::stmts(
                    nqp::push($!group, nekst),
                    self.pull-one
                ),
            ),
        )
    }

    method is-lazy { $!iter.is-lazy }
    method Seq     { Seq.new(self)  }
}

our proto split-at(\it, &pred) is export {*}

multi split-at(Iterable:D \it, &pred --> Seq:D) {
    Seq.new: SplitAt.new: it.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi split-at(Iterator:D \it, &pred --> SplitAt:D) {
    SplitAt.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi split-at(Str:D \st, &pred) {
    (Seq.new: SplitAt.new: st.comb.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)).map(*.join)
}
