#| Trims the given prefix from the string, if it exists.
#| The optional flag =:i= performs it case insensitively.
#`{
    # Strip off from the beginning
    >>> "https://thing.org".&remove-prefix("https://")
    "thing.org"

    # If not strictly at the beginning, no change
    >>> remove-prefix "Somewhere here", "where"
    "Somewhere here"

    # Case insensitive
    >>> "***Info:hi".&remove-prefix("***info:", :i)
    "hi"

    # Newline at the beginning is considered important
    >>> "\nThis stays".&remove-prefix("this", :i)
    "\nThis stays"
}
unit module Remove-Prefix;

our proto remove-prefix(\st, Str:D $prefix, Bool :$i?) is export {*}

multi remove-prefix(Str:D \st, Str:D $prefix, Bool :$i? --> Str:D) {
    my $pc = $prefix.chars;
    return st if st.chars < $pc || !$prefix;
    $i
      ?? st.subst(/:i ^ $prefix/)
      !! st.substr(0, $pc) eq $prefix
           ?? st.substr($pc)
           !! st
}
