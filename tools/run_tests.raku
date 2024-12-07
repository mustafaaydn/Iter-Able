#= Run the tests in the t/ directory, report results
#= TODO: more configurable, e.g., suppress stdout/err, which tests to run, when to stop etc.
use Iter::Able <enumerate>;  # using a function before testing itself?! cool

my (%failed, $total);
for dir("t", test => *.ends-with(".rakutest")).&enumerate(:1start) -> (Int $idx, IO $test-file) {
    print "$idx\'th: $test-file... ";
    my @command = <<raku $test-file>>;
    my $proc = run @command, :err;
    if $proc.exitcode == 0 {
        put "successful!";
    }
    else {
        %failed{$test-file} = $proc.err.slurp;
        put "FAILED!";
    }
    put "-" x 40;
    $total++;
}

print "Ran all $total test files; ";
if !%failed {
    put "ALL of them are ok!";
}
else {
    put "{+%failed} failed; here they are:\n";
    "\t$_.key()\n$_.value()".say for %failed.sort;
}
