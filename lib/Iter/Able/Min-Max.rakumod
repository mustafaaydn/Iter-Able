#| Computes the minimal and maximal values. By default =&cmp= is
#| used for comparing the values but a custom comparator (of arity
#| 1 or 2) can be passed. In case of ties, the first minimal/maximal
#| value is returned. Empty input (after grepping out type objects, if any)
#| results in Failure.
#|
#| Optional flags can control what is returned: =:k= for indexes,
#| =:v= for values, =:kv= for both interspersed and =:p= for indexes and
#| values as pairs. When a flag is supplied, /all/ indexes/values are
#| returned even if tied.
#`{
    # Get minimum and maximum values in one pass
    >>> [24, 11, 75, -6].&min-max
    (-6, 75)

    # Custom comparator
    >>> ["brb", "hi", "no"].&min-max(*.chars)
    ("hi", "brb")

    # Type objects are ignored
    >>> [-9, Date, HyperSeq, PseudoStash, 125].&min-max
    (-9, 125)

    # Argmin/max
    >>> [12, 3, 75].&min-max(:k)
    ((1,), (2,))

    # :v will collect even the tied ones
    >>> [-12, +12, 5].&min-max(*.abs)
    (5, -12)
    >>> [-12, +12, 5].&min-max(*.abs, :v)
    (5, (-12, 12))

    # min/maxpairs together
    >>> min-max [600, 4, -32], :p
    ((2 => -32,), (0 => 600,))

    # Strings are possible too
    >>> min-max "Nomenclature", -*.ord
    ("u", "N")

    # If the input is empty, result is a Failure
    >>> min-max []
    Argument to &min-max is empty (or full of undefined values)

    # Since type objects are ignored, result can fail with them too
    >>> min-max [Cool, IntStr, Raku]
    Argument to &min-max is empty (or full of undefined values)
}
unit module Min-Max;

use nqp;

sub _maybe_first_concrete($iterator, $first is rw) {
    nqp::stmts(
        nqp::until(
            nqp::eqaddr((my $pulled := $iterator.pull-one),IterationEnd),
            nqp::if(
                nqp::isconcrete($pulled),
                nqp::stmts(
                    ($first = $pulled),
                    (return $iterator)
                )
            )
        ),
        Mu
    )
}

sub _maybe_first_concrete_with_index($iterator, $first is rw, $index is rw) {
    nqp::stmts(
        (my int $idx = -1),
        nqp::until(
            nqp::eqaddr((my $pulled := $iterator.pull-one),IterationEnd),
            $idx++,
            nqp::if(
                nqp::isconcrete($pulled),
                nqp::stmts(
                    ($index = $idx),
                    ($first = $pulled),
                    (return $iterator)
                )
            )
        ),
        Mu
    )
}

our proto min-max(\ist, &comparator = &[cmp], :$k, :$v, :$kv, :$p --> List:D) is export {
    if ($k | $v | $kv | $p) && ($k ^ $v ^ $kv ^ $p).not {
        die "Must supply zero or exactly one named argument out of `k`, `v`, `kv` and `p`";
    }
    if &comparator.arity !(elem) (1, 2) {
        die "Custom comparator should have arity 1 or 2, got arity {&comparator.arity}";
    }
    {*}
}

