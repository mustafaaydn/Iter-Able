#| Maps only the first item that satisfies the predicate, if any.
#`{
    # First positive to negative
    >>> map-first [1, 2, 3], * > 0, -*
    (-1, 2, 3)

    # Can use with all-pass filter to assign to head :)
    >>> map-first ["", 5, 9, 11], { True }, { 0 }
    (0, 5, 9, 11)

    # First uppercase to lowercase
    >>> "here WE are".&map-first(/ <.upper> /, &lc).raku
    "here wE are"

    # If no one matches, everyone is yielded as is
    >>> [4, 44, 444, 4444].&map-first(*.is-prime, { 7 });
    (4, 44, 444, 4444)
}
unit module Map-First;

use nqp;

my class MapFirst does Iterator {
    has Mu $!iter;         #= Passed iterator
    has &!pred;            #= Predicate
    has &!mapper;          #= Transformer

    has int $!done-first;  #= State: has the first one seen yet?

    method !SET-SELF($!iter, &!pred, &!mapper) { self }

    method new(\iterator, \pred, \mapper) {
                nqp::create(self)!SET-SELF(iterator, pred, mapper)
    }

    method pull-one {
        nqp::if(
                        # Is the iterable exhausted?
                nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
                        # Yes; signal
            IterationEnd,
                        # No; have we already seen the first one?
            nqp::if(
                $!done-first,
                $next,
                # No; does the item match the predicate?
                nqp::if(
                    &!pred($next),
                    nqp::stmts(
                        ($!done-first = 1),
                        &!mapper($next)
                    ),
                    $next
                )
            )
        )
    }

    method is-lazy() { $!iter.is-lazy }
}

our proto map-first(\ist, &pred, &mapper) is export {*}

multi map-first(Iterable \it, &pred, &mapper) {
    Seq.new: MapFirst.new: it.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

multi map-first(Iterator \it, &pred, &mapper) {
    Seq.new: MapFirst.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

multi map-first(Str \st, &pred, &mapper) {
    join "", Seq.new: MapFirst.new: st.comb.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}
