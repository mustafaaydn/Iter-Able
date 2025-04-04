sub EXPORT(*@things) {
    # If thing(s) were passed, selectively export them and die if an unknown
    # symbol is requested. If `*` is passed, export all. If nothing is passed,
    # export nothing; user needs to use the semi-FQNs.
    return Map.new unless @things;
    OUTER::Iter::Able::
        .values
        .map({"\&{.name}" => $_})
        .cache
    andthen
        (@things eqv [ * ] | ["*"])
        ?? $_
        !! (my \d = (@things (-) $_>>.key>>.substr(1)).keys.sort.list)
            ?? die "Can't import {d == 1 ?? d.head.raku !! d.raku} from Iter::Able"
            !! .grep({.value.name (elem) @things})
    andthen
        .Map
}

#| Entry point, gatherer package.
unit package Iter::Able;

# Imports are automatically generated by "tools/make-new-fun.raku"
use Iter::Able::Group-Conseq;
use Iter::Able::Take-While;
use Iter::Able::Skip-While;
use Iter::Able::Map-When;
use Iter::Able::Enumerate;
use Iter::Able::Annotate;
use Iter::Able::Cycle;
use Iter::Able::Map-Indexed;
use Iter::Able::Map-First;
use Iter::Able::Map-Last;
use Iter::Able::Chain;
use Iter::Able::Flatten;
use Iter::Able::Replace;
use Iter::Able::Assign-At;
use Iter::Able::Clip;
use Iter::Able::Insert-At;
use Iter::Able::N'th;
use Iter::Able::Is-All-Same;
use Iter::Able::Is-All-Different;
use Iter::Able::Remove-First;
use Iter::Able::Remove-Last;
use Iter::Able::Remove-At;
use Iter::Able::Select-At;
use Iter::Able::Min-Max;
use Iter::Able::Fill-Undef;
use Iter::Able::Remove-Prefix;
use Iter::Able::Remove-Suffix;
use Iter::Able::For-Each;
use Iter::Able::Split-At;
use Iter::Able::Some;
use Iter::Able::Every;
use Iter::Able::Noone;

# Subscribe all the subs to the package as well in case one wants to refer
# to them with their semi-FQNs, e.g., `Iter::Able::take-while(...)`, e.g., to
# prevent naming collisions or such.
OUR::{.key} = .value for MY::.grep(*.key.starts-with('&'));
