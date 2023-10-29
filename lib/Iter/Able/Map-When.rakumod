#| Maps only the elements that satisfy the predicate, if any.
#`{
    # If nonpositive, make it cubed; else, keep as is
    >>> [1, -2, 3, 0, 4, -5].&map-when(* <= 0, * ** 3)
    (1, -8, 3, 0, 4, -125)

    # Take the square root only if positive
    >>> (4, -7, 9, 0).&map-when(* > 0, &sqrt)
    (2, -7, 3, 0)

    # Make vowels upper case
    >>> "mixed feelings".&map-when(/:i <[aeiou]>/, &uc).raku
    "mIxEd fEElIngs"

    # Normalize "anomalies"
    >>> (r1 => 7.13, r2 => 6.89, r3 => 7.90, r4 => 6.61).&map-when((*.value - 7).abs >= 0.2, {7})
    (r1 => 7.13, r2 => 6.89, r3 => 7, r4 => 7)
}
unit module Map-When;

#= Implemented in terms of `map`
our proto map-when(\ist, &pred, &mapper) is export {*}

multi map-when(Iterable \it, &pred, &mapper) {
    my &_pred = &pred ~~ Regex ?? (* ~~ &pred).so !! &pred;
    it.map({ _pred($_) ?? mapper($_) !! $_ })
}

multi map-when(Iterator \it, &pred, &mapper) {
    my &_pred = &pred ~~ Regex ?? (* ~~ &pred).so !! &pred;
    Seq.new(it).map({ _pred($_) ?? mapper($_) !! $_ }).iterator
}

multi map-when(Str \st, &pred, &mapper) {
    my &_pred = &pred ~~ Regex ?? (* ~~ &pred).so !! &pred;
    st.comb.map({ _pred($_) ?? mapper($_) !! $_ }).join
}
