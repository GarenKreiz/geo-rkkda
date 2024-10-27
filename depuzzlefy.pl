#!/usr/bin/env perl
# // https://gist.github.com/sirkro/241ef6924245c3ffa6c2
use 5.012;
use warnings;

use File::Temp;
use IPC::System::Simple qw(capture system);
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use File::Copy;

my $url = shift || die 'missing url';

my $ua = LWP::UserAgent->new;
my $res = $ua->get($url);
die $res->status_line unless $res->is_success;

my $content = $res->decoded_content // $res->content // die 'no content';

my @url = $content =~ m[<embed(?: [^>]*?)? src="([^"]+)"]gi;
die 'no swf urls found' unless @url;

for my $url (@url) {
    my $uri = URI->new($url);

    my ($h, $w, $id) = map $uri->query_param($_), qw(h w id);
    next unless $h and $w and $id;
    $uri->query_param(c => 'z');

    my $swf = File::Temp->new(suffix => '.swf');
    my $res = $ua->get($uri, ':content_file' => $swf->filename);

    my $out = capture swfextract => $swf;
    my ($ids) = $out =~ /^\s*\[-j\] \d+ JPEGs: ID\(s\) (\d+,.*)/m;
    
    my @ids = split(", ", $ids);
    
    my $dir = File::Temp->newdir;
        
    foreach my $id (@ids) {
        system swfextract => '-j', $id, '--outputformat', "$dir/%05d.%s", $swf;    
    }
    
     my @jpg = glob "$dir/*.jpg";

    $out = capture identify => $jpg[0];
    my ($x, $y) = $out =~ / JPEG (\d+)x(\d+)/;
    next unless $x and $y and $x == $y;
    $_ = int $_ / $x * 2 for $w, $h;
    # The edges of each puzzle piece image need to be overlapped.
    $_ = int $_ / 4 for $x, $y;

    my $img = "gjp-$id.jpg";
    system montage => '-tile', "${w}x$h", '-geometry', "-$x-$y", @jpg, $img;
}
