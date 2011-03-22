package SDLx::Audio;
use strict;
use warnings;
use Carp ();
use SDL;
use SDL::Mixer;
use SDL::Mixer::Music;
use SDL::Mixer::Channels;
use SDL::Mixer::Samples;
use SDL::Mixer::MixChunk;
use Data::Printer;

my $has_audio = SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 4096 ) == 0 ? 1 : 0;

Carp::carp 'Unable to initialize audio: ' . SDL::get_error
    unless $has_audio;


sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    return $self;
}

sub music {
    my ($self, $file) = @_;
    $self->{music} = SDL::Mixer::Music::load_MUS( $file )
        or die "error loading music" . SDL::get_error;

    return $self;
}

sub play_music {
    my $self = shift;

    my $music = $self->{music}
        or die "please choose a music with first";

    SDL::Mixer::Music::play_music( $music, -1 );
}

sub load {
    my ($self, %samples) = @_;
    Carp::croak 'Syntax: load( label => "path/to/file" )'
        unless %samples;

    foreach my $key (keys %samples) {
        Carp::croak "file $samples{$key} not found"
            unless -e $samples{$key};

        my $sample = SDL::Mixer::Samples::load_WAV( $samples{$key} )
            or Carp::croak "error loading sound sample $samples{$key}";

        $self->{_samples}->{$key} = $sample;
    }

    return $self;
}


sub play {
    my ($self, $label, $times, $ms) = @_;

    Carp::croak "Sample label '$label' not found."
        unless exists $self->{_samples}->{$label};

    $times = 1 unless defined $times;
    Carp::croak "Loop times must be 0 or above"
        unless $times >= 0;

    my $channel = SDL::Mixer::Channels::play_channel(
        -1,
        $self->{_samples}->{$label},
        $times - 1,
    );

    $self->{_channels}->{$label} = $channel;
}


sub playing {
    my ($self, $label) = @_;

    my $channel = -1;
    if ($label) {
        if ( not exists $self->{_channels}->{$label} ) {
            Carp::carp "'$label' not running";
            return;
        }
        $channel = $self->{_channels}->{$label};
    }
    
    return SDL::Mixer::Channels::playing ($channel);
}

# close our audio on program ending.
# Note that this does *NOT* catch signals
# but then again, neither did our previous
# attempt :)
END {
    SDL::Mixer::close_audio();
}

'all your audio are belong to us';

