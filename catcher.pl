#!/usr/bin/env perl

use Mojo::Base -strict, -signatures;
use DateTime;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Log;
use Tie::File;


my $log = Mojo::Log->new(path => "./divi-catcher.log");
my $ua = Mojo::UserAgent->new();

my $edocBase = Mojo::URL->new("https://edoc.rki.de");
my $rkiPageUrl = Mojo::URL->new("https://edoc.rki.de/handle/176904/7012");

my $dom = $ua->get($rkiPageUrl)->res->dom;

my $reportList = $dom->at("ul.ds-artifact-list");
my $listItems = $reportList->children("li.ds-artifact-item");
$log->info("Found " . $listItems->size . " ds-artifact-items");

$listItems->each(sub($item, $num) {
    my $dateBadge = $item->find(".artifact-badges span.badge span.date")->first;
    if(!$dateBadge) {
        $log->error("Failed to identify date badge!");
        return;
    }

    my $date = $dateBadge->text;
    if($date !~ /^\d\d\d\d-\d\d-\d\d$/) {
        $log->error("Found some span.date but text='" . $date . "' does not look like date. ");
        return;
    }

    my $filename = "./DIVI/" . $date . ".csv";

    if(-e $filename) {
        $log->info("Tagesreport for $date already exists. Skipping.");
    }
    else {
        $log->info("Fetching Tagesreport for $date");
        my $link = $item->children("a")->first->attr("href");
        my $subPage = $edocBase->path($link);
        $log->debug("Fetching subPage=$subPage");

        my $subPageDom = $ua->get($subPage)->res->dom;
        my $artifactLinkUrl = $subPageDom->at(".ds-artifact-item > a")->attr("href");
        my $artifactUrl = Mojo::URL->new($artifactLinkUrl)->base($edocBase)->to_abs();
        $log->debug("ArtifactURL=$artifactUrl");

        my $tagesreport = $ua->get($artifactUrl);
        $tagesreport->res->save_to($filename);
        $log->info("Stored Tagesreport for date=$date in filename=$filename");
    }


});
