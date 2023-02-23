#| Checks if the values are all different. Semantically equivalent to
#| `.unique == .elems` but implemented differently. Also works for
#| strings. Sameness can be controlled with a transformer (=as=)
#| and/or an equality checker (=with=). By default, no transformation
#| occurs and ~===~ is used for equivalance.
#`{
    # Shortcircuitingly gives False once two same values are seen
    >>> [1, 1, 2, 3, 4].&is-all-different
    False

    # True when all values are !=== to each other
    >>> is-all-different (1, 2, 3)
    True

    # Vacuously true
    >>> is-all-different []
    True

    # Works for strings the same way
    >>> "yes".&is-all-different
    True

    # Equivalance relation can be altered
    >>> my ($a, $b) = 3, 3
    >>> [$a, $b].&is-all-different(:with(&[=:=]))
    True

    # Values can be transformed before comparison
    >>> [0.2, -0.54, 1, 0.32].&is-all-different(:as(&round))
    False
}
unit module Is-All-Different;

use nqp;

our proto is-all-different(\ist, :&as = {$_}, :&with = &[===]) is export {*}

multi is-all-different(Iterable \it, :&as = {$_}, :&with = &[===]) {
    samewith it.iterator, :&as, :&with
}

multi is-all-different(Iterator \it, :&as = {$_}, :&with = &[===]) {
    nqp::if(
        nqp::eqaddr(&with, &[===]),
        # default &with
        nqp::stmts(
            # allows for a hash
            (my $seen := nqp::hash),
            nqp::until(
                nqp::eqaddr((my \nekst = it.pull-one), IterationEnd),
                nqp::if(
                    nqp::existskey($seen, my \t-nekst = &as(nekst).WHICH),
                    # if already seen, immediately return False
                    (return False),
                    # otherwise store this as a seen value
                    nqp::bindkey($seen, t-nekst, 1),
                ),
            ),
        ),
        # custom &with
        nqp::stmts(
            # can't quite use a hash
            (my $wseen := nqp::list),
            nqp::until(
                nqp::eqaddr((my \wnekst = it.pull-one), IterationEnd),
                nqp::stmts(
                    # traverse the list to see if seen
                    (my int $i = -1),
                    (my int $e = nqp::elems($wseen)),
                    (my \t-wnekst = &as(wnekst)),
                    (say .raku, " ", .WHAT given t-wnekst),
                    nqp::until(
                        nqp::iseq_i(++$i, $e) || &with(t-wnekst, nqp::atpos($wseen, $i)),
                        nqp::null
                    ),

                    nqp::if(
                        nqp::isne_i($i, $e),
                        # if $i didn't reach $e, it means we had a hit; immediately return
                        (return False),
                        # otherwise add this one to the seen list
                        nqp::push($wseen, t-wnekst)
                    ),
                ),
            ),
        ),
    );
    True
}

multi is-all-different(Str \st, :&as = {$_}, :&with = &[===]) {
    samewith st.comb.iterator, :&as, :&with
}
