#| Trims the given suffix from the string, if it exists.
#| The optional flag =:i= performs it case insensitively.
#`{
    # Strip off from the end
    >>> "hi there!".&remove-suffix("!")
    "hi there"

    # If not strictly at the end, no change
    >>> remove-suffix "Zugzwang", "zwan"
    "Zugzwang"

    # Case insensitive
    >>> "Republic".&remove-suffix("Public", :i)
    "Re"

    # Newline at the end is considered important
    >>> "This stays\n".&remove-suffix("ys")
    "This stays\n"
}
unit module Remove-Suffix;

our proto remove-suffix(\st, Str:D $suffix, Bool :$i?) is export {*}

multi remove-suffix(Str:D \st, Str:D $suffix, Bool :$i? --> Str:D) {
    my $sc = $suffix.chars;
    return st if st.chars < $sc || !$suffix;
    $i
      ?? st.subst(/:i $suffix $/)
      !! st.substr(*-$sc) eq $suffix
           ?? st.substr(0, *-$sc)
           !! st
}
