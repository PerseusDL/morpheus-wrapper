#!/usr/bin/perl
package Alpheios::LatinMorph;
use strict;
use Benchmark;
use Cwd;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Encode;
  
use Apache2::Const -compile => qw(OK);


# Package Global Variables
my $version = "1.0-alpheios";
my $suppress = 0;
my $execDir = '/var/www/perl/Alpheios/morpheus/platform/Linux_x86-gcc4';
my $execFile = 'morpheus -L -m../../stemlib -S';
my $usage = <<"END_OF_USAGE";
    LatinMorph: Latin morphological analyzer and POS tagger, v. $version

    Usage:   perl $0 [options] <word1> [<word2> ...]

    Options:
      &h, &help             Print usage
      &v, &version          Print version ($version)
END_OF_USAGE

# Registered as PerlPostConfigHandler, this method should only be called
# once per parent HTTPD process. It initializes the dictionary data which is shared by all child 
# HTTPD Processes and threads.
sub post_config {
    return Apache2::Const::OK;
}



sub handler {
    my $t3 = new Benchmark;
    my $r = shift; # The Apache request object
    my $querystring = $r->args() || q{};
    my %params;
    foreach my $arg (split /[&;]/, $querystring) {
        my ($name,$value) = $arg =~ /^(.+)=(.*)$/;
        push @{$params{$name}},$value;
    }
 
    if ($params{'h'} || $params{'help'} || $params{'v'} || $params{'version'})
    {
        $r->content_type("text/plain");
         print $usage;
        return Apache2::Const::OK;
    }
    # untaint input 
    my $words = join ',', 
        map { s/[^\w|\d|\s]//g; $_; }
        map { s/[\x{00c0}\x{00c1}\x{00c2}\x{00c3}\x{00c4}\x{0100}\x{0102}]/A/g; $_; }
        map { s/[\x{00c8}\x{00c9}\x{00ca}\x{00cb}\x{0112}\x{0114}]/E/g; $_; }
        map { s/[\x{00cc}\x{00cd}\x{00ce}\x{00cf}\x{012a}\x{012c}]/I/g; $_; }
        map { s/[\x{00d2}\x{00d3}\x{00d4}\x{00df}\x{00d6}\x{014c}\x{014e}]/O/g; $_;}
        map { s/[\x{00d9}\x{00da}\x{00db}\x{00dc}\x{0016a}\x{016c}]/U/g; $_;}
        map { s/[\x{00c6}\x{01e2}]/AE/g; $_; }
        map { s/[\x{0152}]/OE/g; $_; }
        map { s/[\x{00e0}\x{00e1}\x{00e2}\x{00e3}\x{00e4}\x{0101}\x{0103}]/a/g; $_; }
        map { s/[\x{00e8}\x{00e9}\x{00ea}\x{00eb}\x{0113}\x{0115}]/e/g; $_; }
        map { s/[\x{00ec}\x{00ed}\x{00ee}\x{00ef}\x{012b}\x{012d}\x{0129}]/i/g; $_; }
        map { s/[\x{00f2}\x{00f3}\x{00f4}\x{00f5}\x{00f6}\x{014d}\x{014f}]/o/g; $_; }
        map { s/[\x{00f9}\x{00fa}\x{00fb}\x{00fc}\x{0016b}\x{016d}]/u/g; $_; }
        map { s/[\x{00e6}\x{01e3}]/ae/g; $_; }
        map { s/[\x{0153}]/oe/g; $_;}
        map { decode("UTF-8", $_); } 
                          map { s/%([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;  
                                $_;
                              }
                          @{$params{word}};
    my $cwd = getcwd;
    print STDERR "Current dir=$cwd\n" unless $suppress;
    chdir($execDir) or warn "$!\n";
    print STDERR "Current dir=" . (getcwd) . "\n" unless $suppress;
    my $response = `./$execFile $words`;
    $response =~ s/<hdwd xml:lang="lat">(.*?)#(\d+)<\/hdwd>/<hdwd xml:lang="lat">$1$2<\/hdwd>/mg;
    chdir $cwd;
    $r->content_type("text/xml");
    print $response; 

    my $t4 = new Benchmark; 
    print STDERR timestr(timediff($t4, $t3), 'noc'), "\n" unless $suppress;
    return Apache2::Const::OK;
}


1;
