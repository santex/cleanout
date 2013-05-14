package Cleanout;
use strict;
use warnings;
use utf8;
use List::AllUtils qw( shuffle );
binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use constant POCO_HTTP => "ua";
use POE qw(Component::Client::HTTP);

our @urls = [qw(http://www.latest-ufo-sightings.net/search/label/2013?&max-results=500)];
if(@ARGV){  
push @urls,@ARGV;
}
our @youtubecodes = ();
our @links;
my $TOP = "ufo";


require Exporter;

our @ISA = qw(Exporter);


our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
new
);

our $VERSION = '0.01';

our $img = "";

our $result = {};



sub new {
    my $class = shift;
    my $this  = bless {
    }, $class;


POE::Component::Client::HTTP->spawn(Alias => POCO_HTTP, Timeout => 30);
POE::Component::My::Master->spawn(UA => POCO_HTTP, TODO => @urls);
$poe_kernel->run;
exit 0;

}



BEGIN {
  package POE::Component::My::Master;
  use POE::Session;             # for constants

  sub spawn {
    my $class = shift;
    POE::Session->create
        (package_states =>
         [$class => [qw(_start ready done)]],
         heap => {KIDMAX => 8, KIDS => 0, @_});
  }

  sub _start {
    my $heap = $_[HEAP];
    for (@{$heap->{TODO}}) {
      $heap->{DONE}{$_ = make_canonical($_)} = 1;
    }
    $_[KERNEL]->yield("ready", "initial");
  }

  sub ready {
    ## warn "ready because $_[ARG0]\n";
    my $heap = $_[HEAP];
    my $kernel = $_[KERNEL];
    return if $heap->{KIDS} >= $heap->{KIDMAX};
    return unless my $url = shift @{$heap->{TODO}};
    ## warn "doing: $url\n";
    $heap->{KIDS}++;
    POE::Component::My::Checker->spawn
        (UA => $heap->{UA},
         URL => $url,
         POSTBACK => $_[SESSION]->postback("done", $url),
        );
    $kernel->yield("ready", "looping");
  }

  sub done {
    my $heap = $_[HEAP];
    my ($request,$response) = @_[ARG0,ARG1];

    my ($url) = @$request;
    my @links = @{$response->[0]};

    for my $n (@links) {
      if($n!~/max-results/){
      $n .="?max-results=5999";
      }else{
            $n =~ s/results=/results=99/g;

        }
      $n = make_canonical($n);
      push @{$heap->{TODO}}, $n;
#        unless $heap->{DONE}{$_}++;
    }

    $heap->{KIDS}--;
    $_[KERNEL]->yield("ready", "child done");
  }

  sub make_canonical {          # not a POE
    require URI;
    my $uri = URI->new(shift);
    $uri->fragment(undef);      # toss fragment
    $uri->canonical->as_string; # return value
  }

}                               # end POE::Component::My::Master

BEGIN {
  package POE::Component::My::Checker;
  use POE::Session;
  use Data::Printer;
  use WWW::YouTube::Download;

  if(-f "/tmp/codes"){

  }else{
    system("echo ''>/tmp/codes");
  }

  sub spawn {
    my $class = shift;
    POE::Session->create
        (package_states =>
         [$class => [qw(_start response)]],
         heap => {@_});
  }

  sub _start {
    require HTTP::Request::Common;
    my $heap = $_[HEAP];
    my $url = $heap->{URL};
    my $request = HTTP::Request::Common::GET($url);
    $_[KERNEL]->post($heap->{UA}, 'request', 'response', $request);
  }



sub test_video_id {
    my ($input) = @_;
    return video_id($input);
}




    sub video_id {
      my $stuff = shift;
      if ($stuff =~ m{/.*?[?&;!]v=([^&#?=/;]+)}) {
          return $1;
      }
      elsif ($stuff =~ m{/(?:e|v|embed)/([^&#?=/;]+)}) {
          return $1;
      }
      elsif ($stuff =~ m{#p/(?:u|search)/\d+/([^&?/]+)}) {
          return $1;
      }
      elsif ($stuff =~ m{youtu.be/([^&#?=/;]+)}) {
          return $1;
      }
      else {
          return $stuff;
      }
  }


  sub response {
    my $url = $_[HEAP]{URL};
    my ($request_packet, $response_packet) = @_[ARG0, ARG1];
    my ($request, $request_tag) = @$request_packet;
    my ($response) = @$response_packet;



    if ($response->is_success) {
        if ($response->content_type eq "text/html") {
          require HTML::SimpleLinkExtor;
          my $e = HTML::SimpleLinkExtor->new($response->base);
          my $content = $response->content;
          $e->parse($content);

          @links = grep m{^http:}, $e->links;
           my $vidurl = "youtube.com/embed";



          warn "doing on: $url\n";

          foreach(grep{/$vidurl/}@links){


            my $a = $_;
            $a =~ s/http:\/\/www\.youtube.*.[\/].*(watch|embed)*.[\/](.?)/$1/gi;
            $a = substr($a,0,11);

            print $_."\t$a\n";

            system("echo $_>>/tmp/codes");




          }


#          my @img = grep m{^http:}, $e->img;
#           warn $#links."\n";
 #          print "\n". join("\n",grep{/$TOP/}@img)unless(!@img);
  #         @img = grep{/$TOP/}@img;
   #        @img = grep{!/ico|^fb*|logo|button|user|placehold|mail|loading|twitter|webs|rss|right|left|top|bottom|header|banner|add|campaign|icon/ui}@img;


    #       map{`wget $_ &`}@img;

#           map{`wget $_ &`}@links;
        } else {
#           warn "not HTML: $url\n";
        }
    } else {
#      warn "BAD (", $response->code, "): $url\n";
    }

    if(-f "/tmp/codesu"){}else{
       system("echo '' > /tmp/codesu");
    }
    system("cat /tmp/codes | sort -u > /tmp/codesu;");
   # system("mv /tmp/codesu /tmp/codes;");
    $_[HEAP]{POSTBACK}(\@links);
  }

}

BEGIN {

  use Data::Printer;

  my $pwd=sprintf `pwd`;

  print $pwd;
    $pwd =~ s/^\s+//;
    $pwd =~ s/\s+$//;
    $pwd =~ s/\t//;
    $pwd =~ s/^\s//;

  foreach(qw(png gif jpg  jpeg)){
    system("for u in \$(ls $pwd/*.$_.*[0-9]);do mv \$u \$u.$_; done");
  }
`for i in \$(ls * | egrep -i "*\.[1-9]\.*(png|jpg|gif)"); do rm \$i; done`;
push @ARGV,  [shuffle split("\n",`mm=\$(mech-dump --links http://www.latest-ufo-sightings.net/search/label/2013?&max-results=500);  echo -e "\$mm\n"  | egrep "^http.*.html\$"`)];


p @ARGV;

}

new Cleanout();

END {


  my $pwd=sprintf `pwd`;

  print $pwd;
    $pwd =~ s/^\s+//;
    $pwd =~ s/\s+$//;
    $pwd =~ s/\t//;
    $pwd =~ s/^\s//;

  foreach(qw(png gif jpg  jpeg)){
    system("for u in \$(ls $pwd/*.$_.*[0-9]);do mv \$u \$u.$_; done");
  }



 exit(0);
}

1;
__DATA__
