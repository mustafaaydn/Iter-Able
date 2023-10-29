#| Skips values from the iterable as long as =&pred= holds; once not,
#| starts taking values indefinitely.
#`{
    # Skip the falsefuls in front
    >>> [0, "", 7, Any, 4, -5].&skip-while(&not).raku
    (7, Any, 4, -5).Seq

    # Generalized trim-leading
    >>> (NaN, NaN, NaN, 4.6, -7.1, 8.0).&skip-while(* === NaN)
    (4.6, -7.1, 8)

    # Skip unwanted characters
    >>> my Set() $unwanteds = <. , ;>;
    >>> ",,.;Trial and error. Important.".&skip-while(* ∈ $unwanteds).raku
    "Trial and error. Important."
}
unit module Skip-While;

use nqp;

my class SkipWhile does Iterator {
    has Mu $!iter;          #= Passed iterator
    has &!pred;             #= Predicate

    has int $!skipped-all;  #= State: whether invalids are yet got ridden of

    method !SET-SELF($!iter, &!pred) {
        $!skipped-all = 0;
        self
    }

    method new(\iterator, \pred) {
        nqp::create(self)!SET-SELF(iterator, pred)
    }

    method pull-one {
        nqp::if(
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            IterationEnd,
            nqp::stmts(
                nqp::unless(
                    $!skipped-all,
                    nqp::stmts(
                        # Consume while predicate holds (and iterable unexhausted)
                        nqp::while(
                            &!pred($next)
                                && nqp::isfalse(nqp::eqaddr(($next := $!iter.pull-one), IterationEnd)),
                            1
                        ),
                        ($!skipped-all = 1),
                    ),
                ),
                nqp::if(
                    nqp::eqaddr($next, IterationEnd),
                    IterationEnd,
                    $next
                ),
            ),
        )
    }
    method is-lazy   { $!iter.is-lazy }
    method Seq       { Seq.new(self)  }
}

our proto skip-while(\ist, &pred) is export {*}

multi skip-while(Iterable \it, &pred) {
    Seq.new: SkipWhile.new: it.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi skip-while(Iterator \it, &pred) {
    SkipWhile.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi skip-while(Str \st, &pred) {
    join "", Seq.new: SkipWhile.new: st.comb.iterator, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}
