package Games::SavingSue::Menu;
use strict;
use warnings;
use SDL;
use SDL::Events;
use SDLx::Audio;
use Sub::Frequency;
use SDLx::Widget::Menu;

sub startup {
    my ($self, $app) = @_;

    my $sound = SDLx::Audio->new->load(
        horn1 => 'data/car_horn1.wav',
        horn2 => 'data/car_horn2.wav',
    );

    my $logo = SDLx::Surface->load('data/opening.png');

    my $menu = SDLx::Widget::Menu->new(
        font    => 'data/font.ttf',
        topleft => [440,340],
        font_size => 40,
    )->items(
        'New Game' => sub { play($app) },
        'Quit'     => sub { quit($app) },
    );

    $app->add_event_handler( sub {
        my $event = shift;
        $menu->event_hook( $event );
    });

    $app->add_show_handler( sub {
        my ($delta, $app) = @_;

        $logo->blit($app);
        $menu->render( $app );

        $app->update;
    });

    $app->add_show_handler( sub {
        my ($delta, $app) = @_;

        with_probability 0.1 => sub {
            $sound->play('horn1');
        };

        with_probability 0.005 => sub {
            $sound->play('horn2');
        };
    });

}

sub play {
    my $app = shift;
    $app->stash->{next_state} = 'Level';
    $app->stop;
}

sub quit {
    my $app = shift;
    $app->stash->{next_state} = undef;
    $app->stop;
}


'all your base are belong to us.'
