#| Skip (drop) values from the iterable as long as `&pred` holds; once not,
#| start taking values indefinitely.
#`{
    # Truthfulness of elements decide to skip or start taking by default
    >>> [4, 8, -1, "", 7, Any, 5, 0].&skip-while.raku
    ("", 7, Any, 5, 0).Seq

    # Skip the falseful ones instead
    >>> [0, "", 7, Any, 4, -5].&skip-while(&not).raku
    (7, Any, 4, -5).Seq

    # Generalized trim-leading
    >>> (NaN, NaN, NaN, 4.6, -7.1, 8.0).&skip-while(* === NaN)
    (4.6 -7.1 8)
}
unit module Skip-While;

use nqp;

my class SkipWhile does Iterator {
	has Mu $!iter;          #= Passed iterable's iterator
    has &!pred;	            #= Predicate

    has int $!skipped-all;  #= State: whether invalids are yet got ridden of

    method !SET-SELF($!iter, &!pred) {
        $!skipped-all = 0;
        self
    }

    method new(\iterable, \pred) {
		nqp::create(self)!SET-SELF(iterable.iterator, pred)
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
    method is-lazy() { $!iter.is-lazy }
}

our proto skip-while(\ist, &pred = {$_}) is export {*}

multi skip-while(Iterable \it, &pred = {$_}) {
    Seq.new: SkipWhile.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}

multi skip-while(Str \st, &pred = {$_}) {
    join "", Seq.new: SkipWhile.new: st.comb, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred)
}
