#!/usr/bin/perl

#
# Copyright (C) 2025 Joelle Maslak
# All Rights Reserved - See License
#

use WTFIMPD::Boilerplate;

my $CONGRESS_URL='https://unitedstates.github.io/congress-legislators/legislators-current.json';
my $ZIP_URL='https://raw.githubusercontent.com/OpenSourceActivismTech/us-zipcodes-congress/refs/heads/master/zccd.csv';
my $CONGRESS_FILENAME='congress.json';
my $ZIP_FILENAME='zccd.json';

class WTFIMPD::Congress {
    use Mojo::UserAgent;
    use Mojo::File qw(path);
    use Mojo::JSON qw(decode_json encode_json);

    use List::Util qw(uniqstr any);
    use Text::CSV_XS qw(csv);

    field $config :param;
    field $members :reader;
    field $zips :reader;

    method fetch_congress() {
        my $ua = Mojo::UserAgent->new;
        my $res = $ua->get($CONGRESS_URL)->result;
        if ($res->is_success) {
            my $json = $res->json;
            if (scalar(@$json) > 535) {
                my $path = path($config->{data_dir})->child($CONGRESS_FILENAME);
                $path->spew($res->body) or confess($!);
            } else {
                confess("Could not fetch at least 535 membrs");
            }
        } else {
            confess("Could not fetch data");
        }
    }

    method fetch_zip() {
        my $ua = Mojo::UserAgent->new;
        my $res = $ua->get($ZIP_URL)->result;
        if ($res->is_success) {
            my $body = $res->body;
            my $csv = csv(in => \$body, headers => "auto");
            my %data;
            for my $row (@$csv) {
                my $zc = $row->{zcta};
                if (!exists($data{$zc})) {
                    $data{$zc} = [];
                }
                push $data{$zc}->@*, $row->{state_abbr} . "_" . $row->{cd};
            }

            if ($data{82716}[0] ne 'WY_0') {
                confess("82716 not found");
            }

            my $json = encode_json(\%data);
            my $path = path($config->{data_dir})->child($ZIP_FILENAME);
            $path->spew($json) or confess($!);
        } else {
            confess("Could not fetch data");
        }
    }

    method fetch() {
        $self->fetch_congress();
        $self->fetch_zip();
    }

    method read() {
        my $path = path($config->{data_dir})->child($CONGRESS_FILENAME);
        my $raw = $path->slurp or confess($!);
        my $json = decode_json($raw) or confess($!);
        $members = $json;

        $path = path($config->{data_dir})->child($ZIP_FILENAME);
        $raw = $path->slurp or confess($!);
        $json = decode_json($raw) or confess($!);
        $zips = $json;
    }

    method zip_to_districts($zip) {
        if (!exists($zips->{$zip})) {
            return undef;
        }

        return $zips->{$zip}->@*;
    }

    method members_district(@districts) {
        my @ret;

        my @states = uniqstr map { (split "_", $_)[0] } @districts;

        for my $member (@$members) {
            my $term = $member->{terms}[-1];
            if ($term->{type} eq 'sen') {
                if (any { $term->{state} eq $_ } @states) {
                    $member->{fulldistrict} = $term->{state};
                    $member->{sortkey} = $term->{state};
                    $member->{title} = "Sen.";
                    push @ret, $member;
                }
            } elsif ($term->{type} eq 'rep') {
                if (any { $term->{state}."_".$term->{district} eq $_} @districts) {
                    if ($term->{district} != 0) {
                        $member->{fulldistrict} = $term->{state} . $term->{district};
                        $member->{sortkey} = sprintf("%s_%03d Z", $term->{state}, $term->{district});
                    } else {
                        $member->{fulldistrict} = $term->{state};
                        $member->{sortkey} = $term->{state} . " Z";
                    }
                    $member->{title} = "Rep.";
                    push @ret, $member;
                }
            }
        }

        return @ret;
    }

    method zip_to_assholes($zip) {
        return sort { $a->{sortkey} cmp $b->{sortkey} } $self->members_district($self->zip_to_districts($zip));
    }
}

1;