multi min-max(\ist, &comparator = &[cmp], *%named where $_ == 1 && .first.key eq "k" | "kv" | "p") {
    my \it = ist ~~ Iterable
                 ?? ist.iterator
                 !! ist ~~ Str
                     ?? ist.comb.iterator
                     !! ist ~~ Iterator
                         ?? ist
                         !! die "Expected Iterable/Str/Iterator, got {ist.^name}";
    my &comparator_ = nqp::iseq_i(&comparator.arity, 2)
                          ?? &comparator
                          !! { comparator($^a) cmp comparator($^b) };
    nqp::if(
        _maybe_first_concrete_with_index(it, my $min, my int $idx),
        nqp::stmts(
            (my $max := $min),
            (my $max-idxs := nqp::create(IterationBuffer)),
            (my $min-idxs := nqp::create(IterationBuffer)),
            (my $maxes := nqp::create(IterationBuffer)),
            (my $mines := nqp::create(IterationBuffer)),
            nqp::push($max-idxs, nqp::decont($idx)),
            nqp::push($min-idxs, nqp::decont($idx)),
            nqp::push($mines, nqp::decont($min)),
            nqp::push($maxes, nqp::decont($max)),
            nqp::until(
                nqp::eqaddr((my $next := it.pull-one), IterationEnd),
                nqp::stmts(
                    $idx++,
                    nqp::if(
                        nqp::isconcrete($next),
                        nqp::stmts(
                            (my $cmp-min := comparator_($next, $min)),
                            (my $cmp-max := comparator_($next, $max)),
                            nqp::if(
                                nqp::eqaddr($cmp-min, Order::Less),
                                nqp::stmts(
                                    ($min := $next),
                                    nqp::splice($min-idxs, nqp::list(nqp::decont($idx)), 0, nqp::elems($min-idxs)),
                                    nqp::splice($mines, nqp::list(nqp::decont($min)), 0, nqp::elems($mines)),
                                ),
                                nqp::if(
                                    nqp::eqaddr($cmp-min, Order::Same),
                                    nqp::stmts(
                                        nqp::push($min-idxs, nqp::decont($idx)),
                                        nqp::push($mines, nqp::decont($next)),
                                    ),
                                ),
                            ),
                            nqp::if(
                                nqp::eqaddr($cmp-max, Order::More),
                                nqp::stmts(
                                    ($max := $next),
                                    nqp::splice($max-idxs, nqp::list(nqp::decont($idx)), 0, nqp::elems($max-idxs)),
                                    nqp::splice($maxes, nqp::list(nqp::decont($max)), 0, nqp::elems($maxes)),
                                ),
                                nqp::if(
                                    nqp::eqaddr($cmp-max, Order::Same),
                                    nqp::stmts(
                                        nqp::push($max-idxs, nqp::decont($idx)),
                                        nqp::push($maxes, nqp::decont($next)),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        )
    );
    nqp::defined($min) ??
        ((my str $wanted-form = %named.first.key) eq "k"
             ?? ($min-idxs.List, $max-idxs.List)
             !! $wanted-form eq "kv"
                 ?? (($min-idxs.List Z $mines.List).flat.list, ($max-idxs.List Z $maxes.List).flat.list)
                 !! (($min-idxs.List Z=> $mines.List).list, ($max-idxs.List Z=> $maxes.List).list)) # "p"
        !! fail "Argument to &min-max is empty (or full of undefined values)"
}


multi min-max(\ist, &comparator = &[cmp]) {
    my \it = ist ~~ Iterable
                 ?? ist.iterator
                 !! ist ~~ Str
                     ?? ist.comb.iterator
                     !! ist ~~ Iterator
                         ?? ist
                         !! die "Expected Iterable/Str/Iterator, got {ist.^name}";
    my &comparator_ = nqp::iseq_i(&comparator.arity, 2)
                          ?? &comparator
                          !! { comparator($^a) cmp comparator($^b) };
    nqp::if(
        _maybe_first_concrete(it, my $min),
        nqp::stmts(
            (my $max := $min),
            nqp::until(
                nqp::eqaddr((my $next := it.pull-one), IterationEnd),
                nqp::stmts(
                    nqp::if(
                        nqp::isconcrete($next),
                        nqp::stmts(
                            nqp::if(
                                nqp::eqaddr(comparator_($next, $min), Order::Less),
                                ($min := $next),
                            ),
                            nqp::if(
                                nqp::eqaddr(comparator_($next, $max), Order::More),
                                ($max := $next),
                            ),
                        ),
                    ),
                ),
            ),
        ),
    );
    nqp::defined($min) ?? ($min, $max) !! fail "Argument to &min-max is empty (or full of undefined values)"
}

multi min-max(\ist, &comparator = &[cmp], :$v!) {
    my \it = ist ~~ Iterable
                 ?? ist.iterator
                 !! ist ~~ Str
                     ?? ist.comb.iterator
                     !! ist ~~ Iterator
                         ?? ist
                         !! die "Expected Iterable/Str/Iterator, got {ist.^name}";
    my &comparator_ = nqp::iseq_i(&comparator.arity, 2)
                          ?? &comparator
                          !! { comparator($^a) cmp comparator($^b) };
    nqp::if(
        _maybe_first_concrete(it, my $min),
        nqp::stmts(
            (my $max := $min),
            (my $maxes := nqp::create(IterationBuffer)),
            (my $mines := nqp::create(IterationBuffer)),
            nqp::push($maxes, nqp::decont($max)),
            nqp::push($mines, nqp::decont($min)),
            nqp::until(
                nqp::eqaddr((my $next := it.pull-one), IterationEnd),
                nqp::stmts(
                    nqp::if(
                        nqp::isconcrete($next),
                        nqp::stmts(
                            (my $cmp-min := comparator_($next, $min)),
                            (my $cmp-max := comparator_($next, $max)),
                            nqp::if(
                                nqp::eqaddr($cmp-min, Order::Less),
                                nqp::stmts(
                                    ($min := $next),
                                    nqp::splice($mines, nqp::list(nqp::decont($min)), 0, nqp::elems($mines))
                                ),
                                nqp::if(
                                    nqp::eqaddr($cmp-min, Order::Same),
                                    nqp::push($mines, nqp::decont($next)),
                                ),
                            ),
                            nqp::if(
                                nqp::eqaddr($cmp-max, Order::More),
                                nqp::stmts(
                                    ($max := $next),
                                    nqp::splice($maxes, nqp::list(nqp::decont($max)), 0, nqp::elems($maxes))
                                ),
                                nqp::if(
                                    nqp::eqaddr($cmp-max, Order::Same),
                                    nqp::push($maxes, nqp::decont($next)),
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        ),
    );
    nqp::defined($min) ?? ($mines.List, $maxes.List) !! fail "Argument to &min-max is empty (or full of undefined values)"
}
