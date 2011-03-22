package Games::SavingSue;
use strict;
use warnings;

use SDL;
use SDLx::App;
use SDLx::Audio;
use Class::Unload;


sub start {
    my $app = SDLx::App->new(
        title  => 'Saving Sue',
        width  => 800,
        height => 600,
        eoq    => 1,
    );

    my $bgmusic = SDLx::Audio->new->music('data/bgmusic.ogg');
    $bgmusic->play_music;

    # initial state
    my $state = 'Menu';

    while ($state) {
        my $class = 'Games::SavingSue::' . $state;
        eval "require $class";
        $class->startup( $app );

        $app->run;
        $app->remove_all_handlers;

        Class::Unload->unload($class);
        $state = $app->stash->{next_state};
        $app->stash->{next_state} = undef;
    }
}


'all your base are belong to us.'
