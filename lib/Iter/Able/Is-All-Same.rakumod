#| Checks if the values are all the same. Semantically equivalent to
#| `.unique <= 1` but implemented differently. Also works for
#| strings. Sameness can be controlled with a transformer (=as=)
#| and/or an equality checker (=with=). By default, no transformation
#| occurs and ~===~ is used for equivalance.
#`{
    # Shortcircuitingly gives False once two different values are seen
    >>> [1, 2, 1, 1, 1].&is-all-same
    False

    # True when all values are === to each other
    >>> is-all-same (1, 1)
    True

    # Vacuously true
    >>> is-all-same []
    True

    # Works for strings the same way
    >>> "no".&is-all-same
    False

    # Equivalance relation can be altered
    >>> my ($a, $b) = 3, 3
    >>> [$a, $b].&is-all-same(:with(&[=:=]))
    False

    # Values can be transformed before comparison
    >>> "aaAaA".&is-all-same(:as(&fc))
    True
}
unit module Is-All-Same;

use nqp;

our proto is-all-same(\ist, :&as = {$_}, :&with = &[===] --> Bool:D) is export {*}

multi is-all-same(Iterable:D \it, :&as = {$_}, :&with = &[===] --> Bool:D) {
    samewith it.iterator, :&as, :&with
}

multi is-all-same(Iterator:D \it, :&as = {$_}, :&with = &[===] --> Bool:D) {
    nqp::if(
        nqp::eqaddr((my \first = it.pull-one), IterationEnd),
        # if we could sweep till the end, all must have been the same
        True,
        nqp::stmts(
            # transformed first value
            (my \t-first = &as(first)),
            # go on until we see a different value or values exhaust
            nqp::until(
                nqp::eqaddr((my \nekst = it.pull-one), IterationEnd)
                || nqp::isfalse(&with(t-first, &as(nekst))),
                nqp::null
            ),
            # did the values exhaust or we saw a same value?
            nqp::if(
                nqp::eqaddr(nekst, IterationEnd),
                True,
                False
            )
        )
    )
}

multi is-all-same(Str:D \st, :&as = {$_}, :&with = &[===] --> Bool:D) {
    samewith st.comb.iterator, :&as, :&with
}
